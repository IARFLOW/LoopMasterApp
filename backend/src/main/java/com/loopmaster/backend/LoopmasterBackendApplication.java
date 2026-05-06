package com.loopmaster.backend;

import com.loopmaster.backend.model.Bucle;
import com.loopmaster.backend.model.Cancion;
import com.loopmaster.backend.model.Carpeta;
import com.loopmaster.backend.repository.BucleDAO;
import com.loopmaster.backend.repository.CancionDAO;
import com.loopmaster.backend.repository.CarpetaDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class LoopmasterBackendApplication implements CommandLineRunner {

	@Autowired
	private CancionDAO cancionDAO;

	@Autowired
	private CarpetaDAO carpetaDAO;

	@Autowired
	private BucleDAO bucleDAO;

	public static void main(String[] args) {
		SpringApplication.run(LoopmasterBackendApplication.class, args);
	}

	@Override
	public void run(String... args) {
		if (this.cancionDAO.count() > 0) {
			System.out.println("[LoopMaster] Ya hay datos en la BD. Saltando carga inicial.");
			return;
		}

		System.out.println("[LoopMaster] BD vacía. Insertando datos de prueba...");

		Cancion ansioso = new Cancion();
		ansioso.setTitulo("Ansioso");
		ansioso.setArtista("Ignacio Ampurdanés");
		ansioso.setDuracionSegundos(180);
		ansioso.setNombreArchivo("Ansioso.m4a");
		this.cancionDAO.save(ansioso);

		Cancion estudio = new Cancion();
		estudio.setTitulo("Estudio de batería");
		estudio.setArtista("Ignacio Ampurdanés");
		estudio.setDuracionSegundos(240);
		estudio.setNombreArchivo("estudio.mp3");
		this.cancionDAO.save(estudio);

		Carpeta favoritas = new Carpeta();
		favoritas.setNombre("Favoritas");
		favoritas.setDescripcion("Mis canciones más usadas para ensayar");
		favoritas.addCancion(ansioso);
		favoritas.addCancion(estudio);
		this.carpetaDAO.save(favoritas);

		Carpeta calentamiento = new Carpeta();
		calentamiento.setNombre("Calentamiento");
		calentamiento.setDescripcion("Pistas para calentar antes de tocar");
		calentamiento.addCancion(estudio);
		this.carpetaDAO.save(calentamiento);

		Bucle estribillo = new Bucle();
		estribillo.setNombre("Estribillo");
		estribillo.setPuntoASegundos(45.3);
		estribillo.setPuntoBSegundos(75.8);
		estribillo.setVelocidad(80);
		estribillo.setTonoSemitonos(0);
		estribillo.setCancion(ansioso);
		this.bucleDAO.save(estribillo);

		Bucle solo = new Bucle();
		solo.setNombre("Solo de batería");
		solo.setPuntoASegundos(120.5);
		solo.setPuntoBSegundos(150.2);
		solo.setVelocidad(100);
		solo.setTonoSemitonos(0);
		solo.setCancion(ansioso);
		this.bucleDAO.save(solo);

		System.out.println("[LoopMaster] Datos de prueba cargados:");
		System.out.println("  - Canciones: " + this.cancionDAO.count());
		System.out.println("  - Carpetas:  " + this.carpetaDAO.count());
		System.out.println("  - Bucles:    " + this.bucleDAO.count());
	}

}
