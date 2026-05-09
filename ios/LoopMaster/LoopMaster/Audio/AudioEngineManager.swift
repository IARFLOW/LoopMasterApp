import AVFoundation
import Observation
import os

@MainActor
@Observable
final class AudioEngineManager {

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()

    private var audioFile: AVAudioFile?
    private(set) var duracionSegundos: Double = 0
    private(set) var nombreArchivoCargado: String = ""

    private(set) var posicionSegundos: Double = 0
    private var offsetSegundos: Double = 0
    private var tieneSegmentoSchedulado: Bool = false
    private var tokenScheduling: Int = 0
    private var timerActualizacion: Timer?

    private var sampleTimeReferencia: AVAudioFramePosition?
    private var sampleRateOutput: Double = 44100

    private let framesEntregados = OSAllocatedUnfairLock<Int64>(initialState: 0)
    private var framesEntregadosInicio: Int64 = 0
    private var tapInstalado: Bool = false

    var reproduciendo: Bool = false

    var tempo: Float = 100 {
        willSet {
            if reproduciendo {
                consolidarOffsetConRateActual()
            }
        }
        didSet {
            timePitch.rate = max(0.25, min(1.75, tempo / 100))
            actualizarBypass()
            if reproduciendo {
                resetearReferenciaFrames()
                capturarReferenciaRender()
            }
        }
    }

    var pitchSemitonos: Float = 0 {
        didSet {
            let acotado = max(-12, min(12, pitchSemitonos))
            timePitch.pitch = acotado * 100
            actualizarBypass()
        }
    }

    var volumen: Float = 1.0 {
        didSet {
            let acotado = max(0, min(1, volumen))
            engine.mainMixerNode.outputVolume = acotado
        }
    }

    init() {
        configurarSesionAudio()
        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.connect(playerNode, to: timePitch, format: nil)
        engine.connect(timePitch, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = volumen
        actualizarBypass()
    }

    private func actualizarBypass() {
        let rateNeutral = abs(timePitch.rate - 1.0) < 0.005
        let pitchNeutral = abs(timePitch.pitch) < 1.0
        timePitch.bypass = rateNeutral && pitchNeutral
    }

    private func configurarSesionAudio() {
        #if os(iOS) || os(tvOS) || os(watchOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    func cargarAudioDelSandbox(nombreArchivo: String) throws {
        detener()
        let url = BibliotecaAudio.urlEnSandbox(nombreArchivo: nombreArchivo)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw ErrorAudio.archivoNoEncontrado(nombre: nombreArchivo)
        }
        try cargarArchivo(desde: url, nombreVisible: nombreArchivo)
        offsetSegundos = 0
        posicionSegundos = 0
        tieneSegmentoSchedulado = false
    }

    private func cargarArchivo(desde url: URL, nombreVisible: String) throws {
        let archivo = try AVAudioFile(forReading: url)
        self.audioFile = archivo
        self.nombreArchivoCargado = nombreVisible
        let frecuenciaMuestreo = archivo.processingFormat.sampleRate
        self.duracionSegundos = Double(archivo.length) / frecuenciaMuestreo

        alinearHardwareConArchivo(formato: archivo.processingFormat)
        desinstalarTap()
        reconectarNodosConFormato(archivo.processingFormat)
    }

