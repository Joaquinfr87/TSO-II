# Seguridad y hardening en servidores

Este documento cubre la teoría detrás de la seguridad del servidor: el modelo de red, el firewall `nftables`, el endurecimiento de SSH y las defensas contra fuerza bruta con `fail2ban`.

## Principio general: defensa en profundidad

Ninguna medida protege sola. La seguridad del servidor se construye por capas:

```
        Capa 1 · Acceso físico    → consola en mano, BIOS
        Capa 2 · Red             → firewall (nftables), segmentación
        Capa 3 · Host            → SSH endurecido, syscalls, parches
        Capa 4 · Aislamiento     → contenedores Docker por servicio
        Capa 5 · Capacidad       → fail2ban, logs, alertas
```

En el proyecto aplicamos varias de estas capas. Este documento se enfoca en firewall, SSH y anti-fuerza bruta.

## Modelo de redes del servidor

El servidor tiene dos interfaces con distinta confianza:

| Interfaz | Red | Confianza | Uso |
|---|---|---|---|
| `wlo1` | 192.168.0.0/24 | **Administradores** | SSH, Portainer, PostgreSQL |
| `eno1` | 192.168.20.0/24 | **Usuarios** | Web, correo, archivos, impresión |

La idea: **lo que es de administración solo se expone en la red de administración**; los servicios públicos se abren donde se necesitan y nada más.

## Firewall: nftables

### Qué es

**nftables** es el framework de firewall de Linux (sucesor de `iptables`, default en Debian 12+). Organiza reglas en **tablas**, **cadenas** y **conjuntos** (sets), con sintaxis declarativa.

### Tabla y hooks

Las cadenas se anclan a **hooks** del kernel:

| Hook | Cuándo corre | Uso típico |
|---|---|---|
| `input` | Paquetes entrantes **al host** | Filtrar accesos |
| `output` | Paquetes salientes del host | Restricciones de salida |
| `forward` | Paquetes **re-encaminados** (ruteo) | Necesaria para bridges/NAT de Docker |

### Política por defecto: denegar

El patrón recomendado es **whitelist**: denegar todo y abrir solo lo necesario.

```nft
type filter hook input priority filter; policy drop;
```

Con `policy drop`, todo lo que no matchee una regla se descarta. Después se van agregando excepciones (`accept`).

### Conjuntos (sets)

Para no repetir IPs, se usan conjuntos:

```nft
set admin_ips { type ipv4_addr; flags interval; elements = { 192.168.0.0/24 } }

tcp dport 22 ip saddr @admin_ips accept
```

### `ct state` (conntrack)

El kernel rastrea conexiones. `ct state established,related accept` permite el tráfico de **ida y respuesta** de conexiones ya iniciadas, sin abrir puertos de forma estática para el retorno.

## SSH y su endurecimiento

### Por qué endurecer SSH

SSH está en el puerto 22 y expuesto al mundo; es el primer objetivo de ataques por **fuerza bruta** de contraseñas. Las medidas clave:

1. **Claves públicas (sin contraseña):** `PasswordAuthentication no`. Una clave RSA/Ed25519 de largo suficiente reemplaza la contraseña.
2. **Sin root por SSH:** `PermitRootLogin no`. Se entra con usuario normal y `sudo`.
3. **Lista de usuarios:** `AllowUsers joaquin david nicolas`.
4. **Límites:** `MaxAuthTries 3`, `LoginGraceTime 30`.
5. **Deshabilitar features** que aumentan superficie: forwarding, tunnel, X11.

### Flujo correcto de implementación

```
1. Cada admin sube su clave pública   →  ssh-copy-id user@server
2. Se prueba login con clave en OTRA terminal
3. Recién entonces se desactiva la contraseña
```

Esto evita quedar afuera del servidor. Ver `docs/guides/hardening-seguridad.md`.

## fail2ban: contra fuerza bruta

**fail2ban** vigila los logs (`/var/log/auth.log`) y, ante repetición de fallos de autenticación desde una misma IP (`maxretry`), **banea transitoriamente** esa IP agregando una regla al firewall.

Elementos:

- **Jails:** reglas por servicio (`[sshd]`, `[proftpd]`, ...).
- **Filtros:** expresiones regulares que detectan el fallo en el log.
- **Acción:** banear por `bantime` segundos tras `maxretry` intentos en `findtime` segundos.

```ini
[sshd]
enabled = true
maxretry = 3
bantime = 3600
findtime = 600
```

## Cómo lo implementamos en el proyecto

Los archivos reales están versionados en `server/` y se aplican en el servidor con `sudo bash server/deploy.sh`:

| Archivo | Qué implementa |
|---|---|
| `server/nftables.conf` | Política `drop`; SSH solo desde `wlo1`; servicios por red |
| `server/sshd_config` | Claves, sin root, `AllowUsers` de los 3 admins |
| `docs/guides/hardening-seguridad.md` | Guía paso a paso + fail2ban + rollback |

La regla de Docker: la cadena `forward` queda en `accept` para no romper el NAT/bridge de los contenedores. Los puertos publicados se controlan desde el `input` del host.

## Conceptos de referencia

- **Whitelist / blacklist:** permitir solo lo conocido vs. bloquear lo conocido malo. En red, whitelist gana.
- **Superficie de ataque:** todos los servicios/puertos expuestos; menos es mejor.
- **Principio de mínimo privilegio:** cada actor (usuario, servicio, contenedor) tiene solo lo que necesita.
- **Confidencialidad · Integridad · Disponibilidad (CIA):** el objetivo que protege cada capa.

## Referencias

- Configs reales: [`server/`](../../server/)
- Guía de aplicación: [Hardening de seguridad](../guides/hardening-seguridad.md)
- Documentación nftables: https://wiki.nftables.org/ · fail2ban: https://github.com/fail2ban/fail2ban