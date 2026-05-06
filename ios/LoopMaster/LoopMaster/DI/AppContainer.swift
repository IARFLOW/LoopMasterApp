import Foundation
import SwiftData

@MainActor
@Observable
final class AppContainer {
    let modelContainer: ModelContainer
    let cliente: APICliente
    let repositorio: LoopMasterRepository

    init() {
        let schema = Schema([Cancion.self, Carpeta.self, Bucle.self])
        let configuracion = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuracion])
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
        self.modelContainer = container

        let cliente: APICliente = DefaultAPICliente(proveedorBaseURL: {
            let raw = UserDefaults.standard.string(forKey: "baseURLBackend") ?? "http://localhost:8080"
            return URL(string: raw) ?? URL(string: "http://localhost:8080")!
        })
        self.cliente = cliente

        self.repositorio = LoopMasterRepository(cliente: cliente, contexto: container.mainContext)
    }
}
