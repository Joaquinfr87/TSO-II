# Servicio: Servidor DHCP (Kea)

Servidor DHCP para asignar direcciones IP automáticamente en la red local, basado en **Kea** (ISC).

## Responsable

**Nicolás**

## Propósito

Asignar IP, máscara, puerta de enlace, servidor DNS y dominio a los equipos de la red del proyecto, para que ningún cliente necesite configuración manual.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Kea DHCP |
| `kea-dhcp4.conf` | Plantilla de configuración (los `__TOKENS__` los reemplaza el entrypoint) |
| `entrypoint.sh` | Aplica las variables del `.env` a la plantilla y arranca Kea |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build dhcp
```

## Verificación

1. **Que el contenedor arranque y Kea escuche en el puerto 67/udp**:

   ```bash
   docker compose logs dhcp
   # Debe verse el resumen (subred, pool, DNS, gateway) y el arranque de Kea
   ```

2. **Configuración aplicada** (ver que los tokens quedaron reemplazados por los valores reales):

   ```bash
   docker compose exec dhcp cat /etc/kea/kea-dhcp4.conf
   ```

3. **Concesiones entregadas** (una vez que algún cliente pidió IP):

   ```bash
   docker compose exec dhcp cat /var/lib/kea/kea-leases4.csv
   ```

4. **Prueba real desde un cliente de la red** (otra máquina en la misma red física):

   ```bash
   sudo dhclient -v eth0        # o el nombre de su interfaz
   ip a                          # ver la IP/máscara/gateway/DNS asignados
   ```

> El DHCP responde por broadcast, así que el cliente debe estar en la **misma red física** que el servidor para que la concesión aparezca en los logs.

## Red y broadcast (importante)

El contenedor `dhcp` corre en la **red bridge de Docker** (`tso-net`) y publica el puerto `67:67/udp`. El bridge de Docker **no reenvía los broadcasts de la LAN física** al contenedor, y los clientes DHCP descubren al servidor **por broadcast**. Por eso, con esta configuración, un cliente en **otra máquina** de la misma red física **no va a encontrar a Kea** aunque el puerto esté publicado: la concesión solo se puede ver probando dentro del host.

Opciones para que DHCP responda en una red real (a evaluar cuando se pruebe con clientes):

| Opción | Cómo | Trade-off |
|---|---|---|
| `network_mode: host` | Kea escucha directo en las interfaces físicas del servidor (el `ports:` no aplica y queda fuera de `tso-net`) | Simple y típico para DHCP; comparte red con el host |
| Red `macvlan` | Contenedor con IP propia en la LAN | Más aislado, más complejo de configurar |

> **Decisión actual**: se mantiene en **bridge** (sirve para probar el servicio a nivel contenedor). La prueba con clientes reales queda pendiente hasta desplegar con `network_mode: host` o `macvlan` en la máquina física.

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `DHCP_SUBNET` | `192.168.1.0/24` | Red que atiende el servidor |
| `DHCP_POOL` | `192.168.1.100 - 192.168.1.200` | Rango de IPs que entrega a los clientes |
| `DHCP_DNS` | `192.168.1.10` | IP del servidor DNS que se anuncia a los clientes |
| `DNS_DOMAIN` | `sudoers.lan` | Dominio interno del proyecto |
| `HOST_IP` | `192.168.1.10` | IP del servidor; se anuncia como puerta de enlace (`routers`) |

## Estado

- [x] Imagen Kea construida y arranque por entrypoint
- [x] Subred, pool, DNS, dominio y gateway parametrizados por variables
- [x] Logs en stdout (visibles con `docker compose logs dhcp`)
- [ ] Confirmar la red real del proyecto (subnet/pool definitivos)
- [ ] Probar con un cliente DHCP físico en la red (necesita `network_mode: host` o red `macvlan`)
- [ ] Actualizar repartición cuando se confirme el rango

## Interacción con otros servicios

- **DNS**: el DHCP distribuye la IP del servidor DNS (`DHCP_DNS`) a todos los clientes.
- **Web/archivos/correo**: los clientes resuelven los nombres de estos servicios gracias al DNS que entrega DHCP.

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
- Documentación Kea: https://kea.readthedocs.io/