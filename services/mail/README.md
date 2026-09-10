# Servicio: Servidor de correo (Postfix + Dovecot)

Servidor de correo electrónico con **Postfix** para envío/recepción (SMTP) y **Dovecot** para acceso de los clientes (IMAP/POP3).

## Responsable

**Joaquín**

## Propósito

Recibir y entregar correo dentro del dominio del proyecto con cuentas de usuario, accesible por SMTP/IMAP.

## Arquitectura

```
                         ┌─────────────────────────────────┐
                         │       tso-mail (contenedor)     │
                         │                                 │
Cliente ──── 587 ────────► Postfix (MTA/SMTP)             │
(Thunderbird)            │  ├─ SASL auth ──► Dovecot       │
                         │  ├─ TLS (STARTTLS)              │
                         │  └─ Delivery ──► Maildir        │
                         │                                 │
Cliente ──── 143 ────────► Dovecot (IMAP/POP3)            │
Cliente ──── 110 ────────►  ├─ Auth /etc/passwd            │
                         │  └─ Lee de ~/Maildir/           │
                         └─────────────────────────────────┘
                                    │
                          DNS (Bind9)
                     MX: mail.sudoers.lan
```

## Puertos

| Puerto | Protocolo | Servicio | Uso |
|--------|-----------|----------|-----|
| 25 | TCP | SMTP | Transferencia entre servidores |
| 587 | TCP | SMTP (submission) | Clientes envían correo (con auth) |
| 110 | TCP | POP3 | Acceso de clientes (descarga) |
| 143 | TCP | IMAP | Acceso de clientes (sync) |
| 993 | TCP | IMAPS | IMAP cifrado (TLS) |
| 995 | TCP | POP3S | POP3 cifrado (TLS) |

## Usuarios

| Usuario | Contraseña | Grupo |
|---------|------------|-------|
| joaquin | adminpass123 | sudo |
| nicolas | adminpass123 | sudo |
| david | adminpass123 | sudo |

> Cambiar las contraseñas antes de producción.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Postfix + Dovecot |
| `main.cf` | Configuración de Postfix (SMTP, SASL, TLS) |
| `10-mail.conf` | Configuración de Dovecot (mailbox, carpetas) |
| `10-auth.conf` | Autenticación de Dovecot (plain, login) |
| `10-ssl.conf` | SSL/TLS en Dovecot (cert auto-firmado) |
| `entrypoint.sh` | Script de inicio: genera certs, crea usuarios, inicia servicios |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build mail

# Ver logs
docker compose logs -f mail
```

## Cómo probar

### Con telnet (prueba básica SMTP)

```bash
telnet localhost 25
EHLO test
MAIL FROM:<test@sudoers.lan>
RCPT TO:<joaquin@sudoers.lan>
DATA
Hola, esto es una prueba.
.
QUIT
```

### Con un cliente de correo (Thunderbird)

1. Crear cuenta nueva
2. Configuración manual:
   - Servidor de entrada: `mail.sudoers.lan` (IMAP, puerto 143)
   - Servidor de salida: `mail.sudoers.lan` (SMTP, puerto 587)
   - Usuario: `joaquin`
   - Contraseña: `adminpass123`
   - Seguridad: STARTTLS para ambos

### Verificar con swaks

```bash
# Instalar: apt install swaks
swaks --to joaquin@sudoers.lan --from nicolas@sudoers.lan \
  --server localhost --port 587 \
  --auth LOGIN --auth-user nicolas --auth-password adminpass123 \
  --header "Subject: Prueba" --body "Hola"
```

### Verificar la cola de correo

```bash
docker exec tso-mail postqueue -p
```

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `MAIL_DOMAIN` | `mail.sudoers.lan` | Dominio completo del servidor de correo |

## Interacción con otros servicios

- **DNS**: necesita registro MX (`@ IN MX 10 mail.sudoers.lan`) y registro A (`mail IN A <IP>`) en la zona `sudoers.lan`
- **Dovecot ↔ Postfix**: Postfix usa SASL via socket de Dovecot para autenticar usuarios

## Estado

- [x] Configurar Postfix (SMTP con SASL, TLS, Maildir)
- [x] Configurar Dovecot (IMAP/POP3, auth, SSL)
- [x] Generar certificado SSL auto-firmado
- [x] Crear usuarios de correo (joaquin, nicolas, david)
- [x] Documentación teórica completa
- [ ] Verificar entrega con cliente de correo
- [ ] Configurar registros SPF/DKIM (si se necesita acceso externo)

## Referencias

- Teoría: [Correo Electrónico: SMTP, IMAP, POP3](../../docs/theory/correo.md)
- Teoría: [DNS: Domain Name System](../../docs/theory/dns.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
