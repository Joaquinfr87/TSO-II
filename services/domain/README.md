# Servicio: Controlador de dominio (Active Directory)

> **IMPORTANTE:** un controlador de dominio con **Active Directory** es una función de Windows Server. AD no existe como servicio nativo en Linux ni se puede ejecutar dentro de un contenedor Docker sobre el kernel de Linux.

## La situación

La consigna pidió un controlador de dominio. Al igual que IIS, es tecnología Microsoft basada en el kernel Windows.

## Opciones disponibles

1. **Samba como controlador de dominio (ADDC)**: Samba puede emular un controlador de dominio compatible con Active Directory (autenticación Kerberos, SAM, LDAP). Es el único camino *realista* para correr un "controlador de dominio" sobre Linux, y en contenedores es complejo y delicado (requiere red, DNS propio y hostname fijos). Se puede intentar si la consigna acepta Samba.
2. **Máquina virtual Windows Server**: si la consigna exige AD de Windows, se necesita una VM Windows Server con un controlador de dominio real, fuera de Docker.
3. **Dejar el rol sin contenedor**: documentar la limitación y cubrir la funcionalidad de autenticación con otro mecanismo.

## Decisión del equipo

Ver el estado de la decisión en [`../../teams/reparticion-tareas.md`](../../teams/reparticion-tareas.md).

## Referencias

- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)