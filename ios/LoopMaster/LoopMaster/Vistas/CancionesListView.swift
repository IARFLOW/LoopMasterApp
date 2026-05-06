import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CancionesListView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(LoopMasterRepository.self) private var repositorio
    @Query(
        filter: #Predicate<Cancion> { !$0.pendienteBorrado },
        sort: \Cancion.fechaCreacion,
        order: .reverse
    ) private var canciones: [Cancion]

    @State private var mostrandoSelector = false
    @State private var mostrandoAjustes = false
    @State private var mensajeError: String?
    @State private var tareaCierreBanner: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                if canciones.isEmpty {
                    estadoVacio
                } else {
                    listaCanciones
                }
            }
            .overlay(alignment: .bottom) {
                if let resultado = repositorio.ultimoResultado {
                    bannerResultado(resultado)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth, value: repositorio.ultimoResultado)
            .navigationTitle("Canciones")
            .toolbar { contenidoToolbar }
            .navigationDestination(for: Cancion.self) { cancion in
                PlayerView(cancion: cancion)
            }
            .fileImporter(
                isPresented: $mostrandoSelector,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false,
                onCompletion: gestionarSeleccionArchivo
            )
            .sheet(isPresented: $mostrandoAjustes) {
                NavigationStack {
                    AjustesView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Hecho") { mostrandoAjustes = false }
                            }
                        }
                }
            }
            .alert("Error", isPresented: errorPresentado) {
                Button("OK", role: .cancel) { mensajeError = nil }
            } message: {
                Text(mensajeError ?? "")
            }
            .task { await semillaInicialSiVacio() }
            .onChange(of: repositorio.ultimoResultado) {
                tareaCierreBanner?.cancel()
                guard repositorio.ultimoResultado != nil else { return }
                tareaCierreBanner = Task { @MainActor in
                    do {
                        try await Task.sleep(for: .seconds(4))
                        repositorio.ultimoResultado = nil
                    } catch {
                        // cancelada antes de tiempo
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var contenidoToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                mostrandoAjustes = true
            } label: {
                Label("Ajustes", systemImage: "gear")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await repositorio.sincronizar() }
            } label: {
                if repositorio.sincronizando {
                    ProgressView()
                } else {
                    Label("Sincronizar", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .disabled(repositorio.sincronizando)
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                mostrandoSelector = true
            } label: {
                Label("Importar canción", systemImage: "plus")
            }
        }
    }

    private var estadoVacio: some View {
        ContentUnavailableView {
            Label("Sin canciones", systemImage: "music.note.list")
        } description: {
            Text("Importa un archivo de audio del dispositivo o pulsa el botón de sincronizar para descargarlas del backend.")
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
        HStack(spacing: 8) {
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
            Spacer()
            if cancion.pendienteSync {
                Image(systemName: "arrow.up.circle.dotted")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Pendiente de subir al servidor")
            }
        }
        .padding(.vertical, 4)
    }

    private func bannerResultado(_ resultado: ResultadoRepositorio) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: resultado.esExito ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(resultado.esExito ? .green : .orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(resultado.mensaje)
                    .font(.callout.weight(.medium))
                if let detalle = resultado.detalle {
                    Text(detalle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
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
                    nombreArchivo: importado.nombreArchivo,
                    pendienteSync: true
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
            repositorio.marcarParaBorrar(canciones[indice])
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
                nombreArchivo: importado.nombreArchivo,
                pendienteSync: true
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
