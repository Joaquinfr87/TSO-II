# Servicio: Servidor de correo (Postfix + Dovecot)

Servidor de correo electrónico con **Postfix** para envío/recepción (SMTP) y **Dovecot** para acceso de los clientes (IMAP/POP3).

## Responsable

**Joaquín**

## Propósito

Recibir y entregar correo dentro del dominio del proyecto con cuentas de usuario, accesible por SMTP/IMAP.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con Postfix y Dovecot |
| `main.cf` | Configuración de Postfix (SMTP) |
| `10-mail.conf` | Configuración de Dovecot (IMAP/POP3) |
| `entrypoint.sh` | Script de inicio que aplica el dominio por variables |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build mail
```

> Este servicio es el más complejo del proyecto (configuración de DNS MX, autenticación, usuarios). Ver las consignas de la materia antes de completar la configuración.

## Estado

- [ ] Definir el dominio de correo real
- [ ] Configurar las cuentas de usuario
- [ ] Agregar registros MX/SPF al DNS (íntegra con el servicio DNS)
- [ ] Verificar entrega local y acceso IMAP

## Interacción con otros servicios

Depende del **DNS** (registro MX) y de los **usuarios** del sistema. Coordinar con el responsable del servicio DNS.

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)