# Servidores web, Nginx y proxy inverso

Este documento cubre la teoría detrás de HTTP, servidores web, Nginx, virtual hosts, proxy inverso, y cómo lo configuramos en nuestro proyecto.

## HTTP: el protocolo de la web

HTTP (HyperText Transfer Protocol) es el protocolo que usa el navegador para comunicarse con los servidores web. Es un protocolo **request-response**: el cliente envía una petición y el servidor responde.

### Estructura de una petición

```
GET /index.html HTTP/1.1
Host: web.sudoers.lan
User-Agent: Firefox/120.0
Accept: text/html
```

- **Método**: `GET` (obtener), `POST` (enviar), `PUT` (actualizar), `DELETE` (borrar)
- **Ruta**: `/index.html` (el recurso que se pide)
- **Host**: `web.sudoers.lan` (el dominio al que va dirigida la petición)
- **Headers**: metadata adicional

### Estructura de una respuesta

```
HTTP/1.1 200 OK
Server: nginx/1.27.5
Content-Type: text/html
Content-Length: 29718

<!DOCTYPE html>
<html>...
```

- **Código de estado**: `200` (OK), `404` (No encontrado), `500` (Error interno), `301` (Redirección)
- **Headers**: metadata de la respuesta
- **Body**: el contenido real (HTML, JSON, imágenes, etc.)

### Puertos

| Puerto | Protocolo | Uso |
|---|---|---|
| 80 | HTTP | Tráfico web sin cifrar |
| 443 | HTTPS | Tráfico web cifrado (TLS/SSL) |
| 8080 | HTTP alternativo | Puertos altos para evitar conflictos |

### Códigos de estado comunes

| Código | Significado | Ejemplo de uso |
|---|---|---|
| 200 | OK | La petición funcionó |
| 301 | Movido permanentemente | Redirección a HTTPS o a otra URL |
| 404 | No encontrado | El recurso no existe |
| 500 | Error interno del servidor | Bug del backend |

## Servidores web

Un **servidor web** es un programa que escucha peticiones HTTP y responde con contenido (HTML, imágenes, API JSON).

Los más comunes en Linux:

| Servidor | Estilo | Caso de uso |
|---|---|---|
| **Apache** | Proceso por petición | Clásico, muy documentado, más pesado |
| **Nginx** | Event-driven, async | Alto rendimiento, proxy inverso, estáticos |
| **Caddy** | Sencillo, HTTPS automático | Proyectos pequeños sin mucha config |

## Por qué Nginx

En nuestro proyecto usamos **Nginx** por tres motivos:

1. **Servir contenido estático eficientemente** — Nginx es extremadamente rápido con archivos estáticos (HTML, CSS, JS).
2. **Proxy inverso** — Permite redirigir peticiones de un dominio a otro servicio interno (CUPS, base de datos, etc.).
3. **Bajo consumo** — Es event-driven: un solo proceso maneja miles de conexiones simultáneas sin explotar la memoria.

## Estructura de configuración de Nginx

Nginx se configura con bloques anidados:

```
events {
    worker_connections 1024;    # máx. conexiones por worker
}

http {
    include mime.types;          # tipos de contenido

    server {
        listen 80;               # puerto donde escucha
        server_name web.sudoers.lan;

        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
```

| Bloque | Para qué sirve |
|---|---|
| `events` | Configuración de conexiones del servidor |
| `http` | Contiene servidores virtuales (web) |
| `server` | Un sitio web / virtual host |
| `location` | Reglas para rutas URL específicas |

## Virtual hosts (server blocks)

Un **virtual host** es un sitio web independiente en el mismo servidor. Nginx elige qué `server` usar según dos criterios:

### 1. Puerto (`listen`)

```nginx
server {
    listen 80;
    server_name web.sudoers.lan;
}
```

Nginx escucha en el puerto 80 y separa los sitios por nombre.

### 2. Nombre (`server_name`)

```nginx
server {
    listen 80;
    server_name web.sudoers.lan;    # solo responde a esta URL
}

server {
    listen 80;
    server_name print.sudoers.lan;  # otra URL
}

server {
    listen 80 default_server;        # cualquier otra petición
    server_name _;
}
```

Cuando llega una petición, Nginx:
1. Verifica el header `Host` del request (ej: `web.sudoers.lan`)
2. Busca un `server` cuyo `server_name` coincida
3. Si no encuentra coincidencia, usa el `default_server`

