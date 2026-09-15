# Documentación Final — Servidor de Archivos Multi-Protocolo (TSO-II)

> **Asignatura:** Taller de Sistemas Operativos II (TSO-II)
> **Equipo:** Nicolás · Joaquín · David
> **Dominio de red:** `sudoers.lan`
> **Fecha:** Septiembre 2026

---

## 1. Introducción

En toda red empresarial, el servidor de archivos constituye uno de los pilares fundamentales de la infraestructura de servicios. Su función principal es centralizar el almacenamiento de documentos, facilitar la colaboración entre usuarios y garantizar un acceso controlado a los recursos compartidos mediante políticas de permisos y autenticación.

En el contexto del proyecto **TSO-II**, el servidor de archivos cumple un rol estratégico: ofrece un punto de acceso unificado a una carpeta compartida (`/srv/share`) dentro de la red local `sudoers.lan`, permitiendo que múltiples clientes —independientemente de su sistema operativo— puedan leer, escribir y administrar archivos de forma centralizada.

A diferencia de una implementación tradicional basada en un único protocolo, el servidor de archivos del proyecto TSO-II fue diseñado como un servicio **multi-protocolo**, integrando tres tecnologías de compartición de archivos en un solo contenedor Docker:

| Protocolo | Tecnología | Caso de uso principal |
|---|---|---|
| **SMB/CIFS** | Samba | Clientes Windows, gestores de archivos gráficos (Thunar, Nautilus, Dolphin) y macOS |
| **NFS** | NFS Kernel Server | Montaje de alto rendimiento en estaciones Linux/Unix |
| **HTTP (Web)** | Filebrowser | Acceso gráfico desde cualquier navegador moderno, sin instalación de software adicional |

Esta arquitectura garantiza **compatibilidad universal**: cualquier dispositivo de la red local puede conectarse al servidor utilizando el protocolo que mejor se adapte a sus capacidades, mientras que todos los protocolos operan sobre el mismo directorio de datos (`/srv/share`), asegurando consistencia total.

El presente documento detalla la arquitectura, el proceso de instalación y configuración, las pruebas realizadas y las conclusiones obtenidas durante la implementación de este servicio dentro del taller de administración de sistemas.

---

## 2. Objetivos del Trabajo

### 2.1 Objetivo General

Implementar, configurar y documentar un servidor de archivos multi-protocolo containerizado que permita a los usuarios de la red `sudoers.lan` compartir y administrar archivos de manera centralizada, segura y eficiente.

### 2.2 Objetivos Específicos

1. **Comprender la arquitectura del servicio de archivos compartidos:** Estudiar los protocolos SMB/CIFS, NFS y la interfaz web Filebrowser, entendiendo sus diferencias, ventajas y casos de uso dentro de una red empresarial.

2. **Implementar un servidor de archivos multi-protocolo en un contenedor Docker:** Construir una imagen basada en Debian que integre Samba, NFS Kernel Server y Filebrowser en un único servicio orquestado.

3. **Configurar carpetas compartidas con permisos y políticas de acceso:** Definir recursos compartidos con autenticación de usuario, máscaras de permisos y exportaciones NFS controladas.

4. **Realizar pruebas de acceso desde múltiples clientes:** Verificar la conectividad y el correcto funcionamiento del servicio desde exploradores de archivos gráficos (SMB), terminales (NFS, `smbclient`) y navegadores web (Filebrowser).

5. **Documentar el proceso completo de instalación y configuración:** Registrar cada paso con comandos, archivos de configuración, capturas de pantalla y justificación técnica.

---

## 3. Alcance y Límites

### 3.1 Configuraciones Realizadas

- Instalación y configuración del rol de servidor de archivos dentro de un contenedor Docker basado en `debian:bookworm-slim`.
- Configuración del protocolo **SMB/CIFS** mediante Samba con autenticación de usuario (`security = user`).
- Configuración del protocolo **NFS** mediante `nfs-kernel-server` con exportación del directorio compartido.
- Configuración de la interfaz web **Filebrowser** con base de datos SQLite y creación automática de usuarios.
- Creación automática de usuarios del sistema, usuarios Samba y usuarios Filebrowser mediante script de aprovisionamiento (`entrypoint.sh`).
- Asignación de permisos sobre el directorio compartido (`/srv/share`) con máscaras de creación (`create mask`, `directory mask`) que garantizan interoperabilidad entre protocolos.
- Integración del servicio con el ecosistema Docker del proyecto mediante `docker-compose.yml`, volúmenes persistentes y red interna `tso-net`.
- Pruebas de acceso desde clientes mediante SMB (explorador gráfico y `smbclient`), NFS (montaje manual y automático) y Filebrowser (navegador web).

