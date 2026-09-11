# Configuración del servidor (host)

Esta carpeta contiene la configuración del **sistema operativo del servidor físico** (por fuera de los contenedores Docker). A diferencia de `services/` (cosas dentro de contenedores), acá viven los cambios a nivel host: firewall y acceso SSH.

La clave: **todo se edita acá, se versiona y se aplica desde el repo en el servidor**. Nadie toca el servidor a mano.

## Estructura

```text
server/
├── README.md        ← este archivo (estructura y flujo)
├── nftables.conf    ← firewall del host (nftables, Debian 13)
├── sshd_config      ← acceso SSH endurecido
└── deploy.sh        ← aplica los configs de forma segura en el servidor
```

## Reglas de red (contexto)

| Interfaz | Red | Uso |
|----------|-----|-----|
| `wlo1` | 192.168.0.0/24 | Administradores (joaquin, david, nicolas) — SSH y gestión |
| `eno1` | 192.168.20.0/24 | Usuarios — servicios publicados (web, correo, archivos, impresión) |

## Flujo de trabajo (git, no scp)

### 1. Hacer un cambio (desde cualquier notebook)

```bash
git pull                # traer lo último
nano server/nftables.conf
git add server/
git commit -m "fix(firewall): abrir puerto X en eno1"
git push
```

### 2. Aplicarlo en el servidor

```bash
cd TSO-II               # el repo ya está clonado en el server
git pull
sudo bash server/deploy.sh
```

El script **valida** la sintaxis antes de aplicar y **respalda** el `sshd_config` previo. Si algo falla, no deja el servidor sin conexión.

### 3. Rollback (si quedó mal algo)

```bash
# nftables: apagar el firewall temporalmente
sudo nft flush ruleset
sudo systemctl stop nftables

# ssh: restaurar respaldo generado por deploy.sh
ls /etc/ssh/sshd_config.bak.*
sudo cp /etc/ssh/sshd_config.bak.<timestamp> /etc/ssh/sshd_config
sudo systemctl restart ssh
```

## Reglas para agregar configs nuevos

1. El nombre del archivo debe coincidir con el destino en el servidor (ej: `sshd_config` → `/etc/ssh/sshd_config`).
2. Todo config que requiera reiniciar un servicio debe sumarse al `deploy.sh` **con validación previa** (`nft -c`, `sshd -t`, etc.).
3. Si el cambio es solo documental (no aplicable), va en `docs/guides/`, no acá.
4. No subir secretos: claves privadas, tokens o contraseñas **nunca** a esta carpeta.

## Detalle de archivos

### `nftables.conf`

Firewall con política `drop` en INPUT. Permite:

- SSH solo desde `wlo1` (admins).
- DNS, DHCP y HTTP (proxy nginx) en ambas redes.
- Correo, Samba/NFS y CUPS para la red de usuarios.
- Portainer y PostgreSQL solo para admins.
- Chain `FORWARD` abierta para no romper el NAT/bridge de Docker.

### `sshd_config`

- Solo autenticación por clave pública (sin contraseñas).
- `PermitRootLogin no`.
- `AllowUsers joaquin david nicolas`.
- Sin forwarding/tunnel. Logging `VERBOSE`.

> ⚠️ Antes de desactivar contraseñas: los 3 admins deben haber subido sus claves con `ssh-copy-id`. Ver [`docs/guides/hardening-seguridad.md`](../docs/guides/hardening-seguridad.md).