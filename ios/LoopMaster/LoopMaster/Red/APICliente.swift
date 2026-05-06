import Foundation

protocol APICliente: Sendable {
    func obtener<T: Decodable & Sendable>(_ ruta: String, tipo: T.Type) async throws -> T
    func crear<E: Encodable & Sendable, R: Decodable & Sendable>(_ ruta: String, cuerpo: E, tipo: R.Type) async throws -> R
    func actualizar<E: Encodable & Sendable, R: Decodable & Sendable>(_ ruta: String, cuerpo: E, tipo: R.Type) async throws -> R
    func eliminar(_ ruta: String) async throws
    func ping() async throws
}

enum ErrorAPI: Error, Sendable {
    case urlInvalida
    case sinConexion(causa: Error)
    case respuestaNoHTTP
    case codigoHTTP(Int)
    case codificacion(causa: Error)
    case decodificacion(causa: Error)

    var descripcionUsuario: String {
        switch self {
        case .urlInvalida:
            "URL del backend no válida."
        case .sinConexion:
            "No se pudo contactar con el backend. Comprueba que está arrancado y que la URL es correcta."
        case .respuestaNoHTTP:
            "Respuesta inesperada del servidor."
        case .codigoHTTP(let codigo):
            "El servidor respondió con código \(codigo)."
        case .codificacion:
            "Error preparando los datos para enviar."
        case .decodificacion:
            "Error interpretando la respuesta del servidor."
        }
    }
}

actor DefaultAPICliente: APICliente {
    private let proveedorBaseURL: @Sendable () -> URL
    private let session: URLSession
    private let codificador: JSONEncoder
    private let decodificador: JSONDecoder

    init(proveedorBaseURL: @escaping @Sendable () -> URL, session: URLSession = .shared) {
        self.proveedorBaseURL = proveedorBaseURL
        self.session = session
        self.codificador = JSONEncoder()
        self.decodificador = JSONDecoder()
    }

    func obtener<T: Decodable & Sendable>(_ ruta: String, tipo: T.Type) async throws -> T {
        let peticion = try construirPeticion(ruta: ruta, metodo: "GET", cuerpo: nil)
        let datos = try await ejecutar(peticion)
        return try decodificar(datos, tipo: tipo)
    }

    func crear<E: Encodable & Sendable, R: Decodable & Sendable>(_ ruta: String, cuerpo: E, tipo: R.Type) async throws -> R {
        let datosCuerpo = try codificar(cuerpo)
        let peticion = try construirPeticion(ruta: ruta, metodo: "POST", cuerpo: datosCuerpo)
        let datos = try await ejecutar(peticion)
        return try decodificar(datos, tipo: tipo)
    }

    func actualizar<E: Encodable & Sendable, R: Decodable & Sendable>(_ ruta: String, cuerpo: E, tipo: R.Type) async throws -> R {
        let datosCuerpo = try codificar(cuerpo)
        let peticion = try construirPeticion(ruta: ruta, metodo: "PUT", cuerpo: datosCuerpo)
        let datos = try await ejecutar(peticion)
        return try decodificar(datos, tipo: tipo)
    }

    func eliminar(_ ruta: String) async throws {
        let peticion = try construirPeticion(ruta: ruta, metodo: "DELETE", cuerpo: nil)
        _ = try await ejecutar(peticion)
    }

    func ping() async throws {
        var peticion = try construirPeticion(ruta: "/api/canciones", metodo: "HEAD", cuerpo: nil)
        peticion.timeoutInterval = 5
        _ = try await ejecutar(peticion)
    }

    private func construirPeticion(ruta: String, metodo: String, cuerpo: Data?) throws -> URLRequest {
        guard let url = URL(string: ruta, relativeTo: proveedorBaseURL()) else {
            throw ErrorAPI.urlInvalida
        }
        var peticion = URLRequest(url: url)
        peticion.httpMethod = metodo
        peticion.setValue("application/json", forHTTPHeaderField: "Accept")
        if let cuerpo {
            peticion.httpBody = cuerpo
            peticion.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return peticion
    }

    private func ejecutar(_ peticion: URLRequest) async throws -> Data {
        let datos: Data
        let respuesta: URLResponse
        do {
            (datos, respuesta) = try await session.data(for: peticion)
        } catch {
            throw ErrorAPI.sinConexion(causa: error)
        }
        guard let http = respuesta as? HTTPURLResponse else {
            throw ErrorAPI.respuestaNoHTTP
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ErrorAPI.codigoHTTP(http.statusCode)
        }
        return datos
    }

    private func codificar<E: Encodable>(_ valor: E) throws -> Data {
        do {
            return try codificador.encode(valor)
        } catch {
            throw ErrorAPI.codificacion(causa: error)
        }
    }

    private func decodificar<T: Decodable>(_ datos: Data, tipo: T.Type) throws -> T {
        guard !datos.isEmpty else {
            if let vacio = NoContenido() as? T {
                return vacio
            }
            throw ErrorAPI.decodificacion(causa: ErrorAPI.respuestaNoHTTP)
        }
        do {
            return try decodificador.decode(tipo, from: datos)
        } catch {
            throw ErrorAPI.decodificacion(causa: error)
        }
    }
}

struct NoContenido: Codable, Sendable {}