### 3.2 Aspectos No Abordados

- **Seguridad avanzada:** No se implementó cifrado TLS/SSL para SMB ni autenticación Kerberos. Las credenciales se transmiten en texto plano dentro de la red local de laboratorio.
- **Integración con dominios externos:** No se configuró integración con Active Directory ni con controladores de dominio Windows. Samba opera como servidor independiente (`standalone server`).
- **Cuotas de disco:** No se establecieron límites de almacenamiento por usuario.
- **Auditoría de accesos:** No se configuraron registros detallados de acceso a archivos por usuario.
- **Alta disponibilidad:** No se implementó replicación ni redundancia del servicio de archivos.

### 3.3 Entorno Utilizado

| Componente | Detalle |
|---|---|
| **Sistema operativo host** | Debian (servidor físico en red local) |
| **Plataforma de contenedores** | Docker + Docker Compose |
| **Imagen base del contenedor** | `debian:bookworm-slim` |
| **Red del proyecto** | `tso-net` (red bridge de Docker) |
| **Dominio** | `sudoers.lan` |
| **Nombre del contenedor** | `tso-files` |
| **Clientes de prueba** | Linux (Arch Linux, Ubuntu), navegadores web |

---

## 4. Desarrollo del Trabajo

### 4.1 Instalación de Roles y Características Necesarias

#### 4.1.1 Construcción de la Imagen Docker (`Dockerfile`)

La imagen del servidor de archivos se construye a partir de `debian:bookworm-slim` e instala todos los paquetes necesarios para los tres protocolos:

```dockerfile
# Servidor de archivos multi-protocolo: Samba (SMB), Filebrowser (Web) y NFS
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends samba nfs-kernel-server rpcbind curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Instalar Filebrowser
RUN curl -fsSL https://github.com/filebrowser/filebrowser/releases/latest/download/linux-amd64-filebrowser.tar.gz | tar -xzv -C /usr/local/bin filebrowser

COPY smb.conf /etc/samba/smb.conf
COPY exports /etc/exports
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /srv/share /database /var/lib/nfs/v4recovery && chmod -R 777 /srv/share

EXPOSE 445 139 80 2049 111

ENTRYPOINT ["/entrypoint.sh"]
```

**Justificación técnica:**

| Paquete | Función |
|---|---|
| `samba` | Proporciona el daemon `smbd` para compartición de archivos vía SMB/CIFS |
| `nfs-kernel-server` | Provee los daemons `rpc.nfsd` y `rpc.mountd` para el servicio NFS del kernel |
| `rpcbind` | Mapeador de puertos RPC, requerido por NFS para registrar servicios |
| `curl` y `ca-certificates` | Necesarios para descargar el binario de Filebrowser desde GitHub |
| `filebrowser` | Explorador de archivos web autónomo con interfaz gráfica moderna |

**Puertos expuestos:**

| Puerto | Protocolo | Servicio |
|---|---|---|
| `445/tcp` | SMB | Samba (puerto principal) |
| `139/tcp` | NetBIOS over TCP | Samba (compatibilidad legacy) |
| `80/tcp` | HTTP | Filebrowser (interfaz web) |
| `2049/tcp+udp` | NFS | Servidor NFS principal |
| `111/tcp+udp` | Portmapper | `rpcbind` para NFS |

#### 4.1.2 Estructura de Archivos del Servicio

```text
services/files/
├── Dockerfile        # Definición de la imagen y empaquetado de paquetes
├── smb.conf          # Configuración de Samba (SMB)
├── exports           # Tabla de exportaciones NFS
├── entrypoint.sh     # Script de inicio, creación de usuarios y arranque de daemons
├── data/             # Directorio de datos compartidos (montado como volumen)
└── README.md         # Documentación de uso rápido
```

#### 4.1.3 Declaración del Servicio en `docker-compose.yml`

El servicio `files` se integra al ecosistema completo del proyecto TSO-II a través del archivo `docker-compose.yml`:

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

