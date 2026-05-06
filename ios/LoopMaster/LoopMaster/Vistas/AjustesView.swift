import SwiftUI

struct AjustesView: View {
    @Environment(LoopMasterRepository.self) private var repositorio
    @AppStorage("baseURLBackend") private var baseURLBackend = "http://localhost:8080"
    @State private var probando = false

    var body: some View {
        Form {
            Section {
                TextField("URL del backend", text: $baseURLBackend)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())
            } header: {
                Text("Servidor backend")
            } footer: {
                Text("Usa http://localhost:8080 si arrancas Spring en este Mac y la app corre en el simulador. En un iPhone físico tendrás que poner la IP del Mac (por ejemplo http://192.168.1.10:8080).")
            }

            Section {
                Button {
                    probarConexion()
                } label: {
                    HStack {
                        Text("Probar conexión")
                        Spacer()
                        if probando {
                            ProgressView()
                        }
                    }
                }
                .disabled(probando)

                if let resultado = repositorio.ultimoResultado {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: resultado.esExito ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(resultado.esExito ? .green : .orange)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resultado.mensaje)
                                .font(.callout)
                            if let detalle = resultado.detalle {
                                Text(detalle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ajustes")
    }

    private func probarConexion() {
        probando = true
        Task {
            await repositorio.probarConexion()
            probando = false
        }
    }
}
