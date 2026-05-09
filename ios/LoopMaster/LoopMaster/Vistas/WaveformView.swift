import SwiftUI

struct WaveformView: View {

    let muestras: [Float]
    var progreso: Double = 0
    var zoom: Double = 10.0
    var colorReproducido: Color = .accentColor
    var colorPendiente: Color = Color.accentColor.opacity(0.5)
    var colorPlayhead: Color = .white
    var alturaMinima: CGFloat = 2
    var anchoPlayhead: CGFloat = 1

    var onScrubChange: ((Double) -> Void)? = nil
    var onScrubEnd: ((Double) -> Void)? = nil

    @State private var tamañoCanvas: CGSize = .zero
    @State private var pathCacheado: Path = Path()
    @State private var anchoTotalCacheado: CGFloat = 0
    @State private var firmaCache: CacheKey = CacheKey(muestrasHash: 0, ancho: 0, alto: 0, zoom: 0)
    @State private var progresoInicialDrag: Double?

    var body: some View {
        GeometryReader { geo in
            let ancho = geo.size.width
            let alto = geo.size.height
            let progresoLimitado = max(0, min(1, progreso))
            let modoFijo = zoom <= 1.0001
            let xPlayhead: CGFloat = modoFijo ? progresoLimitado * ancho : ancho / 2
            let offsetX: CGFloat = modoFijo ? 0 : xPlayhead - progresoLimitado * anchoTotalCacheado

            ZStack(alignment: .topLeading) {
                if anchoTotalCacheado > 0 {
                    capaPendiente(alto: alto)
                        .fixedSize(horizontal: true, vertical: false)
                        .offset(x: offsetX)

                    capaReproducida(alto: alto)
                        .fixedSize(horizontal: true, vertical: false)
                        .mask {
                            HStack(spacing: 0) {
                                Color.white
                                    .frame(width: max(0, progresoLimitado * anchoTotalCacheado))
                                Color.clear
                            }
                            .frame(width: anchoTotalCacheado, alignment: .leading)
                        }
                        .offset(x: offsetX)
                }
            }
            .frame(width: ancho, height: alto, alignment: .topLeading)
            .clipped()
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(colorPlayhead)
                    .frame(width: 1.5, height: alto)
                    .offset(x: xPlayhead - 0.75)
            }
            .contentShape(Rectangle())
            .gesture(scrubGesture)
            .onAppear {
                tamañoCanvas = geo.size
                actualizarCacheSiHaceFalta()
            }
            .onChange(of: geo.size) { _, nuevo in
                tamañoCanvas = nuevo
                actualizarCacheSiHaceFalta()
            }
            .onChange(of: muestras) { _, _ in
                actualizarCacheSiHaceFalta()
            }
            .onChange(of: zoom) { _, _ in
                actualizarCacheSiHaceFalta()
            }
        }
    }

    private func capaPendiente(alto: CGFloat) -> some View {
        Canvas(rendersAsynchronously: false) { ctx, _ in
            ctx.fill(pathCacheado, with: .color(colorPendiente))
        }
        .frame(width: anchoTotalCacheado, height: alto)
    }

    private func capaReproducida(alto: CGFloat) -> some View {
        Canvas(rendersAsynchronously: false) { ctx, _ in
            ctx.fill(pathCacheado, with: .color(colorReproducido))
        }
        .frame(width: anchoTotalCacheado, height: alto)
    }

    private struct CacheKey: Equatable {
        var muestrasHash: Int
        var ancho: CGFloat
        var alto: CGFloat
        var zoom: Double
    }

    private func actualizarCacheSiHaceFalta() {
        guard tamañoCanvas.width > 0, tamañoCanvas.height > 0, !muestras.isEmpty else { return }
        let modoFijo = zoom <= 1.0001
        let zoomEfectivo = modoFijo ? 1.0 : zoom
        let nuevaFirma = CacheKey(
            muestrasHash: muestras.count,
            ancho: tamañoCanvas.width,
            alto: tamañoCanvas.height,
            zoom: zoomEfectivo
        )
        if nuevaFirma == firmaCache && anchoTotalCacheado > 0 { return }
        let anchoTotal = tamañoCanvas.width * CGFloat(zoomEfectivo)
        let nuevoPath = construirEnvelopeCompleto(
            anchoTotal: anchoTotal,
            altoTotal: tamañoCanvas.height
        )
        pathCacheado = nuevoPath
        anchoTotalCacheado = anchoTotal
        firmaCache = nuevaFirma
    }

    private func construirEnvelopeCompleto(anchoTotal: CGFloat, altoTotal: CGFloat) -> Path {
        let total = muestras.count
        guard total > 0 else { return Path() }
        let anchoBarra = max(0.5, anchoTotal / CGFloat(total))
        let centro = altoTotal / 2

        var path = Path()
        var puntosTop: [CGPoint] = []
        puntosTop.reserveCapacity(total)
        var puntosBottom: [CGPoint] = []
        puntosBottom.reserveCapacity(total)

        for i in 0..<total {
            let xCentro = CGFloat(i) * anchoBarra + anchoBarra / 2
            let altura = max(alturaMinima, CGFloat(muestras[i]) * altoTotal)
            puntosTop.append(CGPoint(x: xCentro, y: centro - altura / 2))
            puntosBottom.append(CGPoint(x: xCentro, y: centro + altura / 2))
        }

        path.move(to: puntosTop[0])
        for punto in puntosTop.dropFirst() {
            path.addLine(to: punto)
        }
        for punto in puntosBottom.reversed() {
            path.addLine(to: punto)
        }
        path.closeSubpath()
        return path
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard tamañoCanvas.width > 0 else { return }
                if progresoInicialDrag == nil {
                    progresoInicialDrag = max(0, min(1, progreso))
                }
                let deltaProgreso = -value.translation.width / tamañoCanvas.width / CGFloat(max(1.0, zoom))
                let nuevoProgreso = (progresoInicialDrag ?? 0) + Double(deltaProgreso)
                let limitado = max(0, min(1, nuevoProgreso))
                onScrubChange?(limitado)
            }
            .onEnded { value in
                guard tamañoCanvas.width > 0 else {
                    progresoInicialDrag = nil
                    return
                }
                let deltaProgreso = -value.translation.width / tamañoCanvas.width / CGFloat(max(1.0, zoom))
                let nuevoProgreso = (progresoInicialDrag ?? progreso) + Double(deltaProgreso)
                let limitado = max(0, min(1, nuevoProgreso))
                onScrubEnd?(limitado)
                progresoInicialDrag = nil
            }
    }
}

#Preview("Onda centrada") {
    WaveformView(
        muestras: (0..<200).map { i in
            let x = Float(i) / 200
            return abs(sin(x * .pi * 6)) * (1 - x * 0.3)
        },
        progreso: 0.4,
        onScrubChange: { _ in },
        onScrubEnd: { _ in }
    )
    .frame(height: 240)
    .padding()
}

#Preview("Onda vacía") {
    WaveformView(muestras: [])
        .frame(height: 240)
        .padding()
}
