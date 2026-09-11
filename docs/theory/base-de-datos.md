# Bases de datos relacionales: PostgreSQL

Este documento cubre la teoría detrás de las bases de datos relacionales, el rol del motor PostgreSQL y cómo lo usamos en el proyecto como servicio `database`.

## ¿Qué es una base de datos relacional?

Una base de datos relacional organiza la información en **tablas** compuestas por **filas** (registros) y **columnas** (atributos). Las tablas se relacionan entre sí mediante **claves**:

- **Clave primaria (PK):** identifica de forma única cada fila.
- **Clave foránea (FK):** referencia una PK de otra tabla, creando la relación.

El **lenguaje SQL** (Structured Query Language) es el estándar para consultar y manipular los datos: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, etc.

## ¿Qué es PostgreSQL?

PostgreSQL es un **motor de base de datos relacional** de código abierto, conocido por:

- **Integridad transaccional** (ACID): Atomicidad, Consistencia, Aislamiento y Durabilidad.
- **Extensibilidad:** tipos de datos y funciones definibles por el usuario.
- **Concurrencia:** usa **MVCC** (Multiversion Concurrency Control), que permite lecturas y escrituras simultáneas sin bloqueos excesivos.
- **Roles y permisos** granulares a nivel base, esquema, tabla y fila.
- Soporte de **JSON/JSONB**, índices avanzados (GIN, BRIN, parciales) y replicación.

### Clientes y servidor

PostgreSQL sigue el modelo **cliente-servidor**:

```
 Cliente (psql/app)  ──TCP/5432──▶  postgres (servidor)
                                        │
                                        └─▶  procesos por conexión
```

- El **servidor** (`postgres`) escucha en el puerto `5432` y atiende cada conexión con un proceso propio.
- El **cliente** (`psql`, `pgAdmin`, aplicaciones) abre una conexión TCP y envía consultas SQL.

## Roles y autenticación

En PostgreSQL no se usan usuarios del sistema: se usan **roles** internos. Cada rol tiene atributos (`LOGIN`, `SUPERUSER`, `CREATEDB`, ...) y puede pertenecer a grupos.

La autenticación se configura en `pg_hba.conf` (Host-Based Authentication):

```
host  all  all  0.0.0.0/0  scram-sha-256
```

- `scram-sha-256` / `md5`: contraseña con hash.
- `trust`: sin contraseña (solo para pruebas locales).
- `peer`: identifica por el usuario del SO (solo conexiones locales Unix socket).

## Cómo lo implementamos en el proyecto

El servicio `database` (`docker-compose.yml`) monta PostgreSQL **15** en el contenedor `tso-db`, expuesto en el puerto `5432` del host.

Al primer arranque, el `entrypoint.sh` crea automáticamente el usuario y la base definidos en el `.env`:

| Variable | Default | Descripción |
|---|---|---|
| `DB_PORT` | `5432` | Puerto en el host |
| `POSTGRES_USER` | `tso` | Rol que se crea |
| `POSTGRES_PASSWORD` | `tso` | Contraseña (¡cambiar en producción!) |
| `POSTGRES_DB` | `tso` | Base de datos creada |

Los demás servicios de la red `tso-net` se conectan a `tso-db:5432` con esas credenciales.

### Comandos útiles

```bash
# Estado del servidor
docker compose exec database pg_isready -h 127.0.0.1 -p 5432

# Consulta dentro del contenedor
docker compose exec database psql -h 127.0.0.1 -U tso -d tso -c 'SELECT version();'

# Desde el host (con psql instalado)
psql -h localhost -p ${DB_PORT:-5432} -U tso -d tso
```

## Seguridad

- **Credenciales en `.env`**, nunca en el repo (`.env` está en `.gitignore`).
- En el firewall del host, `5432` queda **solo para la red administrativa** (`wlo1`) — ver `server/nftables.conf`.
- Los contenedores que se conectan lo hacen por la red interna `tso-net`, sin exponer la base a la red de usuarios.

## Referencias

- Servicio: [services/database/README.md](../../services/database/README.md)
- Teoría Docker: [Docker en un servidor Debian](./docker.md)
- Documentación oficial: https://www.postgresql.org/docs/