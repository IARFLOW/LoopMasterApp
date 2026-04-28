package com.loopmaster.backend.service;

import com.loopmaster.backend.dto.BucleDTO;

import java.util.List;
import java.util.Optional;

public interface BucleService {

    List<BucleDTO> listarTodos();

    Optional<BucleDTO> buscarPorId(int id);

    Optional<BucleDTO> crear(BucleDTO datos);

    Optional<BucleDTO> actualizar(int id, BucleDTO datos);

    boolean eliminar(int id);

    Optional<List<BucleDTO>> buclesDeCancion(int cancionId);

}
