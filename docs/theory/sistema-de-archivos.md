# Jerarquía del sistema de archivos en Linux

Este documento explica por qué existe cada carpeta en la raíz `/` de un sistema Debian y qué se guarda en cada una. Entender esta estructura es la base para saber dónde van las configuraciones, los logs y los datos de un servidor. Para los pasos prácticos de usuarios y permisos sobre estos directorios, ver [Usuarios, grupos y permisos](./usuarios-y-permisos.md).

## ¿Por qué existe esta jerarquía?

Linux sigue el **FHS** (Filesystem Hierarchy Standard), un estándar que define qué va en cada directorio. No es caprichoso: la separación responde a preguntas prácticas que un administrador se hace todos los días:

- **¿Qué es estático y qué cambia?** `/usr` apenas cambia (solo con actualizaciones); `/var` y `/etc` cambian con el uso y la configuración. Esto permite montar `/usr` de solo lectura o decidir qué respaldar.
- **¿Qué se puede compartir entre máquinas?** `/usr` y `/opt` son iguales en servidores similares; `/etc` y `/var` son únicos de cada máquina.
- **¿Qué puede crecer hasta llenar el disco?** Logs y colas crecen sin control (`/var`), por eso a menudo vive en su propia partición para que no bloqueen el resto del sistema.
- **¿Qué desaparece al reiniciar?** Nada en `/tmp` ni `/run` debe sobrevivir a un reinicio.

Conocer el propósito de cada carpeta evita errores comunes: guardar datos en `/usr` (se pierden al reinstalar), respaldar `/proc` (no tiene sentido, es virtual) o poner binarios propios en `/bin` (les toca en `/usr/local/bin`).

## Los directorios de la raíz

### `/` — la raíz

Todo el árbol de archivos parte de aquí. Es el único directorio que necesariamente debe existir para arrancar el sistema. La raíz contiene las carpetas que el sistema necesita en el arranque más temprano; lo que no es esencial para bootear puede vivir en particiones montadas después.

### `/bin` y `/sbin` — binarios esenciales

Comandos que deben funcionar incluso en modo monousuario o de rescate: `ls`, `cp`, `cat`, `mount` (`/bin`), y los administrativos como `ip`, `reboot`, `fsck` (`/sbin`, "system binaries").

> **Nota sobre Debian moderno:** desde Debian 10, `/bin`, `/sbin` y `/lib` son enlaces simbólicos a sus equivalentes dentro de `/usr` (`/bin` → `/usr/bin`). Se mantiene la estructura por compatibilidad. Por eso hoy en día prácticamente todos los binarios viven en `/usr/bin`.

### `/boot` — arranque del sistema

El kernel (`vmlinuz-*`), el initramfs y los archivos del gestor de arranque (GRUB). Es lo primero que se carga al encender la máquina. Si `/boot` se llena (pasa al acumular kernels viejos), las actualizaciones fallan.

### `/dev` — dispositivos

Todo dispositivo se representa como un archivo: discos (`/dev/sda`, `/dev/nvme0n1`), terminales (`/dev/tty`), `null` y `random`. No son archivos reales en disco: el kernel los genera dinámicamente (udev). Aquí se ve por qué "en Linux todo es un archivo".

### `/etc` — configuración del sistema

Toda la configuración del sistema y de los servicios: `/etc/ssh/sshd_config`, `/etc/fstab`, `/etc/network/`, `/etc/apt/`, `/etc/sudoers`. El nombre históricamente venía de "etcetera", pero hoy tiene un propósito claro: **configuración editable por humanos, sin binarios ni datos**.

Es el directorio más importante de respaldar en un servidor: describe cómo está configurada la máquina. Buena práctica: versionarlo con git o incluirlo en el backup.

### `/home` — datos de usuarios humanos

Un directorio por usuario (`/home/sofia`) con sus archivos y configuraciones personales (los archivos ocultos tipo `.bashrc`). Debe poder montarse en partición o disco aparte: permite reinstalar el sistema sin perder datos de usuarios, y aplicar cuotas de disco.

### `/root` — home del administrador