**Justificación de decisiones clave:**

- **`privileged: true`:** Es **indispensable** para que el contenedor pueda interactuar con el kernel del host y ejecutar los daemons de NFS (`rpc.nfsd`, `rpc.mountd`). Sin este flag, el servicio NFS no puede funcionar dentro del contenedor.
- **Volumen `${FILES_SHARE_DIR}:/srv/share`:** Mapea el directorio local de datos al punto de compartición dentro del contenedor. Esto permite que los archivos persistan aunque el contenedor se destruya y recree.
- **Volumen `files_db:/database`:** Volumen con nombre de Docker para la base de datos SQLite de Filebrowser, garantizando que las cuentas de usuario y configuraciones persistan entre reinicios.
- **Red `tso-net`:** Conecta el servicio de archivos a la red bridge compartida del proyecto, permitiendo comunicación interna con otros servicios como `tso-web` (Nginx).

---

### 4.2 Configuración del Servidor de Archivos por Protocolo

#### 4.2.1 Configuración de Samba (SMB/CIFS) — `smb.conf`

Samba es el protocolo principal para la compartición de archivos con clientes que utilizan exploradores gráficos (Windows, Thunar, Nautilus, Dolphin).

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

**Explicación de cada directiva:**

**Sección `[global]`:**

| Directiva | Valor | Justificación |
|---|---|---|
| `workgroup` | `WORKGROUP` | Grupo de trabajo estándar, compatible con la configuración por defecto de Windows |
| `security` | `user` | Requiere que el cliente se autentique con usuario y contraseña registrados en Samba |
| `map to guest` | `bad user` | Los intentos de conexión con usuarios no válidos se rechazan (no se les da acceso como invitado) |
| `server role` | `standalone server` | El servidor opera de forma independiente, sin integración con Active Directory |
| `log file` | `/var/log/samba/log.%m` | Archivo de log separado por máquina cliente (`%m` = nombre de la máquina) |

**Sección `[compartido]` (recurso compartido):**

| Directiva | Valor | Justificación |
|---|---|---|
| `path` | `/srv/share` | Directorio físico que se comparte a través de la red |
| `browseable` | `yes` | El recurso aparece visible al explorar la red |
| `writable` | `yes` | Permite operaciones de escritura (crear, modificar, eliminar archivos) |
| `guest ok` | `no` | **No** se permite acceso anónimo; se requiere autenticación |
| `valid users` | `nicolas joaquin david` | Lista blanca de usuarios autorizados |
| `force user` | `root` | Todas las operaciones de archivo se ejecutan como `root` dentro del contenedor, evitando conflictos de permisos entre protocolos |
| `create mask` / `force create mode` | `0666` | Los archivos creados vía SMB tendrán permisos `rw-rw-rw-` |
| `directory mask` / `force directory mode` | `0777` | Los directorios creados vía SMB tendrán permisos `rwxrwxrwx` |

> **Nota sobre permisos forzados:** Las máscaras `0666` y `0777` son deliberadas. Al operar tres protocolos distintos sobre el mismo directorio, es fundamental que los archivos creados por un protocolo no queden bloqueados para los demás. Si Samba creara archivos con permisos restrictivos (ej. `0600`), un cliente NFS o Filebrowser no podría acceder a ellos.

---

#### 4.2.2 Configuración de NFS (Network File System) — `exports`

NFS proporciona acceso directo de alto rendimiento al sistema de archivos para clientes Linux/Unix, con montaje transparente a nivel de kernel.

```text
# Configuracion de exportaciones NFS - Servidor TSO-II
# Compartir /srv/share con todos los clientes de la red local
/srv/share *(rw,sync,no_subtree_check,no_root_squash,fsid=0)
```

**Explicación de cada opción de exportación:**

| Opción | Justificación |
|---|---|
| `/srv/share` | Directorio raíz exportado, el mismo que utilizan Samba y Filebrowser |
| `*` | Permite la conexión desde cualquier IP de la red local (sin restricción por host) |
| `rw` | Acceso de lectura y escritura |
| `sync` | Las escrituras se confirman en disco antes de responder al cliente, priorizando la **integridad de datos** sobre la velocidad |
| `no_subtree_check` | Deshabilita la verificación de subárboles, mejorando el rendimiento y evitando problemas cuando se renombran archivos |
| `no_root_squash` | Permite que las operaciones realizadas como `root` en el cliente conserven privilegios de `root` en el servidor. En un entorno de laboratorio, esto simplifica la administración |
| `fsid=0` | Define `/srv/share` como la **raíz del espacio NFSv4**. Los clientes NFSv4 acceden montando `/` en lugar de `/srv/share` |

