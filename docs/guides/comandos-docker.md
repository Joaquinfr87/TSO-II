# Comandos esenciales de Docker

Guía de referencia rápida de los comandos de Docker y Docker Compose que usamos en el proyecto. No cubre la teoría (ver [Docker en un servidor Debian](../theory/docker.md)) ni la instalación (ver [Instalación de Docker](./instalacion-docker.md)).

## Objetivo

Tener a mano los comandos más usados para construir imágenes, manejar contenedores, volúmenes, redes y levantar servicios con Docker Compose.

## Requisitos previos

- Docker instalado (ver guía de instalación).
- El usuario debe pertenecer al grupo `docker` para no usar `sudo`.

## 1. Información del entorno

| Comando | Qué hace |
|---|---|
| `docker version` | Versión del cliente y del daemon |
| `docker info` | Estado del daemon, recursos, contadores |
| `docker system df` | Uso de disco (imágenes, contenedores, volúmenes) |
| `docker system prune` | Elimina todo lo que no está en uso (¡con cuidado!) |

## 2. Imágenes

Una imagen es un paquete inmutable con la aplicación y sus dependencias.

| Comando | Qué hace |
|---|---|
| `docker build -t nombre:etiqueta .` | Construye una imagen desde el `Dockerfile` del directorio |
| `docker pull nombre:etiqueta` | Descarga una imagen de un registro (ej. Docker Hub) |
| `docker images` | Lista las imágenes locales |
| `docker rmi nombre:etiqueta` | Elimina una imagen |
| `docker tag img repo/name:tag` | Renombra o etiqueta una imagen (`docker tag web tso/web:1.0`) |
| `docker push nombre:etiqueta` | Sube una imagen a un registro |

> En este proyecto casi siempre **construimos** (`docker compose build`) en vez de usar imágenes predefinidas, porque cada servicio tiene su propio `Dockerfile`.

## 3. Contenedores

Un contenedor es una instancia en ejecución de una imagen.

| Comando | Qué hace |
|---|---|
| `docker ps` | Lista los contenedores **en ejecución** |
| `docker ps -a` | Lista todos (incluso detenidos) |
| `docker run -d --name nombre -p 8080:80 imagen` | Crea y arranca un contenedor en segundo plano (`-d` = detach) |
| `docker run -it imagen bash` | Arranca e ingresa en modo interactivo |
| `docker start nombre` | Arranca un contenedor ya creado |
| `docker stop nombre` | Detiene un contenedor (apagado limpio) |
| `docker restart nombre` | Reinicia un contenedor |
| `docker rm nombre` | Elimina un contenedor (debe estar detenido) |
| `docker exec -it nombre bash` | Abre una shell dentro de un contenedor en ejecución |
| `docker logs nombre` | Muestra los logs del contenedor |
| `docker logs -f nombre` | Sigue los logs en vivo |
| `docker inspect nombre` | Detalle completo (IP, redes, volúmenes, config) |
| `docker stats` | Uso de CPU/RAM/memoria en tiempo real |

### Opciones comunes de `docker run`

| Opción | Significado |
|---|---|
| `-d` | Correr en segundo plano (detached) |
| `-it` | Interactivo + terminal TTY |
| `-p host:contenedor` | Publicar un puerto (`-p 8080:80`) |
| `-v /host:/contenedor` | Montar un volumen o bind mount |
| `--name` | Nombre del contenedor |
| `--rm` | Auto-eliminar al detenerse (útil para pruebas) |
| `--network` | Conectar a una red Docker |

## 4. Volúmenes

Persisten los datos cuando el contenedor se borra.

| Comando | Qué hace |
|---|---|
| `docker volume ls` | Lista los volúmenes |
| `docker volume create nombre` | Crea un volumen con nombre |
| `docker volume inspect nombre` | Muestra la ruta real en el host |
| `docker volume rm nombre` | Elimina un volumen **(borra sus datos)** |

**Bind mount** (carpeta del host accesible en el contenedor):

```bash
docker run -v /ruta/en/host:/ruta/en/contenedor imagen
```

## 5. Redes

Los contenedores aislados por defecto se comunican si comparten una red.

| Comando | Qué hace |
|---|---|
| `docker network ls` | Lista las redes |
| `docker network create nombre` | Crea una red |
| `docker network inspect nombre` | Muestra los contenedores conectados y sus IPs |
| `docker network connect red contenedor` | Conecta un contenedor a una red |
| `docker network rm nombre` | Elimina una red |

Dentro de una red bridge, los contenedores se alcanzan **por nombre de servicio o de contenedor**, no por IP (las IP pueden cambiar).

## 6. Limpieza

| Comando | Qué hace |
|---|---|
| `docker system prune` | Elimina contenedores/redes/imágenes sin uso |
| `docker system prune -a` | Lo anterior + imágenes no usadas |
| `docker system prune --volumes` | **También borra volúmenes** (datos) — uso con muchísimo cuidado |

## 7. Docker Compose

Compose define y levanta varios servicios a la vez desde `docker-compose.yml`. Se usa igual con la sintaxis nueva `docker compose` (integrado en Docker) que con la vieja `docker-compose`.

| Comando | Qué hace |
|---|---|
| `docker compose up -d` | Construye (si hace falta) y levanta todos los servicios en segundo plano |
| `docker compose up -d --build` | Fuerza la reconstrucción de las imágenes y levanta |
| `docker compose up -d <servicio>` | Levanta solo un servicio |
| `docker compose down` | Detiene y elimina los contenedores (red queda a veces) |
| `docker compose down -v` | Lo anterior + **elimina los volúmenes (datos)** |
| `docker compose ps` | Estado de los servicios |
| `docker compose logs -f` | Logs de todos los servicios en vivo |
| `docker compose logs -f <servicio>` | Logs de un servicio |
| `docker compose build` | Construye las imágenes sin levantar |
| `docker compose exec <servicio> bash` | Shell dentro del contenedor de un servicio |
| `docker compose config` | Valida el YAML e imprime la config efectiva |
| `docker compose top` | Muestra los procesos dentro de los servicios |

### Flujo típico del proyecto

```bash
cp .env.example .env          # primera vez: completar valores locales
docker compose up -d --build  # construir y levantar todo
docker compose ps             # verificar estado
docker compose logs -f print  # ver logs del servicio de impresión
docker compose down           # al finalizar
```

## Verificación

- `docker ps` muestra los contenedores con estado `Up`.
- `docker compose config` no reporta errores de sintaxis.
- `docker info` responde con datos del daemon.

## Referencias

- `man docker`, `man docker compose`
- [Docker CLI reference](https://docs.docker.com/reference/cli/docker/)
- [Docker Compose CLI reference](https://docs.docker.com/reference/cli/docker/compose/)