import SwiftUI
import SwiftData

struct PlayerView: View {

    let cancion: Cancion

    @Environment(\.modelContext) private var modelContext
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

    @State private var puntoA: Double?
    @State private var puntoB: Double?
    @State private var loopActivo: Bool = false
    @State private var mostrandoBuclesGuardados: Bool = false
    @State private var mostrandoAjustarBucle: Bool = false
    @State private var nombreBucleNuevo: String = ""
    @State private var pidiendoNombreBucle: Bool = false
    @State private var nivelZoom: Int = 5
    @State private var mostrandoTiempoRestante: Bool = true
    @State private var mostrandoVolumen: Bool = false
    @State private var mostrandoMenuZoom: Bool = false

    private static let zoomPorNivel: [Double] = [1, 2, 3, 5, 7, 10, 15, 25, 40, 70, 120]

    private var zoomActual: Double {
        let idx = max(0, min(Self.zoomPorNivel.count - 1, nivelZoom))
        return Self.zoomPorNivel[idx]
    }

    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    #if os(macOS)
    @Environment(\.colorScheme) private var colorScheme
    private var colorFondoPlayer: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    #endif

    private var esCompacto: Bool {
        #if os(iOS)
        return verticalSizeClass == .compact
        #else
        return false
        #endif
    }

    private var mostrarBotonAjustar: Bool {
        #if os(macOS)
        return true
        #else
        return esCompacto
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
            if mostrandoVolumen {
                panelVolumen
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            controlBucle
            scrubberTemporal
            controlesReproduccion
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, paddingInferiorPlataforma)
        .background(fondoBarraInferior.ignoresSafeArea(edges: .bottom))
        .animation(.smooth(duration: 0.25), value: mostrandoVolumen)
    }

