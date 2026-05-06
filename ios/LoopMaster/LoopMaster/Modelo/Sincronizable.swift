import Foundation

protocol Sincronizable: AnyObject {
    var idServidor: Int? { get set }
    var pendienteSync: Bool { get set }
    var pendienteBorrado: Bool { get set }
}

extension Cancion: Sincronizable {}
extension Carpeta: Sincronizable {}
extension Bucle: Sincronizable {}
