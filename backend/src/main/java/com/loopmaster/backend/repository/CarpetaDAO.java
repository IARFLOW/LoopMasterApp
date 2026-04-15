package com.loopmaster.backend.repository;

import com.loopmaster.backend.model.Carpeta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CarpetaDAO extends JpaRepository<Carpeta, Integer> {

    Optional<Carpeta> findByNombreIgnoreCase(String nombre);

}
