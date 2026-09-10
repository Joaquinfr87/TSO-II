# Servicio: Servidor de archivos (Samba)

Servidor de archivos basado en Samba (protocolo SMB) para compartir archivos en la red.

## Responsable

**David**

## Propósito

Compartir archivos por la red local mediante el protocolo SMB, accesible desde Windows, Linux y macOS.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Samba |
| `smb.conf` | Definición del recurso compartido |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build files

# Crear un usuario Samba (el cliente usa esta cuenta para conectarse)
docker compose exec files smbpasswd -a root
```

## Pruébarlo

```bash
# En Windows / macOS / Linux
\\<IP_DEL_HOST>\compartido

# Con smbclient desde el host
smbclient //<IP_DEL_HOST>/compartido -U <usuario>
```

## Estado

- [x] Definir los usuarios Samba (`nicolas`, `joaquin`, `david`) y sus contraseñas en el Dockerfile
- [x] Ajustar permisos y recurso compartido autenticado (`valid users`) en `smb.conf`
- [x] Configurar el recurso como autenticado según consigna

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)