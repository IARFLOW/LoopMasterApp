import Foundation
import SwiftData

@Model
final class Carpeta {
    @Attribute(.unique) var nombre: String
    var fechaCreacion: Date

    @Relationship(inverse: \Cancion.carpetas)
    var canciones: [Cancion] = []

    init(nombre: String) {
        self.nombre = nombre
        self.fechaCreacion = Date()
    }
}
