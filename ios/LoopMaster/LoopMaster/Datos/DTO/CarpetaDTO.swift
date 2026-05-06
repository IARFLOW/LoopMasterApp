import Foundation

nonisolated struct CarpetaDTO: Codable, Sendable {
    var id: Int?
    var nombre: String
    var descripcion: String
    var cantidadCanciones: Int
}
