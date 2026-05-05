import SwiftUI
import SwiftData

@main
struct LoopMasterApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Cancion.self,
            Carpeta.self,
            Bucle.self
        ])
        let configuracion = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuracion])
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
