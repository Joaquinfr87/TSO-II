# Uso colaborativo de Docker en el equipo: flujo de trabajo con Docker Compose

## Objetivo

Definir cómo el equipo de la materia (Joaquín, Nicolás y David) trabaja de forma colaborativa con Docker: la estructura del repositorio, cómo levantar el entorno en cada máquina y cómo replicar el servidor en la máquina física. La base conceptual está en [Docker en un servidor Debian](../theory/docker.md).

## Por qué Docker para un trabajo colaborativo

En esta materia hay que instalar varios servicios en una **única máquina Debian** que no siempre está disponible para todos los integrantes. Docker resuelve esto:

- Cada integrante trabaja en **su propia máquina**, descargando la misma definición de servicios desde el repositorio.
- Los resultados se comparten como **archivos versionados** (Dockerfiles y el `docker-compose.yml`).
- Cuando un integrante termina su tarea, el resto replica su trabajo en la máquina física con un solo comando: `docker compose up -d`.
- No hace falta que todos estén simultáneamente frente a la máquina.

## Estructura del repositorio

```text
TSO-II/
├── docker-compose.yml        ← declara TODOS los servicios del proyecto
├── README.md
├── docs/                     ← teoría y guías prácticas
├── services/                 ← Dockerfiles y config por servicio
│   ├── <servicio-a>/
│   │   ├── Dockerfile
│   │   ├── config/ ...
│   │   └── README.md
│   └── <servicio-b>/ ...
└── teams/                    ← documentación del equipo y repartición
```

- **`docker-compose.yml` en la raíz**: es el único punto de entrada. Levanta el sistema completo. Cada servicio del proyecto se declara aquí.
- **`services/<nombre>/`**: la definición de cada servicio individual. Aquí vive el `Dockerfile`, sus archivos de configuración y un `README.md` con las particularidades de ese servicio.
- **`teams/`**: la documentación del equipo: repartición de tareas, estado y acuerdos.

## Reglas de trabajo

1. **Un solo `docker-compose.yml` en la raíz.** Todos los servicios se agregan ahí. No creamos composes locales por integrante: el raíz es la fuente de verdad.
2. **Cada integrante edita su servicio** dentro de `services/<su-servicio>/` y agrega/actualiza su bloque en el `docker-compose.yml` raíz.
3. **No subir secretos**: las contraseñas y claves de los servicios se cargan por variables de entorno o archivos `.env` excluidos (gitignored), nunca literales en el compose.
4. **Compromisos claros por servicio**: antes de subir un cambio al repo, el responsable prueba que su servicio arranca con `docker compose up`.
5. **Los puertos no se pisan**: cada servicio usa puertos distintos en el host; están mapeados en el compose raíz.

## Flujo de trabajo día a día

### 1. Clonar y la primera vez

Cada integrante clona el repositorio en su máquina:

```bash
git clone <url-del-repo>
cd TSO-II
```

### 2. Copiar el archivo de entorno

Si existe un `.env.example`, copiar a `.env` y completar los valores locales (IPs, contraseñas):

```bash
cp .env.example .env
```

> `.env` está en `.gitignore`; no se comparte. Cada máquina tiene los suyos.

### 3. Levantar todos los servicios (o solo los propios)

Levantar el sistema completo:

```bash
docker compose up -d --build
```

Si solo se quiere trabajar un servicio, se puede levantar uno solo:

```bash
docker compose up -d <nombre-servicio>
```

### 4. Trabajar en el propio servicio

- Editar el `Dockerfile` o los archivos dentro de `services/<su-servicio>/`.
- Reconstruir y reiniciar solo ese servicio:

```bash
docker compose up -d --build <nombre-servicio>
```

- Ver los logs en vivo:

```bash
docker compose logs -f <nombre-servicio>
```

### 5. Compartir el resultado

Cuando el servicio funciona en la máquina local:

```bash
git add services/<su-servicio>/ docker-compose.yml
git commit -m "Servicio <nombre>: descripción del cambio"
git push
```

### 6. Replicar en la máquina del servidor

Cuando un integrante tiene acceso a la máquina física (o el que la administra), replica el estado del repositorio:

```bash
git pull
docker compose up -d --build
```

Esto descarga imágenes, las reconstruye si cambió el `Dockerfile` y levanta o actualiza todos los servicios. El servidor queda idéntico a lo que se probó en otras máquinas.

### 7. Detener y limpiar

```bash
docker compose down          # detiene y elimina los contenedores (sin borrar volúmenes)
docker compose down -v       # además borra los volúmenes con nombre (¡cuidado! elimina datos)
```

## Comandos útiles del flujo

| Comando | Qué hace |
|---|---|
| `docker compose up -d` | Crea y arranca los servicios en segundo plano |
| `docker compose up -d --build` | Igual, pero reconstruyendo las imágenes antes |
| `docker compose ps` | Estado de los servicios |
| `docker compose logs -f <servicio>` | Logs en vivo de un servicio |
| `docker compose restart <servicio>` | Reinicia un servicio |
| `docker compose down` | Detiene y elimina los contenedores |
| `docker compose config` | Valida y muestra la configuración resuelta del compose |
| `docker build -t <nombre> services/<servicio>/` | Construye una imagen individual |

## Cómo asegurar que el resultado es reproducible

- **Pin de imágenes**: las imágenes base usan versión fija (`postgres:16`, no `latest`).
- **Un solo compose**: levantar el sistema entero siempre reproduce el mismo conjunto de servicios.
- **Volúmenes con nombre**: los datos (bases de datos, archivos) quedan guardados aunque se baje el entorno. La configuración, en cambio, vive en el repo.
- **`.env` reproducible**: el `.env.example` documenta qué variables se necesitan, sin secretos reales.

## Referencias

- Teoría: [Docker en un servidor Debian](../theory/docker.md)
- Instalación: [Instalación de Docker en Debian](./instalacion-docker.md)
- Repartición de tareas del equipo: [Equipo de trabajo](../../teams/index.md)