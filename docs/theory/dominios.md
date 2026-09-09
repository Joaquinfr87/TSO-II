# Dominios y resolución de nombres

Este documento explica qué es un dominio, la diferencia entre DNS público y local, por qué usamos `.lan` en lugar de `.local`, y qué dominios tiene nuestro proyecto.

## ¿Qué es un dominio?

Un **dominio** es un nombre jerárquico que identifica de forma única a un dispositivo, servicio u organización en una red. Los dominios existen para que las personas no tengan que recordar direcciones IP numéricas.

### Estructura jerárquica

```
www . sudoers . lan        ← subdominio . dominio . TLD
│      │        │
│      │        └── TLD (Top Level Domain): la terminación
│      └─────────── Dominio principal: identifica la organización
└────────────────── Subdominio: identifica un servicio o dispositivo
```

| Nivel | Ejemplo | Explicación |
|---|---|---|
| Subdominio | `web` | Un servicio específico (web, mail, files...) |
| Dominio | `sudoers` | El nombre principal de la organización |
| TLD | `.lan` | La terminación que clasifica el dominio |

## TLDs (Top Level Domains)

Las terminaciones se dividen en categorías:

| Categoría | Ejemplos | Uso |
|---|---|---|
| **Genéricos** | `.com`, `.org`, `.net`, `.edu` | Uso público global |
| **Country code** | `.ar`, `.es`, `.mx`, `.us` | Un país específico |
| **Infraestructura** | `.arpa` | Resolución inversa de IPs |
| **Especiales** | `.local`, `.lan`, `.test` | Redes locales y desarrollo |

Los TLDs especiales como `.local`, `.lan`, `.internal`, `.test` están reservados por la **IANA** (Internet Assigned Numbers Authority) para usos que no requieren registrar un dominio público.

## DNS público vs DNS local

### DNS público

El sistema DNS global es **distribuido y jerárquico**:

```
Cliente → DNS local → Raíz (.) → TLD (.com) → DNS autoritativo (google.com)
```

- El dominio debe estar **registrado** ante un registrador.
- La información viaja por servidores en Internet.
- Cualquiera en el mundo puede resolver el dominio.

### DNS local

Un DNS local administra dominios que **solo existen en nuestra red interna**:

- No requiere registro ni pagos.
- Solo los clientes que apuntan a nuestro servidor DNS pueden resolverlo.
- Se define en un archivo de zona del servidor DNS.

```
Cliente (192.168.0.x) → Nuestro DNS (192.168.0.105) → "web.sudoers.lan" → 192.168.0.105
```

## `.local` vs `.lan`: la decisión clave

Esta es la decisión que tomamos durante el desarrollo del proyecto.

### `.local` (mDNS)

`.local` está **reservado por la IANA** para **mDNS** (Multicast DNS, Zeroconf). Tecnologías como Bonjour de Apple y Avahi de Linux usan `.local` para descubrir dispositivos automáticamente en la red **sin servidor DNS**.

**El problema**: los dispositivos modernos (especialmente celulares) intentan resolver `.local` por **mDNS broadcast** primero, ignorando el DNS configurado. Si no encuentran el dispositivo, no preguntan a nuestro servidor DNS.

```
Celular: "¿existe web.sudoers.local? Mando un broadcast mDNS..."
          ... no responde nadie ...
          ... el celular NO pregunta al DNS configurado ...
browser: "No se encuentra el servidor"
```

### `.lan` (LAN - Local Area Network)

`.lan` **no está reservado** por IANA. Cuando un dispositivo no hay ningún uso especial, pregunta de forma normal al DNS configurado:

```
Celular → DNS (192.168.0.105) → "¿web.sudoers.lan?" → 192.168.0.105 ✓
```

### Comparación

| Aspecto | `.local` | `.lan` |
|---|---|---|
| Reservado por IANA | Sí (mDNS) | No |
| Resolución en celulares | Por mDNS broadcast (ignora tu DNS) | Vía DNS normal |
| Funciona con Bind9 | A veces, depende del cliente | Siempre |
| Riesgo de conflicto | Alto (nombres como "imac.local") | Bajo |