> **Concepto clave — `fsid=0` en NFSv4:** Cuando se usa NFSv4, la exportación marcada con `fsid=0` actúa como raíz virtual. El cliente monta la ruta remota `/` y el servidor la traduce internamente a `/srv/share`. Esto significa que el comando de montaje correcto es `mount -t nfs4 servidor:/` y **no** `mount -t nfs4 servidor:/srv/share`.

---

#### 4.2.3 Configuración de Filebrowser (Interfaz Web)

Filebrowser proporciona un explorador de archivos web completo, responsivo y liviano, accesible desde cualquier navegador sin instalar software adicional en el cliente.

**Inicialización en `entrypoint.sh`:**

```bash
DB_FILE="/database/filebrowser.db"

if [ ! -f "$DB_FILE" ]; then
    echo ">>> Inicializando Filebrowser DB..."
    filebrowser config init --database "$DB_FILE"
    filebrowser config set --database "$DB_FILE" \
        --root /srv/share \
        --address 0.0.0.0 \
        --port 80 \
        --auth.method json \
        --minimumPasswordLength 1

    for u in $USERS; do
        filebrowser users add "$u" "$PASS" --perm.admin=true --database "$DB_FILE"
    done
else
    for u in $USERS; do
        filebrowser users update "$u" --password "$PASS" --perm.admin=true --database "$DB_FILE" 2>/dev/null || \
        filebrowser users add "$u" "$PASS" --perm.admin=true --database "$DB_FILE" 2>/dev/null || true
    done
fi
```

**Configuración aplicada:**

| Parámetro | Valor | Justificación |
|---|---|---|
| `--root` | `/srv/share` | El directorio raíz visible en la interfaz web es el mismo compartido por SMB y NFS |
| `--address` | `0.0.0.0` | Escucha en todas las interfaces de red del contenedor |
| `--port` | `80` | Puerto HTTP interno (mapeado al puerto host `8082`) |
| `--auth.method` | `json` | Autenticación por formulario web con usuario y contraseña |
| `--minimumPasswordLength` | `1` | Permite contraseñas cortas (entorno de laboratorio) |
| `--perm.admin=true` | — | Todos los usuarios tienen permisos de administración completos en la interfaz |

**Base de datos:** La configuración y cuentas de usuario se almacenan en una base de datos SQLite ubicada en `/database/filebrowser.db`, respaldada por el volumen persistente `files_db`.

**Integración con Nginx:** El servidor web del proyecto (`tso-web`) redirige las solicitudes HTTP dirigidas a `http://files.sudoers.lan` hacia el contenedor `tso-files:80`, proporcionando un acceso limpio mediante nombre de dominio.

---

### 4.3 Creación y Administración de Usuarios — `entrypoint.sh`

El script `entrypoint.sh` actúa como **orquestador** de toda la inicialización del contenedor. Uno de sus roles principales es la creación y sincronización automática de usuarios en los tres sistemas:

```bash
#!/bin/bash
set -e

mkdir -p /srv/share /database /var/lib/nfs/v4recovery /run/samba
chmod -R 777 /srv/share

USERS="nicolas joaquin david"
PASS="sudoers123456"

# Crear usuarios Linux y registrar contraseñas Samba
for u in $USERS; do
    if ! id "$u" > /dev/null 2>&1; then
        useradd -M -g users -s /usr/sbin/nologin "$u"
    fi
    (echo "$PASS"; echo "$PASS") | smbpasswd -a -s "$u"
done
```

**Flujo de aprovisionamiento de usuarios:**

1. **Usuarios del sistema Linux:** Se crean con `useradd -M -g users -s /usr/sbin/nologin`. La opción `-M` evita la creación de un directorio home (innecesario en un contenedor) y `-s /usr/sbin/nologin` impide el inicio de sesión interactivo por seguridad.

2. **Usuarios de Samba:** Se registran mediante `smbpasswd -a -s`, que agrega el usuario a la base de datos de contraseñas de Samba de forma no interactiva (la contraseña se pasa por stdin).

