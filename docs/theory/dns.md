# DNS: Domain Name System

Este documento cubre la teoría detrás de DNS, cómo funciona la resolución de nombres, los registros, las zonas, BIND9, y cómo lo configuramos en nuestro proyecto.

## ¿Qué es DNS y por qué existe?

DNS (Domain Name System) es el sistema que traduce **nombres legibles** (`web.sudoers.lan`) a **direcciones IP** (`192.168.0.105`). Sin DNS, tendrías que recordar la IP numérica de cada servicio, sitio web o dispositivo en la red.

DNS es fundamentalmente un **directorio distribuido jerárquico**: ningún servidor tiene toda la información. Cada servidor es responsable de una porción (una "zona") y consulta a otros cuando no tiene la respuesta.

## Cómo funciona la resolución de nombres

Cuando tu máquina quiere resolver un nombre, ocurre una cadena de consultas:

```
Tu máquina              DNS local (Bind9)        Forwarder (router)       Internet
    |                         |                         |                      |
    |-- "google.com" -------->|                         |                      |
    |                         |-- ¿"google.com" está --|                      |
    |                         |   en mis zonas?         |                      |
    |                         |   No.                   |                      |
    |                         |-- Consulto forwarder -->|                      |
    |                         |                         |-- Consulto DNS ----->|
    |                         |                         |   raíz → .com →     |
    |                         |                         |   google.com        |
    |                         |<-- 142.250.190.46 ------|<-- 142.250.190.46 --|
    |<-- 142.250.190.46 ------|                         |                      |
```

1. Tu máquina pregunta al DNS configurado en `/etc/resolv.conf`.
2. El DNS local verifica si el nombre está en sus **zonas autoritativas** (archivos que administra directamente).
3. Si no está, consulta a sus **forwarders** (servidores que sí pueden resolver externamente).
4. La respuesta viaja de vuelta y se guarda en **caché** según el TTL.

## Tipos de registros DNS

Cada zona tiene registros que asocian nombres a datos. Los más comunes:

| Registro | Qué hace | Ejemplo |
|---|---|---|
| **A** | Nombre → IPv4 | `web IN A 192.168.0.105` |
| **AAAA** | Nombre → IPv6 | `web IN AAAA ::1` |
| **CNAME** | Alias de otro nombre | `www IN CNAME web.sudoers.lan.` |
| **MX** | Servidor de correo del dominio | `@ IN MX 10 mail.sudoers.lan.` |
| **PTR** | IP → nombre (resolución inversa) | `105 IN PTR web.sudoers.lan.` |
| **NS** | Nameserver autoritativo del dominio | `@ IN NS ns1.sudoers.lan.` |
| **SOA** | Registro de autoridad (metadata de la zona) | Define serial, tiempos de refresco, expiración |

### Registro A (Address)

El registro más básico. Asocia un nombre a una dirección IPv4:

```
web.sudoers.lan.    604800    IN    A    192.168.0.105
│                  │         │     │    │
│                  TTL       clase tipo  IP destino
nombre
```

### Registro CNAME (Canonical Name)

Crea un **alias** que apunta a otro nombre. El cliente recibe la IP del nombre original:

```
sudoers.lan.    604800    IN    CNAME    www.sudoers.lan.
```

Aquí `sudoers.lan` es un alias de `www.sudoers.lan`. Cuando preguntás por `sudoers.lan`, el DNS te da la IP de `www.sudoers.lan`.

**Regla importante**: un registro CNAME en el dominio raíz (`@`) no puede coexistir con otros registros del mismo nombre (SOA, NS, MX). Por eso en nuestro proyecto usamos `@ IN A` directamente en vez de un CNAME.

### Registro MX (Mail Exchange)

Indica qué servidor recibe el correo del dominio. El número es la **prioridad** (menor = más prioridad):

```
@    IN    MX    10    mail.sudoers.lan.
```

Esto significa: "el correo para `@sudoers.lan` va a `mail.sudoers.lan` con prioridad 10".

### Registro PTR (Pointer)

Se usa en la **zona inversa** para resolver IP → nombre. Es lo opuesto a un registro A:

```
105    IN    PTR    web.sudoers.lan.
```

Esto significa: "la IP que termina en `.105` tiene el nombre `web.sudoers.lan`".

### Registro SOA (Start of Authority)

Primer registro de toda zona. Contiene metadata:

```
@    IN    SOA    ns1.sudoers.lan. admin.sudoers.lan. (
                    2026090901    ; Serial (formato YYYYMMDDNN)
                    604800        ; Refresh (1 semana)
                    86400         ; Retry (1 día)
                    2419200       ; Expire (4 semanas)
                    604800        ; Negative cache TTL (1 semana)
)
```

- **Serial**: número de versión. Se incrementa cada vez que se modifica la zona.
- **Refresh**: cada cuánto los secundarios piden actualizaciones.
- **Negative cache TTL**: cuánto tiempo se guarda una respuesta negativa ("ese nombre no existe").

## Zonas directa e inversa

### Zona directa

Resuelve **nombre → IP**. Es la que usás cuando escribís `web.sudoers.lan` en el navegador.

El archivo de zona (`db.sudoers.lan`) contiene todos los registros A, CNAME, MX, etc. para el dominio:

```
$TTL    604800
@       IN      SOA     ns1.sudoers.lan. admin.sudoers.lan. ( ... )

@               IN      NS      ns1.sudoers.lan.
ns1             IN      A       192.168.0.105
web             IN      A       192.168.0.105
mail            IN      A       192.168.0.105
@               IN      A       192.168.0.105
@               IN      MX      10 mail.sudoers.lan.
```

