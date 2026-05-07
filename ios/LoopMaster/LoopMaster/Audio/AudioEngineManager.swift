import AVFoundation
import Observation

@MainActor
@Observable
final class AudioEngineManager {

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()

    private var audioFile: AVAudioFile?
    private(set) var duracionSegundos: Double = 0
    private(set) var nombreArchivoCargado: String = ""

    var reproduciendo: Bool = false

    var tempo: Float = 100 {
        didSet {
            timePitch.rate = max(0.25, min(1.75, tempo / 100))
            actualizarBypass()
        }
    }

    var pitchSemitonos: Float = 0 {
        didSet {
            let acotado = max(-12, min(12, pitchSemitonos))
            timePitch.pitch = acotado * 100
            actualizarBypass()
        }
    }

    init() {
        configurarSesionAudio()
        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.connect(playerNode, to: timePitch, format: nil)
        engine.connect(timePitch, to: engine.mainMixerNode, format: nil)
        actualizarBypass()
    }

    private func actualizarBypass() {
        let rateNeutral = abs(timePitch.rate - 1.0) < 0.005
        let pitchNeutral = abs(timePitch.pitch) < 1.0
        timePitch.bypass = rateNeutral && pitchNeutral
    }

    private func configurarSesionAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioEngineManager: no se pudo configurar AVAudioSession: \(error)")
        }
    }

    func cargarAudioDelSandbox(nombreArchivo: String) throws {
        detener()
        let url = BibliotecaAudio.urlEnSandbox(nombreArchivo: nombreArchivo)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw ErrorAudio.archivoNoEncontrado(nombre: nombreArchivo)
        }
        try cargarArchivo(desde: url, nombreVisible: nombreArchivo)
    }

    private func cargarArchivo(desde url: URL, nombreVisible: String) throws {
        let archivo = try AVAudioFile(forReading: url)
        self.audioFile = archivo
        self.nombreArchivoCargado = nombreVisible
        let frecuenciaMuestreo = archivo.processingFormat.sampleRate
        self.duracionSegundos = Double(archivo.length) / frecuenciaMuestreo
    }

    func reproducir() throws {
        guard let archivo = audioFile else {
            throw ErrorAudio.archivoNoCargado
        }

        if !engine.isRunning {
            try engine.start()
        }

        if reproduciendo {
            return
        }

        playerNode.scheduleFile(archivo, at: nil) { [weak self] in
            Task { @MainActor in
                self?.reproduciendo = false
            }
        }
        playerNode.play()
        reproduciendo = true
    }

    func pausar() {
        guard reproduciendo else { return }
        playerNode.pause()
        reproduciendo = false
    }

    func detener() {
        playerNode.stop()
        reproduciendo = false
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
