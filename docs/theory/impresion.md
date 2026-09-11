# Impresión en red: CUPS

Este documento cubre la teoría del sistema de impresión CUPS, el protocolo IPP y cómo lo usamos en el servicio `print` con una impresora virtual PDF.

## ¿Qué es CUPS?

CUPS (**C**ommon **U**nix **P**rinting **S**ystem) es el sistema de impresión estándar en Linux/Unix y macOS. Permite:

- **Descubrir** impresoras de la red (IPP, etc.).
- **Gestionar** colas de impresión con prioridades, pausas y cancelación.
- **Compartir** impresoras a otros equipos de la red.
- Exponer una **interfaz web** de administración en el puerto `631`.

## El protocolo IPP

CUPS habla **IPP** (Internet Printing Protocol), un protocolo sobre HTTP (puerto `631`) que describe y envía trabajos de impresión. Por eso la interfaz web de CUPS está en `http://<servidor>:631`.

## Anatomía de un trabajo de impresión

1. El cliente envía el documento al servidor con `lp`.
2. CUPS recibe el dato, lo almacena en `spool` (área de espera) y lo mete en la **cola** de la impresora elegida.
3. Un **filtro** convierte el formato (texto, PDF, imágenes) al lenguaje de la impresora (PostScript, PWG-Raster, etc.).
4. Un **backend** envía el resultado al dispositivo físico o a un destino especial (como un archivo PDF).

```
lpr archivo.txt --> CUPS (spool) --> filtro --> backend --> impresora/PDF
```

## Impresora virtual PDF (cups-pdf)

**cups-pdf** es un backend especial: en lugar de imprimir en papel, **genera un archivo PDF** por cada trabajo. Es ideal para probar el servicio de impresión sin hardware:

```
lp -d PDF archivo.txt  →  /var/spool/cups-pdf/OUT/archivo.pdf
```

En el proyecto, ese directorio es el volumen persistente `print_output`.

## Comandos del lado cliente

| Comando | Qué hace |
|---|---|
| `lp -d <impresora> archivo` | Envía un archivo a imprimir |
| `lpstat -p` | Lista impresoras |
| `lpstat -o` | Lista trabajos en cola |
| `lpq` | Muestra la cola de espera |
| `lprm <id>` | Cancela un trabajo |

Todos aceptan `-h <servidor>:<puerto>` para apuntar a un CUPS remoto.

## Cómo lo implementamos en el proyecto

El contenedor `tso-print` ejecuta CUPS con la impresora virtual `PDF` ya configurada por el `entrypoint.sh`, expuesto en el puerto `1631` del host (para no chocar con un CUPS local).

```bash
# Interfaz web
http://print.sudoers.lan          (usuario: admin)

# Imprimir una página de prueba
lp -d PDF -h localhost:1631 archivo.txt

# Ver los PDFs generados en el volumen
docker compose exec print ls /var/spool/cups-pdf/OUT/
```

**DNS:** el registro `print.sudoers.lan` resuelve al host, y Nginx proxea al CUPS interno (`print.sudoers.lan:80` → `tso-print:631`).

**Firewall:** CUPS queda abierto para la red de usuarios (`server/nftables.conf`):

```
tcp dport 1631 ip saddr @user_net accept
```

## Referencias

- Servicio: [services/print/README.md](../../services/print/README.md)
- Documentación CUPS: https://openprinting.github.io/cups/