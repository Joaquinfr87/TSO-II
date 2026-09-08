# Equipo de trabajo

Esta carpeta reúne la documentación **del equipo** para la materia: quiénes somos, cómo nos organizamos, la repartición de servicios y el estado de avance del proyecto. Es el punto de referencia para coordinar el trabajo colaborativo.

## Integrantes

| Nombre | Rol principal | Servicios asignados |
|---|---|---|
| Joaquín | Coordinación, base del proyecto Docker | Servidor de correo, arquitectura del repositorio |
| Nicolás | Servicios de red | DNS, DHCP |
| David | Servicios de aplicación | Servidor web, servidor de archivos |

## Documentos

- [Repartición de tareas y decisiones del proyecto](./reparticion-tareas.md)

## Cómo trabaja el equipo

El flujo de trabajo está documentado en la guía práctica [Uso colaborativo de Docker en el equipo](../docs/guides/docker-compose-flujo.md). Resumen:

- Todos los servicios se declaran en el `docker-compose.yml` de la raíz.
- Cada integrante trabaja en `services/<su-servicio>/` en su máquina local.
- Los resultados se comparten por git; en la máquina física se replica con `docker compose up -d --build`.

## Estado del proyecto

Ver el resumen de avance en [Repartición de tareas](./reparticion-tareas.md#estado-del-proyecto).