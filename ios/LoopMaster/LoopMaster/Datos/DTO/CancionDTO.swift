import Foundation

struct CancionDTO: Codable {
    var id: Int?
    var titulo: String
    var artista: String
    var duracionSegundos: Int
    var nombreArchivo: String
}
