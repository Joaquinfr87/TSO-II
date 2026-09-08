# Docker en un servidor Debian

Este documento cubre la teoría detrás de Docker: qué resuelve, cómo funciona por dentro, y cómo lo usamos en este proyecto para desplegar servicios de forma colaborativa. Para los pasos de instalación, ver la guía [Instalación de Docker](../guides/instalacion-docker.md). Para entender cómo lo usamos en el equipo y el flujo de trabajo, ver [Uso colaborativo de Docker en el equipo](../../teams/flujo-docker.md).

## ¿Qué es Docker y qué problema resuelve?

Docker es una plataforma de **contenedores**: permite empaquetar una aplicación con todas sus dependencias (librerías, configuración, runtime) en una unidad reproducible llamada **imagen**, y ejecutarla de forma aislada en el host.

El problema que resuelve es el clásico de "en mi máquina funciona". Con Docker, la imagen que se construye en un entorno es exactamente la misma que se ejecuta en otro, sin importar qué distribución, versión de librerías o configuración tenga el host. Esto es ideal para nuestro caso, donde cada integrante del equipo trabaja en su propia máquina y luego replica el resultado.

## Contenedores vs máquinas virtuales

Es común confundir los dos conceptos. Aunque ambos aíslan aplicaciones, la diferencia es profunda:

| Aspecto | Máquina virtual | Contenedor Docker |
|---|---|---|
| **Aislamiento** | Hardware virtualizado (CPU, RAM, disco virtuales) | Aislamiento a nivel de procesos y espacio de nombres |
| **SO propio** | Cada VM lleva un sistema operativo completo (kernel incluido) | Comparte el kernel del host |
| **Peso** | Gigabytes | Megabytes |
| **Arranque** | Minutos | Segundos |
| **Recursos** | Reserva fija de RAM/CPU | Comparte y usa solo lo que necesita |

La clave está en que un contenedor **comparte el kernel del host**. No tiene sistema operativo propio: solo lleva la aplicación y sus dependencias. Por eso es mucho más liviano y arranca casi al instante.

### ¿Por qué no se pueden correr contenedores Windows en un host Linux?

El kernel es lo que hace de puente entre el software y el hardware. Como un contenedor comparte el kernel del host, una imagen construida para ejecutarse sobre el kernel Windows **no puede** ejecutarse en un host cuyo kernel es Linux, ni tampoco al revés. Esto es relevante para nuestro proyecto porque varios de los servicios pedidos (IIS, controlador de dominio, Exchange) son tecnologías de Microsoft pensadas para ejecutarse sobre el kernel Windows, por lo que **no pueden desplegarse como contenedor Docker en una máquina Debian**.

## Imágenes y contenedores: la relación principal

- **Imagen**: un paquete inmutable y de solo lectura con todo lo necesario para ejecutar una aplicación. Es como un "archivo de instalación" o la definición de qué correr. Se construye a partir de un `Dockerfile` y se identifica con un nombre y etiqueta (`nginx:1.27`, `postgres:16`).
- **Contenedor**: una instancia en ejecución de una imagen. Cada vez que se lanza una imagen se crea un contenedor, con su propia capa de escritura, red y espacio de nombres. Una misma imagen puede lanzar muchos contenedores a la vez.

> La analogía: la imagen es la **clase** o el **molde**; el contenedor es la **instancia** concreta en ejecución.

## El rol del Docker daemon y el comando docker

- **Docker daemon** (`dockerd`): servicio del sistema que gestiona imágenes, contenedores, redes y volúmenes. Es el motor que hace el trabajo real.
- **Cliente** (comando `docker`): la herramienta de línea de comandos que envía instrucciones al daemon (`docker build`, `docker run`, `docker compose`, etc.).

En Debian, el daemon se gestiona como un servicio de systemd (`docker.service`) y, por seguridad, solo puede hablar con él un usuario del grupo `docker`.

## Docker Compose

Docker Compose define y ejecuta **múltiples contenedores** que forman un sistema completo, describiéndolos en un archivo YAML (`docker-compose.yml`). En lugar de ejecutar un `docker run` interminable por cada servicio, se declara todo en un archivo versionable y se levanta todo con un solo comando.

```yaml
services:
  web:
    image: nginx:1.27
    ports:
      - "80:80"
  db:
    image: postgres:16
    volumes:
      - dbdata:/var/lib/postgresql/data

volumes:
  dbdata:
```

`docker compose up -d` levanta todos los servicios declarados. Este archivo es el corazón del proyecto: todos los servicios del equipo se declaran en un solo `docker-compose.yml` en la raíz del repositorio.

## Componentes clave de Docker

### Dockerfile

Archivo de texto que define **cómo se construye** una imagen. Indica la imagen base y los pasos para preparar la aplicación.

```dockerfile
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y nginx
COPY ./html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Volúmenes

Los contenedores son efímeros: si se borran, se pierde la capa de escritura. Para que los **datos persistan** (bases de datos, archivos subidos, configuraciones), se usan volúmenes, que viven en el host fuera del ciclo de vida del contenedor.

- **Volúmenes con nombre** (`docker volume create`): gestionados por Docker, aptos para datos que no querés editar a mano (bases de datos).
- **Bind mounts** (`-v /ruta/host:/ruta/contenedor`): apuntan a una carpeta real del host. Ideales para código y configuración que se quiere editar directamente.

### Redes

Por defecto, cada contenedor está aislado. Docker ofrece redes para conectar contenedores entre sí:

- **bridge** (por defecto): los contenedores de un mismo `compose` se comunican entre sí por su nombre de servicio.
- Las **puertas** se exponen al host mediante `ports` (`"8080:80"` mapea el puerto 8080 del host al 80 del contenedor).

### Registries (registros)

Los registros son repositorios donde se almacenan y distribuyen imágenes. **Docker Hub** es el público más conocido. Docker Compose descarga imágenes desde registros con `image: nombre`. También se pueden construir imágenes locales con `build:` y publicarlas en un registro para que los demás integrantes las compartan.

## El flujo en este proyecto

Nuestro objetivo es que cada integrante del equipo trabaje en su máquina local y publique sus avances, y que luego sea trivial replicar el servidor completo. El flujo propuesto:

1. El `docker-compose.yml` en la raíz del repo declara **todos** los servicios.
2. Cada integrante es responsable de su subcarpeta bajo `services/<nombre-servicio>/` con su `Dockerfile` y configuraciones, y agrega su servicio al `docker-compose.yml` raíz.
3. Cada uno levanta el compose completo (o solo sus servicios) en su máquina para probar.
4. El código y los archivos se comparten por git; el que tenga la máquina física replica el estado completo con `docker compose up -d`.

## Referencias

- `man docker`, `man docker-compose` — documentación local.
- [Docker docs](https://docs.docker.com)
- [Documentación de Docker Compose](https://docs.docker.com/compose/)
- [Instalación de Docker en Debian](https://docs.docker.com/engine/install/debian/)
