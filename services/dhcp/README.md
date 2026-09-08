# Servicio: DHCP (Kea)

Servidor DHCP para asignar direcciones IP automáticamente en la red local, basado en Kea (ISC).

## Responsable

**Nicolás**

## Propósito

Asignar direcciones IP, DNS y puerta de enlace a los equipos de la red del proyecto.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Kea DHCP |
| `kea-dhcp4.conf` | Configuración de subred, pool y opciones |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build dhcp
```

## Pruébarlo

```bash
# Ver las concesiones otorgadas
docker compose exec dhcp cat /var/lib/kea/leases.csv

# Logs del servicio
docker compose logs -f dhcp
```

## Estado

- [ ] Definir el rango de red y la máscara reales
- [ ] Confirmar la IP del servidor DNS
- [ ] Probar con un cliente DHCP en la red

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)