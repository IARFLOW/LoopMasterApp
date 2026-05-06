import Foundation
import SwiftData

@Model
final class Bucle {
    var nombre: String
    var puntoASegundos: Double
    var puntoBSegundos: Double
    var velocidadPorcentaje: Float
    var tonoSemitonos: Float
    var fechaCreacion: Date

    var idServidor: Int?
    var pendienteSync: Bool = false
    var pendienteBorrado: Bool = false

    var cancion: Cancion?

    init(
        nombre: String,
        puntoASegundos: Double,
        puntoBSegundos: Double,
        velocidadPorcentaje: Float = 100,
        tonoSemitonos: Float = 0,
        idServidor: Int? = nil,
        pendienteSync: Bool = false,
        pendienteBorrado: Bool = false
    ) {
        self.nombre = nombre
        self.puntoASegundos = puntoASegundos
        self.puntoBSegundos = puntoBSegundos
        self.velocidadPorcentaje = velocidadPorcentaje
        self.tonoSemitonos = tonoSemitonos
        self.fechaCreacion = Date()
        self.idServidor = idServidor
        self.pendienteSync = pendienteSync
        self.pendienteBorrado = pendienteBorrado
    }
}
