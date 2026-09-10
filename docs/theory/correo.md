# Correo Electrónico: SMTP, IMAP, POP3 y cómo configurar un servidor

Este documento cubre la teoría completa detrás del correo electrónico: los protocolos que lo mueven, los componentes de un servidor, cómo se autentica el correo, y cómo lo configuramos en nuestro proyecto.

## ¿Qué es un servidor de correo?

Un servidor de correo es el equivalente digital del correo postal. Cuando mandás un email, ese email no va directo al destinatario: pasa por una cadena de servidores que lo enrutan, lo almacenan y lo entregan. Un servidor de correo es cada eslabón de esa cadena.

En términos técnicos, un servidor de correo cumple tres roles fundamentales:

| Rol | Siglas | Qué hace | Ejemplo |
|---|---|---|---|
| **Mail Transfer Agent** | MTA | Recibe y enruta correo entre servidores | Postfix, Exim, Sendmail |
| **Mail Delivery Agent** | MDA | Entrega el correo al buzón del usuario | Dovecot (local delivery) |
| **Mail User Agent** | MUA | Interfaz con la que el usuario lee/escribe | Thunderbird, Outlook, mutt |

En nuestro proyecto usamos **Postfix** como MTA y **Dovecot** como MDA/IMA (Internet Message Access).

## Los protocolos del correo

### SMTP (Simple Mail Transfer Protocol) — envío

SMTP es el protocolo que se usa para **enviar** y ** transferir** correo entre servidores. Funciona así:

```
Cliente (Thunderbird)          Postfix (MTA)           Postfix (MTA) externo
      |                            |                          |
      |-- "MAIL FROM: yo@lan" ---->|                          |
      |-- "RCPT TO: them@lan" --->|                          |
      |-- "DATA" ---------------->|                          |
      |-- "Hola, esto es..." --->|                          |
      |-- "." (fin del mensaje)->|                          |
      |<-- "250 OK" --------------|                          |
      |                            |-- Conexión SMTP ------->|
      |                            |   (puerto 25 o 587)     |
      |                            |   "MAIL FROM:..."       |
      |                            |   "RCPT TO:..."         |
      |                            |   "DATA" + contenido    |
      |                            |<-- "250 OK" ------------|
```

**Puertos SMTP:**

| Puerto | Uso |
|---|---|
| **25** | Transferencia entre servidores (MTA↔MTA). Bloqueado en muchas ISP domésticas |
| **587** | Submission: clientes envían correo al servidor con autenticación |
| **465** | SMTPS: SMTP sobre TLS (obsoleto pero aún usado) |

**Comandos SMTP más comunes:**

```
EHLO mail.sudoers.lan     # Identificarse
MAIL FROM:<yo@lan>        # Remitente
RCPT TO:<ellos@lan>       # Destinatario
DATA                      # Empieza el cuerpo del mensaje
.                         # Fin del mensaje (punto solo en una línea)
QUIT                      # Terminar sesión
```

### IMAP (Internet Message Access Protocol) — lectura

IMAP es el protocolo que los clientes usan para **leer** correo. A diferencia de POP3, IMAP mantiene los mensajes en el servidor y sincroniza el estado:

```
Cliente (Thunderbird)              Dovecot (IMAP)
      |                                |
      |-- LOGIN joaquin password ----->|
      |<-- OK logged in ---------------|
      |                                |
      |-- LIST "" "*" --------------->|  (¿qué carpetas hay?)
      |<-- INBOX, Sent, Drafts -------|
      |                                |
      |-- SELECT INBOX --------------->|  (abrir buzón)
      |<-- 17 mensajes, 3 no leídos --|
      |                                |
      |-- FETCH 1 BODY[] ------------>|  (leer mensaje #1)
      |<-- "De: admin@lan..." --------|
      |                                |
      |-- STORE 1 +FLAGS \Seen ------>|  (marcar como leído)
      |<-- OK -------------------------|
```

**Puerto IMAP:**
- **143**: IMAP sin cifrar
- **993**: IMAPS (IMAP sobre TLS)

