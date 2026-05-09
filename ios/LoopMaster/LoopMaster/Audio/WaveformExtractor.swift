import AVFoundation
import Accelerate

nonisolated enum WaveformExtractor {

    enum ErrorExtraccion: Error, LocalizedError {
        case sinPistaAudio
        case lecturaInterrumpida(razon: String)
        case sinMuestras

        var errorDescription: String? {
            switch self {
            case .sinPistaAudio:
                return "El archivo no contiene una pista de audio legible."
            case .lecturaInterrumpida(let razon):
                return "La lectura del audio se interrumpió: \(razon)."
            case .sinMuestras:
                return "El archivo no contenía muestras decodificables."
            }
        }
    }

    static func extraer(
        desde url: URL,
        bucketCount: Int
    ) async throws -> [Float] {
        precondition(bucketCount > 0, "bucketCount debe ser mayor que 0")

        let asset = AVURLAsset(url: url)
        guard let pista = try await asset.loadTracks(withMediaType: .audio).first else {
            throw ErrorExtraccion.sinPistaAudio
        }

        let reader = try AVAssetReader(asset: asset)
        let ajustes: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVNumberOfChannelsKey: 1,
            AVLinearPCMIsBigEndianKey: 0,
            AVLinearPCMIsFloatKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsNonInterleaved: 1
        ]
        let salida = AVAssetReaderTrackOutput(track: pista, outputSettings: ajustes)
        salida.alwaysCopiesSampleData = false
        reader.add(salida)

        guard reader.startReading() else {
            throw ErrorExtraccion.lecturaInterrumpida(
                razon: reader.error?.localizedDescription ?? "estado desconocido"
            )
        }

        var muestras: [Float] = []

        while reader.status == .reading {
            try Task.checkCancellation()
            guard let buffer = salida.copyNextSampleBuffer() else { continue }
            defer { CMSampleBufferInvalidate(buffer) }

            guard let bloque = CMSampleBufferGetDataBuffer(buffer) else { continue }
            let bytes = CMBlockBufferGetDataLength(bloque)
            let count = bytes / MemoryLayout<Float>.size
            guard count > 0 else { continue }

            let trozo = [Float](unsafeUninitializedCapacity: count) { destino, escritos in
                CMBlockBufferCopyDataBytes(
                    bloque,
                    atOffset: 0,
                    dataLength: bytes,
                    destination: destino.baseAddress!
                )
                escritos = count
            }
            muestras.append(contentsOf: trozo)
        }

        guard reader.status == .completed else {
            throw ErrorExtraccion.lecturaInterrumpida(
                razon: reader.error?.localizedDescription ?? "status \(reader.status.rawValue)"
            )
        }

        guard !muestras.isEmpty else {
            throw ErrorExtraccion.sinMuestras
        }

        return reducirRMS(muestras: muestras, bucketCount: bucketCount)
    }

    private static func reducirRMS(muestras: [Float], bucketCount: Int) -> [Float] {
        let total = muestras.count
        var resultado: [Float] = []
        resultado.reserveCapacity(bucketCount)
        var pico: Float = 0

        muestras.withUnsafeBufferPointer { buffer in
            for i in 0..<bucketCount {
                let inicio = (i * total) / bucketCount
                let fin = ((i + 1) * total) / bucketCount
                if inicio >= fin {
                    resultado.append(0)
                    continue
                }
                let trozo = UnsafeBufferPointer(rebasing: buffer[inicio..<fin])
                let rms = vDSP.rootMeanSquare(trozo)
                resultado.append(rms)
                if rms > pico { pico = rms }
            }
        }

        guard pico > 0 else { return resultado }
        return resultado.map { $0 / pico }
    }
}
