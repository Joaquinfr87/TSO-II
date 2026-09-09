# DHCP: Dynamic Host Configuration Protocol

Este documento cubre la teoría detrás de DHCP, el proceso DORA, leases, y cómo lo configuramos en nuestro proyecto con Kea.

## ¿Qué es DHCP y por qué existe?

DHCP (Dynamic Host Configuration Protocol) es el protocolo que asigna **direcciones IP automáticamente** a los dispositivos de una red. Sin DHCP, cada dispositivo necesitaría configuración manual de IP, máscara, gateway y DNS.

DHCP es un protocolo **cliente-servidor**: el cliente pide una IP y el servidor responde con todos los parámetros de red necesarios para conectarse.

## El proceso DORA

Cuando un dispositivo se conecta a la red, negocia su configuración en 4 pasos:

```
Cliente                          Servidor DHCP
  |                                    |
  |--- 1. DISCOVER (broadcast) ------->|
  |    "¿Hay algún servidor DHCP?"     |
  |                                    |
  |<-- 2. OFFER (broadcast) -----------|
  |    "Sí, podés usar la IP           |
  |     192.168.0.100, máscara /24,    |
  |     gateway 192.168.0.1,           |
  |     DNS 192.168.0.105"             |
  |                                    |
  |--- 3. REQUEST (broadcast) -------->|
  |    "Quiero la IP 192.168.0.100"    |
  |                                    |
  |<-- 4. ACKNOWLEDGE (broadcast) -----|
  |    "Perfecto, esa IP es tuya       |
  |     por 24 horas"                  |
```

### Paso 1: DISCOVER

El cliente envía un paquete por **broadcast** (a todos los dispositivos de la red) preguntando si hay un servidor DHCP. No tiene IP propia todavía, así que usa `0.0.0.0` como origen.

### Paso 2: OFFER

El servidor responde ofreciendo una IP disponible de su pool, junto con todos los parámetros de red (máscara, gateway, DNS, dominio, tiempo de lease).

### Paso 3: REQUEST

El cliente acepta la oferta y confirma que quiere esa IP específica. Esto es importante porque pueden haber múltiples servidores DHCP en la red.

### Paso 4: ACKNOWLEDGE

El servidor confirma la asignación y el cliente configura su interfaz de red con todos los parámetros recibidos.

## Leases (concesiones)

Un **lease** es el tiempo que un cliente puede usar una IP asignada. El servidor DHCP lleva un registro de todas las concesiones:

- **Duración**: típicamente horas o días (configurable)
- **Renovación**: el cliente intenta renovar el lease a la mitad del tiempo
- **Expiración**: si el cliente no renueva, la IP vuelve al pool para ser asignada a otro dispositivo
- **Archivo de concesiones**: `/var/lib/kea/kea-leases4.csv` (en Kea)

## Opciones DHCP

DHCP puede enviar múltiples parámetros al cliente. Los más comunes:

| Opción | Código | Qué define | Ejemplo |
|---|---|---|---|
| Subnet Mask | 1 | Máscara de subred | `255.255.255.0` |
| Router | 3 | Puerta de enlace (gateway) | `192.168.0.1` |
| DNS Server | 6 | Servidor DNS primario | `192.168.0.105` |
| Domain Name | 15 | Dominio de búsqueda | `sudoers.lan` |
| Lease Time | 51 | Tiempo de concesión en segundos | `86400` (24h) |

## Kea DHCP

**Kea** es el servidor DHCP de ISC (Internet Systems Consortium), el sucesor de dhcpd. Es el estándar actual para servidores DHCP en Linux.

### Por qué Kea y no dhcpd

- Kea es más moderno y está en desarrollo activo
- Soporta DHCPv4 y DHCPv6
- Tiene interfaz de control por HTTP (kea-ctrl-agent)
- Mejor manejo de grandes redes

### Estructura de configuración

```json
{
    "Dhcp4": {
        "interfaces-config": { "interfaces": ["eth0"] },
        "lease-database": { "type": "memfile", "persist": true },
        "subnet4": [{
            "subnet": "192.168.0.0/24",
            "pools": [{ "pool": "192.168.0.100 - 192.168.0.200" }],
            "option-data": [
                { "name": "routers", "data": "192.168.0.1" },
                { "name": "domain-name-servers", "data": "192.168.0.105" },
                { "name": "domain-name", "data": "sudoers.lan" }
            ]
        }]
    }
}
```

