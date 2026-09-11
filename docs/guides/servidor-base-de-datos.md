# Guía: servidor de base de datos PostgreSQL

## Objetivo

Levantar y validar el motor PostgreSQL del proyecto y conectar un cliente desde el host o desde la red `tso-net`.

## Requisitos previos

- Repo clonado y `.env` configurado (variables `POSTGRES_*`).
- Docker y Docker Compose funcionando.

## Pasos

### 1. Levantar el servicio

```bash
docker compose up -d --build database
```

### 2. Verificar el estado del servidor

```bash
docker compose exec database pg_isready -h 127.0.0.1 -p 5432
```

Debe responder `accepting connections`.

### 3. Conectar con el cliente psql

`POSTGRES_USER`, `POSTGRES_PASSWORD` y `POSTGRES_DB` vienen del `.env` (defaults: `tso` / `tso` / `tso`).

```bash
# Desde el host
psql -h localhost -p ${DB_PORT:-5432} -U tso -d tso

# O dentro del contenedor
docker compose exec database psql -h 127.0.0.1 -U tso -d tso
```

Probar una consulta:

```sql
SELECT version();
```

### 4. Crear una tabla de prueba

```sql
CREATE TABLE prueba (id serial PRIMARY KEY, nombre text);
INSERT INTO prueba (nombre) VALUES ('hola');
SELECT * FROM prueba;
```

Los datos persisten porque la base vive en el volumen `db_data` (no se borra con `docker compose down`).

## Conexión desde otro contenedor

Cualquier contenedor en `tso-net` se conecta por el nombre del servicio:

```bash
psql -h tso-db -p 5432 -U tso -d tso
```

## Verificación

1. `pg_isready` responde `accepting connections`.
2. Ingresan las credenciales del `.env`.
3. La tabla `prueba` creada sobrevive a un `docker compose restart database`.

## Referencias

- Teoría: [Bases de datos relacionales: PostgreSQL](../theory/base-de-datos.md)
- Servicio: [services/database/README.md](../../services/database/README.md)