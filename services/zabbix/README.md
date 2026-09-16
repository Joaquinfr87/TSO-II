# Servicio: Monitoreo (Zabbix)

Sistema de monitoreo **Zabbix 7.4** desplegado como contenedores Docker, integrado al stack del proyecto TSO-II.

## Responsable

**Joaquín**

## Propósito

Monitorear la salud del servidor, los contenedores Docker, las bases de datos y la disponibilidad de los servicios de red (SMTP, IMAP, DNS, HTTP, etc.), con alertas automáticas por email.

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    tso-net (bridge)                      │
│                                                         │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐ │
│  │  zabbix-db   │   │ zabbix-server│   │  zabbix-web  │ │
│  │  (PostgreSQL │◄──│  (core:      │◄──│  (Nginx +    │ │
│  │   16-alpine) │   │   recolecta) │   │   PHP)       │ │
│  └──────────────┘   └──────┬───────┘   └──────────────┘ │
│                            │                             │
│                  ┌─────────┴─────────┐                   │
│                  │ zabbix-agent-docker│                  │
│                  │ (monitorea Docker  │                  │
│                  │  vía socket)       │                  │
│                  └────────────────────┘                  │
└─────────────────────────────────────────────────────────┘

    Agentes en el host (fuera de Docker):
    ┌────────────────────┐
    │ zabbix-agent2      │ ← instalado via apt (server/deploy.sh)
    │ monitorea CPU/RAM/ │
    │ disco/red del host │
    └────────────────────┘
```

## Componentes

| Contenedor | Imagen | Puerto | Función |
|---|---|---|---|
| `tso-zabbix-db` | `postgres:16-alpine` | — | Base de datos del server Zabbix |
| `tso-zabbix-server` | `zabbix/zabbix-server-pgsql:7.4-ubuntu-latest` | `10051/tcp` | Server core (recoge datos de agentes) |
| `tso-zabbix-web` | `zabbix/zabbix-web-nginx-pgsql:7.4-ubuntu-latest` | — (via reverse proxy) | Interfaz web (PHP + Nginx) |
| `tso-zabbix-agent-docker` | `zabbix/zabbix-agent2:7.4-ubuntu-latest` | — | Agente que monitorea contenedores Docker |

## Acceso

**Panel web**: `https://zabbix.sudoers.lan` (via reverse proxy nginx, cert autofirmado)

**Credenciales iniciales**:
- Usuario: `Admin`
- Contraseña: `zabbix`

> Cambiar la contraseña inmediatamente después del primer login.

## Uso

```bash
# Desde la raíz del repositorio — levantar todo el stack incluyendo Zabbix
docker compose up -d --build

# Solo Zabbix (requiere que la DB esté corriendo)
docker compose up -d zabbix-db zabbix-server zabbix-web zabbix-agent-docker
```

## Verificación

1. **Contenedores arriba**:

   ```bash
   docker compose ps | grep zabbix
   ```

2. **Web responde**:

   ```bash
   curl -k https://zabbix.sudoers.lan
   ```

3. **Server escuchando agentes**:

   ```bash
   docker compose exec zabbix-server zabbix_server -R -h  # o verificar puerto
   ```

4. **Agente Docker conectado** (verificar en la UI: Configuration → Hosts → tso-docker → Green icon)

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `ZABBIX_DB_USER` | `zabbix` | Usuario PostgreSQL de Zabbix |
| `ZABBIX_DB_PASSWORD` | `zabbix` | Contraseña PostgreSQL de Zabbix |

## Templates oficiales recomendados

En la UI, enlazar estos templates a los hosts correspondientes:

| Host | Template | Qué monitorea |
|---|---|---|
| `ts-server` (host-agent) | Linux by Zabbix agent 2 | CPU, RAM, disco, red, procesos, services del host Debian |
| `tso-docker` (docker-agent) | Docker by Zabbix agent 2 | Contenedores (uptime, CPU, memoria, IO, reinicios) |
| `tso-db` (endpoint HTTP) | PostgreSQL by Zabbix agent 2 | Conexiones, queries/s, locks, tamaño DB |
| `tso-web` (TCP check) | TCP Service Discovery | HTTP/HTTPS, SMTP, IMAP, POP3, DNS, CUPS, Samba |

### Nota sobre el agente del host

El agente `zabbix-agent2` se instala vía `apt` directamente en el host Debian (no en contenedor). Esto permite ver métricas reales del hardware que un contenedor no puede acceder. Se configura y aplica con:

```bash
git pull
sudo bash server/deploy.sh
```

La config del agente está versionada en `server/zabbix_agent2.conf`.

## Configuración inicial (post-install)

### 1. Cambiar contraseña de Admin

Administration → Users → Admin → Password → Cambiar.

### 2. Configurar media type de email

Administration → Media types → Email → Configurar:
- SMTP server: `tso-mail`
- SMTP port: `587`
- SMTP helo: `sudoers.lan`
- SMTP email: `zabbix@sudoers.lan`
- Authentication: Login/Password (credenciales del mailbox)

### 3. Asignar media a usuario Admin

Administration → Users → Admin → Media → Add:
- Type: Email
- Send to: `admin@sudoers.lan` (o邮箱 deseado)
- When active: 7x24h

### 4. Agregar hosts

Configuration → Hosts → Create host:
- Host name: `ts-server`
- Templates: Linux by Zabbix agent 2
- Interfaces: Agent → IP del server (192.168.1.10 o 127.0.0.1)
- Host groups: Linux servers

Repetir para `tso-docker` con template Docker by Zabbix agent 2.

### 5. Ajustar triggers

Los templates vienen con triggers predefinidos. Ajustar umbrales según necesidad:
- CPU > 90% por 5 minutos
- Disco > 80%
- Memoria swap usada > 50%
- Contenedor reiniciado inesperadamente

## Referencias

- Teoría: [Monitoreo con Zabbix](../../docs/theory/monitoreo.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
- Documentación Zabbix: https://www.zabbix.com/documentation/7.4
- Zabbix Docker: https://github.com/zabbix/zabbix-docker
