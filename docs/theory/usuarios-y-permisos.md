# Usuarios, grupos y permisos en Debian

Este documento cubre la teoría detrás de la gestión de usuarios y sus privilegios. Para los pasos prácticos, ver la guía [Agregar usuarios y asignar privilegios](../guides/agregar-usuarios.md).

## Usuarios en Linux

Cada persona o proceso que interactúa con el sistema lo hace a través de un usuario. Un usuario se identifica por:

- **Nombre de usuario**: la etiqueta legible para humanos.
- **UID** (User ID): el identificador numérico real que usa el kernel. Los UIDs por debajo de 1000 suelen reservarse para cuentas del sistema; los usuarios humanos normalmente empiezan en 1000.
- **Grupo principal (GID)**: todo usuario pertenece a al menos un grupo.
- **Shell**: el programa que se ejecuta al iniciar sesión (por ejemplo `/bin/bash`). Un usuario de servicio suele tener `/usr/sbin/nologin` para impedir inicios de sesión interactivos.

Los usuarios locales se definen en `/etc/passwd` y las contraseñas (como hashes) en `/etc/shadow`, que solo puede leer root.

## Grupos

Un grupo agrupa usuarios para otorgarles permisos comunes. Los grupos se definen en `/etc/group`.

- **Grupo principal**: el grupo asignado por defecto al usuario. Los archivos que crea suelen pertenecer a este grupo.
- **Grupos secundarios**: grupos adicionales a los que pertenece el usuario. Aquí es donde se otorgan privilegios especiales, por ejemplo pertenecer al grupo `sudo` permite ejecutar comandos como root.

Ver los grupos de un usuario:

```bash
id <usuario>
groups <usuario>
```

## El modelo de permisos: usuario, grupo y otros

Cada archivo y directorio del sistema tiene asociados:

- Un **usuario propietario** (u).
- Un **grupo propietario** (g).
- Un conjunto de permisos para **otros** (o): cualquier otro usuario del sistema.

Para cada una de esas tres categorías existen tres permisos:

| Permiso | Archivo | Directorio |
|---|---|---|
| **Lectura (r = 4)** | Ver el contenido | Listar los archivos que contiene |
| **Escritura (w = 2)** | Modificar el contenido | Crear, borrar o renombrar archivos dentro |
| **Ejecución (x = 1)** | Ejecutarlo como programa | Entrar a él (`cd`) y atravesarlo |

Notar que en directorios el significado cambia: `x` no significa "ejecutar" sino "atravesar". Un directorio con `r` pero sin `x` permite listar nombres pero no acceder a lo que hay dentro.

## Permisos numéricos (octales): de dónde salen 750, 644, etc.

Cada permiso vale un número: lectura = 4, escritura = 2, ejecución = 1. El permiso de una categoría es la suma de sus valores:

| Valor | Permisos | Significado |
|---|---|---|
| 7 | 4+2+1 | rwx — leer, escribir y ejecutar |
| 6 | 4+2 | rw- — leer y escribir |
| 5 | 4+1 | r-x — leer y ejecutar |
| 4 | 4 | r-- — solo lectura |
| 0 | 0 | --- — ningún permiso |

Un modo como **750** se lee como tres dígitos: **propietario-grupo-otros**.

Ejemplo: `chmod 750 archivo`

- **7** → propietario: `rwx` (control total).
- **5** → grupo: `r-x` (puede leer y ejecutar, pero no modificar).
- **0** → otros: `---` (sin acceso alguno).

Es un modo típico para directorios de proyecto compartidos entre un equipo: el dueño administra, el grupo trabaja, y el resto del sistema no ve nada.

Otros modos habituales:

| Modo | Permisos efectivos | Uso típico |
|---|---|---|
| 700 | `rwx------` | Directorio personal o privado del propietario |
| 750 | `rwxr-x---` | Proyecto compartido con un grupo, cerrado a otros |
| 755 | `rwxr-xr-x` | Programas y directorios públicos de solo lectura |
| 644 | `rw-r--r--` | Archivos de configuración y documentos normales |
| 600 | `rw-------` | Archivos privados, como claves SSH |

## Permisos simbólicos

Además de en octal, `chmod` acepta notación simbólica: a quién (`u`, `g`, `o`, `a`), qué operación (`+`, `-`, `=`) y qué permiso (`r`, `w`, `x`).

```bash
chmod u+x script.sh      # el propietario puede ejecutar
chmod g-w archivo        # el grupo pierde escritura
chmod o=r archivo        # otros quedan en solo lectura
```

`750` equivale a `u=rwx,g=rx,o=`.

## Escalada de privilegios: sudo y su

Un usuario normal no puede administrar el sistema. Para tareas administrativas existen dos mecanismos:

- **`su`**: cambia de usuario por completo (por defecto a root) pidiendo la contraseña **de root**. La sesión entera queda con esa identidad hasta salir.
- **`sudo`**: ejecuta un comando puntual con privilegios de otro usuario (por defecto root) pidiendo la contraseña **del propio usuario**. Quién puede usar `sudo` y qué puede hacer está definido en `/etc/sudoers` y los archivos de `/etc/sudoers.d/`; en Debian, lo normal es que pertenezcas al grupo `sudo`.

Ventajas de `sudo` sobre usar la cuenta root directamente:

- No hace falta compartir ni conocer la contraseña de root.
- Cada comando queda registrado en los logs con el usuario que lo ejecutó (`/var/log/auth.log`).
- Se puede limitar con precisión qué comandos puede ejecutar cada usuario o grupo.

Por eso la práctica recomendada en Debian es deshabilitar el inicio de sesión directo de root y administrar mediante usuarios con privilegios `sudo`.

Ver los privilegios `sudo` vigentes:

```bash
sudo -l
```

## Usuarios de sistema vs usuarios humanos

- **Usuarios humanos**: tienen shell, home y contraseña; inician sesión.
- **Usuarios de sistema**: existen para que un servicio (por ejemplo un daemon) corra con una identidad propia y limitada. Suelen tener UID por debajo de 1000, sin shell de inicio de sesión y a veces sin home. Si el servicio se ve comprometido, el atacante queda confinado a los permisos de ese usuario y no obtiene root.

En Debian se crean con `adduser --system` o `useradd --system`.

## Cómo se relaciona todo con la seguridad

- **Mínimo privilegio**: cada usuario y servicio debe tener solo los permisos que necesita. Nada que corre como root si puede correr como usuario normal.
- **Permisos de archivos**: modos como `750` o `640` en directorios de servicio evitan que otros usuarios del sistema lean datos sensibles.
- **Grupos como unidades de privilegio**: otorgar acceso por grupos (por ejemplo un grupo `deploy` con acceso al directorio de la aplicación) escala mucho mejor que ajustar permisos usuario por usuario.
- **Auditoría**: saber qué usuario ejecutó qué es esencial; de ahí la importancia de `sudo` con logs y de no compartir cuentas.
