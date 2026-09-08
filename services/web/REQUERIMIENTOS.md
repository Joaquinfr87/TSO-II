# Requerimientos para el Servidor Web (Nginx)

**Responsable:** David

## Servicio actual

Nginx sirve contenido estático desde `/usr/share/nginx/html/`.

## Requerimientos

### 1. Proxy inverso para CUPS (Impresión)

Cuando alguien acceda a `print.sudoers.local`, Nginx debe redirigir al servidor de impresión.

```nginx
server {
    listen 80;
    server_name print.sudoers.local;

    location / {
        proxy_pass http://tso-print:631;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Importante:** El nombre del servicio en docker-compose es `tso-print`, no `localhost`.

### 2. Contenido estático

El sitio principal debe seguir funcionando:

```nginx
server {
    listen 80;
    server_name web.sudoers.local www.sudoers.local sudoers.local;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 3. Default server

Para requests sin Host header o con dominios no configurados:

```nginx
server {
    listen 80 default_server;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

## DNS Records

El servidor DNS (Bind9) ya tiene configurados estos registros:

| Subdominio | IP |
|---|---|
| web.sudoers.local | 192.168.0.105 / 172.16.0.16 |
| print.sudoers.local | 192.168.0.105 / 172.16.0.16 |
| mail.sudoers.local | 192.168.0.105 / 172.16.0.16 |

## Docker Compose

El servicio Nginx ya está declarado en `docker-compose.yml`:

```yaml
web:
    build: ./services/web
    container_name: tso-web
    ports:
      - "${WEB_PORT_HTTP:-8080}:80"
    volumes:
      - ${WEB_SITE_DIR:-./services/web/public}:/usr/share/nginx/html:ro
    networks:
      - tso-net
```

## Probar

```bash
# Levantar el servicio
docker compose up -d --build web

# Probar el sitio principal
curl http://localhost:8080

# Probar proxy a CUPS (desde otra máquina o con DNS configurado)
curl http://print.sudoers.local

# Ver logs
docker compose logs -f web
```

## Notas

- Nginx escucha en el puerto 80 del contenedor
- Se expone en el puerto 8080 del host (configurable en `.env`)
- Los proxies usan nombres de servicio de Docker, no IPs