3. **Usuarios de Filebrowser:** Se crean o actualizan mediante los comandos `filebrowser users add` y `filebrowser users update`, con permisos de administrador (`--perm.admin=true`).

**Credenciales unificadas:**

| Campo | Valor |
|---|---|
| **Usuarios** | `nicolas`, `joaquin`, `david` |
| **Contraseña** | `sudoers123456` |
| **Workgroup (Samba)** | `WORKGROUP` |

> Las mismas credenciales funcionan para los tres protocolos (SMB, Filebrowser web). NFS no utiliza autenticación por usuario/contraseña, sino por host/IP.

---

### 4.4 Arranque de Servicios — Secuencia de Inicio

El `entrypoint.sh` inicia los tres servicios en el siguiente orden:

```bash
# 1. Arrancar servicios NFS (kernel)
echo ">>> Iniciando servicios NFS..."
rpcbind 2>/dev/null || true
exportfs -arv 2>/dev/null || true
rpc.nfsd 8 2>/dev/null || true
rpc.mountd 2>/dev/null || true

# 2. Arrancar Filebrowser en segundo plano
echo ">>> Iniciando Filebrowser (Web) en el puerto 80..."
filebrowser --database "$DB_FILE" --root /srv/share --address 0.0.0.0 --port 80 &

# 3. Arrancar Samba en primer plano (mantiene el contenedor activo)
echo ">>> Iniciando Samba (SMB) para Thunar / Windows..."
exec /usr/sbin/smbd --foreground --no-process-group
```

**Justificación de la secuencia:**

| Paso | Servicio | Modo | Razón |
|---|---|---|---|
| 1 | `rpcbind` | Daemon (background) | Registra los servicios RPC necesarios para NFS |
| 2 | `exportfs -arv` | Comando único | Reexporta todas las entradas del archivo `/etc/exports` |
| 3 | `rpc.nfsd 8` | Daemon (background) | Inicia 8 hilos del servidor NFS del kernel |
| 4 | `rpc.mountd` | Daemon (background) | Maneja las solicitudes de montaje NFS de los clientes |
| 5 | `filebrowser` | Background (`&`) | Sirve la interfaz web en el puerto 80 |
| 6 | `smbd --foreground` | Foreground (`exec`) | Se ejecuta en primer plano con `exec` para que sea el proceso PID 1 del contenedor; si Samba se detiene, el contenedor se detiene |

---

### 4.5 Pruebas de Acceso desde Clientes

#### 4.5.1 Prueba de Conexión Vía Samba (SMB/CIFS)

**A. Desde Explorador Gráfico (Thunar / Nautilus / Dolphin / Explorador de Windows):**

1. Abrir el gestor de archivos y presionar `Ctrl + L` para habilitar la barra de direcciones.
2. Escribir la URL del recurso:
   ```
   smb://files.sudoers.lan/compartido
   ```
   O alternativamente con la IP directa:
   ```
   smb://192.168.0.105/compartido
   ```
3. En la ventana emergente de autenticación, ingresar:
   - **Usuario:** `david` (o `nicolas` / `joaquin`)
   - **Dominio:** `WORKGROUP`
   - **Contraseña:** `sudoers123456`
4. El explorador de archivos muestra el contenido de `/srv/share`. Se pueden crear, modificar, eliminar y arrastrar archivos como si fuera una carpeta local.

**B. Desde Terminal con `smbclient`:**

```bash
smbclient //192.168.0.105/compartido -U david
# Solicitará contraseña: sudoers123456
```

Una vez dentro de la sesión `smbclient`, se pueden utilizar comandos como `ls`, `put`, `get`, `mkdir`, `rm` para operar sobre los archivos compartidos.

---

#### 4.5.2 Prueba de Conexión Vía Web (Filebrowser)

1. Abrir cualquier navegador web e ingresar a la URL:
   - `http://files.sudoers.lan` (a través del proxy Nginx)
   - `http://<IP_DEL_SERVIDOR>:8082` (acceso directo al puerto mapeado)
2. En la pantalla de inicio de sesión, ingresar:
   - **Usuario:** `david`
   - **Contraseña:** `sudoers123456`
3. La interfaz permite:
   - Navegación gráfica por directorios y archivos.
   - Descarga de archivos individuales y en lotes (ZIP).
   - Subida de archivos mediante arrastrar y soltar (*drag & drop*).
   - Reproducción de archivos multimedia directamente en el navegador.
   - Edición de archivos de texto desde la interfaz web.

