package com.loopmaster.backend.service;

import com.loopmaster.backend.dto.CancionDTO;
import com.loopmaster.backend.dto.CarpetaDTO;

import java.util.List;
import java.util.Optional;

public interface CarpetaService {

    List<CarpetaDTO> listarTodas();

    Optional<CarpetaDTO> buscarPorId(int id);

    CarpetaDTO crear(CarpetaDTO datos);

    Optional<CarpetaDTO> actualizar(int id, CarpetaDTO datos);

    boolean eliminar(int id);

    Optional<List<CancionDTO>> cancionesDeCarpeta(int carpetaId);

    boolean anadirCancionACarpeta(int carpetaId, int cancionId);

    boolean quitarCancionDeCarpeta(int carpetaId, int cancionId);

}
