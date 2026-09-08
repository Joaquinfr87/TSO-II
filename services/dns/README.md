# Servicio: DNS (Bind9)

Servidor DNS para el dominio interno del proyecto, basado en Bind9.

## Responsable

**Nicolás**

## Propósito

Resolver los nombres de los servicios del proyecto dentro del dominio interno y servir como DNS de la red local.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Bind9 |
| `named.conf` | Configuración de opciones y definición de zonas |
| `zones/` | Archivos de zona (directa e inversa) |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build dns
```

## Pruébarlo

```bash
# Resolver un nombre contra el servidor DNS (desde un host de la red)
dig @<IP_DEL_HOST> www.tsolab.local

# Registros del servicio
docker compose logs -f dns
```

## Estado

- [ ] Configurar zona directa (`zones/db.<dominio>`)
- [ ] Configurar zona inversa
- [ ] Integrar registros de los demás servicios (MX, SRV, etc.)

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)