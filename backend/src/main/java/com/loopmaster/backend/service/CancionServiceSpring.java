package com.loopmaster.backend.service;

import com.loopmaster.backend.dto.CancionDTO;
import com.loopmaster.backend.dto.CancionResumenDTO;
import com.loopmaster.backend.model.Cancion;
import com.loopmaster.backend.repository.CancionDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class CancionServiceSpring implements CancionService {

    private CancionDAO cancionDAO;

    @Autowired
    public CancionServiceSpring(CancionDAO cancionDAO) {
        this.cancionDAO = cancionDAO;
    }

    @Override
    public List<CancionDTO> listarTodas() {
        List<Cancion> canciones = this.cancionDAO.findAll();
        return canciones.stream().map(this::mapearADTO).toList();
    }

    @Override
    public Optional<CancionDTO> buscarPorId(int id) {
        Optional<Cancion> existente = this.cancionDAO.findById(id);
        if (existente.isPresent()) {
            return Optional.of(mapearADTO(existente.get()));
        }
        return Optional.empty();
    }

    @Override
    public CancionDTO crear(CancionDTO datos) {
        Cancion entidad = new Cancion();
        entidad.setTitulo(datos.getTitulo());
        entidad.setArtista(datos.getArtista());
        entidad.setDuracionSegundos(datos.getDuracionSegundos());
        entidad.setNombreArchivo(datos.getNombreArchivo());
        Cancion guardada = this.cancionDAO.save(entidad);
        return mapearADTO(guardada);
    }

    @Override
    public Optional<CancionDTO> actualizar(int id, CancionDTO datos) {
        Optional<Cancion> existente = this.cancionDAO.findById(id);
        if (existente.isPresent()) {
            Cancion c = existente.get();
            c.setTitulo(datos.getTitulo());
            c.setArtista(datos.getArtista());
            c.setDuracionSegundos(datos.getDuracionSegundos());
            c.setNombreArchivo(datos.getNombreArchivo());
            Cancion actualizada = this.cancionDAO.save(c);
            return Optional.of(mapearADTO(actualizada));
        }
        return Optional.empty();
    }

    @Override
    public boolean eliminar(int id) {
        if (this.cancionDAO.existsById(id)) {
            this.cancionDAO.deleteById(id);
            return true;
        }
        return false;
    }

    @Override
    @Transactional(readOnly = true)
    public List<CancionResumenDTO> resumenConMinBucles(long minBucles) {
        List<Object[]> filas = this.cancionDAO.resumenConMinBucles(minBucles);
        List<CancionResumenDTO> resultado = new ArrayList<>();
        for (Object[] fila : filas) {
            resultado.add(mapearFilaResumen(fila));
        }
        return resultado;
    }

    @Override
    @Transactional(readOnly = true)
    public List<CancionResumenDTO> conMasBuclesQueMedia() {
        List<Long> conteos = this.cancionDAO.conteosBuclesPorCancion();
        if (conteos.isEmpty()) {
            return new ArrayList<>();
        }
        long suma = 0;
        for (Long n : conteos) {
            suma += n;
        }
        double media = (double) suma / conteos.size();
        long umbral = (long) Math.floor(media) + 1;
        return resumenConMinBucles(umbral);
    }

    private CancionResumenDTO mapearFilaResumen(Object[] fila) {
        CancionResumenDTO dto = new CancionResumenDTO();
        dto.setId((Integer) fila[0]);
        dto.setTitulo((String) fila[1]);
        dto.setArtista((String) fila[2]);
        dto.setCantidadBucles(((Long) fila[3]).intValue());
        Double mediaSegundos = (Double) fila[4];
        dto.setDuracionMediaBuclesSegundos(mediaSegundos != null ? mediaSegundos : 0.0);
        return dto;
    }

    private CancionDTO mapearADTO(Cancion c) {
        CancionDTO dto = new CancionDTO();
        dto.setId(c.getId());
        dto.setTitulo(c.getTitulo());
        dto.setArtista(c.getArtista());
        dto.setDuracionSegundos(c.getDuracionSegundos());
        dto.setNombreArchivo(c.getNombreArchivo());
        return dto;
    }

}
