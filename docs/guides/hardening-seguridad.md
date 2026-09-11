# Hardening de seguridad del servidor

## Objetivo

Configurar el firewall `nftables` y endurecer el acceso SSH del servidor, respetando el modelo de red del proyecto:

- **wlo1 (192.168.0.0/24):** red administrativa. Solo los administradores (joaquin, david, nicolas) pueden entrar por SSH y acceder a herramientas de gestión.
- **eno1 (192.168.20.0/24):** red de usuarios. Solo servicios publicados (web, correo, archivos, impresión).

## Requisitos previos

- Acceso SSH al servidor desde la red administrativa (wlo1).
- Usuario con privilegios `sudo` en el servidor.
- Los 3 admins ya creados como usuarios del sistema.
- El repo clonado en el servidor.

> Los archivos de configuración viven en `server/` (raíz del repo), **no** en esta carpeta. Acá está la guía; la configuración real se versiona y se aplica con `git pull` + `deploy.sh`.

## Pasos

### 1. Subir claves públicas SSH (una vez por admin)

Desde cada notebook de los admins, antes de desactivar la contraseña:

```bash
ssh-copy-id joaquin@192.168.0.105
ssh-copy-id david@192.168.0.105
ssh-copy-id nicolas@192.168.0.105
```

Probar en OTRA terminal que el login con clave funciona antes de continuar.

### 2. Aplicar firewall y SSH desde el repo

Los configs están en `server/nftables.conf` y `server/sshd_config`. Para aplicarlos en el servidor, dentro del repo clonado:

```bash
git pull
sudo bash server/deploy.sh
```

El script hace 4 cosas en orden seguro:

1. **Valida** la sintaxis de `nftables.conf` con `nft -c` (si falla, no aplica nada).
2. Aplica el firewall.
3. Hace **respaldo automático** de `/etc/ssh/sshd_config` (con fecha).
4. Valida la config de ssh con `sshd -t` y **solo entonces** reinicia el servicio.

Verificación en una nueva sesión:

```bash
ssh joaquin@192.168.0.105   # debe entrar sin pedir contraseña
```

> ⚠️ La primera vez, hacerlo en una sesión con la clave SSH ya probada: si una regla cierra el acceso, podés reentrar solo si la clave funciona.

### 4. Instalar y configurar fail2ban

```bash
sudo apt install fail2ban
```

Crear `/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
```

Reiniciar:

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

### 5. Docker y firewall

Docker agrega sus propias reglas de cadena `FORWARD`/`NAT` en nftables (vía el plugin). La regla `forward policy accept` del config permite el funcionamiento normal de los contenedores en `tso-net`. No usar la opción `"iptables": false` salvo que se conozca bien el impacto (corta NAT de los puertos publicados).

## Tabla de puertos según red

| Servicio | Puerto | wlo1 (admins) | eno1 (usuarios) |
|----------|--------|:---:|:---:|
| SSH | 22 | ✅ | ❌ |
| DNS | 53 | ✅ | ✅ |
| DHCP | 67 | ✅ | ✅ |
| Web (nginx) | 80, 8080 | ✅ | ✅ |
| Portainer (directo) | 9443, 8000 | ✅ | ❌ |
| Correo (SMTP/IMAP/POP3) | 25,110,143,587,993,995 | ✅ | ✅ |
| PostgreSQL | 5432 | ✅ | ❌ |
| Samba / NFS | 139,445,111,2049 | ✅ | ✅ |
| CUPS | 1631 | ✅ | ✅ |

## Rollback (si algo queda mal)

```bash
sudo systemctl stop nftables    # rechaza las reglas y deja la política por defecto
sudo systemctl disable nftables
```

Para SSH:

```bash
sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config   # si se guardó respaldo
sudo systemctl restart ssh
```