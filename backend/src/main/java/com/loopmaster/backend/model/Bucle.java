package com.loopmaster.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "bucle")
public class Bucle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "punto_a_segundos", nullable = false)
    private int puntoASegundos;

    @Column(name = "punto_b_segundos", nullable = false)
    private int puntoBSegundos;

    @Column(name = "velocidad", nullable = false)
    private int velocidad;

    @Column(name = "tono_semitonos", nullable = false)
    private int tonoSemitonos;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "cancion_id")
    private Cancion cancion;

    public Bucle() {
        this.velocidad = 100;
        this.tonoSemitonos = 0;
    }

    public Bucle(int id, String nombre, int puntoASegundos, int puntoBSegundos, Cancion cancion) {
        this.id = id;
        this.nombre = nombre;
        this.puntoASegundos = puntoASegundos;
        this.puntoBSegundos = puntoBSegundos;
        this.velocidad = 100;
        this.tonoSemitonos = 0;
        this.cancion = cancion;
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

    public Cancion getCancion() {
        return cancion;
    }

    public void setCancion(Cancion cancion) {
        this.cancion = cancion;
    }

    @Override
    public String toString() {
        return "Bucle{" +
                "id=" + id +
                ", nombre='" + nombre + '\'' +
                ", puntoASegundos=" + puntoASegundos +
                ", puntoBSegundos=" + puntoBSegundos +
                ", velocidad=" + velocidad +
                ", tonoSemitonos=" + tonoSemitonos +
                '}';
    }
}