**Ventajas de IMAP sobre POP3:**
- Los mensajes permanecen en el servidor
- Sincronización entre múltiples dispositivos
- Carpetas en el servidor (Sent, Drafts, Trash)
- Búsqueda del lado del servidor

### POP3 (Post Office Protocol v3) — descarga

POP3 descarga los correos al cliente y (por defecto) los **borra del servidor**:

```
Cliente                        Dovecot (POP3)
  |                                |
  |-- USER joaquin --------------->|
  |-- PASS password -------------->|
  |<-- +OK logged in --------------|
  |                                |
  |-- STAT ----------------------->|  (¿cuántos mensajes, cuánto espacio?)
  |<-- +OK 5 12345 ----------------|
  |                                |
  |-- RETR 1 --------------------->|  (descargar mensaje #1)
  |<-- +OK [contenido] ------------|
  |                                |
  |-- DELE 1 --------------------->|  (marcar para borrar)
  |<-- +OK ------------------------|
  |                                |
  |-- QUIT ----------------------->|  (borrar marcados y salir)
  |<-- +OK bye --------------------|
```

**Puerto POP3:**
- **110**: POP3 sin cifrar
- **995**: POP3S (POP3 sobre TLS)

**Cuándo usar POP3 vs IMAP:**

| Criterio | POP3 | IMAP |
|---|---|---|
| ¿Querés copia en el servidor? | No (solo local) | Sí |
| ¿Más de un dispositivo? | Problemático | Ideal |
| ¿Espacio en servidor limitado? | Sí (bueno) | No (los mensajes ocupan espacio) |
| ¿Acceso web? | No | Sí (Roundcube, etc.) |

### Comparación visual

```
                    SMTP                    IMAP/POP3
              (envío y tránsito)          (acceso del usuario)

Cliente ──────► Postfix ──────► Postfix ──────► Dovecot ◄────── Cliente
(Thunderbird)   (nuestro)       (remoto)        (nuestro)      (Thunderbird)
  puerto 587      puerto 25       puerto 25      puerto 143/993
```

## Componentes de nuestro servidor

### Postfix (MTA)

Postfix es el demonio que se encarga de:
1. **Recibir** correo entrante (puerto 25)
2. **Enviar** correo saliente
3. **Autenticar** a los usuarios que quieren enviar (SASL)
4. **Cifrar** la conexión (TLS)

Configuración clave en `main.cf`:

```
myhostname = mail.sudoers.lan     # Nombre completo de este servidor
mydomain = sudoers.lan            # Dominio del proyecto
myorigin = $mydomain              # Remitente visible ("de" del email)
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
mynetworks = 127.0.0.0/8, 192.168.0.0/16  # Redes que confían en este servidor
home_mailbox = Maildir/            # Dónde guarda los emails de cada usuario
```

### Dovecot (MDA / IMAP / POP3)

Dovecot es el demonio que:
1. **Almacena** el correo en el buzón del usuario
2. ** sirve ** el correo a los clientes via IMAP o POP3
3. **Autentica** a los usuarios contra `/etc/passwd`
4. **Cifra** la conexión (TLS)

### DNS (Bind9)

El registro **MX** (Mail Exchange) le dice al mundo hacia dónde enviar el correo de un dominio:

```
sudoers.lan.    IN    MX    10    mail.sudoers.lan.
```

Esto significa: "el correo para `@sudoers.lan` va a `mail.sudoers.lan` con prioridad 10". Sin este registro, cualquier servidor externo no sabe dónde entregar el correo de nuestro dominio.

El registro **A** del subdominio `mail` también es necesario:

```
mail.sudoers.lan.    IN    A    192.168.20.226
```

## Flujo completo de un email

