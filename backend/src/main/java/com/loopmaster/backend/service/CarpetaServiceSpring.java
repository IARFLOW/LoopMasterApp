package com.loopmaster.backend.service;

import com.loopmaster.backend.dto.CancionDTO;
import com.loopmaster.backend.dto.CarpetaDTO;
import com.loopmaster.backend.model.Cancion;
import com.loopmaster.backend.model.Carpeta;
import com.loopmaster.backend.repository.CancionDAO;
import com.loopmaster.backend.repository.CarpetaDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class CarpetaServiceSpring implements CarpetaService {

    private CarpetaDAO carpetaDAO;
    private CancionDAO cancionDAO;

    @Autowired
    public CarpetaServiceSpring(CarpetaDAO carpetaDAO, CancionDAO cancionDAO) {
        this.carpetaDAO = carpetaDAO;
        this.cancionDAO = cancionDAO;
    }

    @Override
    public List<CarpetaDTO> listarTodas() {
        List<Carpeta> carpetas = this.carpetaDAO.findAll();
        return carpetas.stream().map(this::mapearADTO).toList();
    }

    @Override
    public Optional<CarpetaDTO> buscarPorId(int id) {
        Optional<Carpeta> existente = this.carpetaDAO.findById(id);
        if (existente.isPresent()) {
            return Optional.of(mapearADTO(existente.get()));
        }
        return Optional.empty();
    }

    @Override
    public CarpetaDTO crear(CarpetaDTO datos) {
        Carpeta entidad = new Carpeta();
        entidad.setNombre(datos.getNombre());
        entidad.setDescripcion(datos.getDescripcion());
        Carpeta guardada = this.carpetaDAO.save(entidad);
        return mapearADTO(guardada);
    }

    @Override
    public Optional<CarpetaDTO> actualizar(int id, CarpetaDTO datos) {
        Optional<Carpeta> existente = this.carpetaDAO.findById(id);
        if (existente.isPresent()) {
            Carpeta c = existente.get();
            c.setNombre(datos.getNombre());
            c.setDescripcion(datos.getDescripcion());
            Carpeta actualizada = this.carpetaDAO.save(c);
            return Optional.of(mapearADTO(actualizada));
        }
        return Optional.empty();
    }

    @Override
    public boolean eliminar(int id) {
        if (this.carpetaDAO.existsById(id)) {
            this.carpetaDAO.deleteById(id);
            return true;
        }
        return false;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<List<CancionDTO>> cancionesDeCarpeta(int carpetaId) {
        Optional<Carpeta> existente = this.carpetaDAO.findById(carpetaId);
        if (existente.isPresent()) {
            List<CancionDTO> resultado = new ArrayList<>();
            for (Cancion c : existente.get().getCanciones()) {
                resultado.add(mapearCancionADTO(c));
            }
            return Optional.of(resultado);
        }
        return Optional.empty();
    }

    @Override
    @Transactional
    public boolean anadirCancionACarpeta(int carpetaId, int cancionId) {
        Optional<Carpeta> carpeta = this.carpetaDAO.findById(carpetaId);
        Optional<Cancion> cancion = this.cancionDAO.findById(cancionId);
        if (carpeta.isPresent() && cancion.isPresent()) {
            carpeta.get().addCancion(cancion.get());
            this.carpetaDAO.save(carpeta.get());
            return true;
        }
        return false;
    }

    @Override
    @Transactional
    public boolean quitarCancionDeCarpeta(int carpetaId, int cancionId) {
        Optional<Carpeta> carpeta = this.carpetaDAO.findById(carpetaId);
        Optional<Cancion> cancion = this.cancionDAO.findById(cancionId);
        if (carpeta.isPresent() && cancion.isPresent()) {
            carpeta.get().removeCancion(cancion.get());
            this.carpetaDAO.save(carpeta.get());
            return true;
        }
        return false;
    }

    private CarpetaDTO mapearADTO(Carpeta c) {
        CarpetaDTO dto = new CarpetaDTO();
        dto.setId(c.getId());
        dto.setNombre(c.getNombre());
        dto.setDescripcion(c.getDescripcion());
        dto.setCantidadCanciones(c.getCanciones() != null ? c.getCanciones().size() : 0);
        return dto;
    }

    private CancionDTO mapearCancionADTO(Cancion c) {
        CancionDTO dto = new CancionDTO();
        dto.setId(c.getId());
        dto.setTitulo(c.getTitulo());
        dto.setArtista(c.getArtista());
        dto.setDuracionSegundos(c.getDuracionSegundos());
        dto.setNombreArchivo(c.getNombreArchivo());
        return dto;
    }

}
