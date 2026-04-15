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
            timePitch.rate = max(0.25, min(2.0, tempo / 100))
        }
    }

    var pitchSemitonos: Float = 0 {
        didSet {
            let acotado = max(-12, min(12, pitchSemitonos))
            timePitch.pitch = acotado * 100
        }
    }

    init() {
        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.connect(playerNode, to: timePitch, format: nil)
        engine.connect(timePitch, to: engine.mainMixerNode, format: nil)
    }

    func cargarAudioDelBundle(nombre: String, extensión: String) throws {
        detener()

        guard let url = Bundle.main.url(forResource: nombre, withExtension: extensión) else {
            throw ErrorAudio.archivoNoEncontrado(nombre: "\(nombre).\(extensión)")
        }

        let archivo = try AVAudioFile(forReading: url)
        self.audioFile = archivo
        self.nombreArchivoCargado = "\(nombre).\(extensión)"
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
                return "No se encontró el archivo de audio '\(nombre)' en el bundle."
            case .archivoNoCargado:
                return "No hay ningún archivo de audio cargado en el reproductor."
            }
        }
    }
}
