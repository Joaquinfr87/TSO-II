# Servicio: DNS (Bind9)

Servidor DNS para el dominio interno del proyecto, basado en Bind9.

## Responsable

**Joaquín**

## Propósito

Resolver los nombres de los servicios del proyecto dentro del dominio interno `sudoers.lan` y servir como DNS de la red local.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Bind9 |
| `named.conf` | Configuración principal: zonas que administra el servidor |
| `zones/db.sudoers.lan` | **Zona directa**: resuelve nombres → IPs |
| `zones/db.1.168.192` | **Zona inversa**: resuelve IPs → nombres |

## Teoría esencial

### ¿Qué es un servidor DNS?

DNS (Domain Name System) es el sistema que traduce nombres legibles (`web.sudoers.lan`) a direcciones IP (`192.168.1.10`). Sin DNS, tendrías que recordar la IP de cada servicio.

### Tipos de registros más comunes

| Registro | Qué hace | Ejemplo |
|---|---|---|
| **A** | Nombre → IPv4 | `web.sudoers.lan. IN A 192.168.1.10` |
| **AAAA** | Nombre → IPv6 | `web.sudoers.lan. IN AAAA ::1` |
| **PTR** | IP → nombre (inversa) | `10 IN PTR web.sudoers.lan.` |
| **NS** | Nameserver del dominio | `@ IN NS ns1.sudoers.lan.` |
| **MX** | Servidor de correo | `@ IN MX 10 mail.sudoers.lan.` |
| **CNAME** | Alias de otro nombre | `www IN CNAME web.sudoers.lan.` |

### Zona directa vs inversa

- **Directa** (`db.sudoers.lan`): cuando preguntás `¿Cuál es la IP de web?`, el servidor busca el registro A y responde `192.168.1.10`.
- **Inversa** (`db.1.168.192`): cuando preguntás `¿Qué nombre tiene la IP 192.168.1.10?`, el servidor busca el registro PTR y responde `web.sudoers.lan`.

### Cómo funciona una consulta DNS

```
Tu máquina                DNS (Bind9)              Internet
    |                         |                        |
    |--- "web.sudoers.lan" ->|                        |
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
| `DNS_DOMAIN` | `sudoers.lan` | Dominio interno a resolver |
| `DNS_IP_WLO1` | (auto-detectada) | IP de la interfaz WiFi (wlo1). Si está vacío, se detecta automáticamente |
| `DNS_IP_ENO1` | (auto-detectada) | IP de la interfaz LAN (eno1). Si está vacío, se detecta automáticamente |

## Uso

```bash
# Levantar el servidor DNS (auto-detecta IPs)
docker compose up -d --build dns

# O especificar las IPs manualmente
DNS_IP_WLO1=192.168.0.105 DNS_IP_ENO1=172.16.0.16 docker compose up -d --build dns

# Ver logs en tiempo real
docker compose logs -f dns
```

## Cómo probar

```bash
# Resolver un nombre contra el servidor DNS
dig @localhost sudoers.lan

# Verificar un registro específico
dig @localhost web.sudoers.lan

# Verificar resolución inversa
dig @localhost -x 192.168.1.10

# Consulta verbose (muestra más detalle)
dig @localhost web.sudoers.lan +noall +answer

# Ver todos los registros de un dominio
dig @localhost sudoers.lan ANY
```

## Servidor con múltiples interfaces (WiFi + LAN)

El DNS usa **Views** de Bind9 para dar respuestas diferentes según la red del cliente:

```
Cliente en wlo1 (192.168.0.x)  →  print.sudoers.lan = 192.168.0.105
Cliente en eno1 (172.16.x.x)  →  print.sudoers.lan = 172.16.0.16
```

Cada cliente recibe la IP correcta para su red automáticamente.

### Configurar IPs manualmente

```bash
# En .env
DNS_IP_WLO1=192.168.0.105
DNS_IP_ENO1=172.16.0.16
```

### Auto-detección

Si dejás las variables vacías, el entrypoint detecta las IPs automáticamente:

```bash
# Detecta IPs de wlo1 y eno1
docker compose up -d --build dns
```

## Agregar un registro nuevo

Los archivos de zona se generan automáticamente al iniciar el contenedor. Para agregar un registro nuevo, editá el `entrypoint.sh` y agregá la línea en la función `generar_zona()`:

```bash
# Ejemplo: agregar servidor de base de datos
db             IN      A       ${IP}
```

Después reiniciá el contenedor:

```bash
docker compose down
docker compose up -d --build dns
```

## Apuntar tu máquina al DNS

Para que tu máquina use este servidor DNS, editá `/etc/resolv.conf`:

```
nameserver 192.168.1.10
```

O configurá la interfaz de red para que use esta IP como DNS primario.

## Estado

- [x] Configurar zona directa (`zones/db.sudoers.lan`)
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
