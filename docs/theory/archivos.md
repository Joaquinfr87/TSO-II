# Servidores de archivos: Samba, NFS y Web

Este documento cubre las tecnologías para compartir archivos en red, las diferencias entre protocolos y cómo las implementamos en el servicio `files` (Samba + NFS + Filebrowser).

## ¿Por qué varios protocolos?

No todos los clientes hablan el mismo idioma de red. El servidor de archivos del proyecto responde a tres protocolos para cubrir todos los casos:

| Protocolo | ¿Quién lo usa? | Puertos |
|---|---|---|
| **SMB/CIFS** (Samba) | Windows, Linux (Thunar/Nautilus), macOS | 445, 139 |
| **NFS** | Linux/Unix nativo (montaje como disco local) | 2049, 111 |
| **HTTP/Web** (Filebrowser) | Cualquier navegador | 80 / 8082 |

## SMB/CIFS y Samba

**SMB** (Server Message Block) es el protocolo de compartición de archivos de Microsoft. **CIFS** fue una variante histórica; hoy SMB 2/3 es el estándar en Windows.

**Samba** es una reimplementación libre de SMB para sistemas Unix/Linux. Permite que un servidor Linux aparezca como un servidor de archivos de Windows.

Conceptos clave:

- **Recursos (shares):** carpetas publicadas con nombre, p. ej. `/compartido`.
- **Autenticación:** Samba usa sus propias contraseñas, que se marcan con `smbpasswd`. Un usuario del SO no puede acceder a Samba hasta tener contraseña Samba (`smbpasswd -a usuario`).
- **`smb.conf`:** archivo central que define los recursos, permisos y opciones del servidor.

Forma de acceso:

```
smb://files.sudoers.lan/compartido        (URL universal)
smbclient //files.sudoers.lan/compartido -U david   (CLI)
```

## NFS (Network File System)

**NFS** es el protocolo de archivos en red nativo de Unix/Linux. Monta un directorio remoto como si fuera local (`/mnt`), integrado con el sistema de archivos.

- Las carpetas publicadas se llaman **exportaciones** y se definen en `/etc/exports`.
- Cada línea declara el path, qué clientes pueden montar y opciones:

```
/srv/share  192.168.20.0/24(rw,sync,no_subtree_check)
```

- Utiliza el **portmapper** (puerto 111) y el servicio `nfsd` en el puerto 2049.
- El cliente monta con:

```bash
sudo mount -t nfs files.sudoers.lan:/srv/share /mnt
```

Se suele agregar al `/etc/fstab` para que sea persistente.

### SMB vs NFS: cuál usar

| | SMB (Samba) | NFS |
|---|---|---|
| Clientes | Windows, macOS, Linux | Linux/Unix |
| Autenticación | Usuario y contraseña propia | Basada en IP/host (o Kerberos) |
| Encriptación | Sí (SMB3) | Opcional |
| Uso típico | Redes mixtas | Redes Linux |

## Filebrowser (interfaz web)

**Filebrowser** es una aplicación web que ofrece un gestor de archivos en el navegador: subir, descargar, renombrar, mover y compartir archivos con una cuenta de usuario. Se usa como capa HTTP del servidor de archivos.

Conceptos: un **usuario** de Filebrowser se asocia a un directorio y puede tener permisos de escritura/espacio propio. Se configura con un binario `filebrowser` y una base SQLite interna.

## Cómo lo implementamos en el proyecto

El contenedor `tso-files` levanta los tres servicios juntos. Usuarios preconfigurados: `joaquin`, `david`, `nicolas`.

```bash
# SMB
smbclient //files.sudoers.lan/compartido -U david

# Web
http://files.sudoers.lan

# NFS
sudo mount -t nfs files.sudoers.lan:/srv/share /mnt
```

El acceso por DNS (`files.sudoers.lan`) resuelve al host, y **Nginx** proxea el tráfico web a Filebrowser (puerto 80 del host → contenedor).

En el firewall (`server/nftables.conf`), SMB/NFS quedan abiertos para la red de usuarios:

```
tcp dport { 139, 445, 111, 2049 } ip saddr @user_net accept
udp dport { 111, 2049 } ip saddr @user_net accept
```

## Referencias

- Servicio: [services/files/README.md](../../services/files/README.md)
- Guía completa: [Servidor de archivos multi-protocolo](../guides/servidor-archivos.md)
- Samba: https://www.samba.org/ · NFS: https://nfs.sourceforge.net/ · Filebrowser: https://github.com/filebrowser/filebrowser