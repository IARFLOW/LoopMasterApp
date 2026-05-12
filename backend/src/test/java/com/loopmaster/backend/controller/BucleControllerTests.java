package com.loopmaster.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.loopmaster.backend.dto.BucleDTO;
import com.loopmaster.backend.model.Bucle;
import com.loopmaster.backend.model.Cancion;
import com.loopmaster.backend.repository.BucleDAO;
import com.loopmaster.backend.repository.CancionDAO;
import com.loopmaster.backend.repository.CarpetaDAO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class BucleControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private BucleDAO bucleDAO;

    @Autowired
    private CancionDAO cancionDAO;

    @Autowired
    private CarpetaDAO carpetaDAO;

    private Cancion cancionSeed;
    private Bucle bucleSeed;

    @BeforeEach
    void prepararDatos() {
        this.carpetaDAO.deleteAll();
        this.bucleDAO.deleteAll();
        this.cancionDAO.deleteAll();

        Cancion c = new Cancion();
        c.setTitulo("Ansioso");
        c.setArtista("Andres Calamaro");
        c.setDuracionSegundos(240);
        c.setNombreArchivo("ansioso.mp3");
        this.cancionSeed = this.cancionDAO.save(c);

        Bucle b = new Bucle();
        b.setNombre("Estribillo");
        b.setPuntoASegundos(45.250);
        b.setPuntoBSegundos(62.500);
        b.setVelocidad(100);
        b.setTonoSemitonos(0);
        b.setCancion(this.cancionSeed);
        this.bucleSeed = this.bucleDAO.save(b);
    }

    @Test
    void getBuclesDevuelveLaListaSembrada() throws Exception {
        this.mockMvc.perform(get("/api/bucles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].nombre").value("Estribillo"))
                .andExpect(jsonPath("$[0].puntoASegundos").value(45.250))
                .andExpect(jsonPath("$[0].puntoBSegundos").value(62.500))
                .andExpect(jsonPath("$[0].cancionId").value(this.cancionSeed.getId()));
    }

    @Test
    void getBucleByIdDevuelveDoscientosCuandoExiste() throws Exception {
        this.mockMvc.perform(get("/api/bucles/" + this.bucleSeed.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(this.bucleSeed.getId()))
                .andExpect(jsonPath("$.nombre").value("Estribillo"));
    }

    @Test
    void getBucleByIdDevuelveCuatrocientosCuatroCuandoNoExiste() throws Exception {
        this.mockMvc.perform(get("/api/bucles/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void postCreaUnBucleNuevoYDevuelveDoscientosUnoConLocation() throws Exception {
        BucleDTO nuevo = new BucleDTO();
        nuevo.setNombre("Solo");
        nuevo.setPuntoASegundos(100.000);
        nuevo.setPuntoBSegundos(120.500);
        nuevo.setVelocidad(90);
        nuevo.setTonoSemitonos(2);
        nuevo.setCancionId(this.cancionSeed.getId());

        this.mockMvc.perform(post("/api/bucles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(nuevo)))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", containsString("/api/bucles/")))
                .andExpect(jsonPath("$.nombre").value("Solo"))
                .andExpect(jsonPath("$.velocidad").value(90))
                .andExpect(jsonPath("$.tonoSemitonos").value(2));
    }

    @Test
    void postDevuelveCuatrocientosCuatroSiLaCancionNoExiste() throws Exception {
        BucleDTO nuevo = new BucleDTO();
        nuevo.setNombre("Solo huerfano");
        nuevo.setPuntoASegundos(0.0);
        nuevo.setPuntoBSegundos(10.0);
        nuevo.setVelocidad(100);
        nuevo.setTonoSemitonos(0);
        nuevo.setCancionId(999999);

        this.mockMvc.perform(post("/api/bucles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(nuevo)))
                .andExpect(status().isNotFound());
    }

    @Test
    void putActualizaUnBucleExistente() throws Exception {
        BucleDTO datos = new BucleDTO();
        datos.setNombre("Estribillo lento");
        datos.setPuntoASegundos(45.000);
        datos.setPuntoBSegundos(63.000);
        datos.setVelocidad(80);
        datos.setTonoSemitonos(-1);
        datos.setCancionId(this.cancionSeed.getId());

        this.mockMvc.perform(put("/api/bucles/" + this.bucleSeed.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(datos)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Estribillo lento"))
                .andExpect(jsonPath("$.velocidad").value(80))
                .andExpect(jsonPath("$.tonoSemitonos").value(-1));
    }

    @Test
    void putDevuelveCuatrocientosCuatroSiElBucleNoExiste() throws Exception {
        BucleDTO datos = new BucleDTO();
        datos.setNombre("Fantasma");
        datos.setPuntoASegundos(0.0);
        datos.setPuntoBSegundos(1.0);
        datos.setVelocidad(100);
        datos.setTonoSemitonos(0);
        datos.setCancionId(this.cancionSeed.getId());

        this.mockMvc.perform(put("/api/bucles/999999")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(datos)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteEliminaUnBucleExistenteYDevuelveDoscientosCuatro() throws Exception {
        this.mockMvc.perform(delete("/api/bucles/" + this.bucleSeed.getId()))
                .andExpect(status().isNoContent());

        this.mockMvc.perform(get("/api/bucles/" + this.bucleSeed.getId()))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteDevuelveCuatrocientosCuatroSiElBucleNoExiste() throws Exception {
        this.mockMvc.perform(delete("/api/bucles/999999"))
                .andExpect(status().isNotFound());
    }

}