## Docker y DHCP: el problema del broadcast

DHCP depende del **broadcast** (paquetes que llegan a todos los dispositivos de la red). Docker usa redes bridge que **no reenvían broadcasts de la LAN física** al contenedor.

### Con bridge (configuración actual)

```
Cliente physical LAN ──X──> Contenedor Docker (bridge tso-net)
       (broadcast)        no llega
```

El cliente nunca recibe el OFFER porque el broadcast no cruza el bridge de Docker.

### Soluciones

| Opción | Cómo funciona | Trade-off |
|---|---|---|
| **`network_mode: host`** | El contenedor usa la red del host directamente | Simple; Kea escucha en las interfaces físicas |
| **Red `macvlan`** | El contenedor tiene su propia IP en la LAN | Más aislado, más complejo |

> **Decisión actual**: usamos bridge para demostración del servicio. Para clientes reales se necesita `network_mode: host` o `macvlan`.

## En nuestro proyecto

### Archivos clave

| Archivo | Propósito |
|---|---|
| `kea-dhcp4.conf` | Plantilla de configuración con tokens (`__SUBNET__`, `__POOL__`, etc.) |
| `entrypoint.sh` | Reemplaza los tokens por valores reales del `.env` y arranca Kea |
| `.env` | Variables: `DHCP_SUBNET`, `DHCP_POOL`, `DHCP_DNS`, `DNS_DOMAIN`, `HOST_IP` |

### Plantilla de configuración

Usamos una plantilla con tokens que el entrypoint reemplaza:

```bash
# kea-dhcp4.conf (plantilla)
"subnet": "__SUBNET__",
"pool": "__POOL__",
"routers": "__HOST_IP__",
"domain-name-servers": "__DNS_IP__",
"domain-name": "__DNS_DOMAIN__"
```

```bash
# entrypoint.sh (reemplazo)
sed -e "s/__SUBNET__/${DHCP_SUBNET}/g" \
    -e "s/__POOL__/${DHCP_POOL}/g" \
    -e "s/__HOST_IP__/${HOST_IP}/g" \
    -e "s/__DNS_IP__/${DNS_DNS}/g" \
    -e "s/__DNS_DOMAIN__/${DNS_DOMAIN}/g" \
    /etc/kea/kea-dhcp4.conf.template > /etc/kea/kea-dhcp4.conf
```

### Variables de entorno

| Variable | Default | Qué controla |
|---|---|---|
| `DHCP_SUBNET` | `192.168.0.0/24` | Red que atiende el servidor |
| `DHCP_POOL` | `192.168.0.100 - 192.168.0.200` | Rango de IPs disponibles |
| `DHCP_DNS` | `192.168.0.105` | IP del DNS que se entrega a clientes |
| `DNS_DOMAIN` | `sudoers.lan` | Dominio que se entrega a clientes |
| `HOST_IP` | `192.168.0.1` | IP del gateway (puerta de enlace) |

### Interacción con otros servicios

```
Dispositivo se conecta a la red
         ↓
DHCP asigna: IP + gateway + DNS (192.168.0.105) + dominio (sudoers.lan)
         ↓
Cliente usa DNS (192.168.0.105) para resolver nombres
         ↓
DNS resuelve web.sudoers.lan → 192.168.0.105
         ↓
Cliente accede a http://web.sudoers.lan
```

El DHCP es el punto de entrada: sin él, los clientes no saben qué DNS usar ni a qué dominio pertenecen.

### Verificación

```bash
# Ver logs del servidor
docker compose logs -f dhcp

# Ver concesiones activas
docker compose exec dhcp cat /var/lib/kea/kea-leases4.csv

# Probar desde un cliente en la misma red
sudo dhclient -v eth0
ip a    # ver la IP asignada
```

## Referencias

- [Documentación de Kea DHCP](https://kea.readthedocs.io/)
- [RFC 2131 - Dynamic Host Configuration Protocol](https://datatracker.ietf.org/doc/html/rfc2131)
- Teoría: [Docker en un servidor Debian](./docker.md)
