package com.loopmaster.backend.dto;

public class BucleDTO {

    private int id;
    private String nombre;
    private int puntoASegundos;
    private int puntoBSegundos;
    private int velocidad;
    private int tonoSemitonos;
    private int cancionId;

    public BucleDTO() {
    }

    public BucleDTO(int id, String nombre, int puntoASegundos, int puntoBSegundos, int velocidad, int tonoSemitonos, int cancionId) {
        this.id = id;
        this.nombre = nombre;
        this.puntoASegundos = puntoASegundos;
        this.puntoBSegundos = puntoBSegundos;
        this.velocidad = velocidad;
        this.tonoSemitonos = tonoSemitonos;
        this.cancionId = cancionId;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public int getPuntoASegundos() {
        return puntoASegundos;
    }

    public void setPuntoASegundos(int puntoASegundos) {
        this.puntoASegundos = puntoASegundos;
    }

    public int getPuntoBSegundos() {
        return puntoBSegundos;
    }

    public void setPuntoBSegundos(int puntoBSegundos) {
        this.puntoBSegundos = puntoBSegundos;
    }

    public int getVelocidad() {
        return velocidad;
    }

    public void setVelocidad(int velocidad) {
        this.velocidad = velocidad;
    }

    public int getTonoSemitonos() {
        return tonoSemitonos;
    }

    public void setTonoSemitonos(int tonoSemitonos) {
        this.tonoSemitonos = tonoSemitonos;
    }

    public int getCancionId() {
        return cancionId;
    }

    public void setCancionId(int cancionId) {
        this.cancionId = cancionId;
    }

    @Override
    public String toString() {
        return "BucleDTO{" +
                "id=" + id +
                ", nombre='" + nombre + '\'' +
                ", puntoASegundos=" + puntoASegundos +
                ", puntoBSegundos=" + puntoBSegundos +
                ", velocidad=" + velocidad +
                ", tonoSemitonos=" + tonoSemitonos +
                ", cancionId=" + cancionId +
                '}';
    }
}
