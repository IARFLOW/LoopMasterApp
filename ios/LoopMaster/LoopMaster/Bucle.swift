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

    var cancion: Cancion?

    init(
        nombre: String,
        puntoASegundos: Double,
        puntoBSegundos: Double,
        velocidadPorcentaje: Float = 100,
        tonoSemitonos: Float = 0
    ) {
        self.nombre = nombre
        self.puntoASegundos = puntoASegundos
        self.puntoBSegundos = puntoBSegundos
        self.velocidadPorcentaje = velocidadPorcentaje
        self.tonoSemitonos = tonoSemitonos
        self.fechaCreacion = Date()
    }
}
