# Servicio: Servidor de impresión (CUPS + impresora virtual PDF)

Servidor de impresión con **CUPS** (Common Unix Printing System) y una impresora virtual basada en **cups-pdf** que genera archivos PDF a partir de los trabajos de impresión.

## Responsable

**Joaquín**

## Propósito

Ofrecer un servicio de impresión compartido en la red local. Los trabajos enviados a la impresora virtual se guardan como archivos PDF en un volumen persistente, permitiendo probar el funcionamiento del servidor sin una impresora física.

## Archivos

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Construcción de la imagen con CUPS y cups-pdf |
| `cupsd.conf` | Configuración del demonio CUPS |
| `entrypoint.sh` | Script de inicio: crea usuario admin, inicia CUPS y configura la impresora virtual |

## Uso

```bash
# Desde la raíz del repositorio
docker compose up -d --build print
```

## Verificación

1. **Interfaz web**: acceder a `http://localhost:1631` (usuario: `admin`, contraseña: `admin`).
2. **Imprimir una página de prueba**:
   ```bash
   # Desde el host
   lp -d PDF -h localhost:${CUPS_PORT:-1631} archivo.txt

   # O desde otro contenedor en la red tso-net
   lp -d PDF -h tso-print:631 archivo.txt
   ```
3. **Verificar los PDFs generados**:
   ```bash
   # Los archivos aparecen en el volumen print_output
   docker compose exec print ls /var/spool/cups-pdf/OUT/
   ```

## Comandos del cliente CUPS

Los clientes (máquina con `cups-client` instalado) usan estos comandos para hablar con el servidor. Todos usan `-h <servidor>:<puerto>` para apuntar al CUPS remoto.

| Comando | Qué hace |
|---|---|
| `lp -d PDF -h server:631 archivo` | Envía `archivo` a la impresora `PDF` |
| `lpstat -h server:631 -p` | Lista las impresoras del servidor |
| `lpstat -h server:631 -d` | Muestra la impresora por defecto |
| `lpstat -h server:631 -o` | Lista los trabajos en la cola |
| `lpq -h server:631` | Muestra la cola de espera |
| `lprm -h server:631 123` | Cancela el trabajo `123` |
| `lpadmin -h server:631 -p PDF -E` | Activa una impresora (admin) |

> `lp` = *line printer*; es el comando estándar para imprimir en Unix/Linux. Envía el trabajo por el protocolo **IPP** (puerto 631) al servidor CUPS.

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `CUPS_PORT` | `1631` | Puerto en el host para la interfaz web de CUPS (evita conflicto con CUPS del host) |
| `CUPS_ADMIN_USER` | `admin` | Usuario administrador de CUPS |
| `CUPS_ADMIN_PASS` | `admin` | Contraseña del administrador |

## Estado

- [x] Servidor CUPS funcionando
- [x] Impresora virtual PDF configurada
- [x] Interfaz web accesible
- [ ] Configurar impresoras físicas (si se conectan al servidor)
- [ ] Integrar con DNS (registro del servicio)
- [ ] Agregar autenticación segura para producción

## Interacción con otros servicios

- **DNS**: puede registrar un hostname `print.sudoers.lan` apuntando al servidor.
- **Samba**: se puede compartir la impresora virtual vía SMB para clientes Windows.

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
- Documentación CUPS: https://openprinting.github.io/cups/
