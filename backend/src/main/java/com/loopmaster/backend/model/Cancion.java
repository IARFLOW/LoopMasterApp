package com.loopmaster.backend.model;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "cancion")
public class Cancion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "titulo", nullable = false, length = 200)
    private String titulo;

    @Column(name = "artista", length = 200)
    private String artista;

    @Column(name = "duracion_segundos", nullable = false)
    private int duracionSegundos;

    @Column(name = "nombre_archivo", length = 255)
    private String nombreArchivo;

    @OneToMany(mappedBy = "cancion", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Bucle> bucles = new ArrayList<>();

    @ManyToMany(mappedBy = "canciones")
    private Set<Carpeta> carpetas = new HashSet<>();

    public Cancion() {
        this.bucles = new ArrayList<>();
        this.carpetas = new HashSet<>();
    }

    public Cancion(int id, String titulo, String artista, int duracionSegundos) {
        this.id = id;
        this.titulo = titulo;
        this.artista = artista;
        this.duracionSegundos = duracionSegundos;
        this.bucles = new ArrayList<>();
        this.carpetas = new HashSet<>();
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getArtista() {
        return artista;
    }

    public void setArtista(String artista) {
        this.artista = artista;
    }

    public int getDuracionSegundos() {
        return duracionSegundos;
    }

    public void setDuracionSegundos(int duracionSegundos) {
        this.duracionSegundos = duracionSegundos;
    }

    public String getNombreArchivo() {
        return nombreArchivo;
    }

    public void setNombreArchivo(String nombreArchivo) {
        this.nombreArchivo = nombreArchivo;
    }

    public List<Bucle> getBucles() {
        return bucles;
    }

    public void setBucles(List<Bucle> bucles) {
        this.bucles = bucles;
    }

    public Set<Carpeta> getCarpetas() {
        return carpetas;
    }

    public void setCarpetas(Set<Carpeta> carpetas) {
        this.carpetas = carpetas;
    }

    @Override
    public String toString() {
        return "Cancion{" +
                "id=" + id +
                ", titulo='" + titulo + '\'' +
                ", artista='" + artista + '\'' +
                ", duracionSegundos=" + duracionSegundos +
                ", nombreArchivo='" + nombreArchivo + '\'' +
                '}';
    }
}
