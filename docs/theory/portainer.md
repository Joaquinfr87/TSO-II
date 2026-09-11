# Gestión de contenedores: Portainer

Este documento cubre la teoría detrás de portainer y las herramientas de gestión de Docker, y por qué lo incorporamos al proyecto.

## Administrar Docker sin línea de comandos

Docker (y Docker Compose) se manejan principalmente por CLI. Cuando hay muchos contenedores, ver su estado, logs, reiniciarlos o ajustar redes se vuelve tedioso en la consola. Además, no todo el equipo tiene la misma fluidez con los comandos.

> Quien usa la terminal sigue pudiendo usar `docker` normalmente: Portainer **no reemplaza** la CLI, la complementa.

## ¿Qué es Portainer?

**Portainer** es una aplicación web open source que administra motores Docker (y clústeres) desde el navegador. Expone la misma API que usa la CLI de Docker detrás de una interfaz gráfica.

Funcionamiento básico:

```
Navegador ──▼── Portainer ──▶ API de Docker ──▶ demonio docker
```

- Delega **en la API del motor Docker** (montando el socket `/var/run/docker.sock`), por eso ve todo: contenedores, imágenes, volúmenes, redes, stacks.
- Se entrega como un contenedor más, sin dependencias extra.

## Piezas clave de Portainer

### Entorno (environment)

Un entorno es el motor Docker (o clúster) que Portainer controla. En el proyecto apuntamos a **Local**: el socket del host donde corre el propio contenedor.

### Stacks

Un stack es la forma de Portainer de referirse a un archivo `docker-compose.yml` desplegado. Portainer puede crear una **plantilla** desde nuestro propio compose del repo.

### Controles por elemento

- **Contenedores:** iniciar/detener/reiniciar, ver logs en vivo, abrir una **consola** (WebSocket).
- **Imágenes:** construir, descargar, eliminar.
- **Volúmenes y redes:** crear y administrar.
- **Usuarios/teams** (CE con administración por roles): acceso granular al panel.

## Seguridad en el panel

La UI de Portainer va por HTTPS (`9443`) con un certificado autofirmado al primer arranque. En la instalación inicial hay que crear el usuario administrador.

Dos consideraciones de seguridad:

- **No exponer la UI a redes no confiables**: un panel que controla el Docker daemon es una puerta enorme. En nuestro firewall queda limitado a la red administrativa (`wlo1`).
- **Timeout de seguridad**: si la instalación queda sin configurar, Portainer se bloquea y pide reiniciar el contenedor.

## Cómo lo implementamos en el proyecto

El contenedor `tso-portainer` se define en el `docker-compose.yml` raíz:

```yaml
portainer:
  image: portainer/portainer-ce:latest
  container_name: tso-portainer
  restart: unless-stopped
  ports:
    - "8000:8000"                      # Agente Edge / túnel
    - "${PORTAINER_PORT:-9443}:9443"   # UI HTTPS
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - portainer_data:/data
```

Accesos:

- `http://portainer.sudoers.lan` (proxy Nginx → puerto interno `9000`, sin puerto en la URL).
- `https://192.168.20.226:9443` (directo, para el primer setup).

> Nginx proxea a `tso-portainer:9000` (el puerto HTTP interno de Portainer), con headers de WebSocket habilitados para la consola. Ver `services/web/nginx.conf`.

## Por qué sí / por qué no

**A favor:**

- Curva de aprendizaje baja para el equipo.
- Consola y logs sin SSH.
- Vista unificada de todos los contenedores `tso-*`.
- Git sigue siendo la fuente de verdad: los configs viven en el repo, Portainer solo los administra.

**En contra / precauciones:**

- Un clic con permiso de más puede tumbar un servicio.
- Debe quedar restringido por firewall y contraseña fuerte.
- No usar para deploy principal: el flujo sigue siendo `git pull && docker compose up`.

## Referencias

- Compose: [`docker-compose.yml`](../../docker-compose.yml)
- Documentación oficial: https://docs.portainer.io/