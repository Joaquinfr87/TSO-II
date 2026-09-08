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

- [x] Configuración de Virtual Hosts para `web.sudoers.local`, `www.sudoers.local` y `sudoers.local`
- [x] Proxy inverso configurado hacia el servicio de impresión CUPS (`print.sudoers.local` -> `http://tso-print:631`)
- [x] Configuración de `default_server` para capturar peticiones no mapeadas
- [x] Landing page moderna del proyecto en `public/index.html`
- [ ] Configurar HTTPS con certificados SSL si se requiere más adelante

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)