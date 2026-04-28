import SwiftUI
import UniformTypeIdentifiers

struct PlayerView: View {

    @State private var motor = AudioEngineManager()
    @State private var mensajeError: String?
    @State private var mostrandoSelector = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                cabecera

                Divider()

                controlesReproduccion

                controlTempo

                controlPitch

                Spacer()

                botonCargarArchivo
            }
            .padding()
            .navigationTitle("LoopMaster")
            .onAppear(perform: cargarAudioInicial)
            .alert("Error de audio", isPresented: errorPresentado) {
                Button("OK", role: .cancel) { mensajeError = nil }
            } message: {
                Text(mensajeError ?? "")
            }
            .fileImporter(
                isPresented: $mostrandoSelector,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false,
                onCompletion: gestionarSeleccionArchivo
            )
        }
    }

    private var cabecera: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Archivo cargado")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(motor.nombreArchivoCargado.isEmpty ? "—" : motor.nombreArchivoCargado)
                .font(.headline)
            Text("Duración: \(formateoDuracion(motor.duracionSegundos))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controlesReproduccion: some View {
        HStack(spacing: 40) {
            Button {
                alternarReproduccion()
            } label: {
                Image(systemName: motor.reproduciendo ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            .accessibilityLabel(motor.reproduciendo ? "Pausar" : "Reproducir")

            Button {
                motor.detener()
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Detener")
        }
    }

    private var controlTempo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tempo")
                    .font(.headline)
                Spacer()
                Text("\(Int(motor.tempo)) %")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.tint)
            }
            Slider(value: Binding(
                get: { Double(motor.tempo) },
                set: { motor.tempo = Float($0) }
            ), in: 25...175, step: 1)
            .accessibilityLabel("Tempo en porcentaje")
            .accessibilityValue("\(Int(motor.tempo)) por ciento")
            Text("Cambia la velocidad sin alterar el tono.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var controlPitch: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tono")
                    .font(.headline)
                Spacer()
                Text(formateoSemitonos(motor.pitchSemitonos))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.tint)
            }
            Slider(value: Binding(
                get: { Double(motor.pitchSemitonos) },
                set: { motor.pitchSemitonos = Float($0) }
            ), in: -12...12, step: 1)
            .accessibilityLabel("Tono en semitonos")
            .accessibilityValue(formateoSemitonos(motor.pitchSemitonos))
            Text("Cambia el tono sin alterar la velocidad.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var botonCargarArchivo: some View {
        Button {
            mostrandoSelector = true
        } label: {
            Label("Cargar archivo de audio", systemImage: "folder.badge.plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.15), in: .rect(cornerRadius: 12))
        }
        .accessibilityHint("Abre el selector de archivos para escoger un audio del dispositivo.")
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

    private func cargarAudioInicial() {
        do {
            try motor.cargarAudioDelBundle(nombre: "Ansioso", extensión: "m4a")
        } catch {
            mensajeError = error.localizedDescription
        }
    }

    private func gestionarSeleccionArchivo(_ resultado: Result<[URL], Error>) {
        switch resultado {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                try motor.cargarAudioDeURL(url)
            } catch {
                mensajeError = error.localizedDescription
            }
        case .failure(let error):
            mensajeError = error.localizedDescription
        }
    }

    private func formateoSemitonos(_ valor: Float) -> String {
        let entero = Int(valor)
        if entero == 0 { return "±0" }
        return entero > 0 ? "+\(entero)" : "\(entero)"
    }

    private func formateoDuracion(_ segundos: Double) -> String {
        let total = Int(segundos)
        let minutos = total / 60
        let segs = total % 60
        return String(format: "%d:%02d", minutos, segs)
    }
}

#Preview {
    PlayerView()
}
