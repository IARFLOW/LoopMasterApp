import Foundation
import SwiftData

@Model
final class Cancion {
    var titulo: String
    var artista: String
    var duracionSegundos: Int
    var nombreArchivo: String
    var fechaCreacion: Date

    init(
        titulo: String,
        artista: String = "",
        duracionSegundos: Int,
        nombreArchivo: String = ""
    ) {
        self.titulo = titulo
        self.artista = artista
        self.duracionSegundos = duracionSegundos
        self.nombreArchivo = nombreArchivo
        self.fechaCreacion = Date()
    }
}
