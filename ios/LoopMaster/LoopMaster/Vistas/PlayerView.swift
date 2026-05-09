import SwiftUI

struct PlayerView: View {

    let cancion: Cancion

    @State private var motor = AudioEngineManager()
    @State private var mensajeError: String?
    @State private var muestrasOnda: [Float] = []
    @State private var cargandoOnda: Bool = false
    @State private var errorOnda: String?
    @State private var arrastrandoScrubber: Bool = false
    @State private var posicionScrubberLocal: Double = 0
    @State private var arrastrandoOnda: Bool = false
    @State private var ultimoSeekScrub: Date = .distantPast
    @State private var posicionTentativaOnda: Double = 0

    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    private var esCompacto: Bool {
        #if os(iOS)
        return verticalSizeClass == .compact
        #else
        return false
        #endif
    }

    private var contenido: some View {
        VStack(spacing: 16) {
            cabeceraCompacta
            controlPitch
            controlTempo
            ondaVista
                .frame(maxHeight: esCompacto ? 200 : .infinity)
                .frame(minHeight: 200)
        }
    }

    private var controlesFijos: some View {
        VStack(spacing: 12) {
            scrubberTemporal
            controlesReproduccion
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, paddingInferiorPlataforma)
        .background(fondoBarraInferior.ignoresSafeArea(edges: .bottom))
    }

    private var paddingInferiorPlataforma: CGFloat {
        #if os(macOS)
        return 24
        #else
        return 0
        #endif
    }

    @ViewBuilder
    private var fondoBarraInferior: some View {
        #if os(macOS)
        Color.clear
        #else
        Color(.systemBackground)
        #endif
    }

    var body: some View {
        Group {
            #if os(iOS)
            if verticalSizeClass == .compact {
                ScrollView {
                    contenido
                        .padding()
                }
            } else {
                contenido
                    .padding()
            }
            #else
            contenido
                .padding()
            #endif
        }
        .safeAreaInset(edge: .bottom) {
            controlesFijos
        }
        .navigationTitle(cancion.titulo)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear(perform: cargarCancion)
        .onDisappear { motor.pausar() }
        .onChange(of: motor.posicionSegundos) { _, nueva in
            if !arrastrandoScrubber {
                posicionScrubberLocal = nueva
            }
        }
        .task(id: cancion.nombreArchivo) {
            await cargarOnda()
        }
        .alert("Error de audio", isPresented: errorPresentado) {
            Button("OK", role: .cancel) { mensajeError = nil }
        } message: {
            Text(mensajeError ?? "")
        }
    }

