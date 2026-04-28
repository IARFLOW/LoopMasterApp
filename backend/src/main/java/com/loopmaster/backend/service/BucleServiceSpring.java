package com.loopmaster.backend.service;

import com.loopmaster.backend.dto.BucleDTO;
import com.loopmaster.backend.model.Bucle;
import com.loopmaster.backend.model.Cancion;
import com.loopmaster.backend.repository.BucleDAO;
import com.loopmaster.backend.repository.CancionDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class BucleServiceSpring implements BucleService {

    private BucleDAO bucleDAO;
    private CancionDAO cancionDAO;

    @Autowired
    public BucleServiceSpring(BucleDAO bucleDAO, CancionDAO cancionDAO) {
        this.bucleDAO = bucleDAO;
        this.cancionDAO = cancionDAO;
    }

    @Override
    public List<BucleDTO> listarTodos() {
        List<Bucle> bucles = this.bucleDAO.findAll();
        return bucles.stream().map(this::mapearADTO).toList();
    }

    @Override
    public Optional<BucleDTO> buscarPorId(int id) {
        Optional<Bucle> existente = this.bucleDAO.findById(id);
        if (existente.isPresent()) {
            return Optional.of(mapearADTO(existente.get()));
        }
        return Optional.empty();
    }

    @Override
    public Optional<BucleDTO> crear(BucleDTO datos) {
        Optional<Cancion> cancion = this.cancionDAO.findById(datos.getCancionId());
        if (cancion.isEmpty()) {
            return Optional.empty();
        }
        Bucle entidad = new Bucle();
        entidad.setNombre(datos.getNombre());
        entidad.setPuntoASegundos(datos.getPuntoASegundos());
        entidad.setPuntoBSegundos(datos.getPuntoBSegundos());
        entidad.setVelocidad(datos.getVelocidad());
        entidad.setTonoSemitonos(datos.getTonoSemitonos());
        entidad.setCancion(cancion.get());
        Bucle guardado = this.bucleDAO.save(entidad);
        return Optional.of(mapearADTO(guardado));
    }

    @Override
    public Optional<BucleDTO> actualizar(int id, BucleDTO datos) {
        Optional<Bucle> existente = this.bucleDAO.findById(id);
        if (existente.isPresent()) {
            Bucle b = existente.get();
            b.setNombre(datos.getNombre());
            b.setPuntoASegundos(datos.getPuntoASegundos());
            b.setPuntoBSegundos(datos.getPuntoBSegundos());
            b.setVelocidad(datos.getVelocidad());
            b.setTonoSemitonos(datos.getTonoSemitonos());
            Bucle actualizado = this.bucleDAO.save(b);
            return Optional.of(mapearADTO(actualizado));
        }
        return Optional.empty();
    }

    @Override
    public boolean eliminar(int id) {
        if (this.bucleDAO.existsById(id)) {
            this.bucleDAO.deleteById(id);
            return true;
        }
        return false;
    }

    @Override
    public Optional<List<BucleDTO>> buclesDeCancion(int cancionId) {
        if (!this.cancionDAO.existsById(cancionId)) {
            return Optional.empty();
        }
        List<Bucle> bucles = this.bucleDAO.findByCancionId(cancionId);
        return Optional.of(bucles.stream().map(this::mapearADTO).toList());
    }

    private BucleDTO mapearADTO(Bucle b) {
        BucleDTO dto = new BucleDTO();
        dto.setId(b.getId());
        dto.setNombre(b.getNombre());
        dto.setPuntoASegundos(b.getPuntoASegundos());
        dto.setPuntoBSegundos(b.getPuntoBSegundos());
        dto.setVelocidad(b.getVelocidad());
        dto.setTonoSemitonos(b.getTonoSemitonos());
        dto.setCancionId(b.getCancion() != null ? b.getCancion().getId() : 0);
        return dto;
    }

}