El home de root **no** está en `/home` sino directamente en la raíz, y es así a propósito: si `/home` es una partición separada y falla el montaje, root debe poder iniciar sesión de todos modos para arreglar el sistema.

### `/lib`, `/lib64` — bibliotecas esenciales

Las bibliotecas compartidas (`.so`) que necesitan los binarios de `/bin` y `/sbin` para arrancar, y los módulos del kernel (`/lib/modules`). Hoy también es un enlace a `/usr/lib`.

### `/media` y `/mnt` — puntos de montaje

- `/mnt`: punto de montaje temporal para montajes manuales del administrador (un disco externo por un rato, una ISO).
- `/media`: donde el entorno de escritorio monta automáticamente dispositivos removibles (`/media/usuario/usb`), con subdirectorios por dispositivo.

La diferencia es quién monta: manual (`/mnt`) vs automático (`/media`).

### `/opt` — software de terceros

Software "opcional" instalado por paquetes que no vienen de los repositorios de Debian: cada aplicación en su propio subdirectorio (`/opt/google/chrome`, `/opt/teamspeak`). Se usa para lo que no se integra con el sistema de paquetes y quiere vivir aislado y completo en una carpeta.

### `/proc` — información del kernel (virtual)

Sistema de archivos virtual generado por el kernel en tiempo real: `/proc/cpuinfo`, `/proc/meminfo`, y por proceso `/proc/<pid>/`. No ocupa disco; leerlo es consultar el estado vivo del kernel y de cada proceso. Herramientas como `top` y `ps` leen de aquí.

### `/run` — datos de runtime (virtual)

Datos que los servicios escriben mientras el sistema corre: PIDs (`/run/sshd.pid`), sockets, archivos de lock. Es un tmpfs (en RAM): se vacía en cada arranque, y existe justamente porque escribir esto en disco causaba problemas de arranque en el diseño viejo de `/var/run`.

### `/srv` — datos servidos por servicios

Datos que el sistema **sirve** a otros: `/srv/www` para un sitio web, `/srv/ftp` para archivos compartidos. Su uso no es obligatorio y muchas distribuciones usan `/var/www` por costumbre, pero el estándar lo reserva para esto.

### `/sys` — interfaz con el kernel (virtual)

Como `/proc`, es virtual (sysfs): expone dispositivos y drivers detectados (`/sys/class/net/` para las interfaces de red). Permite leer e incluso cambiar parámetros del kernel en caliente, como el forwarding de paquetes: `/proc/sys/net/ipv4/ip_forward` y su equivalente en sysctl.

### `/tmp` — archivos temporales

Rascacielos de trabajo para cualquier programa y usuario: se borra al reiniciar (por defecto en Debian con tmpfiles.d). Permisos especiales `1777` (sticky bit): cualquiera puede escribir, pero nadie puede borrar archivos de otros. Por seguridad, en servidores endurecidos se monta con `noexec,nosuid`.

### `/usr` — software del sistema operativo

El corazón del software instalado: la mayoría de binarios (`/usr/bin`), bibliotecas (`/usr/lib`), cabeceras de desarrollo, documentación y datos compartidos (`/usr/share`). "usr" no es "user": viene de "UNIX System Resources". Contiene lo que viene de los paquetes de Debian y es compartible y mayormente estático (solo cambia con `apt upgrade`).

- `/usr/local`: lo instalado **manualmente** por el administrador, fuera del sistema de paquetes. `make install` cae aquí (`/usr/local/bin`, `/usr/local/lib`). Esta separación permite saber qué instaló apt y qué instalaste tú.
- `/usr/share`: datos independientes de la arquitectura: documentación (`man`), fuentes, iconos.

### `/var` — datos variables

Todo lo que **cambia** durante la operación normal del sistema:

- `/var/log`: los logs del sistema y de los servicios (`syslog`, `auth.log`, `nginx/`). El primer lugar donde mirar cuando algo falla.
- `/var/lib`: estado persistente de servicios y gestores de paquetes (bases de datos de `apt`/`dpkg`, datos de Docker en `/var/lib/docker`).
- `/var/cache`: cachés regenerables de paquetes descargados, etc.
- `/var/spool`: colas de trabajo pendiente (correo por enviar, trabajos de impresión).
- `/var/tmp`: temporales que **deben** sobrevivir un reinicio (a diferencia de `/tmp`).

