# Repartición de tareas y decisiones del proyecto

Este documento define cómo se reparten los servicios de la materia entre los integrantes del equipo, y registra las decisiones importantes (incluidas las limitaciones de Docker para servicios de Microsoft).

## Servicios pedidos por la materia

- Servidor de correos
- Servidor de archivos
- Servidor **DHCP**
- **IIS** (servidor web)
- **Controlador de dominio** (Active Directory)
- Servidor **DNS**
- Servidor web
- (otros que agregue la consigna)

## Repartición de servicios

| Servicio | Tecnología elegida | Integrante | Estado |
|---|---|---|---|
| Servidor de correo | Postfix + Dovecot | Joaquín | En desarrollo |
| DNS | Bind9 | Nicolás | En desarrollo |
| DHCP | Kea | Nicolás | En desarrollo |
| Servidor web | Nginx | David | En desarrollo |
| Servidor de archivos | Samba | David | En desarrollo |
| IIS | Ver decisión abajo | — | Bloqueado por plataforma |
| Controlador de dominio | Ver decisión abajo | — | Bloqueado por plataforma |

> El estado se actualiza en este documento a medida que avanza cada tarea.

## La decisión sobre IIS y el controlador de dominio

La consigna incluye **IIS** y un **controlador de dominio** (Active Directory). Ambos son tecnologías de **Microsoft** que dependen del kernel de Windows. Docker sobre Debian comparte el **kernel de Linux**, por lo que **no pueden ejecutarse como contenedores** en esta máquina.

Las opciones reales:

| Rol pedido | Opción alineada a Docker/Linux | Opción alternativa fuera de Docker |
|---|---|---|
| Servidor web (IIS) | Nginx (mismo rol: servidor HTTP) | Máquina virtual Windows Server |
| Controlador de dominio (AD) | Samba como controlador de dominio de red (Kerberos/LDAP) | Máquina virtual Windows Server |

### Decisión del equipo

- **Servidor web**: se implementa con **Nginx**, equivalente funcional de IIS para el rol "servidor web". Queda documentado en [`../services/iis/README.md`](../services/iis/README.md) por si la consigna exige IIS literal.
- **Controlador de dominio**: **pendiente de decisión**. Si la consigna acepta Samba AD DC, se intenta el enfoque contenedor (complejo). Si exige Active Directory de Windows, hay que plantear una VM Windows Server.

> Marcar en este documento la decisión final cuando se confirme con el docente.

## Cómo se integran los servicios entre sí

- El **DNS** (Bind9) debe poder resolver los nombres de todos los demás servicios.
- El **correo** usa registros MX del DNS para recibir correo del dominio.
- El **DHCP** entrega a los clientes la IP del servidor DNS.
- El **servidor web** y el de **archivos** se acceden por IP o nombre del host.

Esto significa que los responsables **dependen entre sí**; conviene acordar los nombres de dominio e IPs desde el inicio (ver `.env.example` en la raíz).

## Acuerdos del equipo

1. **Un solo `docker-compose.yml` en la raíz**: todos los servicios se agregan ahí, nunca en archivos sueltos por integrante.
2. **Cada integrante edita solo su carpeta** en `services/<servicio>/` y el bloque correspondiente del compose, para evitar conflictos de git.
3. **Nada de secretos en el repositorio**: las contraseñas van en `.env` (que está en `.gitignore`); en el repo solo `.env.example`.
4. **Ver cada cambio**: cada uno prueba su servicio localmente con `docker compose up` antes de hacer push.
5. **Replicar siempre desde el repo**: la máquina física se actualiza con `git pull && docker compose up -d --build`, nunca con cambios a mano.

## Estado del proyecto

### Qué está listo (andamiaje)

- Estructura del repositorio (compose raíz + `services/`).
- Dockerfiles y configuraciones iniciales de DNS, DHCP, web, archivos y correo.
- Documentación de equipo, teoría y guías.

### Qué falta

- Configurar a fondo cada servicio (zonas DNS, pool DHCP, usuarios de correo y Samba, contenido web).
- La decisión sobre **IIS** y **controlador de dominio**.
- Probar la integración completa en la máquina física.

## Referencias

- Flujo de trabajo: [Uso colaborativo de Docker](../docs/guides/docker-compose-flujo.md)
- Teoría de Docker: [Docker en un servidor Debian](../docs/theory/docker.md)