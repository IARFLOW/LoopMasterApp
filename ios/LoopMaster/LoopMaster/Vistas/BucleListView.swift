import SwiftUI
import SwiftData

struct BucleListView: View {

    let cancion: Cancion
    let aplicar: (Bucle) -> Void

    @Environment(LoopMasterRepository.self) private var repositorio
    @Query private var bucles: [Bucle]

    init(cancion: Cancion, aplicar: @escaping (Bucle) -> Void) {
        self.cancion = cancion
        self.aplicar = aplicar
        let cancionID = cancion.persistentModelID
        _bucles = Query(
            filter: #Predicate<Bucle> { bucle in
                !bucle.pendienteBorrado && bucle.cancion?.persistentModelID == cancionID
            },
            sort: \Bucle.fechaCreacion,
            order: .reverse
        )
    }

    var body: some View {
        Group {
            if bucles.isEmpty {
                estadoVacio
            } else {
                lista
            }
        }
        .navigationTitle("Bucles guardados")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var estadoVacio: some View {
        ContentUnavailableView {
            Label("Sin bucles guardados", systemImage: "repeat.circle")
        } description: {
            Text("Marca los puntos A y B sobre la onda y pulsa el icono de marcador para guardar el bucle.")
        }
    }

    private var lista: some View {
        List {
            ForEach(bucles) { bucle in
                Button {
                    aplicar(bucle)
                } label: {
                    filaBucle(bucle)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        repositorio.marcarParaBorrar(bucle)
                    } label: {
                        Label("Borrar", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        repositorio.marcarParaBorrar(bucle)
                    } label: {
                        Label("Borrar", systemImage: "trash")
                    }
                }
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #endif
    }

    private func filaBucle(_ bucle: Bucle) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bucle.nombre)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label(formateoTiempoBucle(bucle.puntoASegundos), systemImage: "a.circle.fill")
                        .foregroundStyle(.green)
                    Label(formateoTiempoBucle(bucle.puntoBSegundos), systemImage: "b.circle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.caption.monospacedDigit())
                HStack(spacing: 8) {
                    Text("Tempo \(Int(bucle.velocidadPorcentaje)) %")
                    Text("Tono \(formateoSemitonos(bucle.tonoSemitonos))")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if bucle.pendienteSync {
                Image(systemName: "arrow.up.circle.dotted")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Pendiente de subir al servidor")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func borrar(en offsets: IndexSet) {
        for indice in offsets {
            repositorio.marcarParaBorrar(bucles[indice])
        }
    }

    private func formateoTiempoBucle(_ segundos: Double) -> String {
        guard segundos.isFinite, segundos >= 0 else { return "0:00.0" }
        let total = segundos
        let minutos = Int(total) / 60
        let segs = total - Double(minutos * 60)
        return String(format: "%d:%05.2f", minutos, segs)
    }

    private func formateoSemitonos(_ valor: Float) -> String {
        let entero = Int(valor)
        if entero == 0 { return "±0" }
        return entero > 0 ? "+\(entero)" : "\(entero)"
    }
}
