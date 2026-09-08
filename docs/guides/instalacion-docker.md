# Instalación de Docker en Debian

## Objetivo

Instalar Docker Engine y Docker Compose en un servidor Debian para poder desplegar los servicios del proyecto de forma aislada y reproducible. La base conceptual está en [Docker en un servidor Debian](../theory/docker.md).

## Requisitos previos

- Servidor Debian instalado y accesible (ver [Instalación de Debian en el servidor](./instalacion-debian.md)).
- Usuario con privilegios de administración (`sudo`).
- Conexión a internet para descargar los paquetes. Si el servidor no tiene internet, ver [Proxy APT y NAT](./proxy-apt-y-nat.md).

> Esta guía sigue la [instalación oficial de Docker Engine en Debian](https://docs.docker.com/engine/install/debian/). El método recomendado es desinstalar cualquier versión anterior y usar el repositorio oficial.

## Pasos

### 1. Desinstalar versiones anteriores (si las hay)

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

Si no había una versión anterior, aparece un aviso de que no hay nada instalado; es normal.

### 2. Preparar el sistema: dependencias y repositorio

Instalar paquetes para que `apt` pueda usar repositorios por HTTPS:

```bash
sudo apt update
sudo apt install ca-certificates curl gnupg
```

Crear el directorio para las claves del repositorio:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

Agregar la clave GPG oficial de Docker:

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

Agregar el repositorio oficial de Docker al fuente de paquetes. Reemplazar `<codename>` con el nombre en clave de la versión de Debian (`bookworm` para Debian 12, `trixie` para Debian 13):

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Se puede verificar el nombre en clave antes:

```bash
. /etc/os-release && echo "$VERSION_CODENAME"
```

### 3. Instalar Docker Engine

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

> `docker-compose-plugin` instala el plugin `docker compose` (sin guion). `docker-buildx-plugin` habilita `docker buildx`.

### 4. Habilitar el servicio y verificar

```bash
sudo systemctl enable --now docker
```

Verificar que el daemon está activo y que el comando responde:

```bash
sudo systemctl status docker
sudo docker version
sudo docker run hello-world
```

El contenedor `hello-world` descarga una imagen mínima y confirma que el motor funciona correctamente.

### 5. Agregar tu usuario al grupo docker (opcional pero recomendado)

Por defecto, `docker` requiere `sudo`. Para no escribir `sudo` en cada comando, se agrega el usuario al grupo `docker`:

```bash
sudo usermod -aG docker $USER
```

El cambio toma efecto en la **próxima sesión**; cerrar y volver a iniciar sesión (o ejecutar `newgrp docker`).

> **Seguridad:** pertenecer al grupo `docker` equivale a tener `root` (puede montar volúmenes y ejecutar código arbitrario). Solo agregar usuarios de confianza.

Verificar sin `sudo`:

```bash
docker run hello-world
```

### 6. Verificar Docker Compose

```bash
docker compose version
```

Este proyecto usa el plugin `docker compose`. Confirmar que la versión soporta la sintaxis del `docker-compose.yml` raíz.

## Verificación final

- `docker ps` muestra los contenedores en ejecución (vacío al inicio es correcto).
- `docker run hello-world` finaliza sin errores.
- `docker compose version` imprime una versión.
- El usuario puede ejecutar `docker` sin `sudo`.

## Configuración adicional recomendada

### Iniciar Docker automáticamente

Ya quedó habilitado con `systemctl enable --now docker`; se inicia solo al arrancar el servidor.

### Ejecutar contenedores en un host sin internet

Docker necesita descargar imágenes de registros. Si el servidor no tiene internet, usar el método NAT de la guía [Proxy APT y NAT](./proxy-apt-y-nat.md), o cargar imágenes previamente exportadas con `docker save` / `docker load`.

## Solución de problemas

**`permission denied` al ejecutar `docker`:**
- Asegurarse de haber iniciado sesión después de `usermod -aG docker`.

**El repositorio no se agrega o `apt update` falla:**
- Verificar el nombre en clave de la versión de Debian.
- Confirmar que el archivo `/etc/apt/keyrings/docker.gpg` existe y tiene permisos de lectura.

**`docker compose` no se encuentra:**
- Confirmar que se instaló `docker-compose-plugin`, no solo `docker-ce`, y verificar con `docker compose version`.

## Referencias

- Teoría: [Docker en un servidor Debian](../theory/docker.md)
- Instalación oficial: <https://docs.docker.com/engine/install/debian/>
- Postinstall (grupo docker): <https://docs.docker.com/engine/install/linux-postinstall/>
- Documentación de Compose: <https://docs.docker.com/compose/>
