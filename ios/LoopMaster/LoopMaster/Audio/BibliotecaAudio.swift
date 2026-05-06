import AVFoundation
import Foundation

enum BibliotecaAudio {

    static func urlEnSandbox(nombreArchivo: String) -> URL {
        directorioCanciones().appending(path: nombreArchivo)
    }

    static func importarArchivo(desde origen: URL) throws -> ArchivoImportado {
        let necesitaScope = origen.startAccessingSecurityScopedResource()
        defer {
            if necesitaScope {
                origen.stopAccessingSecurityScopedResource()
            }
        }

        let directorio = directorioCanciones()
        try crearDirectorioSiHaceFalta(directorio)

        let nombreFinal = nombreUnico(en: directorio, basadoEn: origen.lastPathComponent)
        let destino = directorio.appending(path: nombreFinal)

        try FileManager.default.copyItem(at: origen, to: destino)

        let duracion = try duracionSegundos(de: destino)
        return ArchivoImportado(nombreArchivo: nombreFinal, duracionSegundos: duracion)
    }

    static func copiarRecursoDelBundleSiHaceFalta(
        nombre: String,
        extensión: String
    ) throws -> ArchivoImportado? {
        let directorio = directorioCanciones()
        try crearDirectorioSiHaceFalta(directorio)

        let nombreCompleto = "\(nombre).\(extensión)"
        let destino = directorio.appending(path: nombreCompleto)

        if FileManager.default.fileExists(atPath: destino.path(percentEncoded: false)) {
            let duracion = try duracionSegundos(de: destino)
            return ArchivoImportado(nombreArchivo: nombreCompleto, duracionSegundos: duracion)
        }

        guard let origen = Bundle.main.url(forResource: nombre, withExtension: extensión) else {
            return nil
        }

        try FileManager.default.copyItem(at: origen, to: destino)
        let duracion = try duracionSegundos(de: destino)
        return ArchivoImportado(nombreArchivo: nombreCompleto, duracionSegundos: duracion)
    }

    private static func directorioCanciones() -> URL {
        URL.documentsDirectory.appending(path: "Canciones", directoryHint: .isDirectory)
    }

    private static func crearDirectorioSiHaceFalta(_ url: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path(percentEncoded: false)) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private static func nombreUnico(en directorio: URL, basadoEn original: String) -> String {
        let fm = FileManager.default
        let candidatoInicial = directorio.appending(path: original)
        if !fm.fileExists(atPath: candidatoInicial.path(percentEncoded: false)) {
            return original
        }

        let url = URL(fileURLWithPath: original)
        let base = url.deletingPathExtension().lastPathComponent
        let extensión = url.pathExtension

        var contador = 1
        while true {
            let nuevoNombre = extensión.isEmpty
                ? "\(base) (\(contador))"
                : "\(base) (\(contador)).\(extensión)"
            let candidato = directorio.appending(path: nuevoNombre)
            if !fm.fileExists(atPath: candidato.path(percentEncoded: false)) {
                return nuevoNombre
            }
            contador += 1
        }
    }

    private static func duracionSegundos(de url: URL) throws -> Int {
        let archivo = try AVAudioFile(forReading: url)
        let frecuencia = archivo.processingFormat.sampleRate
        guard frecuencia > 0 else { return 0 }
        return Int(Double(archivo.length) / frecuencia)
    }
}

struct ArchivoImportado: Sendable {
    let nombreArchivo: String
    let duracionSegundos: Int
}