### Zona inversa

Resuelve **IP → nombre**. Se usa para validación y debugging. La zona inversa para `192.168.0.0/24` se llama `0.168.192.in-addr.arpa`:

```
$TTL    604800
@       IN      SOA     ns1.sudoers.lan. admin.sudoers.lan. ( ... )

@               IN      NS      ns1.sudoers.lan.
105             IN      PTR     web.sudoers.lan.
105             IN      PTR     mail.sudoers.lan.
```

El número antes de `IN PTR` es el **último octeto** de la IP. Entonces `105` dentro de la zona `0.168.192.in-addr.arpa` significa `192.168.0.105`.

## BIND9

**BIND** (Berkeley Internet Name Domain) es el servidor DNS más utilizado en Linux. En nuestro proyecto usamos BIND9, la versión actual.

### Estructura de configuración

La configuración de BIND9 se organiza en archivos:

| Archivo | Contenido |
|---|---|
| `named.conf` | Archivo principal: incluye opciones, zonas y views |
| `named.conf.options` | Opciones globales: forwarders, recursion, permisos |
| `zones/db.dominio` | Archivos de zona (directa e inversa) |

### Views (vistas)

BIND9 soporta **views**: configuraciones DNS diferentes para diferentes clientes. Esto es útil cuando el servidor tiene múltiples interfaces de red:

```
Cliente en 192.168.0.x  →  View "wlo1"  →  web = 192.168.0.105
Cliente en 192.168.20.x →  View "eno1"  →  web = 192.168.20.226
Cualquier otro           →  View "default" → fallback
```

Cada view define sus propias zonas con IPs diferentes para el mismo nombre. El DNS decide qué view usar basándose en la IP del cliente que consulta (`match-clients`).

### Herramientas de verificación

```bash
# Verificar sintaxis de named.conf
named-checkconf /etc/bind/named.conf

# Verificar integridad de un archivo de zona
named-checkzone sudoers.lan /etc/bind/zones/db.sudoers.lan

# Consultar un DNS desde la línea de comandos
dig @192.168.0.105 web.sudoers.lan +short
dig @192.168.0.105 google.com +short
```

## En nuestro proyecto

### Cómo funciona `entrypoint.sh`

El contenedor DNS no usa archivos de zona estáticos. En su lugar, el `entrypoint.sh` **genera todo dinámicamente** al iniciar:

1. **Lee las variables de entorno**: `DNS_DOMAIN`, `DNS_IP_WLO1`, `DNS_IP_ENO1`
2. **Detecta IPs automáticamente** si no se especifican (usando `ip -4 addr show`)
3. **Genera archivos de zona** para cada interfaz mediante la función `generar_zona()`
4. **Genera `named.conf`** con las views correspondientes
5. **Incluye `named.conf.options`** que contiene los forwarders y opciones globales
6. **Valida** la configuración con `named-checkconf` y `named-checkzone`
7. **Arranca BIND9** como el usuario `bind`

### Por qué usamos views

El servidor tiene dos interfaces de red:
- `wlo1` (WiFi): `192.168.0.105/24`
- `eno1` (LAN cableada): `192.168.20.226/24`

Un cliente en `192.168.0.x` necesita que `web.sudoers.lan` resuelva a `192.168.0.105`, pero un cliente en `192.168.20.x` necesita que resuelva a `192.168.20.226`. Las views resuelven este problema dando la IP correcta según la red del cliente.

### El include de `named.conf.options`

Cuando se usan views en BIND9, la configuración global (forwarders, recursion) vive en un archivo separado que se incluye antes de las views:

```bash
# Genera named.conf.options con forwarders
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    listen-on port 53 { any; };
    recursion yes;
    allow-query { any; };
    forwarders { 192.168.0.11; 1.1.1.1; };
};
EOF

# Genera named.conf con el include
cat > /etc/bind/named.conf << 'EOF'
include "/etc/bind/named.conf.options";
// ... views aquí
EOF
```

Sin este `include`, las views no tienen acceso a los forwarders y **no pueden resolver nombres externos** (como google.com).

### Los forwarders

Configuramos dos forwarders en orden de prioridad:

```bash
forwarders { 192.168.0.1; 1.1.1.1; };
```

1. **192.168.0.1** (router): el router tiene acceso directo a Internet y puede resolver cualquier nombre externo.
2. **1.1.1.1** (Cloudflare): si el router falla, se usa Cloudflare como fallback.

### El registro `@ IN A` para el dominio raíz

En la zona, el dominio raíz (`sudoers.lan`) necesita un registro A para resolver:

```bash
@    IN    A    ${IP}
```

Sin esto, `sudoers.lan` no resuelve a ninguna IP. El registro CNAME anterior (`sudoers IN CNAME www.sudoers.lan`) creaba un subdominio `sudoers.sudoers.lan`, no el dominio raíz.

### Flujo completo de una consulta

```
Cliente (192.168.0.x) → pregunta "web.sudoers.lan"
         ↓
Bind9 recibe en puerto 53
         ↓
Verifica match-clients → IP del cliente está en 192.168.0.0/24 → view "wlo1"
         ↓
Busca en zona "sudoers.lan" de la view wlo1
         ↓
Encuentra: web IN A 192.168.0.105
         ↓
Responde: 192.168.0.105
```

## Referencias

- [Documentación oficial de BIND9](https://www.isc.org/bind/)
- [Herramienta dig](https://linux.die.net/man/1/dig)
- [RFC 1034 - Domain Names](https://datatracker.ietf.org/doc/html/rfc1034)
