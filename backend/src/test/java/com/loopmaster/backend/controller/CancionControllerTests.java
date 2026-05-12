package com.loopmaster.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.loopmaster.backend.dto.CancionDTO;
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
class CancionControllerTests {

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

    private Cancion cancionSinBucles;
    private Cancion cancionConDosBucles;
    private Cancion cancionConCuatroBucles;

    @BeforeEach
    void prepararDatos() {
        this.carpetaDAO.deleteAll();
        this.bucleDAO.deleteAll();
        this.cancionDAO.deleteAll();

        this.cancionSinBucles = guardarCancion("Vamos", "Andres Calamaro", 200);
        this.cancionConDosBucles = guardarCancion("Ansioso", "Andres Calamaro", 240);
        this.cancionConCuatroBucles = guardarCancion("Cosquillas", "Andres Calamaro", 260);

        guardarBucle("A1", 0.0, 10.0, this.cancionConDosBucles);
        guardarBucle("A2", 30.0, 50.0, this.cancionConDosBucles);

        guardarBucle("B1", 0.0, 5.0, this.cancionConCuatroBucles);
        guardarBucle("B2", 10.0, 15.0, this.cancionConCuatroBucles);
        guardarBucle("B3", 20.0, 25.0, this.cancionConCuatroBucles);
        guardarBucle("B4", 30.0, 35.0, this.cancionConCuatroBucles);
    }

    private Cancion guardarCancion(String titulo, String artista, int duracion) {
        Cancion c = new Cancion();
        c.setTitulo(titulo);
        c.setArtista(artista);
        c.setDuracionSegundos(duracion);
        c.setNombreArchivo(titulo.toLowerCase() + ".mp3");
        return this.cancionDAO.save(c);
    }

    private void guardarBucle(String nombre, double a, double b, Cancion cancion) {
        Bucle bucle = new Bucle();
        bucle.setNombre(nombre);
        bucle.setPuntoASegundos(a);
        bucle.setPuntoBSegundos(b);
        bucle.setVelocidad(100);
        bucle.setTonoSemitonos(0);
        bucle.setCancion(cancion);
        this.bucleDAO.save(bucle);
    }

    @Test
    void getCancionesDevuelveLasTresSembradas() throws Exception {
        this.mockMvc.perform(get("/api/canciones"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)));
    }

    @Test
    void getCancionByIdDevuelveDoscientosCuandoExiste() throws Exception {
        this.mockMvc.perform(get("/api/canciones/" + this.cancionConDosBucles.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.titulo").value("Ansioso"))
                .andExpect(jsonPath("$.artista").value("Andres Calamaro"))
                .andExpect(jsonPath("$.duracionSegundos").value(240));
    }

    @Test
    void getCancionByIdDevuelveCuatrocientosCuatroCuandoNoExiste() throws Exception {
        this.mockMvc.perform(get("/api/canciones/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void postCreaUnaCancionYDevuelveDoscientosUnoConLocation() throws Exception {
        CancionDTO nueva = new CancionDTO();
        nueva.setTitulo("Sin Documentos");
        nueva.setArtista("Los Rodriguez");
        nueva.setDuracionSegundos(220);
        nueva.setNombreArchivo("sin-documentos.mp3");

        this.mockMvc.perform(post("/api/canciones")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(nueva)))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", containsString("/api/canciones/")))
                .andExpect(jsonPath("$.titulo").value("Sin Documentos"))
                .andExpect(jsonPath("$.artista").value("Los Rodriguez"));
    }

    @Test
    void putActualizaUnaCancionExistente() throws Exception {
        CancionDTO datos = new CancionDTO();
        datos.setTitulo("Ansioso (remasterizado)");
        datos.setArtista("Andres Calamaro");
        datos.setDuracionSegundos(245);
        datos.setNombreArchivo("ansioso-remaster.mp3");

        this.mockMvc.perform(put("/api/canciones/" + this.cancionConDosBucles.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(datos)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.titulo").value("Ansioso (remasterizado)"))
                .andExpect(jsonPath("$.duracionSegundos").value(245));
    }

    @Test
    void putDevuelveCuatrocientosCuatroSiLaCancionNoExiste() throws Exception {
        CancionDTO datos = new CancionDTO();
        datos.setTitulo("Fantasma");
        datos.setArtista("Nadie");
        datos.setDuracionSegundos(100);
        datos.setNombreArchivo("fantasma.mp3");

        this.mockMvc.perform(put("/api/canciones/999999")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(datos)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteEliminaUnaCancionYDevuelveDoscientosCuatro() throws Exception {
        this.mockMvc.perform(delete("/api/canciones/" + this.cancionSinBucles.getId()))
                .andExpect(status().isNoContent());

        this.mockMvc.perform(get("/api/canciones/" + this.cancionSinBucles.getId()))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteDevuelveCuatrocientosCuatroSiLaCancionNoExiste() throws Exception {
        this.mockMvc.perform(delete("/api/canciones/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getBuclesDeUnaCancionDevuelveSusDosBucles() throws Exception {
        this.mockMvc.perform(get("/api/canciones/" + this.cancionConDosBucles.getId() + "/bucles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void getBuclesDeUnaCancionDevuelveCuatrocientosCuatroSiNoExiste() throws Exception {
        this.mockMvc.perform(get("/api/canciones/999999/bucles"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getResumenSinFiltroDevuelveLasTresOrdenadasPorCantidadDescYTituloAsc() throws Exception {
        this.mockMvc.perform(get("/api/canciones/resumen"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)))
                .andExpect(jsonPath("$[0].titulo").value("Cosquillas"))
                .andExpect(jsonPath("$[0].cantidadBucles").value(4))
                .andExpect(jsonPath("$[0].duracionMediaBuclesSegundos").value(5.0))
                .andExpect(jsonPath("$[1].titulo").value("Ansioso"))
                .andExpect(jsonPath("$[1].cantidadBucles").value(2))
                .andExpect(jsonPath("$[1].duracionMediaBuclesSegundos").value(15.0))
                .andExpect(jsonPath("$[2].titulo").value("Vamos"))
                .andExpect(jsonPath("$[2].cantidadBucles").value(0))
                .andExpect(jsonPath("$[2].duracionMediaBuclesSegundos").value(0.0));
    }

    @Test
    void getResumenConMinBuclesIgualADosDevuelveSoloLasDosConBucles() throws Exception {
        this.mockMvc.perform(get("/api/canciones/resumen").param("minBucles", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].titulo").value("Cosquillas"))
                .andExpect(jsonPath("$[1].titulo").value("Ansioso"));
    }

    @Test
    void getConMasBuclesQueMediaDevuelveSoloLaCancionConCuatroBucles() throws Exception {
        this.mockMvc.perform(get("/api/canciones/con-mas-bucles-que-media"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].titulo").value("Cosquillas"))
                .andExpect(jsonPath("$[0].cantidadBucles").value(4));
    }

}
