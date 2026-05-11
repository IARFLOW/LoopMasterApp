package com.loopmaster.backend.dto;

public class CarpetaResumenDTO {

    private int id;
    private String nombre;
    private int cantidadCanciones;

    public CarpetaResumenDTO() {
    }
    public CarpetaResumenDTO(int id, String nombre, int cantidadCanciones) {
        this.id = id;
        this.nombre = nombre;
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
    public int getCantidadCanciones() {
        return cantidadCanciones;
    }
    public void setCantidadCanciones(int cantidadCanciones) {
        this.cantidadCanciones = cantidadCanciones;
    }

    @Override
    public String toString() {
        return "CarpetaResumenDTO{" +
                "id=" + id +
                ", nombre='" + nombre + '\'' +
                ", cantidadCanciones=" + cantidadCanciones +
                '}';
    }
}