**Por eso cambiamos de `sudoers.local` a `sudoers.lan`.**

## Cómo apuntar un cliente a nuestro DNS

Para que un dispositivo resuelva `sudoers.lan`, debe usar `192.168.0.105` como servidor DNS.

### Linux (nmcli / NetworkManager)

```bash
nmcli connection modify "CONEXION" ipv4.dns "192.168.0.105"
nmcli connection modify "CONEXION" ipv4.ignore-auto-dns yes
nmcli connection up "CONEXION"
```

### Linux (manual, /etc/resolv.conf)

```
nameserver 192.168.0.105
```

> Nota: NetworkManager puede sobrescribir este archivo. Usar `nmcli` es preferible.

### iOS

Ajustes → WiFi → tocar `(i)` en la red → Configurar DNS → **Manual** → agregar `192.168.0.105` → Guardar

### Android

Ajustes → WiFi → mantener presionada la red → Modificar → Opciones avanzadas → Configuración IP → **Estática** → DNS 1: `192.168.0.105`

## Dominios de nuestro proyecto

Nuestro `entrypoint.sh` genera registros para todos los servicios. Estos son los dominios disponibles:

| Dominio | Tipo de registro | Servicio |
|---|---|---|
| `sudoers.lan` | A → 192.168.0.105 | Sitio principal |
| `web.sudoers.lan` | A → 192.168.0.105 | Servidor web (Nginx) |
| `www.sudoers.lan` | A → 192.168.0.105 | Alias del sitio principal |
| `ns1.sudoers.lan` | A → 192.168.0.105 | Nameserver (BIND9) |
| `dns.sudoers.lan` | A → 192.168.0.105 | DNS del proyecto |
| `dhcp.sudoers.lan` | A → 192.168.0.105 | DHCP (Kea) |
| `mail.sudoers.lan` | A → 192.168.0.105 | Correo (Postfix + Dovecot) |
| `files.sudoers.lan` | A → 192.168.0.105 | Archivos (Samba) |
| `print.sudoers.lan` | A → 192.168.0.105 | Impresión (CUPS) |

> Nota: en una red con dos interfaces (WiFi + LAN cableada), cada cliente ve la IP de **su propia red** gracias a las views de BIND9. El dominio es el mismo, la IP cambia según el cliente.

### Por qué todos apuntan a la misma IP

En nuestra configuración todos los servicios corren en **el mismo servidor físico**, publicado por Docker en el mismo host. Por eso `web`, `mail`, `files`, etc. comparten la misma IP. El header `Host` de HTTP (o el puerto) es el que Nginx usa para decidir qué servicio atiende cada petición.

## Resolución completa de una petición

```
1. Escribís: http://web.sudoers.lan
2. El navegador pregunta a su DNS (192.168.0.105): "¿cuál es la IP de web.sudoers.lan?"
3. Bind9 busca en la zona directa → responde 192.168.0.105
4. El navegador conecta a 192.168.0.105 en el puerto 80
5. Envía: GET / HTTP/1.1  Host: web.sudoers.lan
6. Nginx recibe, ve el header Host, elige el server block "web.sudoers.lan"
7. Nginx sirve index.html → HTTP 200 OK
8. El navegador muestra la página
```

### Y si le sacás el puerto

```
http://web.sudoers.lan     → puerto 80 por defecto → funciona
http://web.sudoers.lan:8080→ puerto 8080 → mismo sitio (mapeo alternativo)
http://print.sudoers.lan   → puerto 80 → Nginx redirige a CUPS (proxy inverso)
http://print.sudoers.lan:1631→ CUPS directo (sin pasar por Nginx)
```

## Referencias

- [IANA - Special-Use Domain Names](https://www.iana.org/assignments/special-use-domain-names/)
- [RFC 6762 - mDNS](https://datatracker.ietf.org/doc/html/rfc6762)
- [RFC 6761 - Special-Use Domain Names](https://datatracker.ietf.org/doc/html/rfc6761)
- Teoría: [DNS en este proyecto](./dns.md)
- Guía: [Configurar DNS de red](https://wiki.archlinux.org/title/Domain_name_resolution)