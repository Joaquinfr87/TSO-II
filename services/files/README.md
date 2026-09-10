# Servicio: Servidor de Archivos Multi-Protocolo (Samba, Web y NFS)

Servidor centralizado de archivos para compartir recursos en la red local soportando acceso por SMB (Samba), interfaz Web (Filebrowser) y montajes nativos Linux (NFS).

## Responsable

**David**

## Propósito

Compartir archivos en la red local accesibles mediante:
- **SMB (Samba):** Windows, Linux (Thunar/Nautilus) y macOS (`smb://files.sudoers.lan/compartido`).
- **Web (Filebrowser):** Interfaz gráfica para navegadores (`http://files.sudoers.lan` o puerto 8082).
- **NFS (Network File System):** Montaje directo nativo para clientes Linux (`files.sudoers.lan:/srv/share`).

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen multi-protocolo |
| `smb.conf` | Configuración de los recursos Samba (SMB) |
| `exports` | Configuración de exportaciones NFS |
| `entrypoint.sh` | Inicialización de usuarios y servicios (Samba + Web + NFS) |

## Usuarios Preconfigurados

- **nicolas** / `sudoers123`
- **joaquin** / `sudoers123`
- **david** / `sudoers123`

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build files
```

## Probar Conexiones

### 1. Vía Samba (SMB)
```bash
# Desde Linux con smbclient
smbclient //files.sudoers.lan/compartido -U david

# Desde Thunar / Explorador de archivos
smb://files.sudoers.lan/compartido
```

### 2. Vía Web (Filebrowser)
Abrí en el navegador:
`http://files.sudoers.lan` (o `http://<IP_DEL_HOST>:8082`)

### 3. Vía NFS (Cliente Linux)
```bash
sudo mount -t nfs files.sudoers.lan:/srv/share /mnt
```

## Estado

- [x] Configurar usuarios Samba y Filebrowser (`nicolas`, `joaquin`, `david`)
- [x] Configurar permisos de lectura/escritura en `smb.conf`
- [x] Integrar interfaz Web con Filebrowser
- [x] Configurar servidor NFS Kernel y archivo `exports`