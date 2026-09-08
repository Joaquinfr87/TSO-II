# Servicio: DNS (Bind9)

Servidor DNS para el dominio interno del proyecto, basado en Bind9.

## Responsable

**Joaquín**

## Propósito

Resolver los nombres de los servicios del proyecto dentro del dominio interno `sudoers.local` y servir como DNS de la red local.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Bind9 |
| `named.conf` | Configuración principal: zonas que administra el servidor |
| `zones/db.sudoers.local` | **Zona directa**: resuelve nombres → IPs |
| `zones/db.1.168.192` | **Zona inversa**: resuelve IPs → nombres |

## Teoría esencial

### ¿Qué es un servidor DNS?

DNS (Domain Name System) es el sistema que traduce nombres legibles (`web.sudoers.local`) a direcciones IP (`192.168.1.10`). Sin DNS, tendrías que recordar la IP de cada servicio.

### Tipos de registros más comunes

| Registro | Qué hace | Ejemplo |
|---|---|---|
| **A** | Nombre → IPv4 | `web.sudoers.local. IN A 192.168.1.10` |
| **AAAA** | Nombre → IPv6 | `web.sudoers.local. IN AAAA ::1` |
| **PTR** | IP → nombre (inversa) | `10 IN PTR web.sudoers.local.` |
| **NS** | Nameserver del dominio | `@ IN NS ns1.sudoers.local.` |
| **MX** | Servidor de correo | `@ IN MX 10 mail.sudoers.local.` |
| **CNAME** | Alias de otro nombre | `www IN CNAME web.sudoers.local.` |

### Zona directa vs inversa

- **Directa** (`db.sudoers.local`): cuando preguntás `¿Cuál es la IP de web?`, el servidor busca el registro A y responde `192.168.1.10`.
- **Inversa** (`db.1.168.192`): cuando preguntás `¿Qué nombre tiene la IP 192.168.1.10?`, el servidor busca el registro PTR y responde `web.sudoers.local`.

### Cómo funciona una consulta DNS

```
Tu máquina                DNS (Bind9)              Internet
    |                         |                        |
    |--- "web.sudoers.local" ->|                        |
    |                         |-- ¿Está en mi zona? --|
    |                         |   Sí: 192.168.1.10    |
    |<-- 192.168.1.10 --------|                        |
    |                         |                        |
    |--- "google.com" ------->|                        |
    |                         |-- ¿Está en mi zona? --|
    |                         |   No: consulto        |
    |                         |   1.1.1.1 (forwarder) |
    |<-- respuesta -----------|<-- respuesta ----------|
```

### Propagación y TTL

- **TTL** (Time To Live): cuántos segundos se guarda la respuesta en caché antes de volver a preguntar. Por defecto: `604800` (7 días).
- **Serial**: número de versión del archivo de zona. Se incrementa cada vez que se modifica (formato: `YYYYMMDDNN`).

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `DNS_DOMAIN` | `sudoers.local` | Dominio interno a resolver |
| `DNS_SERVER_IP` | (auto-detectada) | IP del servidor DNS. Si está vacío, se detecta automáticamente |

## Uso

```bash
# Levantar el servidor DNS (auto-detecta IP)
docker compose up -d --build dns

# O especificar la IP manualmente
DNS_SERVER_IP=192.168.1.10 docker compose up -d --build dns

# Ver logs en tiempo real
docker compose logs -f dns
```

## Cómo probar

```bash
# Resolver un nombre contra el servidor DNS
dig @localhost sudoers.local

# Verificar un registro específico
dig @localhost web.sudoers.local

# Verificar resolución inversa
dig @localhost -x 192.168.1.10

# Consulta verbose (muestra más detalle)
dig @localhost web.sudoers.local +noall +answer

# Ver todos los registros de un dominio
dig @localhost sudoers.local ANY
```

## Servidor con múltiples interfaces (WiFi + LAN)

Si tu servidor tiene dos interfaces de red (WiFi y LAN), el entrypoint detectará automáticamente la IP de la interfaz por defecto (la que tiene ruta hacia Internet).

Para usar una IP específica:

```bash
# Especificar la IP de la interfaz LAN
DNS_SERVER_IP=192.168.1.10 docker compose up -d --build dns

# O configurar en .env
echo "DNS_SERVER_IP=192.168.1.10" >> .env
docker compose up -d --build dns
```

El DNS escuchará en **todas las interfaces** (0.0.0.0:53), así que será accesible desde ambas redes.

## Agregar un registro nuevo

1. Abrí `zones/db.sudoers.local`
2. Agregá la línea con el registro deseado:
   ```
   # Servidor de base de datos
   db             IN      A       192.168.1.20
   ```
3. Incrementá el **Serial** (ej: de `2026090801` a `2026090802`)
4. Recargá Bind9 sin reiniciar el contenedor:
   ```bash
   docker compose exec dns rndc reload
   ```
5. Probá:
   ```bash
   dig @localhost db.sudoers.local
   ```

## Apuntar tu máquina al DNS

Para que tu máquina use este servidor DNS, editá `/etc/resolv.conf`:

```
nameserver 192.168.1.10
```

O configurá la interfaz de red para que use esta IP como DNS primario.

## Estado

- [x] Configurar zona directa (`zones/db.sudoers.local`)
- [x] Configurar zona inversa (`zones/db.1.168.192`)
- [x] Registros de todos los servicios (web, mail, files, print, dns, dhcp)
- [x] Registro MX para correo
- [ ] Integrar con DHCP (que entregue la IP del DNS a los clientes)
- [ ] Configurar DNS externo (forwarding a 8.8.8.8 o 1.1.1.1)

## Referencias

- [Documentación oficial de Bind9](https://www.isc.org/bind/)
- [Herramienta dig](https://linux.die.net/man/1/dig)
- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