    private var panelVolumen: some View {
        HStack(spacing: 14) {
            Image(systemName: "speaker.fill")
                .foregroundStyle(.secondary)
            Slider(value: Binding(
                get: {
                    let v = max(0, min(1, Double(motor.volumen)))
                    return sqrt(v)
                },
                set: { perceptual in
                    let lineal = perceptual * perceptual
                    motor.volumen = Float(max(0, min(1, lineal)))
                }
            ), in: 0...1)
            .accessibilityLabel("Volumen")
            Image(systemName: "speaker.wave.3.fill")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .rect(cornerRadius: 14))
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
        #if os(macOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorFondoPlayer)
        .toolbarBackground(colorFondoPlayer, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        #endif
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
        .onChange(of: loopActivo) { _, nuevo in
            actualizarMotorBucle()
            if nuevo, let a = puntoA, let b = puntoB, b > a {
                motor.saltarA(segundo: a)
            }
        }
        .onChange(of: puntoA) { _, _ in actualizarMotorBucle() }
        .onChange(of: puntoB) { _, _ in actualizarMotorBucle() }
        .onChange(of: nivelZoom) { _, _ in
            guard motor.reproduciendo else { return }
            motor.saltarA(segundo: motor.posicionSegundos)
        }
        .task(id: cancion.nombreArchivo) {
            await cargarOnda()
        }
        .alert("Error de audio", isPresented: errorPresentado) {
            Button("OK", role: .cancel) { mensajeError = nil }
        } message: {
            Text(mensajeError ?? "")
        }
        .alert("Guardar bucle", isPresented: $pidiendoNombreBucle) {
            TextField("Nombre del bucle", text: $nombreBucleNuevo)
            Button("Guardar") { guardarBucleActual() }
            Button("Cancelar", role: .cancel) { nombreBucleNuevo = "" }
        } message: {
            if let a = puntoA, let b = puntoB {
                Text("Puntos \(formateoTiempoBucle(a)) – \(formateoTiempoBucle(b)) con tempo \(Int(motor.tempo)) % y tono \(formateoSemitonos(motor.pitchSemitonos)).")
            } else {
                Text("Marca primero los puntos A y B sobre la onda.")
            }
        }
        .sheet(isPresented: $mostrandoBuclesGuardados) {
            NavigationStack {
                BucleListView(
                    cancion: cancion,
                    aplicar: { bucle in
                        aplicarBucleGuardado(bucle)
                        mostrandoBuclesGuardados = false
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hecho") { mostrandoBuclesGuardados = false }
                    }
                }
            }
            #if os(macOS)
            .frame(minWidth: 480, minHeight: 360)
            #endif
        }
        .sheet(isPresented: $mostrandoAjustarBucle) {
            AjustarBucleView(
                duracion: motor.duracionSegundos,
                puntoAInicial: puntoA ?? 0,
                puntoBInicial: puntoB ?? motor.duracionSegundos,
                muestrasOnda: muestrasOnda,
                motor: motor,
                onCambio: { nuevoA, nuevoB in
                    puntoA = nuevoA
                    puntoB = nuevoB
                    loopActivo = true
                    actualizarMotorBucle()
                }
            )
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
                    zoom: zoomActual,
                    progresoA: progresoNormalizado(puntoA),
                    progresoB: progresoNormalizado(puntoB),
                    bucleResaltado: loopActivo,
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
            .simultaneousGesture(
                MagnifyGesture(minimumScaleDelta: 0.05)
                    .onEnded { value in
                        aplicarPinchZoom(factor: value.magnification)
                    }
            )
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
        let rango = rangoScrubber
        return HStack(spacing: 8) {
            Text(formateoTiempo(tiempoInicialScrubber))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 38, alignment: .leading)

            Slider(
                value: posicionLimitadaBinding,
                in: rango,
                onEditingChanged: { empezando in
                    arrastrandoScrubber = empezando
                    if !empezando {
                        motor.saltarA(segundo: posicionScrubberLocal)
                    }
                }
            )
            .accessibilityLabel("Posición de reproducción")
            .accessibilityValue(formateoTiempo(motor.posicionSegundos))

            Button {
                mostrandoTiempoRestante.toggle()
            } label: {
                Text(textoTiempoFinal)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 38, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mostrandoTiempoRestante ? "Tiempo restante. Toca para mostrar duración total." : "Duración total. Toca para mostrar tiempo restante.")
        }
    }

    private var tiempoInicialScrubber: Double {
        if loopActivo, let a = puntoA, let b = puntoB, b > a {
            return max(0, motor.posicionSegundos - a)
        }
        return motor.posicionSegundos
    }

    private var textoTiempoFinal: String {
        if loopActivo, let a = puntoA, let b = puntoB, b > a {
            if mostrandoTiempoRestante {
                return "-" + formateoTiempo(max(0, b - motor.posicionSegundos))
            }
            return formateoTiempo(b - a)
        }
        if mostrandoTiempoRestante {
            let restante = max(0, motor.duracionSegundos - motor.posicionSegundos)
            return "-" + formateoTiempo(restante)
        }
        return formateoTiempo(motor.duracionSegundos)
    }

    private var rangoScrubber: ClosedRange<Double> {
        if loopActivo, let a = puntoA, let b = puntoB, b > a {
            return a...b
        }
        return 0...max(motor.duracionSegundos, 1)
    }

    private var posicionLimitadaBinding: Binding<Double> {
        Binding(
            get: {
                let r = rangoScrubber
                return min(r.upperBound, max(r.lowerBound, posicionScrubberLocal))
            },
            set: { posicionScrubberLocal = $0 }
        )
    }

    private var controlBucle: some View {
        HStack(spacing: 14) {
            botonMarcaPunto(etiqueta: "A", marcado: puntoA != nil, colorActivo: .green, accion: marcarA)
            botonMarcaPunto(etiqueta: "B", marcado: puntoB != nil, colorActivo: .orange, accion: marcarB)

            Toggle(isOn: $loopActivo) {
                Image(systemName: loopActivo ? "repeat.circle.fill" : "repeat.circle")
                    .font(.system(size: 26))
            }
            .toggleStyle(.button)
            .tint(Color.accentColor)
            .disabled(!hayAlgunPunto)
            .accessibilityLabel(loopActivo ? "Loop activo" : "Loop apagado")

            Spacer()

            botonVolumen

            if mostrarBotonAjustar {
                Button {
                    mostrandoAjustarBucle = true
                } label: {
                    Image(systemName: "slider.horizontal.below.rectangle")
                        .font(.system(size: 26))
                        .foregroundStyle(hayAlgunPunto ? Color.accentColor : Color.secondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(!hayAlgunPunto)
                .accessibilityLabel("Ajustar bucle con precisión")
            }

            Button {
                limpiarBucle()
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 26))
                    .foregroundStyle(hayAlgunPunto ? Color.accentColor : Color.secondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(!hayAlgunPunto)
            .accessibilityLabel("Quitar bucle")

            botonZoom

            Button {
                pidiendoNombreBucle = true
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(hayBucleValido ? Color.accentColor : Color.secondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(!hayBucleValido)
            .accessibilityLabel("Guardar bucle")

            Button {
                mostrandoBuclesGuardados = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bucles guardados")
        }
    }

    private var botonVolumen: some View {
        Button {
            mostrandoVolumen.toggle()
        } label: {
            Image(systemName: iconoVolumen)
                .font(.system(size: 26))
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Volumen \(Int(motor.volumen * 100)) por ciento")
    }

    private var iconoVolumen: String {
        let v = motor.volumen
        if v < 0.01 { return "speaker.slash.fill" }
        if v < 0.34 { return "speaker.wave.1.fill" }
        if v < 0.67 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    @ViewBuilder
    private var botonZoom: some View {
        #if os(macOS)
        Button {
            mostrandoMenuZoom.toggle()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nivel de zoom de la onda. Actual: nivel \(nivelZoom)")
        .popover(isPresented: $mostrandoMenuZoom, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<Self.zoomPorNivel.count, id: \.self) { nivel in
                    Button {
                        nivelZoom = nivel
                        mostrandoMenuZoom = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: nivel == nivelZoom ? "checkmark" : "")
                                .frame(width: 16)
                            Text("Nivel \(nivel)")
                            Spacer(minLength: 12)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Divider().padding(.vertical, 4)
                Button {
                    nivelZoom = 5
                    mostrandoMenuZoom = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise").frame(width: 16)
                        Text("Reset (nivel 5)")
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .frame(minWidth: 180)
        }
        #else
        Menu {
            ForEach(0..<Self.zoomPorNivel.count, id: \.self) { nivel in
                Button {
                    nivelZoom = nivel
                } label: {
                    if nivel == nivelZoom {
                        Label("Nivel \(nivel)", systemImage: "checkmark")
                    } else {
                        Text("Nivel \(nivel)")
                    }
                }
            }
            Divider()
            Button {
                nivelZoom = 5
            } label: {
                Label("Reset (nivel 5)", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26))
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
        }
        .menuOrder(.fixed)
        .accessibilityLabel("Nivel de zoom de la onda. Actual: nivel \(nivelZoom)")
        #endif
    }

    private func botonMarcaPunto(
        etiqueta: String,
        marcado: Bool,
        colorActivo: Color,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            Text(etiqueta)
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(marcado ? colorActivo : Color.gray.opacity(0.25), in: .circle)
                .foregroundStyle(marcado ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Marcar punto \(etiqueta) en la posición actual")
        .accessibilityHint("Mantén pulsado para ajustar con precisión")
        .contextMenu {
            Button {
                mostrandoAjustarBucle = true
            } label: {
                Label("Ajustar bucle con precisión", systemImage: "slider.horizontal.below.rectangle")
            }
            .disabled(!hayAlgunPunto)
        }
    }

    private var hayBucleValido: Bool {
        guard let a = puntoA, let b = puntoB else { return false }
        return b > a
    }

    private var hayAlgunPunto: Bool {
        puntoA != nil || puntoB != nil
    }

    private func limpiarBucle() {
        puntoA = nil
        puntoB = nil
        loopActivo = false
        actualizarMotorBucle()
    }

    private var controlesReproduccion: some View {
        HStack(spacing: 28) {
            Button {
                motor.saltarA(segundo: inicioReproduccion)
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(EscalaPulsadaButtonStyle())
            .accessibilityLabel(loopActivo ? "Ir al punto A" : "Ir al principio")

            Button {
                motor.saltarA(segundo: max(inicioReproduccion, motor.posicionSegundos - 5))
            } label: {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(EscalaPulsadaButtonStyle())
            .accessibilityLabel("Retroceder 5 segundos")

            Button {
                alternarReproduccion()
            } label: {
                Image(systemName: motor.reproduciendo ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(.tint)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(EscalaPulsadaButtonStyle(escalaPulsada: 0.82))
            .keyboardShortcut(.space, modifiers: [])
            #if os(iOS)
            .sensoryFeedback(.impact(weight: .medium), trigger: motor.reproduciendo)
            #endif
            .accessibilityLabel(motor.reproduciendo ? "Pausar" : "Reproducir")

            Button {
                motor.saltarA(segundo: min(finalReproduccion, motor.posicionSegundos + 5))
            } label: {
                Image(systemName: "goforward.5")
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(EscalaPulsadaButtonStyle())
            .accessibilityLabel("Avanzar 5 segundos")

            Button {
                motor.saltarA(segundo: finalReproduccion)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(EscalaPulsadaButtonStyle())
            .accessibilityLabel(loopActivo ? "Ir al punto B" : "Ir al final")
        }
    }

    private var inicioReproduccion: Double {
        if loopActivo, let a = puntoA { return a }
        return 0
    }

    private var finalReproduccion: Double {
        if loopActivo, let b = puntoB { return b }
        return motor.duracionSegundos
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
                if loopActivo, let a = puntoA, let b = puntoB, b > a {
                    let pos = motor.posicionSegundos
                    if pos < a || pos >= b {
                        motor.saltarA(segundo: a)
                    }
                }
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

    private func formateoTiempoBucle(_ segundos: Double) -> String {
        guard segundos.isFinite, segundos >= 0 else { return "0:00.0" }
        let total = segundos
        let minutos = Int(total) / 60
        let segs = total - Double(minutos * 60)
        return String(format: "%d:%05.2f", minutos, segs)
    }

    private func progresoNormalizado(_ segundos: Double?) -> Double? {
        guard let segundos, motor.duracionSegundos > 0 else { return nil }
        return max(0, min(1, segundos / motor.duracionSegundos))
    }

    private func marcarA() {
        let actual = motor.posicionSegundos
        if let b = puntoB, actual >= b {
            puntoB = nil
        }
        puntoA = max(0, min(motor.duracionSegundos, actual))
        loopActivo = true
        actualizarMotorBucle()
    }

    private func marcarB() {
        let actual = motor.posicionSegundos
        if let a = puntoA, actual <= a {
            puntoA = nil
        }
        puntoB = max(0, min(motor.duracionSegundos, actual))
        loopActivo = true
        actualizarMotorBucle()
        if let a = puntoA, let b = puntoB, b > a {
            motor.saltarA(segundo: a)
        }
    }

    private func actualizarMotorBucle() {
        if let a = puntoA, let b = puntoB, b > a {
            motor.bucle = AudioEngineManager.RangoBucle(inicio: a, fin: b)
        } else {
            motor.bucle = nil
        }
        motor.loopActivo = loopActivo && motor.bucle != nil
    }

    private func aplicarBucleGuardado(_ bucle: Bucle) {
        puntoA = bucle.puntoASegundos
        puntoB = bucle.puntoBSegundos
        motor.tempo = bucle.velocidadPorcentaje
        motor.pitchSemitonos = bucle.tonoSemitonos
        loopActivo = true
        actualizarMotorBucle()
        motor.saltarA(segundo: bucle.puntoASegundos)
    }

    private func guardarBucleActual() {
        guard let a = puntoA, let b = puntoB, b > a else { return }
        let nombreFinal = nombreBucleNuevo.trimmingCharacters(in: .whitespacesAndNewlines)
        let nombre = nombreFinal.isEmpty ? formateoNombrePorDefecto(a: a, b: b) : nombreFinal
        let nuevo = Bucle(
            nombre: nombre,
            puntoASegundos: a,
            puntoBSegundos: b,
            velocidadPorcentaje: motor.tempo,
            tonoSemitonos: motor.pitchSemitonos,
            pendienteSync: true
        )
        nuevo.cancion = cancion
        modelContext.insert(nuevo)
        nombreBucleNuevo = ""
    }

    private func formateoNombrePorDefecto(a: Double, b: Double) -> String {
        return "Bucle \(formateoTiempo(a))–\(formateoTiempo(b))"
    }

    private func aplicarPinchZoom(factor: Double) {
        guard factor.isFinite, factor > 0 else { return }
        let zoomDeseado = zoomActual * factor
        var mejorIndice = 0
        var mejorDistancia = Double.infinity
        for (indice, valor) in Self.zoomPorNivel.enumerated() {
            let distancia = abs(log(valor) - log(zoomDeseado))
            if distancia < mejorDistancia {
                mejorDistancia = distancia
                mejorIndice = indice
            }
        }
        if mejorIndice != nivelZoom {
            nivelZoom = mejorIndice
        }
    }
}

private struct EscalaPulsadaButtonStyle: ButtonStyle {

    var escalaPulsada: CGFloat = 0.88

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? escalaPulsada : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

