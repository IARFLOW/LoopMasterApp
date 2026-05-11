package com.loopmaster.backend.dto;

public class CancionResumenDTO {

    private int id;
    private String titulo;
    private String artista;
    private int cantidadBucles;
    private double duracionMediaBuclesSegundos;

    public CancionResumenDTO() {
    }
    public CancionResumenDTO(int id, String titulo, String artista, int cantidadBucles, double duracionMediaBuclesSegundos) {
        this.id = id;
        this.titulo = titulo;
        this.artista = artista;
        this.cantidadBucles = cantidadBucles;
        this.duracionMediaBuclesSegundos = duracionMediaBuclesSegundos;
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
    public int getCantidadBucles() {
        return cantidadBucles;
    }
    public void setCantidadBucles(int cantidadBucles) {
        this.cantidadBucles = cantidadBucles;
    }
    public double getDuracionMediaBuclesSegundos() {
        return duracionMediaBuclesSegundos;
    }
    public void setDuracionMediaBuclesSegundos(double duracionMediaBuclesSegundos) {
        this.duracionMediaBuclesSegundos = duracionMediaBuclesSegundos;
    }

    @Override
    public String toString() {
        return "CancionResumenDTO{" +
                "id=" + id +
                ", titulo='" + titulo + '\'' +
                ", artista='" + artista + '\'' +
                ", cantidadBucles=" + cantidadBucles +
                ", duracionMediaBuclesSegundos=" + duracionMediaBuclesSegundos +
                '}';
    }
}
