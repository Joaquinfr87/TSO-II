# Configuración del Servidor de Archivos Multi-Protocolo (Samba, NFS y Filebrowser)

Documentación detallada sobre la arquitectura, configuración e implementación del servicio de archivos unificado para el proyecto **TSO-II**.

---

## 1. Objetivo y Visión General

El servidor de archivos del proyecto TSO-II está diseñado para ofrecer **almacenamiento compartido unificado** en la red local (`sudoers.lan`). Permite a diferentes clientes acceder a la misma carpeta compartida (`/srv/share`) utilizando el protocolo que mejor se adapte a sus necesidades:

1. **SMB / CIFS (Samba):** Compatibilidad con clientes Windows, Linux (Thunar, Nautilus) y macOS.
2. **NFS (Network File System):** Montaje directo de alto rendimiento para sistemas operativos Linux/Unix.
3. **Filebrowser (Web UI):** Interfaz gráfica accesible desde cualquier navegador web moderno sin necesidad de instalar clientes adicionales.

Toda la infraestructura está containerizada en un único servicio Docker de alta eficiencia (`tso-files`) basado en Debian.

---

## 2. Arquitectura y Dockerización

### 2.1 Estructura del Servicio (`services/files/`)

```text
services/files/
├── Dockerfile        # Definición de la imagen y empaquetado de paquetes
├── smb.conf          # Configuración de Samba (SMB)
├── exports           # Tabla de exportaciones NFS
├── entrypoint.sh     # Script de inicio, creación de usuarios y arranque de daemons
└── README.md         # Documentación de uso rápido
```

### 2.2 Dockerfile

La imagen de contenedor se construye a partir de `debian:bookworm-slim`:

- **Paquetes instalados:** `samba`, `nfs-kernel-server`, `rpcbind`, `curl`, `ca-certificates`.
- **Filebrowser:** Se descarga y extrae la versión binaria oficial ejecutable en `/usr/local/bin/filebrowser`.
- **Puertos expuestos:**
  - `445/tcp` y `139/tcp`: Samba (SMB).
  - `80/tcp`: Interfaz Web de Filebrowser.
  - `2049/tcp+udp`: Servicio principal de NFS.
  - `111/tcp+udp`: `rpcbind` / Portmapper para NFS.

### 2.3 Configuración en `docker-compose.yml`

```yaml
  files:
    build: ./services/files
    container_name: tso-files
    privileged: true
    ports:
      - "${SMB_PORT_445:-445}:445"
      - "139:139"
      - "${FILES_WEB_PORT:-8082}:80"
      - "2049:2049"
      - "2049:2049/udp"
      - "111:111"
      - "111:111/udp"
    volumes:
      - ${FILES_SHARE_DIR:-./services/files/data}:/srv/share
      - files_db:/database
    networks:
      - tso-net
```

> **Nota importante sobre privilegios:** La opción `privileged: true` es indispensable para que el contenedor pueda interactuar con el sistema de archivos del kernel host y ejecutar los daemons de NFS (`rpc.nfsd`, `rpc.mountd`).

---

## 3. Configuración por Protocolo

### 3.1 Samba (SMB/CIFS)

La configuración se define en `services/files/smb.conf`:

```ini
[global]
    workgroup = WORKGROUP
    server string = Servidor de archivos TSO-II
    security = user
    map to guest = bad user
    server role = standalone server
    log file = /var/log/samba/log.%m
    max log size = 1000

[compartido]
    path = /srv/share
    browseable = yes
    writable = yes
    guest ok = no
    valid users = nicolas joaquin david
    force user = root
    create mask = 0666
    directory mask = 0777
    force create mode = 0666
    force directory mode = 0777
```

**Aspectos clave:**
- **Recurso compartido:** `[compartido]` mapeado al directorio `/srv/share`.
- **Seguridad:** Requiere autenticación de usuario (`security = user`). Solo los usuarios válidos (`nicolas`, `joaquin`, `david`) tienen permiso de acceso.
- **Permisos forzados:** `force create mode = 0666` y `force directory mode = 0777` garantizan que cualquier archivo o directorio creado mediante SMB conserve permisos de lectura/escritura totales para que no haya bloqueos entre protocolos.

---

### 3.2 NFS (Network File System)

La tabla de exportación se define en `services/files/exports`:

```text
/srv/share *(rw,sync,no_subtree_check,no_root_squash,fsid=0)
```

**Opciones de exportación:**
- `/srv/share`: Directorio raíz exportado.
- `*`: Permite la conexión desde cualquier IP de la red local.
- `rw`: Opciones de lectura y escritura.
- `sync`: Confirmación de cambios en disco antes de responder a las peticiones del cliente (mayor integridad de datos).
- `no_subtree_check`: Deshabilita la verificación de subárboles para mejorar el rendimiento.
- `no_root_squash`: Permite que las operaciones realizadas como `root` en el cliente conserven privilegios sobre los archivos del servidor.
- `fsid=0`: Define la carpeta como raíz principal para clientes NFSv4.

