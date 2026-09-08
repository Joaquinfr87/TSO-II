# Servicio: IIS (Internet Information Services)

> **IMPORTANTE:** IIS es un servidor web **exclusivo de Windows**. No tiene versión para Linux ni puede ejecutarse como contenedor Docker sobre el kernel de Linux.

## La situación

La consigna de la materia pidió IIS como servidor web. Docker en esta máquina Debian corre sobre el kernel de Linux, y un contenedor comparte el kernel del host. Por esa razón **no es posible** correr IIS dentro de Docker en Debian.

## Qué decidimos

- El **equivalente funcional** en este stack es el servidor web **Nginx** (equivalente en el rol de "servidor web HTTP"). Su implementación está en [`../web/`](../web/).
- Si la materia **exige** IIS como tal, la única vía sería una **máquina virtual Windows** con Hyper-V/VirtualBox fuera de Docker; eso queda a criterio de lo que pida la consigna.

## Discusión

Ver el detalle y las alternativas en [`../../teams/reparticion-tareas.md`](../../teams/reparticion-tareas.md).

## Referencias

- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)