```
1. Juancito (en su PC) escribe un email en Thunderbird
   "De: joaquin@sudoers.lan  Para: nicolas@sudoers.lan"

2. Thunderbird se conecta a mail.sudoers.lan:587 (submission)
   y se autentica con usuario/contraseña

3. Postfix recibe el email, verifica:
   - ¿El remitente está autenticado? → Sí
   - ¿El destinatario es local? → Sí (nicolas@sudoers.lan es nuestro dominio)

4. Postfix entrega el email al MDA (Dovecot)
   Dovecot lo guarda en /home/nicolas/Maildir/

5. Nicolas abre Thunderbird, se conecta a mail.sudoers.lan:143 (IMAP)
   y ve el email nuevo en su buzón
```

Si el destinatario fuera externo (ej: `nicolas@gmail.com`):
1. Postfix consulta DNS: ¿cuál es el MX de gmail.com?
2. DNS responde: `gmail-smtp-in.l.google.com`
3. Postfix se conecta a ese servidor por puerto 25
4. Transfiere el email via SMTP
5. El servidor de Google lo entrega al buzón de Nicolas

## Formatos de almacenamiento: Maildir vs mbox

### mbox (un archivo por buzón)

```
/var/mail/nicolas          ← UN SOLO ARCHIVO con todos los emails
┌─────────────────────────┐
│ From nicolas@lan lun... │ ← Email 1
│ De: admin@lan...        │
│                         │
│ From admin@lan mar...   │ ← Email 2
│ De: joaquin@lan...      │
└─────────────────────────┘
```

**Ventajas**: simple, compatible con许多 tools.
**Desventajas**: un bloqueo en un email bloquea todo el buzño, riesgo de corrupción, no funciona bien con IMAP concurrente.

### Maildir (un archivo por email)

```
/home/nicolas/Maildir/
├── cur/                   ← Emails ya leídos
│   ├── 1694000000.V802I2e3f8d0:2,S
│   └── 1694000001.V802I2e3f8d1:2,S
├── new/                   ← Emails nuevos (no vistos)
│   └── 1694000002.V802I2e3f8d2:2,S
└── tmp/                   ← Temporal (operaciones atómicas)
```

**Ventajas**: cada email es un archivo independiente, ideal para IMAP, no hay bloqueos, más resiliente.
**Desventajas**: muchos archivos en disco (millones de emails = problemas de inode).

**En nuestro proyecto usamos Maildir** porque es el estándar para Dovecot + IMAP y permite acceso concurrente sin problemas.

## Autenticación: SASL

**SASL** (Simple Authentication and Security Layer) es el mecanismo que permite a Postfix autenticar usuarios antes de dejarles enviar correo. Sin SASL, cualquiera en la red podría enviar correo como si fuera otro usuario.

```
Cliente                  Postfix
  |                        |
  |-- EHLO --------------->|
  |<-- 250-AUTH LOGIN PLAIN|  (anuncia que soporta autenticación)
  |                        |
  |-- AUTH LOGIN --------->|
  |-- (usuario en base64)->|
  |-- (contraseña en b64)->|
  |<-- 235 Authentication  |  (aceptado)
  |     successful         |
  |                        |
  |-- MAIL FROM:<yo@lan>-->|  (ahora sí puede enviar)
```

La configuración SASL en Postfix apunta a Dovecot para verificar credenciales:

```
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
```

Esto significa: "cuando alguien quiera autenticarse, consultá a Dovecot via el socket `private/auth`".

## Cifrado: TLS/SSL

TLS cifra la conexión entre el cliente y el servidor para que nadie en la red pueda leer los emails ni las credenciales.

### En Postfix (SMTP con STARTTLS)

El cliente se conecta sin cifrar y luego negocia cifrado:

```
Cliente                    Postfix
  |                          |
  |-- EHLO ----------------->|
  |<-- 250-STARTTLS ----------|  (soporta cifrado)
  |                          |
  |-- STARTTLS ------------->|  (¿empezamos a cifrar?)
  |<-- 220 Ready to start ---|
  |                          |
  |   [Negociación TLS]     |
  |   [Certificado server]  |
  |   [Llave compartida]    |
  |                          |
  |-- EHLO (ahora cifrado)->|
  |<-- 250-AUTH -------------|
```

### En Dovecot (IMAP con TLS)

Similar, pero en los puertos 993 (IMAPS) o 143 con STARTTLS.