### En nuestro proyecto

Tenemos 3 virtual hosts en `services/web/nginx.conf`:

| server_name | Responde |
|---|---|
| `print.sudoers.lan` | Proxy inverso a CUPS |
| `web.sudoers.lan` `www.sudoers.lan` `sudoers.lan` | Sitio principal (estático) |
| `_` (default) | Cualquier otra petición → sitio principal |

## Proxy inverso

Un **proxy inverso** es un servidor que se interpone entre los clientes y los servicios internos:

```
Cliente ──> Nginx (proxy inverso) ──> Servicio interno
              puerto 80                 puerto 631 (CUPS)
              print.sudoers.lan
```

### ¿Qué resuelve?

1. **Ocultar servicios internos**: el cliente nunca ve el puerto del servicio real.
2. **Unificar accesos**: `http://print.sudoers.lan` en vez de `http://192.168.0.105:1631`.
3. **Centralizar configuración**: autenticación, límites, caché, en un solo punto.

### La directiva `proxy_pass`

```nginx
location / {
    proxy_pass http://tso-print:631;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

- `proxy_pass`: a qué servicio interno reenviar la petición
- `proxy_set_header Host`: preserva el dominio original para el backend
- `proxy_set_header X-Real-IP`: informa la IP real del cliente

## El resolver de Docker: `127.0.0.11`

Docker tiene un **DNS embebido** que resuelve los nombres de los contenedores (`tso-print`, `tso-db`, etc.). Este DNS vive en la dirección virtual `127.0.0.11` dentro de cada contenedor.

### El problema

Nginx intenta resolver el nombre `tso-print` **al arrancar**. Si el contenedor de CUPS no está levantado todavía, Nginx falla con:

```
host not found in upstream "tso-print:631"
```

### La solución

Usamos `resolver` + `set` para que Nginx resuelva el nombre **en tiempo de ejecución**, no al arrancar:

```nginx
location / {
    resolver 127.0.0.11 valid=10s ipv6=off;   # DNS de Docker, caché 10s
    set $cups_upstream http://tso-print:631;  # resuelve bajo demanda
    proxy_pass $cups_upstream;
}
```

- `resolver 127.0.0.11`: usa el DNS embebido de Docker
- `valid=10s`: el resultado se re-cachea cada 10 segundos
- `ipv6=off`: no intenta resolución IPv6
- `set $cups_upstream`: variable que se resuelve solo cuando hay una petición

## Estados HTTP clave en nuestro sitio

Cuando probás nuestro sitio:

```
curl -i http://web.sudoers.lan
HTTP/1.1 200 OK           ← la petición funcionó
Server: nginx/1.27.5     ← Nginx respondió
Content-Type: text/html  ← contenido HTML
```

```
curl -i http://web.sudoers.lan/no-existe
HTTP/1.1 404 Not Found    ← el recurso no existe
```

## En nuestro proyecto: flujo completo

```
Cliente: http://web.sudoers.lan
         ↓
DNS (192.168.0.105) → web.sudoers.lan → 192.168.0.105
         ↓
Nginx (puerto 80 docker-compose) → server_name "web.sudoers.lan"
         ↓
root /usr/share/nginx/html → index.html
         ↓
Respuesta HTTP 200

===============================

Cliente: http://print.sudoers.lan
         ↓
DNS (192.168.0.105) → print.sudoers.lan → 192.168.0.105
         ↓
Nginx (puerto 80) → server_name "print.sudoers.lan"
         ↓
location / → proxy_pass http://tso-print:631 (CUPS)
         ↓
Nginx responde con la interfaz web de CUPS
```

### Los puertos en docker-compose

```yaml
web:
    ports:
      - "80:80"
      - "${WEB_PORT_HTTP:-8080}:80"
```

- `80:80`: acceso al sitio por **puerto 80** (sin especificar puerto en la URL)
- `8080:80`: acceso alternativo por **puerto 8080**

Ambos mapeos apuntan al **mismo Nginx interior** (`:80` del contenedor).

## Referencias

- [Documentación de Nginx](https://nginx.org/en/docs/)
- [Documentación de proxy_pass](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass)
- Teoría: [DNS en este proyecto](./dns.md)
- Teoría: [Docker en un servidor Debian](./docker.md)