---

#### 4.5.3 Prueba de Conexión y Montaje Vía NFS

NFS no utiliza un formulario de login con usuario/contraseña. La autenticación se realiza a nivel de host/IP y permisos de kernel.

**A. Requisitos en la PC Cliente (Linux):**

```bash
# Arch Linux
sudo pacman -S nfs-utils

# Debian / Ubuntu / Mint
sudo apt install nfs-common
```

**B. Verificación de Exportaciones:**

```bash
# Comprobar que el servidor está exportando correctamente
showmount -e 192.168.0.105
```

Salida esperada:
```
Export list for 192.168.0.105:
/srv/share *
```

**C. Montaje Manual:**

```bash
# 1. Crear el punto de montaje local
sudo mkdir -p /mnt/servidor_archivos

# 2. Montar el sistema NFSv4 apuntando a la raíz (/)
sudo mount -t nfs 192.168.0.105:/ /mnt/servidor_archivos

# O especificando NFSv4 explícitamente:
sudo mount -t nfs4 192.168.0.105:/ /mnt/servidor_archivos
```

> **Importante:** Se monta `/` y **no** `/srv/share` porque la exportación usa `fsid=0`, lo que convierte a `/srv/share` en la raíz virtual del espacio NFSv4.

**D. Montaje Automático en Inicio del Sistema (`/etc/fstab`):**

Para que la carpeta se monte automáticamente cada vez que se enciende la PC cliente, agregar la siguiente línea al archivo `/etc/fstab`:

```text
192.168.0.105:/  /mnt/servidor_archivos  nfs  defaults,_netdev,x-systemd.automount  0  0
```

| Opción | Justificación |
|---|---|
| `defaults` | Opciones de montaje estándar |
| `_netdev` | Indica al sistema que este montaje requiere red, evitando errores si la red aún no está disponible |
| `x-systemd.automount` | Garantiza que el montaje se realice únicamente cuando haya red disponible, evitando retardos en el arranque de la PC |

**E. Desmontaje:**

```bash
sudo umount /mnt/servidor_archivos
```

---

### 4.6 Resumen de Puertos y Protocolos

| Servicio | Protocolo | Puerto Interno | Puerto Host | Descripción |
|---|---|---|---|---|
| **Filebrowser** | HTTP (TCP) | 80 | 8082 (o `files.sudoers.lan`) | Interfaz Web de gestión de archivos |
| **Samba** | SMB (TCP) | 445, 139 | 445, 139 | Compartición de archivos SMB/CIFS |
| **NFS** | NFS (TCP/UDP) | 2049 | 2049 | Servidor de archivos NFS |
| **rpcbind** | Portmapper (TCP/UDP) | 111 | 111 | Mapeador de puertos RPC para NFS |

---

### 4.7 Asignación de Permisos — NTFS vs. Permisos Unix

En un servidor de archivos tradicional sobre Windows Server, los permisos se gestionan mediante dos capas:

- **Permisos NTFS:** Se aplican a nivel del sistema de archivos local (lectura, escritura, modificación, control total).
- **Permisos de recurso compartido:** Se aplican a nivel de red sobre la carpeta compartida.

En el servidor TSO-II, al operar sobre un sistema de archivos Linux (ext4) dentro de un contenedor Docker, se utiliza el equivalente Unix:

| Concepto Windows | Equivalente Unix en TSO-II | Implementación |
|---|---|---|
| Permisos NTFS | Permisos de archivo Unix (`chmod`) | `chmod -R 777 /srv/share` en el `entrypoint.sh` |
| Permisos de recurso compartido (SMB) | Directivas en `smb.conf` | `valid users`, `writable`, `guest ok`, `create mask`, `directory mask` |
| Control de acceso por usuario | `security = user` en Samba | Los usuarios deben autenticarse con credenciales registradas en `smbpasswd` |
| Permisos NFS | Opciones de exportación en `/etc/exports` | `rw`, `no_root_squash`, restricción por IP (`*` = todas) |

**Política de permisos aplicada:**

