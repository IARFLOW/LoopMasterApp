package com.loopmaster.backend.dto;

public class CarpetaDTO {

    private int id;
    private String nombre;
    private String descripcion;
    private int cantidadCanciones;

    public CarpetaDTO() {
    }

    public CarpetaDTO(int id, String nombre, String descripcion, int cantidadCanciones) {
        this.id = id;
        this.nombre = nombre;
        this.descripcion = descripcion;
        this.cantidadCanciones = cantidadCanciones;
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

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public int getCantidadCanciones() {
        return cantidadCanciones;
    }

    public void setCantidadCanciones(int cantidadCanciones) {
        this.cantidadCanciones = cantidadCanciones;
    }

    @Override
    public String toString() {
        return "CarpetaDTO{" +
                "id=" + id +
                ", nombre='" + nombre + '\'' +
                ", descripcion='" + descripcion + '\'' +
                ", cantidadCanciones=" + cantidadCanciones +
                '}';
    }
}
