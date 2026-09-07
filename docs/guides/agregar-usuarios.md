# Agregar usuarios y asignar privilegios

## Objetivo

Crear usuarios en un servidor Debian y otorgarles distintos niveles de privilegio: administración completa con `sudo`, acceso restringido por grupos, o cuentas de servicio sin inicio de sesión interactivo.

## Requisitos previos

- Servidor Debian instalado y accesible (ver [Instalación de Debian en el servidor](./instalacion-debian.md)).
- Acceso con un usuario que tenga privilegios de administración (`sudo`).
- Tener claro qué usuarios crear y qué deberían poder hacer cada uno. La base teórica está en [Usuarios, grupos y permisos](../theory/usuarios-y-permisos.md).

## Pasos

### 1. Crear un usuario normal

```bash
sudo adduser sofia
```

`adduser` crea el home, asigna grupo principal y pide la contraseña de forma interactiva.

Verificar el resultado:

```bash
id sofia
```

### 2. Dar privilegios de administración (grupo sudo)

Agregando al usuario al grupo `sudo` puede ejecutar cualquier comando como root con su propia contraseña:

```bash
sudo usermod -aG sudo sofia
```

> `-aG` es *append to Group*: agrega sin quitar los grupos que ya tenía. Olvidar `-a` reemplaza todos los grupos secundarios del usuario.

Verificar:

```bash
groups sofia
```

El cambio toma efecto en la **próxima sesión** del usuario; si tiene una abierta, debe cerrarla y volver a entrar (o ejecutar `newgrp sudo`).

Probar que puede escalar privilegios:

```bash
su - sofia
sudo -l        # lista qué comandos puede ejecutar con sudo
```

### 3. Dar privilegios parciales con un grupo compartido

Para que un usuario pueda trabajar en un área específica sin ser administrador, se usa un grupo con permisos sobre ese directorio. Ejemplo: un grupo `deploy` para gestionar la aplicación.

```bash
# Crear el grupo
sudo groupadd deploy

# Crear el directorio de trabajo y asignarlo al grupo
sudo mkdir -p /opt/miapp
sudo chgrp deploy /opt/miapp
sudo chmod 750 /opt/miapp
```

Con `750`, el propietario tiene control total (`rwx`), el grupo `deploy` puede leer y ejecutar/entrar (`r-x`), y el resto del sistema no ve nada (`---`). Ver la teoría de permisos numéricos en [Usuarios, grupos y permisos](../theory/usuarios-y-permisos.md).

Agregar usuarios al grupo:

```bash
sudo usermod -aG deploy sofia
```

Verificar:

```bash
su - sofia
ls -ld /opt/miapp     # debe mostrar drwxr-x--- ... deploy
touch /opt/miapp/test # debe funcionar solo tras re-iniciar sesión
```

Para que los archivos nuevos creados dentro hereden el grupo en lugar del grupo principal del usuario:

```bash
sudo chmod 2750 /opt/miapp    # el 2 inicial activa el bit setgid
```

### 4. Crear un usuario de sistema para un servicio

Los servicios no deben correr como root ni como un usuario humano. Se les crea una identidad propia sin shell:

```bash
sudo adduser --system --group --no-create-home miapp
```

Verificar:

```bash
id miapp    # UID < 1000 y shell /usr/sbin/nologin
```

Luego se asigna la propiedad de los archivos del servicio a ese usuario:

```bash
sudo chown -R miapp:miapp /opt/miapp
sudo chmod 750 /opt/miapp
```

### 5. Limitar sudo a comandos específicos (opcional)

Si un usuario necesita ejecutar solo algunos comandos como root (por ejemplo reiniciar un servicio), no debe estar en el grupo `sudo`. Se le crea una regla dedicada:

```bash
sudo visudo -f /etc/sudoers.d/sofia
```

Contenido:

```text
sofia ALL=(root) NOPASSWD: /usr/bin/systemctl restart miapp, /usr/bin/systemctl status miapp
```

> Siempre editar sudoers con `visudo`, que valida la sintaxis antes de guardar. Un error de sintaxis puede dejar el sistema sin posibilidad de escalar privilegios.

Verificar:

```bash
su - sofia
sudo systemctl restart miapp   # funciona
sudo apt update                # denegado
```

## Verificación

- `id <usuario>` muestra los grupos esperados para cada usuario.
- `sudo -l` como usuario admin lista permisos completos; como usuario restringido, solo los comandos definidos en `/etc/sudoers.d/`.
- `ls -l` sobre los directorios compartidos muestra los permisos asignados (por ejemplo `drwxr-x---`).
- Los usuarios de sistema aparecen con UID < 1000 y sin shell de inicio de sesión.
- Queda documentado qué usuario tiene qué privilegios y por qué.

## Referencias

- Teoría: [Usuarios, grupos y permisos en Debian](../theory/usuarios-y-permisos.md)
- `man adduser`, `man usermod`, `man chmod`, `man sudoers`, `man visudo`
