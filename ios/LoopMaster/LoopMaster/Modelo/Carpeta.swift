import Foundation
import SwiftData

@Model
final class Carpeta {
    @Attribute(.unique) var nombre: String
    var descripcion: String = ""
    var fechaCreacion: Date

    var idServidor: Int?
    var pendienteSync: Bool = false
    var pendienteBorrado: Bool = false

    @Relationship(inverse: \Cancion.carpetas)
    var canciones: [Cancion] = []

    init(
        nombre: String,
        descripcion: String = "",
        idServidor: Int? = nil,
        pendienteSync: Bool = false,
        pendienteBorrado: Bool = false
    ) {
        self.nombre = nombre
        self.descripcion = descripcion
        self.fechaCreacion = Date()
        self.idServidor = idServidor
        self.pendienteSync = pendienteSync
        self.pendienteBorrado = pendienteBorrado
    }
}
