import Foundation

extension CancionDTO {
    init(desde cancion: Cancion) {
        self.id = cancion.idServidor
        self.titulo = cancion.titulo
        self.artista = cancion.artista
        self.duracionSegundos = cancion.duracionSegundos
        self.nombreArchivo = cancion.nombreArchivo
    }
}

extension Cancion {
    func actualizar(desde dto: CancionDTO) {
        self.titulo = dto.titulo
        self.artista = dto.artista
        self.duracionSegundos = dto.duracionSegundos
        self.nombreArchivo = dto.nombreArchivo
        if let idRemoto = dto.id {
            self.idServidor = idRemoto
        }
        self.pendienteSync = false
        self.pendienteBorrado = false
    }
}

extension CarpetaDTO {
    init(desde carpeta: Carpeta) {
        self.id = carpeta.idServidor
        self.nombre = carpeta.nombre
        self.descripcion = carpeta.descripcion
        self.cantidadCanciones = carpeta.canciones.count
    }
}

extension Carpeta {
    func actualizar(desde dto: CarpetaDTO) {
        self.nombre = dto.nombre
        self.descripcion = dto.descripcion
        if let idRemoto = dto.id {
            self.idServidor = idRemoto
        }
        self.pendienteSync = false
        self.pendienteBorrado = false
    }
}

extension BucleDTO {
    init?(desde bucle: Bucle) {
        guard let cancionIdRemoto = bucle.cancion?.idServidor else {
            return nil
        }
        self.id = bucle.idServidor
        self.nombre = bucle.nombre
        self.puntoASegundos = bucle.puntoASegundos
        self.puntoBSegundos = bucle.puntoBSegundos
        self.velocidad = Int(bucle.velocidadPorcentaje.rounded())
        self.tonoSemitonos = Int(bucle.tonoSemitonos.rounded())
        self.cancionId = cancionIdRemoto
    }
}

extension Bucle {
    func actualizar(desde dto: BucleDTO) {
        self.nombre = dto.nombre
        self.puntoASegundos = dto.puntoASegundos
        self.puntoBSegundos = dto.puntoBSegundos
        self.velocidadPorcentaje = Float(dto.velocidad)
        self.tonoSemitonos = Float(dto.tonoSemitonos)
        if let idRemoto = dto.id {
            self.idServidor = idRemoto
        }
        self.pendienteSync = false
        self.pendienteBorrado = false
    }
}