- El directorio `/srv/share` tiene permisos `777` (lectura, escritura y ejecución para todos los usuarios del sistema).
- Samba fuerza los permisos de creación a `0666` (archivos) y `0777` (directorios), garantizando que los archivos creados por un protocolo sean accesibles por los demás.
- Samba fuerza todas las operaciones bajo el usuario `root` (`force user = root`), eliminando conflictos de propiedad de archivos entre los tres protocolos.
- NFS exporta con `no_root_squash`, permitiendo que el usuario `root` del cliente conserve sus privilegios en el servidor.

---

## 5. Conclusiones

### 5.1 Resultados Obtenidos

- Se logró implementar exitosamente un servidor de archivos multi-protocolo que integra **SMB/CIFS (Samba)**, **NFS** y **Filebrowser (Web)** en un único contenedor Docker.
- Los tres protocolos operan sobre el mismo directorio de datos (`/srv/share`), garantizando **consistencia total**: un archivo creado desde el explorador web de Filebrowser es inmediatamente visible desde un montaje NFS o una conexión Samba, y viceversa.
- El sistema de aprovisionamiento automático de usuarios (`entrypoint.sh`) sincroniza las credenciales en los tres servicios, permitiendo una experiencia de acceso unificada para los usuarios `nicolas`, `joaquin` y `david`.
- Las pruebas de acceso desde clientes Linux (Thunar, `smbclient`, montaje NFS) y navegadores web confirmaron el correcto funcionamiento de todos los protocolos.
- La containerización del servicio permite su despliegue reproducible con un solo comando (`docker compose up -d`).

### 5.2 Dificultades Encontradas

- **NFS dentro de Docker:** La ejecución de `rpc.nfsd` y `rpc.mountd` dentro de un contenedor requiere el flag `privileged: true`, ya que estos daemons interactúan directamente con el kernel del host. Sin este privilegio, el servicio NFS falla silenciosamente.
- **Interoperabilidad de permisos:** Lograr que archivos creados por un protocolo fueran accesibles por los demás requirió una configuración cuidadosa de máscaras de permisos (`create mask`, `force user`, `chmod 777`).
- **NFSv4 y `fsid=0`:** La comprensión del concepto de raíz virtual en NFSv4 fue necesaria para poder montar correctamente el directorio desde los clientes (usar `/` en lugar de `/srv/share`).

### 5.3 Importancia del Servidor de Archivos en la Administración de Sistemas

El servidor de archivos es un servicio esencial en cualquier red empresarial:

- **Centralización:** Permite almacenar documentos, recursos y datos compartidos en un único punto, evitando la dispersión de información en múltiples estaciones de trabajo.
- **Colaboración:** Facilita el trabajo en equipo al permitir que múltiples usuarios accedan y modifiquen los mismos archivos de forma controlada.
- **Control de acceso:** Mediante autenticación y permisos, se garantiza que solo los usuarios autorizados puedan acceder a los recursos compartidos.
- **Respaldo:** Al centralizar los datos, se simplifica la implementación de políticas de respaldo y recuperación ante desastres.
- **Compatibilidad:** Un servidor multi-protocolo como el implementado garantiza que cualquier dispositivo de la red pueda acceder a los archivos, independientemente de su sistema operativo.

### 5.4 Aprendizajes Adquiridos

1. **Containerización de servicios de red complejos:** Se aprendió a integrar múltiples daemons (Samba, NFS, Filebrowser) dentro de un único contenedor Docker, gestionando su ciclo de vida mediante un script de entrada (`entrypoint.sh`).

2. **Protocolos de compartición de archivos:** Se comprendieron las diferencias fundamentales entre SMB/CIFS (orientado a sesión con autenticación de usuario), NFS (orientado a kernel con autenticación por host) y HTTP/Web (acceso universal por navegador).

3. **Gestión de permisos en entornos multi-protocolo:** Se aprendió la importancia de las máscaras de permisos forzados para garantizar la interoperabilidad entre protocolos que operan sobre el mismo directorio.

4. **Infraestructura como código:** Todo el servicio está definido en archivos de configuración versionados (`Dockerfile`, `smb.conf`, `exports`, `entrypoint.sh`, `docker-compose.yml`), lo que permite su reproducción exacta en cualquier entorno.

5. **Automatización del aprovisionamiento:** El script de entrada automatiza la creación de usuarios y la inicialización de servicios, eliminando la necesidad de configuración manual post-despliegue.

---

> **Documento generado para el taller de Sistemas Operativos II (TSO-II) — Proyecto Sudoers**