### Certificados auto-firmados

En nuestro entorno interno usamos certificados **auto-firmados**: el servidor genera su propio certificado con `openssl`. No es válido para Internet (los clientes mostrarán advertencia), pero para una red interna es perfecto.

```bash
openssl req -new -x509 -days 3650 -nodes \
  -out /etc/ssl/certs/mail.pem \
  -keyout /etc/ssl/private/mail.key \
  -subj "/CN=mail.sudoers.lan"
```

## Autenticación de correo: SPF, DKIM y DMARC

Estos mecanismos existen para evitar que alguien **falsifique** emails haciéndose pasar por tu dominio.

### SPF (Sender Policy Framework)

Registro DNS que lista qué IPs están autorizadas a enviar correo en nombre de tu dominio:

```
sudoers.lan.  IN  TXT  "v=spf1 ip4:192.168.20.226 -all"
```

Significado: "solo `192.168.20.226` puede enviar correo como `@sudoers.lan`. Rechazar todo lo demás."

### DKIM (DomainKeys Identified Mail)

Firma digitalmente cada email con una llave privada. El destinatario verifica la firma con tu llave pública (publicada en DNS):

```
# Registro DNS
default._domainkey.sudoers.lan.  IN  TXT  "v=DKIM1; k=rsa; p=MIGfMA0GCS..."
```

### DMARC (Domain-based Message Authentication)

Indica a los receptores qué hacer si SPF o DKIM fallan:

```
_dmarc.sudoers.lan.  IN  TXT  "v=DMARC1; p=quarantine; rua=mailto:admin@sudoers.lan"
```

**En nuestro proyecto interno no configuramos SPF/DKIM/DMARC** porque todo el tráfico es local. Son relevantes para servidores de correo públicos.

## El archivo /etc/aliases

Postfix usa `/etc/aliases` para redirigir correo:

```
# /etc/aliases
root: joaquin           # Todo correo para root va a joaquin
admin: joaquin, nicolas # admin recibe varios usuarios
```

Después de editar, ejecutar `newaliases` para regenerar la base de datos hash.

## Logs y debugging

### Ubicación de logs

```bash
# Postfix
/var/log/mail.log          # Log general de correo
/var/log/mail.err          # Solo errores

# Dovecot
/var/log/mail.log          # También logea aquí
```

### Comandos útiles para debugging

```bash
# Ver el estado de la cola de correo
postqueue -p

# Forzar reintentos
postqueue -f

# Verificar configuración de Postfix
postconf -n                # Solo valores no-default
postconf -d                # Todos los valores default

# Probar conexión SMTP
telnet mail.sudoers.lan 25
EHLO test
MAIL FROM:<test@test.com>
RCPT TO:<joaquin@sudoers.lan>

# Ver logs en tiempo real
docker compose logs -f mail
```

## Variables de entorno en nuestro proyecto

| Variable | Default | Descripción |
|---|---|---|
| `MAIL_DOMAIN` | `mail.sudoers.lan` | Dominio completo del servidor de correo |

El `entrypoint.sh` usa esta variable para configurar `myhostname` y `mydomain` en Postfix.

## Seguridad del servidor de correo

1. **No开放 relay**: que el servidor no reenvíe correo de desconocidos. Controlado por `mynetworks`.
2. **Autenticación obligatoria**: solo usuarios autenticados pueden enviar (SASL).
3. **TLS**: cifrar las conexiones para proteger credenciales y contenido.
4. **Rate limiting**: limitar la cantidad de emails por usuario para prevenir spam.
5. **Logs**: monitorear quién envía qué y cuándo.

## Referencias

- [Postfix Documentation](https://www.postfix.org/docs.html)
- [Dovecot Wiki](https://wiki.dovecot.org/)
- [RFC 5321 - SMTP](https://datatracker.ietf.org/doc/html/rfc5321)
- [RFC 3501 - IMAP](https://datatracker.ietf.org/doc/html/rfc3501)
- [RFC 1939 - POP3](https://datatracker.ietf.org/doc/html/rfc1939)
