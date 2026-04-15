package com.loopmaster.backend.repository;

import com.loopmaster.backend.model.Bucle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BucleDAO extends JpaRepository<Bucle, Integer> {

    List<Bucle> findByCancionId(int cancionId);

}
