package com.loopmaster.backend.dto;

public class CancionDTO {

    private int id;
    private String titulo;
    private String artista;
    private int duracionSegundos;
    private String nombreArchivo;

    public CancionDTO() {
    }

    public CancionDTO(int id, String titulo, String artista, int duracionSegundos, String nombreArchivo) {
        this.id = id;
        this.titulo = titulo;
        this.artista = artista;
        this.duracionSegundos = duracionSegundos;
        this.nombreArchivo = nombreArchivo;
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

    @Override
    public String toString() {
        return "CancionDTO{" +
                "id=" + id +
                ", titulo='" + titulo + '\'' +
                ", artista='" + artista + '\'' +
                ", duracionSegundos=" + duracionSegundos +
                ", nombreArchivo='" + nombreArchivo + '\'' +
                '}';
    }
}
