package com.loopmaster.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.loopmaster.backend.dto.CarpetaDTO;
import com.loopmaster.backend.model.Cancion;
import com.loopmaster.backend.model.Carpeta;
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
class CarpetaControllerTests {

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

    private Carpeta carpetaConCanciones;
    private Carpeta carpetaVacia;
    private Cancion cancionAsociada;
    private Cancion cancionLibre;

    @BeforeEach
    void prepararDatos() {
        this.carpetaDAO.deleteAll();
        this.bucleDAO.deleteAll();
        this.cancionDAO.deleteAll();

        this.cancionAsociada = guardarCancion("Ansioso", "Andres Calamaro", 240);
        Cancion otraAsociada = guardarCancion("Cosquillas", "Andres Calamaro", 260);
        this.cancionLibre = guardarCancion("Sin Documentos", "Los Rodriguez", 220);

        Carpeta carpetaA = new Carpeta();
        carpetaA.setNombre("Favoritas");
        carpetaA.setDescripcion("Las que ensayo en directo");
        carpetaA.addCancion(this.cancionAsociada);
        carpetaA.addCancion(otraAsociada);
        this.carpetaConCanciones = this.carpetaDAO.save(carpetaA);

        Carpeta carpetaB = new Carpeta();
        carpetaB.setNombre("Por ensayar");
        carpetaB.setDescripcion("Pendientes");
        this.carpetaVacia = this.carpetaDAO.save(carpetaB);
    }

    private Cancion guardarCancion(String titulo, String artista, int duracion) {
        Cancion c = new Cancion();
        c.setTitulo(titulo);
        c.setArtista(artista);
        c.setDuracionSegundos(duracion);
        c.setNombreArchivo(titulo.toLowerCase().replace(' ', '-') + ".mp3");
        return this.cancionDAO.save(c);
    }

    @Test
    void getCarpetasDevuelveLasDosSembradas() throws Exception {
        this.mockMvc.perform(get("/api/carpetas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void getCarpetaByIdDevuelveDoscientosCuandoExiste() throws Exception {
        this.mockMvc.perform(get("/api/carpetas/" + this.carpetaConCanciones.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Favoritas"))
                .andExpect(jsonPath("$.cantidadCanciones").value(2));
    }

    @Test
    void getCarpetaByIdDevuelveCuatrocientosCuatroCuandoNoExiste() throws Exception {
        this.mockMvc.perform(get("/api/carpetas/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void postCreaUnaCarpetaYDevuelveDoscientosUnoConLocation() throws Exception {
        CarpetaDTO nueva = new CarpetaDTO();
        nueva.setNombre("Acustico");
        nueva.setDescripcion("Versiones tranquilas");

        this.mockMvc.perform(post("/api/carpetas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(nueva)))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", containsString("/api/carpetas/")))
                .andExpect(jsonPath("$.nombre").value("Acustico"))
                .andExpect(jsonPath("$.cantidadCanciones").value(0));
    }

    @Test
    void putActualizaUnaCarpetaExistente() throws Exception {
        CarpetaDTO datos = new CarpetaDTO();
        datos.setNombre("Favoritas 2026");
        datos.setDescripcion("Set list actualizado");

        this.mockMvc.perform(put("/api/carpetas/" + this.carpetaConCanciones.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(datos)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Favoritas 2026"))
                .andExpect(jsonPath("$.descripcion").value("Set list actualizado"));
    }

    @Test
    void putDevuelveCuatrocientosCuatroSiLaCarpetaNoExiste() throws Exception {
        CarpetaDTO datos = new CarpetaDTO();
        datos.setNombre("Fantasma");
        datos.setDescripcion("");

        this.mockMvc.perform(put("/api/carpetas/999999")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(this.objectMapper.writeValueAsString(datos)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteEliminaUnaCarpetaVaciaYDevuelveDoscientosCuatro() throws Exception {
        this.mockMvc.perform(delete("/api/carpetas/" + this.carpetaVacia.getId()))
                .andExpect(status().isNoContent());

        this.mockMvc.perform(get("/api/carpetas/" + this.carpetaVacia.getId()))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteDevuelveCuatrocientosCuatroSiLaCarpetaNoExiste() throws Exception {
        this.mockMvc.perform(delete("/api/carpetas/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getCancionesDeCarpetaDevuelveLasDosAsociadas() throws Exception {
        this.mockMvc.perform(get("/api/carpetas/" + this.carpetaConCanciones.getId() + "/canciones"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void getCancionesDeCarpetaDevuelveListaVaciaCuandoLaCarpetaNoTieneCanciones() throws Exception {
        this.mockMvc.perform(get("/api/carpetas/" + this.carpetaVacia.getId() + "/canciones"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void getCancionesDeCarpetaDevuelveCuatrocientosCuatroSiLaCarpetaNoExiste() throws Exception {
        this.mockMvc.perform(get("/api/carpetas/999999/canciones"))
                .andExpect(status().isNotFound());
    }

    @Test
    void anadirCancionAUnaCarpetaDevuelveDoscientosCuatroYActualizaLaRelacion() throws Exception {
        this.mockMvc.perform(post("/api/carpetas/" + this.carpetaConCanciones.getId() + "/canciones/" + this.cancionLibre.getId()))
                .andExpect(status().isNoContent());

        this.mockMvc.perform(get("/api/carpetas/" + this.carpetaConCanciones.getId() + "/canciones"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)));
    }

    @Test
    void anadirCancionDevuelveCuatrocientosCuatroSiLaCarpetaNoExiste() throws Exception {
        this.mockMvc.perform(post("/api/carpetas/999999/canciones/" + this.cancionLibre.getId()))
                .andExpect(status().isNotFound());
    }

    @Test
    void quitarCancionDeUnaCarpetaDevuelveDoscientosCuatroYActualizaLaRelacion() throws Exception {
        this.mockMvc.perform(delete("/api/carpetas/" + this.carpetaConCanciones.getId() + "/canciones/" + this.cancionAsociada.getId()))
                .andExpect(status().isNoContent());

        this.mockMvc.perform(get("/api/carpetas/" + this.carpetaConCanciones.getId() + "/canciones"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }

    @Test
    void quitarCancionDevuelveCuatrocientosCuatroSiLaCarpetaNoExiste() throws Exception {
        this.mockMvc.perform(delete("/api/carpetas/999999/canciones/" + this.cancionAsociada.getId()))
                .andExpect(status().isNotFound());
    }

    @Test
    void getResumenSinFiltroDevuelveLasDosOrdenadasPorCantidadDescYNombreAsc() throws Exception {
        this.mockMvc.perform(get("/api/carpetas/resumen"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].nombre").value("Favoritas"))
                .andExpect(jsonPath("$[0].cantidadCanciones").value(2))
                .andExpect(jsonPath("$[1].nombre").value("Por ensayar"))
                .andExpect(jsonPath("$[1].cantidadCanciones").value(0));
    }

    @Test
    void getResumenConMinCancionesIgualAUnoDevuelveSoloLaCarpetaConCanciones() throws Exception {
        this.mockMvc.perform(get("/api/carpetas/resumen").param("minCanciones", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].nombre").value("Favoritas"))
                .andExpect(jsonPath("$[0].cantidadCanciones").value(2));
    }

}
