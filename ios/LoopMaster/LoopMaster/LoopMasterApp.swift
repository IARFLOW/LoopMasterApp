import SwiftUI
import SwiftData

@main
struct LoopMasterApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
                .environment(container.repositorio)
        }
        .modelContainer(container.modelContainer)
    }
}
