import Foundation

struct BucleDTO: Codable {
    var id: Int?
    var nombre: String
    var puntoASegundos: Double
    var puntoBSegundos: Double
    var velocidad: Int
    var tonoSemitonos: Int
    var cancionId: Int
}
