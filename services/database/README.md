# Servicio: Base de datos (PostgreSQL)

Servidor de base de datos con **PostgreSQL 15** para el proyecto, accesible por la red `tso-net` y desde el host.

## Responsable

**Nicolás**

## Propósito

Brindar un motor de base de datos relacional para los servicios del proyecto (usuarios, contenido, etc.). Crea automáticamente un usuario y una base de datos por variables del `.env` en el primer arranque.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con PostgreSQL 15 (Debian bookworm) |
| `entrypoint.sh` | Inicializa el cluster, configura la red, crea usuario/base del `.env` y arranca el servidor |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build database
```

## Verificación

1. **Que el servidor acepte conexiones**:

   ```bash
   docker compose exec database pg_isready -h 127.0.0.1 -p 5432
   ```

2. **Conectar por TCP con el usuario y la base del `.env`** (cambiar credenciales por las del `.env` real):

   ```bash
   # Sin cliente psql en el host, dentro del propio contenedor:
   docker compose exec database psql -h 127.0.0.1 -U tso -d tso -c 'SELECT version();'
   ```

   ```bash
   # Con PostgreSQL client instalado en el host:
   psql -h localhost -p ${DB_PORT:-5432} -U tso -d tso
   ```

3. **Ver los logs de arranque** (debe verse el resumen con usuario/base y `listo`):

   ```bash
   docker compose logs database
   ```

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `DB_PORT` | `5432` | Puerto expuesto en el host |
| `POSTGRES_USER` | `tso` | Usuario que se crea al iniciar |
| `POSTGRES_PASSWORD` | `tso` | Contraseña del usuario (cambiar para producción) |
| `POSTGRES_DB` | `tso` | Base de datos que se crea al iniciar |

> La contraseña va en `.env` (nunca en el repo). Ver `.env.example`.

## Estado

- [x] Imagen PostgreSQL construida y arranque por entrypoint
- [x] Cluster inicializado automáticamente en el primer arranque
- [x] Usuario y base de datos creados desde variables del `.env`
- [x] Escucha en todas las interfaces (accesible desde `tso-net` y el host)
- [ ] Definir qué esquemas/tablas necesita el proyecto
- [ ] Conectar los demás servicios a esta base (usuario de correo, web, etc.)

## Interacción con otros servicios

El resto de los servicios de `tso-net` pueden conectarse por el nombre de contenedor `tso-db` y el puerto `5432`, usando las credenciales del `.env`.

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
- Documentación PostgreSQL: https://www.postgresql.org/docs/