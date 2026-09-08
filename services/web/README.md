# Servicio: Servidor web (Nginx)

Servidor web basado en Nginx que publica el sitio del proyecto.

## Responsable

**David**

## Propósito

Servir el sitio web del proyecto en HTTP. Es el reemplazo equivalente a IIS en este stack Linux.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Nginx |
| `nginx.conf` | Configuración del virtual host principal |
| `public/` | Contenido estático servido por Nginx |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build web
```

## Pruébarlo

```bash
# Desde el host
curl http://localhost:8080

# En un navegador apuntando a la IP del host
# http://<IP_DEL_HOST>:8080
```

Sustituir el contenido de `public/` por el sitio real del proyecto.

## Estado

- [ ] Cambiar el contenido por defecto (`public/`)
- [ ] Ajustar el virtual host a un `server_name` real
- [ ] Configurar HTTPS si se requiere en la red

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)