    private func instalarTapSiHaceFalta() {
        guard !tapInstalado else { return }
        guard engine.isRunning else { return }
        let contador = framesEntregados
        let cb: @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void = { buffer, _ in
            let frames = Int64(buffer.frameLength)
            contador.withLock { valor in
                valor &+= frames
            }
        }
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: nil, block: cb)
        tapInstalado = true
    }

    private func desinstalarTap() {
        if tapInstalado {
            engine.mainMixerNode.removeTap(onBus: 0)
            tapInstalado = false
        }
    }

    private func leerFramesEntregados() -> Int64 {
        framesEntregados.withLock { $0 }
    }

    private func resetearReferenciaFrames() {
        framesEntregadosInicio = leerFramesEntregados()
    }

    private func alinearHardwareConArchivo(formato: AVAudioFormat) {
        #if os(iOS) || os(tvOS) || os(watchOS)
        try? AVAudioSession.sharedInstance().setPreferredSampleRate(formato.sampleRate)
        #endif
    }

    private func reconectarNodosConFormato(_ formato: AVAudioFormat) {
        let estabaCorriendo = engine.isRunning
        if estabaCorriendo {
            engine.stop()
        }
        engine.disconnectNodeOutput(playerNode)
        engine.disconnectNodeOutput(timePitch)
        engine.connect(playerNode, to: timePitch, format: formato)
        engine.connect(timePitch, to: engine.mainMixerNode, format: formato)
    }

    func reproducir() throws {
        guard let archivo = audioFile else {
            throw ErrorAudio.archivoNoCargado
        }

        if !engine.isRunning {
            try engine.start()
        }
        instalarTapSiHaceFalta()

        if reproduciendo {
            return
        }

        if !tieneSegmentoSchedulado {
            tokenScheduling &+= 1
            let miToken = tokenScheduling
            playerNode.scheduleFile(archivo, at: nil) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.alFinalizarSiToken(miToken)
                }
            }
            tieneSegmentoSchedulado = true
        }

        playerNode.play()
        reproduciendo = true
        resetearReferenciaFrames()
        capturarReferenciaRender()
        iniciarTimer()
    }

    func pausar() {
        guard reproduciendo else { return }
        consolidarOffsetConRateActual()
        playerNode.pause()
        reproduciendo = false
        sampleTimeReferencia = nil
        timerActualizacion?.invalidate()
        timerActualizacion = nil
    }

    func detener() {
        tokenScheduling &+= 1
        playerNode.stop()
        reproduciendo = false
        tieneSegmentoSchedulado = false
        offsetSegundos = 0
        posicionSegundos = 0
        sampleTimeReferencia = nil
        timerActualizacion?.invalidate()
        timerActualizacion = nil
    }

    func saltarA(segundo: Double) {
        guard let archivo = audioFile else { return }
        let segundoLimitado = max(0, min(duracionSegundos, segundo))
        let estabaReproduciendo = reproduciendo

        tokenScheduling &+= 1
        let miToken = tokenScheduling

        playerNode.stop()
        reproduciendo = false
        sampleTimeReferencia = nil
        timerActualizacion?.invalidate()
        timerActualizacion = nil

        let frecuencia = archivo.processingFormat.sampleRate
        let frameInicio = AVAudioFramePosition(segundoLimitado * frecuencia)
        let framesRestantes = AVAudioFrameCount(max(0, archivo.length - frameInicio))

        offsetSegundos = segundoLimitado
        posicionSegundos = segundoLimitado
        tieneSegmentoSchedulado = false

        guard framesRestantes > 0 else { return }

        playerNode.scheduleSegment(
            archivo,
            startingFrame: frameInicio,
            frameCount: framesRestantes,
            at: nil
        ) { [weak self] in
            Task { @MainActor [weak self] in
                self?.alFinalizarSiToken(miToken)
            }
        }
        tieneSegmentoSchedulado = true

        if estabaReproduciendo {
            if !engine.isRunning {
                try? engine.start()
            }
            instalarTapSiHaceFalta()
            playerNode.play()
            reproduciendo = true
            resetearReferenciaFrames()
            capturarReferenciaRender()
            iniciarTimer()
        }
    }

    private func alFinalizarSiToken(_ token: Int) {
        guard token == tokenScheduling else { return }
        alFinalizarReproduccion()
    }

    private func alFinalizarReproduccion() {
        reproduciendo = false
        tieneSegmentoSchedulado = false
        timerActualizacion?.invalidate()
        timerActualizacion = nil
        posicionSegundos = duracionSegundos
    }

    private func iniciarTimer() {
        timerActualizacion?.invalidate()
        timerActualizacion = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refrescarPosicion()
            }
        }
    }

    private func capturarReferenciaRender() {
        let outputRender = engine.outputNode.lastRenderTime
        let mixerRender = engine.mainMixerNode.lastRenderTime
        let render = outputRender ?? mixerRender
        guard let render else {
            sampleTimeReferencia = nil
            return
        }
        sampleTimeReferencia = render.sampleTime
        let outputSR = engine.outputNode.outputFormat(forBus: 0).sampleRate
        if outputSR > 0 {
            sampleRateOutput = outputSR
        } else if render.sampleRate > 0 {
            sampleRateOutput = render.sampleRate
        }
    }

    private func segundosArchivoDesdeReferencia() -> Double? {
        guard sampleRateOutput > 0 else { return nil }
        let framesActual = leerFramesEntregados()
        let framesDelta = framesActual - framesEntregadosInicio
        guard framesDelta >= 0 else { return nil }
        let segundosTap = Double(framesDelta) / sampleRateOutput
        return segundosTap * Double(timePitch.rate)
    }

    private func refrescarPosicion() {
        guard reproduciendo else { return }
        if sampleTimeReferencia == nil {
            capturarReferenciaRender()
            guard sampleTimeReferencia != nil else { return }
        }
        guard let segundosArchivo = segundosArchivoDesdeReferencia() else { return }
        posicionSegundos = min(duracionSegundos, max(0, offsetSegundos + segundosArchivo))
    }

    private func consolidarOffsetConRateActual() {
        guard let segundosArchivo = segundosArchivoDesdeReferencia() else { return }
        offsetSegundos = min(duracionSegundos, max(0, offsetSegundos + segundosArchivo))
    }

    enum ErrorAudio: Error, LocalizedError {
        case archivoNoEncontrado(nombre: String)
        case archivoNoCargado

        var errorDescription: String? {
            switch self {
            case .archivoNoEncontrado(let nombre):
                return "No se encontró el archivo de audio '\(nombre)'."
            case .archivoNoCargado:
                return "No hay ningún archivo de audio cargado en el reproductor."
            }
        }
    }
}
