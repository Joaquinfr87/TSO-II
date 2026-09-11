# Guía: servidor de impresión CUPS

## Objetivo

Levantar el servidor CUPS con la impresora virtual PDF, imprimir un archivo y recuperar el PDF generado.

## Requisitos previos

- Repo clonado y `.env` configurado (variable `CUPS_PORT`).
- Cliente con `cups-client` instalado si se prueba desde otra máquina (`sudo apt install cups-client`).

## Pasos

### 1. Levantar el servicio

```bash
docker compose up -d --build print
```

### 2. Verificar la interfaz web

Abrir `http://print.sudoers.lan` (o `http://<IP>:1631`). Usuario/contraseña por defecto: `admin` / `admin` (ver `.env`).

### 3. Imprimir una página de prueba

```bash
# Desde el host
lp -d PDF -h localhost:1631 archivo.txt

# Desde otro contenedor de tso-net
lp -d PDF -h tso-print:631 archivo.txt
```

### 4. Recuperar el PDF

```bash
docker compose exec print ls /var/spool/cups-pdf/OUT/
```

El archivo aparece con el nombre del documento impreso y queda persistido en el volumen `print_output` (se puede copiar al host con `docker cp`).

## Gestión desde el cliente

| Comando | Qué hace |
|---|---|
| `lpstat -h localhost:1631 -p` | Lista impresoras |
| `lpstat -h localhost:1631 -o` | Trabajos en cola |
| `lpq -h localhost:1631` | Ver cola de espera |
| `lprm -h localhost:1631 <id>` | Cancelar trabajo |

> Todos los clientes usan `-h <host>:<puerto>`; el puerto del host es `CUPS_PORT` (default `1631`).

## Verificación

1. La interfaz web carga y muestra la impresora `PDF`.
2. Tras `lp`, el trabajo sale de la cola y aparece un `.pdf` en `print_output`.

## Referencias

- Teoría: [Impresión en red: CUPS](../theory/impresion.md)
- Servicio: [services/print/README.md](../../services/print/README.md)