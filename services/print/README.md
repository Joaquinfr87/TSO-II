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

1. **Interfaz web**: acceder a `http://localhost:631` (usuario: `admin`, contraseña: `admin`).
2. **Imprimir una página de prueba**:
   ```bash
   # Desde el host
   lp -d PDF -h localhost:631 archivo.txt

   # O desde otro contenedor en la red tso-net
   lp -d PDF -h tso-print:631 archivo.txt
   ```
3. **Verificar los PDFs generados**:
   ```bash
   # Los archivos aparecen en el volumen print_output
   docker compose exec print ls /var/spool/cups-pdf/OUT/
   ```

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `CUPS_PORT` | `631` | Puerto en el host para la interfaz web de CUPS |
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

- **DNS**: puede registrar un hostname `print.tsolab.local` apuntando al servidor.
- **Samba**: se puede compartir la impresora virtual vía SMB para clientes Windows.

## Referencias

- Teoría: [Docker en un servidor Debian](../../docs/theory/docker.md)
- Guía de flujo: [Uso colaborativo de Docker](../../docs/guides/docker-compose-flujo.md)
- Documentación CUPS: https://openprinting.github.io/cups/
