# Guía: panel de gestión Portainer

## Objetivo

Levantar Portainer, crear el usuario administrador y administrar los contenedores del proyecto desde el navegador.

## Requisitos previos

- Repo clonado y `.env` configurado (variable `PORTAINER_PORT`, default `9443`).
- Acceso a la red administrativa `wlo1` (el firewall limita el panel a los admins).

## Pasos

### 1. Levantar el servicio

```bash
docker compose up -d --build portainer
```

### 2. Primer acceso

Dos formas:

- **Por proxy (sin puerto):** `http://portainer.sudoers.lan` (Nginx → `tso-portainer:9000`).
- **Directa (primer setup):** `https://<IP>:9443` (certificado autofirmado; el navegador pedirá aceptar la excepción).

### 3. Configuración inicial

1. Crear el usuario administrador (usuario + contraseña).
2. Elegir el entorno **Local** (usa `/var/run/docker.sock`).
3. Ya deberían verse los contenedores `tso-*`.

> Si aparece el aviso de **security timeout** (instalación sin configurar), reiniciar el contenedor:
> ```bash
> docker compose restart portainer
> ```

### 4. Tareas comunes

| Tarea | Cómo |
|---|---|
| Ver logs de un contenedor | Menú **Containers** → contenedor → **Logs** |
| Abrir consola | Contenedor → **Console** (usa WebSocket) |
| Reiniciar servicio | Containers → contenedor → **Restart** |
| Ver uso de imágenes/volúmenes | Menús **Images** / **Volumes** |

### 5. Comprobar que la CLI sigue de fuente de verdad

Portainer administra la vista, pero los cambios de configuración se hacen en el repo:

```bash
git commit -am "cambio..." && git push   # notebook
git pull && docker compose up -d --build # servidor
```

## Seguridad

- No exponer la UI fuera de la red de administración (`server/nftables.conf` solo abre `9443`/`8000` para `wlo1`).
- Cambiar la contraseña inicial del administrador.

## Verificación

1. `http://portainer.sudoers.lan` carga el panel y autentica.
2. Se ven los contenedores `tso-*` con estado y logs.

## Referencias

- Teoría: [Gestión de contenedores: Portainer](../theory/portainer.md)
- Compose: [`docker-compose.yml`](../../docker-compose.yml)