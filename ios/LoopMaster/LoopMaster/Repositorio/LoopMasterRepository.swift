import Foundation
import SwiftData

enum ResultadoRepositorio: Sendable, Equatable {
    case exito(mensaje: String)
    case error(mensaje: String, detalle: String?)

    var esExito: Bool {
        if case .exito = self { return true }
        return false
    }

    var mensaje: String {
        switch self {
        case .exito(let m): m
        case .error(let m, _): m
        }
    }

    var detalle: String? {
        switch self {
        case .exito: nil
        case .error(_, let d): d
        }
    }
}

@MainActor
@Observable
final class LoopMasterRepository {
    private let cliente: APICliente
    private let contexto: ModelContext

    var sincronizando: Bool = false
    var ultimoResultado: ResultadoRepositorio?

    init(cliente: APICliente, contexto: ModelContext) {
        self.cliente = cliente
        self.contexto = contexto
    }

    func registrarCambio<T>(en objeto: T) where T: PersistentModel & Sincronizable {
        objeto.pendienteSync = true
        guardar()
    }

    func marcarParaBorrar<T>(_ objeto: T) where T: PersistentModel & Sincronizable {
        if objeto.idServidor == nil {
            contexto.delete(objeto)
        } else {
            objeto.pendienteBorrado = true
            objeto.pendienteSync = true
        }
        guardar()
    }

    func probarConexion() async {
        do {
            try await cliente.ping()
            ultimoResultado = .exito(mensaje: "Conexión correcta con el backend")
        } catch let error as ErrorAPI {
            ultimoResultado = .error(mensaje: "No se pudo conectar", detalle: error.descripcionUsuario)
        } catch {
            ultimoResultado = .error(mensaje: "No se pudo conectar", detalle: error.localizedDescription)
        }
    }

    func sincronizar() async {
        guard !sincronizando else { return }
        sincronizando = true
        defer { sincronizando = false }

        do {
            try await subirPendientes()
            try await descargarDelServidor()
            ultimoResultado = .exito(mensaje: "Sincronización completa")
        } catch let error as ErrorAPI {
            ultimoResultado = .error(mensaje: "Error sincronizando", detalle: error.descripcionUsuario)
        } catch {
            ultimoResultado = .error(mensaje: "Error sincronizando", detalle: error.localizedDescription)
        }
    }

    private func subirPendientes() async throws {
        try await subirCarpetasPendientes()
        try await subirCancionesPendientes()
        try await subirBuclesPendientes()
    }

