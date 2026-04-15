package com.loopmaster.backend.service;

import com.loopmaster.backend.model.Cancion;
import com.loopmaster.backend.repository.CancionDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CancionService {

    @Autowired
    private CancionDAO cancionDAO;

    public List<Cancion> listarTodas() {
        return cancionDAO.findAll();
    }

    public Optional<Cancion> buscarPorId(int id) {
        return cancionDAO.findById(id);
    }

    public Cancion crear(Cancion cancion) {
        return cancionDAO.save(cancion);
    }

    public Optional<Cancion> actualizar(int id, Cancion datos) {
        Optional<Cancion> existente = cancionDAO.findById(id);
        if (existente.isPresent()) {
            Cancion c = existente.get();
            c.setTitulo(datos.getTitulo());
            c.setArtista(datos.getArtista());
            c.setDuracionSegundos(datos.getDuracionSegundos());
            c.setNombreArchivo(datos.getNombreArchivo());
            return Optional.of(cancionDAO.save(c));
        }
        return Optional.empty();
    }

    public boolean eliminar(int id) {
        if (cancionDAO.existsById(id)) {
            cancionDAO.deleteById(id);
            return true;
        }
        return false;
    }

}
