package com.loopmaster.backend.controller;

import com.loopmaster.backend.dto.BucleDTO;
import com.loopmaster.backend.dto.CancionDTO;
import com.loopmaster.backend.service.BucleService;
import com.loopmaster.backend.service.CancionService;
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
@RequestMapping("/api/canciones")
public class CancionController {

    @Autowired
    private CancionService cancionService;

    @Autowired
    private BucleService bucleService;

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<CancionDTO>> getCanciones() {
        List<CancionDTO> canciones = this.cancionService.listarTodas();
        return ResponseEntity.ok(canciones);
    }

    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<CancionDTO> getCancionById(@PathVariable int id) {
        Optional<CancionDTO> c = this.cancionService.buscarPorId(id);
        if (c.isPresent()) {
            return ResponseEntity.ok(c.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<CancionDTO> crearCancion(@RequestBody CancionDTO datos) {
        CancionDTO guardada = this.cancionService.crear(datos);
        return ResponseEntity.created(URI.create("/api/canciones/" + guardada.getId())).body(guardada);
    }

    @PutMapping(value = "/{id}", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<CancionDTO> actualizarCancion(@PathVariable int id, @RequestBody CancionDTO datos) {
        Optional<CancionDTO> actualizada = this.cancionService.actualizar(id, datos);
        if (actualizada.isPresent()) {
            return ResponseEntity.ok(actualizada.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarCancion(@PathVariable int id) {
        if (this.cancionService.eliminar(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @GetMapping(value = "/{id}/bucles", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<BucleDTO>> getBuclesDeCancion(@PathVariable int id) {
        Optional<List<BucleDTO>> bucles = this.bucleService.buclesDeCancion(id);
        if (bucles.isPresent()) {
            return ResponseEntity.ok(bucles.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

}
