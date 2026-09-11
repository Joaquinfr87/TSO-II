# Guías prácticas

Esta carpeta contiene las guías paso a paso para instalar y configurar un servidor Debian.

## Contenido esperado

- Instalación de Debian en el servidor.
- Configuración inicial del sistema operativo.
- Instalación de Docker y uso de Docker Compose.
- Instalación y configuración de Zsh con Oh My Zsh.
- Configuración de red y acceso remoto.
- Servicios básicos y ajustes de producción.
- Buenas prácticas de mantenimiento y seguridad.

## Convención de cada guía

Cada guía debe incluir:

1. Objetivo de la guía.
2. Requisitos previos.
3. Pasos detallados.
4. Verificación de que todo quedó correctamente configurado.

## Índice de guías

### Instalación y base

- [Instalación de Debian en el servidor](./instalacion-debian.md)
- [Configuración inicial del servidor Debian](./configuracion-debian.md)
- [Instalación de Docker en Debian](./instalacion-docker.md)
- [Comandos esenciales de Docker](./comandos-docker.md)
- [Uso colaborativo de Docker: flujo de trabajo con Docker Compose](./docker-compose-flujo.md)
- [Instalar Zsh con Oh My Zsh](./zsh-ohmyzsh.md)
- [Agregar usuarios y asignar privilegios](./agregar-usuarios.md)
- [Evitar la suspensión al cerrar la tapa (laptop como servidor)](./laptop-siempre-encendida.md)
- [Instalar paquetes en un servidor sin internet: proxy APT y NAT](./proxy-apt-y-nat.md)

### Servicios

- [Servidor de archivos multi-protocolo: Samba, NFS y Filebrowser](./servidor-archivos.md)
- [Servidor de base de datos: PostgreSQL](./servidor-base-de-datos.md)
- [Servidor de impresión: CUPS](./servidor-impresion.md)
- [Panel de gestión: Portainer](./portainer.md)
- [Servidor de correo (Postfix + Dovecot)](../../services/mail/README.md)
- [Servidor DNS (Bind9)](../../services/dns/README.md)
- [Servidor web (Nginx)](../../services/web/README.md)
- [Servidor DHCP (Kea)](../../services/dhcp/README.md)

### Seguridad

- [Hardening de seguridad: nftables + SSH + fail2ban](./hardening-seguridad.md)

## Cómo continuar

Cuando exista una guía lista, agregarla aquí y enlazarla desde este índice. Si una guía es muy larga, conviene dividirla en varias secciones o documentos más pequeños.
