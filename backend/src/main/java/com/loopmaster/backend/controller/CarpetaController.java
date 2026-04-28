package com.loopmaster.backend.controller;

import com.loopmaster.backend.dto.CancionDTO;
import com.loopmaster.backend.dto.CarpetaDTO;
import com.loopmaster.backend.service.CarpetaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/carpetas")
public class CarpetaController {

    @Autowired
    private CarpetaService carpetaService;

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<CarpetaDTO>> getCarpetas() {
        List<CarpetaDTO> carpetas = this.carpetaService.listarTodas();
        return ResponseEntity.ok(carpetas);
    }

    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<CarpetaDTO> getCarpetaById(@PathVariable int id) {
        Optional<CarpetaDTO> c = this.carpetaService.buscarPorId(id);
        if (c.isPresent()) {
            return ResponseEntity.ok(c.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<CarpetaDTO> crearCarpeta(@RequestBody CarpetaDTO datos) {
        CarpetaDTO guardada = this.carpetaService.crear(datos);
        return ResponseEntity.created(URI.create("/api/carpetas/" + guardada.getId())).body(guardada);
    }

    @PutMapping(value = "/{id}", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<CarpetaDTO> actualizarCarpeta(@PathVariable int id, @RequestBody CarpetaDTO datos) {
        Optional<CarpetaDTO> actualizada = this.carpetaService.actualizar(id, datos);
        if (actualizada.isPresent()) {
            return ResponseEntity.ok(actualizada.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarCarpeta(@PathVariable int id) {
        if (this.carpetaService.eliminar(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @GetMapping(value = "/{id}/canciones", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<CancionDTO>> getCancionesDeCarpeta(@PathVariable int id) {
        Optional<List<CancionDTO>> canciones = this.carpetaService.cancionesDeCarpeta(id);
        if (canciones.isPresent()) {
            return ResponseEntity.ok(canciones.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @PostMapping(value = "/{carpetaId}/canciones/{cancionId}")
    public ResponseEntity<Void> anadirCancionACarpeta(@PathVariable int carpetaId, @PathVariable int cancionId) {
        if (this.carpetaService.anadirCancionACarpeta(carpetaId, cancionId)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @DeleteMapping(value = "/{carpetaId}/canciones/{cancionId}")
    public ResponseEntity<Void> quitarCancionDeCarpeta(@PathVariable int carpetaId, @PathVariable int cancionId) {
        if (this.carpetaService.quitarCancionDeCarpeta(carpetaId, cancionId)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

}
