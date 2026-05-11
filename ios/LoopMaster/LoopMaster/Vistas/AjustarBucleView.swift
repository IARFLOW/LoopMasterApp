import SwiftUI

struct AjustarBucleView: View {

    let titulo: String
    let duracion: Double
    let puntoAInicial: Double
    let puntoBInicial: Double
    let muestrasOnda: [Float]
    let motor: AudioEngineManager?
    let onCambio: (Double, Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var minutosA: Int
    @State private var segundosA: Int
    @State private var milisA: Int

    @State private var minutosB: Int
    @State private var segundosB: Int
    @State private var milisB: Int

    @State private var mostrandoAlertLatidos: Bool = false

    init(
        titulo: String = "Ajustar Bucle",
        duracion: Double,
        puntoAInicial: Double,
        puntoBInicial: Double,
        muestrasOnda: [Float] = [],
        motor: AudioEngineManager? = nil,
        onCambio: @escaping (Double, Double) -> Void
    ) {
        self.titulo = titulo
        self.duracion = max(0, duracion)
        self.puntoAInicial = max(0, puntoAInicial)
        self.puntoBInicial = max(puntoAInicial, puntoBInicial)
        self.muestrasOnda = muestrasOnda
        self.motor = motor
        self.onCambio = onCambio

        let descA = Self.descomponer(puntoAInicial)
        let descB = Self.descomponer(puntoBInicial)
        _minutosA = State(initialValue: descA.minutos)
        _segundosA = State(initialValue: descA.segundos)
        _milisA = State(initialValue: descA.milisegundos)
        _minutosB = State(initialValue: descB.minutos)
        _segundosB = State(initialValue: descB.segundos)
        _milisB = State(initialValue: descB.milisegundos)
    }

    private var puntoA: Double {
        recomponer(minutos: minutosA, segundos: segundosA, milisegundos: milisA)
    }

    private var puntoB: Double {
        recomponer(minutos: minutosB, segundos: segundosB, milisegundos: milisB)
    }

    private var posicionMotor: Double {
        motor?.posicionSegundos ?? 0
    }

    var body: some View {
        Group {
            #if os(macOS)
            VStack(spacing: 0) {
                headerManual
                Divider()
                scrollContenido
            }
            .frame(minWidth: 520, minHeight: 640)
            .background(Color(nsColor: .windowBackgroundColor))
            .background(
                Button(action: { dismiss() }, label: { EmptyView() })
                    .keyboardShortcut(.escape, modifiers: [])
                    .opacity(0)
            )
            .alert("Próximamente", isPresented: $mostrandoAlertLatidos) {
                Button("De acuerdo", role: .cancel) {}
            } message: {
                Text("El ajuste automático a los latidos requiere detectar el tempo de la canción. Se añadirá en una iteración posterior.")
            }
            #else
            NavigationStack {
                scrollContenido
                    .navigationTitle(titulo)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { barraHerramientasIOS }
                    .alert("Próximamente", isPresented: $mostrandoAlertLatidos) {
                        Button("De acuerdo", role: .cancel) {}
                    } message: {
                        Text("El ajuste automático a los latidos requiere detectar el tempo de la canción. Se añadirá en una iteración posterior.")
                    }
            }
            .presentationDetents([.large])
            #endif
        }
    }

    private var scrollContenido: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !muestrasOnda.isEmpty {
                    miniOnda
                }
                if motor != nil {
                    controlesPreview
                }
                botonLatidos
                ruletasPunto(.a)
                ruletasPunto(.b)
                if motor != nil {
                    botonPlayPause
                        .padding(.top, 8)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
    }

    #if os(macOS)
    private var headerManual: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .regular))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary.opacity(0.75), Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar")
            .help("Cerrar (ESC)")

            Text(titulo)
                .font(.headline)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }
    #endif

    #if os(iOS)
    @ToolbarContentBuilder
    private var barraHerramientasIOS: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .regular))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary.opacity(0.75), Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar")
        }
    }
    #endif

    private var miniOnda: some View {
        WaveformView(
            muestras: muestrasOnda,
            progreso: progresoNormalizado(posicionMotor) ?? 0,
            zoom: 1.0,
            colorReproducido: .secondary,
            colorPendiente: Color.secondary.opacity(0.6),
            colorMuyApagado: Color.secondary.opacity(0.35),
            alturaMinima: 1,
            progresoA: progresoNormalizado(puntoA),
            progresoB: progresoNormalizado(puntoB),
            bucleResaltado: true
        )
        .frame(height: 80)
    }

    private var controlesPreview: some View {
        HStack(spacing: 24) {
            botonSaltarBucle(esInicio: true)
            Text(Self.formatoTiempo(posicionMotor))
                .font(.system(size: 22, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .frame(minWidth: 110)
            botonSaltarBucle(esInicio: false)
        }
        .frame(maxWidth: .infinity)
    }

    private var botonPlayPause: some View {
        Button {
            guard let motor else { return }
            if motor.reproduciendo {
                motor.pausar()
            } else {
                try? motor.reproducir()
            }
        } label: {
            Image(systemName: (motor?.reproduciendo == true) ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 64, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.space, modifiers: [])
        #if os(iOS)
        .sensoryFeedback(.impact(weight: .medium), trigger: motor?.reproduciendo ?? false)
        #endif
        .accessibilityLabel((motor?.reproduciendo == true) ? "Pausar" : "Reproducir")
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private func botonSaltarBucle(esInicio: Bool) -> some View {
        Button {
            motor?.saltarA(segundo: esInicio ? puntoA : puntoB)
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 1.5)
                    .frame(width: 36, height: 36)
                HStack(spacing: 1) {
                    if esInicio {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .heavy))
                    }
                    Text("AB")
                        .font(.system(size: 11, weight: .heavy))
                    if !esInicio {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .heavy))
                    }
                }
                .foregroundStyle(Color.accentColor)
            }
            .frame(width: 48, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(esInicio ? "Saltar al punto A" : "Saltar al punto B")
    }

    private var botonLatidos: some View {
        Button("Ajustar a los latidos") {
            mostrandoAlertLatidos = true
        }
        .font(.body)
        .foregroundStyle(Color.accentColor)
        .accessibilityHint("Aún no disponible")
    }

    @ViewBuilder
    private func ruletasPunto(_ punto: Punto) -> some View {
        #if os(macOS)
        HStack(spacing: 10) {
            ruleta(rango: 0...maximoMinutos, binding: bindingMinutos(punto), formato: "%d")
            separadorRueda(":")
            ruleta(rango: 0...59, binding: bindingSegundos(punto), formato: "%02d")
            separadorRueda(".")
            ruleta(rango: 0...999, binding: bindingMilisegundos(punto), formato: "%03d")
        }
        .frame(height: 160)
        .frame(maxWidth: 320)
        .overlay(alignment: .leading) {
            Text(punto.letra)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .offset(x: -28)
        }
        #else
        HStack(spacing: 12) {
            ruleta(rango: 0...maximoMinutos, binding: bindingMinutos(punto), formato: "%d")
            separadorRueda(":")
            ruleta(rango: 0...59, binding: bindingSegundos(punto), formato: "%02d")
            separadorRueda(".")
            ruleta(rango: 0...999, binding: bindingMilisegundos(punto), formato: "%03d")
        }
        .frame(height: 180)
        .padding(.horizontal, 36)
        .overlay(alignment: .leading) {
            Text(punto.letra)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .frame(width: 28, alignment: .center)
                .padding(.leading, 4)
        }
        #endif
    }

    @ViewBuilder
    private func ruleta(rango: ClosedRange<Int>, binding: Binding<Int>, formato: String) -> some View {
        #if os(iOS)
        Picker("", selection: binding) {
            ForEach(rango, id: \.self) { valor in
                Text(String(format: formato, valor))
                    .font(.system(size: 22, weight: .medium, design: .rounded).monospacedDigit())
                    .tag(valor)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
        #else
        RuletaCustomMacOS(rango: rango, seleccion: binding, formato: formato)
            .frame(maxWidth: .infinity)
        #endif
    }

    private func separadorRueda(_ texto: String) -> some View {
        Text(texto)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private var maximoMinutos: Int {
        max(0, Int(duracion / 60) + 1)
    }

    private func bindingMinutos(_ punto: Punto) -> Binding<Int> {
        switch punto {
        case .a:
            return Binding(
                get: { minutosA },
                set: { minutosA = $0; propagar() }
            )
        case .b:
            return Binding(
                get: { minutosB },
                set: { minutosB = $0; propagar() }
            )
        }
    }

    private func bindingSegundos(_ punto: Punto) -> Binding<Int> {
        switch punto {
        case .a:
            return Binding(
                get: { segundosA },
                set: { segundosA = $0; propagar() }
            )
        case .b:
            return Binding(
                get: { segundosB },
                set: { segundosB = $0; propagar() }
            )
        }
    }

    private func bindingMilisegundos(_ punto: Punto) -> Binding<Int> {
        switch punto {
        case .a:
            return Binding(
                get: { milisA },
                set: { milisA = $0; propagar() }
            )
        case .b:
            return Binding(
                get: { milisB },
                set: { milisB = $0; propagar() }
            )
        }
    }

    private func propagar() {
        let a = clampear(puntoA)
        let bBruto = clampear(puntoB)
        let b = max(a + 0.001, bBruto)
        onCambio(a, b)
    }

    private func clampear(_ valor: Double) -> Double {
        max(0, min(duracion, valor))
    }

    private func recomponer(minutos: Int, segundos: Int, milisegundos: Int) -> Double {
        Double(minutos) * 60 + Double(segundos) + Double(milisegundos) / 1000
    }

    private func progresoNormalizado(_ segundos: Double) -> Double? {
        guard duracion > 0 else { return nil }
        return max(0, min(1, segundos / duracion))
    }

    private static func descomponer(_ segundos: Double) -> Descomposicion {
        let total = max(0, segundos)
        let minutosBase = Int(total) / 60
        let restoSegundos = total - Double(minutosBase * 60)
        let segsBase = Int(restoSegundos)
        let milisReales = (restoSegundos - Double(segsBase)) * 1000
        var ms = Int(milisReales.rounded())
        var segs = segsBase
        var minutos = minutosBase
        if ms >= 1000 {
            ms -= 1000
            segs += 1
        }
        if segs >= 60 {
            segs -= 60
            minutos += 1
        }
        return Descomposicion(minutos: minutos, segundos: segs, milisegundos: ms)
    }

    private static func formatoTiempo(_ segundos: Double) -> String {
        let d = descomponer(segundos)
        return String(format: "%d:%02d.%03d", d.minutos, d.segundos, d.milisegundos)
    }

    private struct Descomposicion {
        let minutos: Int
        let segundos: Int
        let milisegundos: Int
    }

    private enum Punto {
        case a
        case b

        var letra: String {
            switch self {
            case .a: return "A"
            case .b: return "B"
            }
        }
    }
}

#if os(macOS)
struct RuletaCustomMacOS: View {

    let rango: ClosedRange<Int>
    @Binding var seleccion: Int
    let formato: String

    private let alturaFila: CGFloat = 30
    private let filasVisibles: Int = 5

    @State private var valorEnCentro: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    Color.clear.frame(height: alturaFila * CGFloat(filasVisibles / 2))
                    ForEach(rango, id: \.self) { valor in
                        filaValor(valor)
                    }
                    Color.clear.frame(height: alturaFila * CGFloat(filasVisibles / 2))
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $valorEnCentro, anchor: .center)
            .frame(height: alturaFila * CGFloat(filasVisibles))
            .onAppear {
                valorEnCentro = seleccion
                DispatchQueue.main.async {
                    proxy.scrollTo(seleccion, anchor: .center)
                }
            }
            .onChange(of: valorEnCentro) { _, nuevo in
                if let n = nuevo, n != seleccion {
                    seleccion = n
                }
            }
        }
    }

    @ViewBuilder
    private func filaValor(_ valor: Int) -> some View {
        let esActivo = valor == (valorEnCentro ?? seleccion)
        Text(String(format: formato, valor))
            .font(.system(size: 17, weight: esActivo ? .semibold : .regular, design: .rounded).monospacedDigit())
            .foregroundStyle(esActivo ? Color.primary : Color.secondary.opacity(0.45))
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(esActivo ? Color.gray.opacity(0.25) : Color.clear)
            )
            .frame(maxWidth: .infinity)
            .frame(height: alturaFila)
            .id(valor)
    }
}
#endif
