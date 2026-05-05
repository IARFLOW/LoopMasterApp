import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        CancionesListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Cancion.self, Carpeta.self, Bucle.self], inMemory: true)
}