Es el directorio que crece con el tiempo y el que merece monitoreo de espacio en disco (logs sin rotar llenan discos).

## Resumen rápido

| Directorio | Contiene | ¿Sobrevive a un reinicio? |
|---|---|---|
| `/bin`, `/sbin` | Binarios esenciales (enlaces a `/usr`) | Sí |
| `/boot` | Kernel y gestor de arranque | Sí |
| `/dev` | Dispositivos (virtual) | Se regenera |
| `/etc` | Configuración del sistema | Sí |
| `/home` | Datos de usuarios | Sí |
| `/media`, `/mnt` | Puntos de montaje | — |
| `/opt` | Software de terceros | Sí |
| `/proc`, `/sys` | Estado del kernel (virtual) | Se regenera |
| `/root` | Home del administrador | Sí |
| `/run` | Datos de runtime (RAM) | No |
| `/srv` | Datos servidos a otros | Sí |
| `/tmp` | Temporales | No |
| `/usr` | Software del sistema | Sí (estático) |
| `/var` | Logs, estado, cachés | Sí (crece) |

## Por qué le importa a un administrador de servidores

- **Particionado:** separar `/home`, `/var` y `/tmp` en particiones propias evita que un llenado de logs o de datos de usuario bloquee el sistema completo.
- **Backups:** lo esencial a respaldar es `/etc` (configuración), `/home` (usuarios), `/srv` o `/opt` (datos de aplicaciones) y las bases de datos en `/var/lib`. `/usr` se reconstruye reinstalando paquetes; `/proc`, `/sys` y `/run` no se respaldan jamás.
- **Seguridad:** montar `/tmp` con `noexec,nosuid`, revisar permisos con `750` en directorios de servicio (ver [Usuarios, grupos y permisos](./usuarios-y-permisos.md)) y saber que `/var/log/auth.log` registra el uso de `sudo`.
- **Diagnóstico:** un servidor lento o lleno casi siempre se resuelve mirando `/var/log` (qué pasó) y `df -h` (dónde creció, normalmente `/var`).

## Copiar archivos: por qué una copia no es idéntica

Por defecto, **no es una copia exacta**. Aunque el comando `cp` básico transfiere el contenido, los metadatos del archivo resultante sufren modificaciones automáticas:

- **Propietario:** el nuevo archivo pasa a ser de tu propiedad (del usuario que ejecutó `cp`), perdiendo el dueño y grupo originales.
- **Permisos y umask:** `cp` intenta aplicar los permisos originales, pero los filtra a través de tu `umask` (la regla de seguridad predeterminada de tu sesión en Debian, típicamente `022`). Por ejemplo, si el archivo original tenía permisos totales (`777`), la copia probablemente nacerá restringida (`755`).
- **Fechas:** las marcas de tiempo de creación y modificación se actualizan al instante exacto en que ejecutaste el comando.

### Cómo forzar una copia idéntica

Si necesitas que el archivo clonado respete los permisos originales, debes usar banderas específicas:

- **`cp -p archivo copia`**: la bandera `-p` (*preserve*) copia el contenido y mantiene intactos **los permisos exactos y las marcas de tiempo**. *(Nota: para conservar también al usuario propietario original si pertenece a otra cuenta, deberás ejecutar este comando con `sudo`.)*
- **`cp -a carpeta copia`**: la bandera `-a` (*archive*) hace exactamente lo mismo que `-p`, pero de forma recursiva. Es la opción estándar cuando necesitas clonar proyectos o directorios enteros preservando absolutamente todos los metadatos, permisos y enlaces simbólicos sin alterarlos.

## Referencias

- Especificación FHS: <https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html>
- `man hier` — descripción de la jerarquía incluida en el propio sistema
- `man file-hierarchy` — versión systemd de la misma descripción
