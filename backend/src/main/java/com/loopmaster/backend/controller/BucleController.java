package com.loopmaster.backend.controller;

import com.loopmaster.backend.dto.BucleDTO;
import com.loopmaster.backend.service.BucleService;
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
@RequestMapping("/api/bucles")
public class BucleController {

    @Autowired
    private BucleService bucleService;

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<BucleDTO>> getBucles() {
        List<BucleDTO> bucles = this.bucleService.listarTodos();
        return ResponseEntity.ok(bucles);
    }

    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<BucleDTO> getBucleById(@PathVariable int id) {
        Optional<BucleDTO> b = this.bucleService.buscarPorId(id);
        if (b.isPresent()) {
            return ResponseEntity.ok(b.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<BucleDTO> crearBucle(@RequestBody BucleDTO datos) {
        Optional<BucleDTO> guardado = this.bucleService.crear(datos);
        if (guardado.isPresent()) {
            return ResponseEntity.created(URI.create("/api/bucles/" + guardado.get().getId())).body(guardado.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @PutMapping(value = "/{id}", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<BucleDTO> actualizarBucle(@PathVariable int id, @RequestBody BucleDTO datos) {
        Optional<BucleDTO> actualizado = this.bucleService.actualizar(id, datos);
        if (actualizado.isPresent()) {
            return ResponseEntity.ok(actualizado.get());
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarBucle(@PathVariable int id) {
        if (this.bucleService.eliminar(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

}