---

### 3.3 Filebrowser (Interfaz Web)

Filebrowser proporciona un explorador de archivos Web completo, responsivo y liviano.

**Configuración e Inicialización en `entrypoint.sh`:**
```bash
filebrowser config init --database "$DB_FILE"
filebrowser config set --database "$DB_FILE" \
    --root /srv/share \
    --address 0.0.0.0 \
    --port 80 \
    --auth.method json \
    --minimumPasswordLength 1
```

- **Base de datos SQLite:** Almacenada en la ruta `/database/filebrowser.db` (asociada al volumen persistente `files_db`).
- **Integración con Nginx:** El servidor web `tso-web` redirecciona las solicitudes dirigidas a `http://files.sudoers.lan` hacia `http://tso-files:80`.

---

## 4. Inicialización y Aprovisionamiento (`entrypoint.sh`)

El script `entrypoint.sh` actúa como orquestador del contenedor:

1. **Creación de estructura de directorios y permisos:**
   ```bash
   mkdir -p /srv/share /database /var/lib/nfs/v4recovery /run/samba
   chmod -R 777 /srv/share
   ```
2. **Creación de usuarios del sistema y Samba:**
   Crea los usuarios de Linux (`nicolas`, `joaquin`, `david`) si no existen y registra sus credenciales Samba mediante `smbpasswd`.
3. **Aprovisionamiento de la base de datos Filebrowser:**
   Crea o actualiza los usuarios en Filebrowser sincronizando las credenciales.
4. **Arranque de servicios NFS:**
   ```bash
   rpcbind 2>/dev/null || true
   exportfs -arv 2>/dev/null || true
   rpc.nfsd 8 2>/dev/null || true
   rpc.mountd 2>/dev/null || true
   ```
5. **Arranque de Filebrowser y Samba:**
   - Filebrowser se ejecuta en segundo plano (`&`) en el puerto 80.
   - Samba (`smbd`) se ejecuta en primer plano (`exec smbd --foreground`) manteniendo el contenedor activo.

---

## 5. Guía de Pruebas y Verificación

### 5.1 Credenciales por Defecto

- **Usuarios:** `nicolas`, `joaquin`, `david`
- **Contraseña por defecto:** `sudoers123456`

---

### 5.2 Verificación Vía Samba (SMB)

#### Desde explorador gráfico (Thunar / Nautilus / Dolphin):
1. Presionar `Ctrl + L` para ingresar la barra de ubicación.
2. Ingresar: `smb://files.sudoers.lan/compartido` (o `smb://<IP_DEL_SERVIDOR>/compartido`).
3. Ingresar usuario (`david`), dominio (`WORKGROUP`) y contraseña (`sudoers123456`).

#### Desde terminal con `smbclient`:
```bash
smbclient //192.168.0.105/compartido -U david
# Contraseña: sudoers123456
```

---

### 5.3 Verificación Vía Web (Filebrowser)

1. Abrir el navegador e ingresar a `http://files.sudoers.lan` o `http://<IP_DEL_SERVIDOR>:8082`.
2. Iniciar sesión con cualquiera de los usuarios preconfigurados (`david` / `sudoers123456`).
3. Probar la subida, navegación y descarga de archivos desde la interfaz web.

---

### 5.4 Verificación Vía NFS (Kernel)

#### 1. Comprobar recursos exportados desde el cliente:
```bash
showmount -e 192.168.0.105
```
*Resultado esperado:*
```text
Export list for 192.168.0.105:
/srv/share *
```

#### 2. Montar en la máquina cliente:
```bash
sudo mkdir -p /mnt/nfs_test
sudo mount -t nfs 192.168.0.105:/srv/share /mnt/nfs_test
```

#### 3. Probar sincronización entre protocolos:
```bash
# Crear un archivo por NFS
sudo touch /mnt/nfs_test/prueba_nfs.txt

# Verificar que es visible en el sistema
ls -la /mnt/nfs_test
```

Al revisar en **Filebrowser** o **Samba**, el archivo `prueba_nfs.txt` estará disponible de manera inmediata.

#### 4. Desmontar al finalizar:
```bash
sudo umount /mnt/nfs_test
```

---

## 6. Resumen de Puertos y Protocolos

| Servicio | Protocolo | Puerto Interno | Puerto Host | Descripción |
|---|---|---|---|---|
| **Filebrowser** | HTTP (TCP) | 80 | 8082 (o `files.sudoers.lan`) | Interfaz Web |
| **Samba** | SMB (TCP) | 445, 139 | 445, 139 | Compartición SMB/CIFS |
| **NFS** | NFS (TCP/UDP) | 2049 | 2049 | Servidor de archivos NFS |
| **rpcbind** | Portmapper (TCP/UDP) | 111 | 111 | Mapeador de puertos RPC |
