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

El contenedor `dhcp` corre con **`network_mode: host`** y escucha solo en la interfaz física `DHCP_INTERFACE` (ej: `wlo1`). Es la única configuración que funciona en WiFi: los broadcasts de los clientes llegan a Kea y las respuestas (OFFER/ACK) salen con la **MAC real del server**. Con bridge o `macvlan` el AP descarta las respuestas que salen con una MAC virtual desconocida, y por eso el cliente se queda sin IP.

Alternativa considerada (descartada en la práctica):

| Opción | Resultado |
|---|---|
| Red bridge + puerto `67:67/udp` | El bridge no reenvía los broadcasts de la LAN al contenedor |
| Red `macvlan` | Recibe los `DISCOVER`, pero el OFFER sale con una MAC desconocida para el AP WiFi y el cliente nunca completa la concesión |

> **Decisión actual**: `network_mode: host` con `DHCP_INTERFACE` apuntando a la interfaz física (wlo1).

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `DHCP_SUBNET` | `192.168.1.0/24` | Red que atiende el servidor |
| `DHCP_POOL` | `192.168.1.110 - 192.168.1.254` | Rango de IPs que entrega a los clientes |
| `DHCP_DNS` | `192.168.1.10` | IP del servidor DNS que se anuncia a los clientes |
| `DHCP_ROUTER` | `192.168.1.1` | Gateway que se anuncia a los clientes (`routers`) |
| `DHCP_INTERFACE` | `wlo1` | Interfaz física donde escucha Kea (necesario con `network_mode: host`) |
| `DNS_DOMAIN` | `sudoers.lan` | Dominio interno del proyecto |

## Estado

- [x] Imagen Kea construida y arranque por entrypoint
- [x] Subred, pool, DNS, dominio y gateway parametrizados por variables
- [x] Logs en stdout (visibles con `docker compose logs dhcp`)
- [x] Clientes reales atendidos (prueba con router sin DHCP propio)
- [ ] Confirmar la red real del proyecto (subnet/pool definitivos)
- [ ] Actualizar repartición cuando se confirme el rango

## Interacción con otros servicios

- **DNS**: el DHCP distribuye la IP del servidor DNS (`DHCP_DNS`) a todos los clientes.
- **Web/archivos/correo**: los clientes resuelven los nombres de estos servicios gracias al DNS que entrega DHCP.

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
- Documentación Kea: https://kea.readthedocs.io/