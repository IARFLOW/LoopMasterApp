import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CancionesListView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cancion.fechaCreacion, order: .reverse) private var canciones: [Cancion]

    @State private var mostrandoSelector = false
    @State private var mensajeError: String?

    var body: some View {
        NavigationStack {
            Group {
                if canciones.isEmpty {
                    estadoVacio
                } else {
                    listaCanciones
                }
            }
            .navigationTitle("Canciones")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        mostrandoSelector = true
                    } label: {
                        Label("Importar canción", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Cancion.self) { cancion in
                PlayerView(cancion: cancion)
            }
            .fileImporter(
                isPresented: $mostrandoSelector,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false,
                onCompletion: gestionarSeleccionArchivo
            )
            .alert("Error", isPresented: errorPresentado) {
                Button("OK", role: .cancel) { mensajeError = nil }
            } message: {
                Text(mensajeError ?? "")
            }
            .task { await semillaInicialSiVacio() }
        }
    }

    private var estadoVacio: some View {
        ContentUnavailableView {
            Label("Sin canciones", systemImage: "music.note.list")
        } description: {
            Text("Importa un archivo de audio del dispositivo para empezar.")
        } actions: {
            Button("Importar canción") { mostrandoSelector = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var listaCanciones: some View {
        List {
            ForEach(canciones) { cancion in
                NavigationLink(value: cancion) {
                    filaCancion(cancion)
                }
            }
            .onDelete(perform: borrarCanciones)
        }
    }

    private func filaCancion(_ cancion: Cancion) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cancion.titulo)
                .font(.headline)
            HStack(spacing: 8) {
                Text(formateoDuracion(cancion.duracionSegundos))
                if !cancion.bucles.isEmpty {
                    Text("·")
                    Text("\(cancion.bucles.count) bucle\(cancion.bucles.count == 1 ? "" : "s")")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var errorPresentado: Binding<Bool> {
        Binding(
            get: { mensajeError != nil },
            set: { if !$0 { mensajeError = nil } }
        )
    }

    private func gestionarSeleccionArchivo(_ resultado: Result<[URL], Error>) {
        switch resultado {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let importado = try BibliotecaAudio.importarArchivo(desde: url)
                let titulo = (importado.nombreArchivo as NSString).deletingPathExtension
                let cancion = Cancion(
                    titulo: titulo,
                    duracionSegundos: importado.duracionSegundos,
                    nombreArchivo: importado.nombreArchivo
                )
                modelContext.insert(cancion)
            } catch {
                mensajeError = error.localizedDescription
            }
        case .failure(let error):
            mensajeError = error.localizedDescription
        }
    }

    private func borrarCanciones(en offsets: IndexSet) {
        for indice in offsets {
            modelContext.delete(canciones[indice])
        }
    }

    private func semillaInicialSiVacio() async {
        guard canciones.isEmpty else { return }
        do {
            guard let importado = try BibliotecaAudio.copiarRecursoDelBundleSiHaceFalta(
                nombre: "Ansioso",
                extensión: "m4a"
            ) else {
                return
            }
            let cancion = Cancion(
                titulo: "Ansioso",
                artista: "Ramiro Barrios (en vivo)",
                duracionSegundos: importado.duracionSegundos,
                nombreArchivo: importado.nombreArchivo
            )
            modelContext.insert(cancion)
        } catch {
            mensajeError = error.localizedDescription
        }
    }

    private func formateoDuracion(_ segundos: Int) -> String {
        let minutos = segundos / 60
        let segs = segundos % 60
        return String(format: "%d:%02d", minutos, segs)
    }
}

#Preview {
    CancionesListView()
        .modelContainer(for: [Cancion.self, Carpeta.self, Bucle.self], inMemory: true)
}
