package com.loopmaster.backend.repository;

import com.loopmaster.backend.model.Cancion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CancionDAO extends JpaRepository<Cancion, Integer> {

    List<Cancion> findByTituloContainingIgnoreCase(String titulo);

    List<Cancion> findByArtistaIgnoreCase(String artista);

}