    private func subirCarpetasPendientes() async throws {
        let aBorrar = try contexto.fetch(FetchDescriptor<Carpeta>(predicate: #Predicate { $0.pendienteBorrado && $0.idServidor != nil }))
        for carpeta in aBorrar {
            try await cliente.eliminar("/api/carpetas/\(carpeta.idServidor!)")
            contexto.delete(carpeta)
        }

        let aCrear = try contexto.fetch(FetchDescriptor<Carpeta>(predicate: #Predicate { $0.pendienteSync && $0.idServidor == nil && !$0.pendienteBorrado }))
        for carpeta in aCrear {
            let dto = CarpetaDTO(desde: carpeta)
            let respuesta: CarpetaDTO = try await cliente.crear("/api/carpetas", cuerpo: dto, tipo: CarpetaDTO.self)
            carpeta.actualizar(desde: respuesta)
        }

        let aActualizar = try contexto.fetch(FetchDescriptor<Carpeta>(predicate: #Predicate { $0.pendienteSync && $0.idServidor != nil && !$0.pendienteBorrado }))
        for carpeta in aActualizar {
            let dto = CarpetaDTO(desde: carpeta)
            let respuesta: CarpetaDTO = try await cliente.actualizar("/api/carpetas/\(carpeta.idServidor!)", cuerpo: dto, tipo: CarpetaDTO.self)
            carpeta.actualizar(desde: respuesta)
        }

        guardar()
    }

    private func subirCancionesPendientes() async throws {
        let aBorrar = try contexto.fetch(FetchDescriptor<Cancion>(predicate: #Predicate { $0.pendienteBorrado && $0.idServidor != nil }))
        for cancion in aBorrar {
            try await cliente.eliminar("/api/canciones/\(cancion.idServidor!)")
            contexto.delete(cancion)
        }

        let aCrear = try contexto.fetch(FetchDescriptor<Cancion>(predicate: #Predicate { $0.pendienteSync && $0.idServidor == nil && !$0.pendienteBorrado }))
        for cancion in aCrear {
            let dto = CancionDTO(desde: cancion)
            let respuesta: CancionDTO = try await cliente.crear("/api/canciones", cuerpo: dto, tipo: CancionDTO.self)
            cancion.actualizar(desde: respuesta)
        }

        let aActualizar = try contexto.fetch(FetchDescriptor<Cancion>(predicate: #Predicate { $0.pendienteSync && $0.idServidor != nil && !$0.pendienteBorrado }))
        for cancion in aActualizar {
            let dto = CancionDTO(desde: cancion)
            let respuesta: CancionDTO = try await cliente.actualizar("/api/canciones/\(cancion.idServidor!)", cuerpo: dto, tipo: CancionDTO.self)
            cancion.actualizar(desde: respuesta)
        }

        guardar()
    }

    private func subirBuclesPendientes() async throws {
        let aBorrar = try contexto.fetch(FetchDescriptor<Bucle>(predicate: #Predicate { $0.pendienteBorrado && $0.idServidor != nil }))
        for bucle in aBorrar {
            try await cliente.eliminar("/api/bucles/\(bucle.idServidor!)")
            contexto.delete(bucle)
        }

        let aCrear = try contexto.fetch(FetchDescriptor<Bucle>(predicate: #Predicate { $0.pendienteSync && $0.idServidor == nil && !$0.pendienteBorrado }))
        for bucle in aCrear {
            guard let dto = BucleDTO(desde: bucle) else { continue }
            let respuesta: BucleDTO = try await cliente.crear("/api/bucles", cuerpo: dto, tipo: BucleDTO.self)
            bucle.actualizar(desde: respuesta)
        }

        let aActualizar = try contexto.fetch(FetchDescriptor<Bucle>(predicate: #Predicate { $0.pendienteSync && $0.idServidor != nil && !$0.pendienteBorrado }))
        for bucle in aActualizar {
            guard let dto = BucleDTO(desde: bucle) else { continue }
            let respuesta: BucleDTO = try await cliente.actualizar("/api/bucles/\(bucle.idServidor!)", cuerpo: dto, tipo: BucleDTO.self)
            bucle.actualizar(desde: respuesta)
        }

        guardar()
    }

    private func descargarDelServidor() async throws {
        let carpetas: [CarpetaDTO] = try await cliente.obtener("/api/carpetas", tipo: [CarpetaDTO].self)
        for dto in carpetas {
            try aplicarCarpeta(dto: dto)
        }

        let canciones: [CancionDTO] = try await cliente.obtener("/api/canciones", tipo: [CancionDTO].self)
        for dto in canciones {
            try aplicarCancion(dto: dto)
        }

        let bucles: [BucleDTO] = try await cliente.obtener("/api/bucles", tipo: [BucleDTO].self)
        for dto in bucles {
            try aplicarBucle(dto: dto)
        }

        guardar()
    }

    private func aplicarCarpeta(dto: CarpetaDTO) throws {
        guard let idServ = dto.id else { return }
        let descriptor = FetchDescriptor<Carpeta>(predicate: #Predicate { $0.idServidor == idServ })
        if let existente = try contexto.fetch(descriptor).first {
            existente.actualizar(desde: dto)
        } else {
            let nueva = Carpeta(
                nombre: dto.nombre,
                descripcion: dto.descripcion,
                idServidor: dto.id,
                pendienteSync: false
            )
            contexto.insert(nueva)
        }
    }

    private func aplicarCancion(dto: CancionDTO) throws {
        guard let idServ = dto.id else { return }
        let descriptor = FetchDescriptor<Cancion>(predicate: #Predicate { $0.idServidor == idServ })
        if let existente = try contexto.fetch(descriptor).first {
            existente.actualizar(desde: dto)
        } else {
            let nueva = Cancion(
                titulo: dto.titulo,
                artista: dto.artista,
                duracionSegundos: dto.duracionSegundos,
                nombreArchivo: dto.nombreArchivo,
                idServidor: dto.id,
                pendienteSync: false
            )
            contexto.insert(nueva)
        }
    }

    private func aplicarBucle(dto: BucleDTO) throws {
        guard let idServ = dto.id else { return }
        let cancionId = dto.cancionId
        let cancionDescriptor = FetchDescriptor<Cancion>(predicate: #Predicate { $0.idServidor == cancionId })
        guard let cancionLocal = try contexto.fetch(cancionDescriptor).first else {
            return
        }
        let descriptor = FetchDescriptor<Bucle>(predicate: #Predicate { $0.idServidor == idServ })
        if let existente = try contexto.fetch(descriptor).first {
            existente.actualizar(desde: dto)
        } else {
            let nuevo = Bucle(
                nombre: dto.nombre,
                puntoASegundos: dto.puntoASegundos,
                puntoBSegundos: dto.puntoBSegundos,
                velocidadPorcentaje: Float(dto.velocidad),
                tonoSemitonos: Float(dto.tonoSemitonos),
                idServidor: dto.id,
                pendienteSync: false
            )
            nuevo.cancion = cancionLocal
            contexto.insert(nuevo)
        }
    }

    private func guardar() {
        do {
            try contexto.save()
        } catch {
            ultimoResultado = .error(mensaje: "Error guardando datos en local", detalle: error.localizedDescription)
        }
    }
}
