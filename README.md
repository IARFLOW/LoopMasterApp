# LoopMaster

Aplicación para músicos que permite reproducir canciones con control independiente de velocidad (tempo) y tono (pitch), visualizar la forma de onda del audio y crear bucles A-B sobre secciones concretas para facilitar la práctica musical.

Proyecto del Grado Superior en Desarrollo de Aplicaciones Multiplataforma (DAM), IES Fernando Wirtz Suárez, A Coruña. Curso 2025–2026.

---

## Estado del proyecto

**Entrega inicial.** Fase temprana de desarrollo. Ya son funcionales:

- Cliente iOS: reproductor de audio con control independiente de **tempo (25–175 %)** y **tono (±12 semitonos)** usando `AVAudioEngine` + `AVAudioUnitTimePitch`. Play / pausa / stop. Audio de muestra incluido en el bundle.
- Backend: API REST completa para la entidad `Cancion` (`GET`, `POST`, `PUT`, `DELETE`). Entidades `Carpeta` (N:M con `Cancion`) y `Bucle` (1:N desde `Cancion`) modeladas en JPA, listas para recibir endpoints propios en siguientes iteraciones.

Lo pendiente está descrito en la sección *Roadmap* al final.

---

## Estructura del repositorio

```
LoopMasterApp/
├── ios/              Proyecto Xcode del cliente iOS (Swift 6 + SwiftUI)
│   └── LoopMaster/
│       ├── LoopMaster.xcodeproj
│       └── LoopMaster/           Código fuente de la app
├── backend/          Proyecto Spring Boot del servidor (Java 21 + MySQL)
├── docs/             Memoria del proyecto (Markdown + PDF) y documentación
└── Informacion/      Material de partida del proyecto (idea inicial, referencias)
```

---

## Requisitos

### Generales

- **macOS** 14 o superior (recomendado 26).
- **Git** 2.40+.

### Cliente iOS

- **Xcode** 26 o superior.
- **Swift** 6.
- **iOS** 26 o superior — deployment target del proyecto, aprovecha las últimas APIs de SwiftUI, SwiftData y AVFoundation.

### Backend

- **Java JDK** 21 o superior.
- **Maven Wrapper** (`./mvnw`, incluido en el repositorio — no hace falta Maven global).
- **MySQL** 8 o superior (testeado con 9.1).

### Herramientas de prueba

- **curl** (incluido en macOS).
- **Postman** o **Insomnia** (opcional, para probar la API REST gráficamente).

---

## Despliegue paso a paso

### 1. Clonar el repositorio

```bash
git clone https://github.com/IARFLOW/LoopMasterApp.git
cd LoopMasterApp
```

### 2. Arrancar MySQL (si aún no está corriendo)

#### 2.1 Si MySQL está instalado desde el instalador oficial

Panel de Preferencias del sistema → **MySQL** → pulsar **Start MySQL Server**.

O desde terminal (requiere contraseña de administrador):

```bash
sudo /usr/local/mysql/support-files/mysql.server start
```

#### 2.2 Si MySQL está instalado con Homebrew

```bash
brew services start mysql
```

#### 2.3 Verificar que el servidor responde

```bash
mysql -u root -p -e "SELECT VERSION();"
```

### 3. Crear la base de datos y el usuario

Desde la raíz del repositorio:

```bash
mysql -u root -p < backend/init-db.sql
```

El script `backend/init-db.sql` crea la base de datos `loopmaster`, el usuario `loopmaster` con contraseña `loopmaster` y le concede los permisos necesarios. Si tu instalación de MySQL usa otras credenciales para `root`, ajusta el comando.

Contenido equivalente en SQL:

```sql
CREATE DATABASE IF NOT EXISTS loopmaster CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'loopmaster'@'localhost' IDENTIFIED BY 'loopmaster';
GRANT ALL PRIVILEGES ON loopmaster.* TO 'loopmaster'@'localhost';
FLUSH PRIVILEGES;
```

### 4. Arrancar el backend Spring Boot

```bash
cd backend
./mvnw spring-boot:run
```

El servidor arrancará en `http://localhost:8080`. Hibernate creará automáticamente las tablas (`canciones`, `carpetas`, `bucles`, `carpeta_cancion`) en el primer arranque gracias a `spring.jpa.hibernate.ddl-auto=update`.

Si necesitas cambiar puerto, credenciales o URL de la base de datos, edita `backend/src/main/resources/application.properties`.

### 5. Probar la API con curl

Listar canciones (inicialmente vacío):

```bash
curl http://localhost:8080/api/canciones
```

Crear una canción:

```bash
curl -X POST http://localhost:8080/api/canciones \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Tema de prueba","artista":"Demo","duracionSegundos":180}'
```

Obtener una canción por id:

```bash
curl http://localhost:8080/api/canciones/1
```

Actualizar una canción:

```bash
curl -X PUT http://localhost:8080/api/canciones/1 \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Tema actualizado","artista":"Demo","duracionSegundos":200}'
```

Eliminar una canción:

```bash
curl -X DELETE http://localhost:8080/api/canciones/1
```

### 6. Arrancar el cliente iOS

```bash
cd ios/LoopMaster
open LoopMaster.xcodeproj
```

En Xcode:

1. En la barra superior, selecciona un simulador con **iOS 26** (por ejemplo *iPhone 17 Pro*) o tu iPhone físico conectado.
2. Pulsa el botón de Play (▶) o usa `Cmd + R`.
3. La app arranca y muestra la vista del reproductor.

#### Qué puedes probar

- Pulsa el botón grande de **Play** ▶ para iniciar la reproducción del audio de muestra (*Ansioso M*, Ramiro Barrios — En vivo en Assejazz Sevilla, grabación propia incluida con permiso del autor).
- Mueve el slider de **Tempo** hacia la izquierda (25 %) y verás que el audio suena mucho más lento **sin cambiar el tono**. Hacia la derecha (175 %) suena bastante más rápido, igualmente sin cambiar el tono.
- Mueve el slider de **Tono** hacia abajo (−12 semitonos) y el audio sonará una octava más grave **sin cambiar la velocidad**. Hacia arriba (+12) suena una octava más agudo.
- El botón de **Stop** detiene y rebobina al principio.

---

## Roadmap

Esta entrega inicial cubre los requisitos mínimos exigidos para la primera entrega. Las siguientes iteraciones incorporarán:

- Carga de canciones propias desde el almacenamiento del dispositivo (selector de archivos).
- Visualización de la **forma de onda** del audio.
- Sistema completo de **bucles A-B** persistidos, con punto A y B seleccionables visualmente sobre la onda.
- **Organización por carpetas**: CRUD de carpetas y asignación N:M con canciones.
- **Sincronización** bidireccional iOS ↔ backend.
- Endpoints REST para `Carpeta` y `Bucle`.
- Consultas complejas en el backend (`JOIN`, `GROUP BY`, `HAVING`).
- Tests automáticos en ambas capas.

---

## Autor

Ignacio Ampurdanés Ruz — 2º DAM, IES Fernando Wirtz Suárez, A Coruña. Curso 2025–2026.\
Tutor: Noé Vila Muñoz.
