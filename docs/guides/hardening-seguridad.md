# Hardening de seguridad del servidor

## Objetivo

Configurar el firewall `nftables` y endurecer el acceso SSH del servidor, respetando el modelo de red del proyecto:

- **wlo1 (192.168.0.0/24):** red administrativa. Solo los administradores (joaquin, david, nicolas) pueden entrar por SSH y acceder a herramientas de gestión.
- **eno1 (192.168.20.0/24):** red de usuarios. Solo servicios publicados (web, correo, archivos, impresión).

## Requisitos previos

- Acceso SSH al servidor desde la red administrativa (wlo1).
- Usuario con privilegios `sudo` en el servidor.
- Los 3 admins ya creados como usuarios del sistema.

## Pasos

### 1. Subir claves públicas SSH (una vez por admin)

Desde cada notebook de los admins, antes de desactivar la contraseña:

```bash
ssh-copy-id joaquin@192.168.0.105
ssh-copy-id david@192.168.0.105
ssh-copy-id nicolas@192.168.0.105
```

Probar en OTRA terminal que el login con clave funciona antes de continuar.

### 2. Copiar el sshd_config endurecido

Desde una máquina con el repo clonado (o vía scp):

```bash
scp docs/guides/sshd_config joaquin@192.168.0.105:/tmp/sshd_config
```

En el servidor:

```bash
sudo cp /tmp/sshd_config /etc/ssh/sshd_config
sudo systemctl restart ssh
```

Verificación en una nueva sesión:

```bash
ssh joaquin@192.168.0.105   # debe entrar sin pedir contraseña
```

### 3. Copiar el firewall nftables

```bash
scp docs/guides/nftables.conf joaquin@192.168.0.105:/tmp/nftables.conf
```

En el servidor:

```bash
sudo cp /tmp/nftables.conf /etc/nftables.conf
sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables --now
```

> ⚠️ Hacerlo en una sesión con la clave SSH ya probada: si una regla cierra el acceso, podés reentrar solo si la clave funciona (las reglas de nftables no sobreviven a un `systemctl stop nftables` por defecto en Trixie solo si está habilitado como servicio... ver nota abajo).

> Nota: en Debian Trixie, `nftables` corre como servicio. Si la regla te deja afuera, agregar regla con `sudo nft add rule` en otra consola o usar la consola física/Docker (tty) del servidor.

Verificación:

```bash
sudo nft list ruleset
sudo nft -c -f /etc/nftables.conf   # valida sintaxis sin aplicar
```

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