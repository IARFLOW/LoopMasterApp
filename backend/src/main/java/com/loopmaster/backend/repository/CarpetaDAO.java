package com.loopmaster.backend.repository;

import com.loopmaster.backend.model.Carpeta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CarpetaDAO extends JpaRepository<Carpeta, Integer> {

    Optional<Carpeta> findByNombreIgnoreCase(String nombre);
    @Query("SELECT c.id, c.nombre, COUNT(can) " +
            "FROM Carpeta c LEFT JOIN c.canciones can " +
            "GROUP BY c.id, c.nombre " +
            "HAVING COUNT(can) >= :minCanciones " +
            "ORDER BY COUNT(can) DESC, c.nombre ASC")
    List<Object[]> resumenConMinCanciones(@Param("minCanciones") long minCanciones);

}
