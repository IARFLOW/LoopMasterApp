package com.loopmaster.backend.service;

import com.loopmaster.backend.dto.CancionDTO;

import java.util.List;
import java.util.Optional;

public interface CancionService {

    List<CancionDTO> listarTodas();

    Optional<CancionDTO> buscarPorId(int id);

    CancionDTO crear(CancionDTO datos);

    Optional<CancionDTO> actualizar(int id, CancionDTO datos);

    boolean eliminar(int id);

}