    private var cabeceraCompacta: some View {
        HStack(spacing: 8) {
            if !cancion.artista.isEmpty {
                Text(cancion.artista)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var ondaVista: some View {
        VStack(spacing: 4) {
            ZStack {
                WaveformView(
                    muestras: muestrasOnda,
                    progreso: progresoActual,
                    zoom: 10.0,
                    onScrubChange: scrubChange,
                    onScrubEnd: scrubEnd
                )
                .frame(minHeight: 200, maxHeight: .infinity)
                .accessibilityElement()
                .accessibilityLabel("Forma de onda de \(cancion.titulo)")
                .accessibilityValue(formateoTiempo(motor.posicionSegundos) + " de " + formateoTiempo(motor.duracionSegundos))
                if cargandoOnda && muestrasOnda.isEmpty {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            if let errorOnda {
                Text("No se pudo dibujar la forma de onda: \(errorOnda)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func scrubChange(progreso: Double) {
        let segundo = progreso * motor.duracionSegundos
        arrastrandoOnda = true
        posicionTentativaOnda = segundo
        let ahora = Date()
        if ahora.timeIntervalSince(ultimoSeekScrub) > 0.1 {
            motor.saltarA(segundo: segundo)
            posicionScrubberLocal = segundo
            ultimoSeekScrub = ahora
        }
    }

    private func scrubEnd(progreso: Double) {
        let segundo = progreso * motor.duracionSegundos
        motor.saltarA(segundo: segundo)
        posicionScrubberLocal = segundo
        ultimoSeekScrub = Date()
        arrastrandoOnda = false
    }

    private var scrubberTemporal: some View {
        HStack(spacing: 12) {
            Text(formateoTiempo(arrastrandoScrubber ? posicionScrubberLocal : motor.posicionSegundos))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .leading)

            Slider(
                value: $posicionScrubberLocal,
                in: 0...max(motor.duracionSegundos, 1),
                onEditingChanged: { empezando in
                    arrastrandoScrubber = empezando
                    if !empezando {
                        motor.saltarA(segundo: posicionScrubberLocal)
                    }
                }
            )
            .accessibilityLabel("Posición de reproducción")
            .accessibilityValue(formateoTiempo(motor.posicionSegundos))

            Text(formateoTiempo(motor.duracionSegundos))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    private var controlesReproduccion: some View {
        HStack(spacing: 28) {
            Button {
                motor.saltarA(segundo: 0)
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ir al principio")

            Button {
                motor.saltarA(segundo: max(0, motor.posicionSegundos - 5))
            } label: {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retroceder 5 segundos")

            Button {
                alternarReproduccion()
            } label: {
                Image(systemName: motor.reproduciendo ? "pause.fill" : "play.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])
            .accessibilityLabel(motor.reproduciendo ? "Pausar" : "Reproducir")

            Button {
                motor.saltarA(segundo: min(motor.duracionSegundos, motor.posicionSegundos + 5))
            } label: {
                Image(systemName: "goforward.5")
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Avanzar 5 segundos")

            Button {
                motor.saltarA(segundo: motor.duracionSegundos)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ir al final")
        }
    }

    private var controlTempo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tempo")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.smooth) { motor.tempo = 100 }
                } label: {
                    Text("\(Int(motor.tempo)) %")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tempo actual: \(Int(motor.tempo)) por ciento")
                .accessibilityHint("Toca para volver al tempo original")
            }
            Slider(value: Binding(
                get: { Double(motor.tempo) },
                set: { motor.tempo = Float($0.rounded()) }
            ), in: 25...175)
            .accessibilityLabel("Tempo en porcentaje")
            .accessibilityValue("\(Int(motor.tempo)) por ciento")
        }
    }

    private var controlPitch: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tono")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.smooth) { motor.pitchSemitonos = 0 }
                } label: {
                    Text(formateoSemitonos(motor.pitchSemitonos))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tono actual: \(formateoSemitonos(motor.pitchSemitonos))")
                .accessibilityHint("Toca para volver al tono original")
            }
            Slider(value: Binding(
                get: { Double(motor.pitchSemitonos) },
                set: { motor.pitchSemitonos = Float($0.rounded()) }
            ), in: -12...12)
            .accessibilityLabel("Tono en semitonos")
            .accessibilityValue(formateoSemitonos(motor.pitchSemitonos))
        }
    }

    private var progresoActual: Double {
        guard motor.duracionSegundos > 0 else { return 0 }
        let segundoBase: Double
        if arrastrandoOnda {
            segundoBase = posicionTentativaOnda
        } else if arrastrandoScrubber {
            segundoBase = posicionScrubberLocal
        } else {
            segundoBase = motor.posicionSegundos
        }
        return max(0, min(1, segundoBase / motor.duracionSegundos))
    }

    private var errorPresentado: Binding<Bool> {
        Binding(
            get: { mensajeError != nil },
            set: { if !$0 { mensajeError = nil } }
        )
    }

    private func alternarReproduccion() {
        do {
            if motor.reproduciendo {
                motor.pausar()
            } else {
                try motor.reproducir()
            }
        } catch {
            mensajeError = error.localizedDescription
        }
    }

    private func cargarCancion() {
        do {
            try motor.cargarAudioDelSandbox(nombreArchivo: cancion.nombreArchivo)
        } catch {
            mensajeError = error.localizedDescription
        }
    }

    private func cargarOnda() async {
        let nombre = cancion.nombreArchivo
        guard !nombre.isEmpty else { return }

        errorOnda = nil

        if let cacheada = BibliotecaAudio.leerOnda(paraNombre: nombre) {
            muestrasOnda = cacheada
            return
        }

        cargandoOnda = true
        defer { cargandoOnda = false }

        let url = BibliotecaAudio.urlEnSandbox(nombreArchivo: nombre)
        do {
            let datos = try await WaveformExtractor.extraer(desde: url, bucketCount: 4000)
            try? BibliotecaAudio.guardarOnda(datos, paraNombre: nombre)
            muestrasOnda = datos
        } catch is CancellationError {
            return
        } catch {
            errorOnda = error.localizedDescription
        }
    }

    private func formateoSemitonos(_ valor: Float) -> String {
        let entero = Int(valor)
        if entero == 0 { return "±0" }
        return entero > 0 ? "+\(entero)" : "\(entero)"
    }

    private func formateoTiempo(_ segundos: Double) -> String {
        guard segundos.isFinite, segundos >= 0 else { return "0:00" }
        let total = Int(segundos)
        let minutos = total / 60
        let segs = total % 60
        return String(format: "%d:%02d", minutos, segs)
    }
}
