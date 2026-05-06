import Foundation

nonisolated struct CancionDTO: Codable, Sendable {
    var id: Int?
    var titulo: String
    var artista: String
    var duracionSegundos: Int
    var nombreArchivo: String
}
