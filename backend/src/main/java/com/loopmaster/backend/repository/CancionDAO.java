package com.loopmaster.backend.repository;

import com.loopmaster.backend.model.Cancion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CancionDAO extends JpaRepository<Cancion, Integer> {

    List<Cancion> findByTituloContainingIgnoreCase(String titulo);
    List<Cancion> findByArtistaIgnoreCase(String artista);
    @Query("SELECT c.id, c.titulo, c.artista, COUNT(b), AVG(b.puntoBSegundos - b.puntoASegundos) " +
            "FROM Cancion c LEFT JOIN c.bucles b " +
            "GROUP BY c.id, c.titulo, c.artista " +
            "HAVING COUNT(b) >= :minBucles " +
            "ORDER BY COUNT(b) DESC, c.titulo ASC")
    List<Object[]> resumenConMinBucles(@Param("minBucles") long minBucles);
    @Query("SELECT COUNT(b) FROM Cancion c LEFT JOIN c.bucles b GROUP BY c.id")
    List<Long> conteosBuclesPorCancion();

}
