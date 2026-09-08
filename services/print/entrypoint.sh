#!/bin/bash
set -e

# Crear usuario admin si no existe (CUPS requiere un usuario con permisos)
ADMIN_USER="${CUPS_ADMIN_USER:-admin}"
ADMIN_PASS="${CUPS_ADMIN_PASS:-admin}"

if ! id "$ADMIN_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$ADMIN_USER"
fi

# Establecer contraseña del usuario admin
echo "${ADMIN_USER}:${ADMIN_PASS}" | chpasswd

# Agregar usuario al grupo administradores de CUPS
groupadd -f lpadmin
usermod -aG lpadmin "$ADMIN_USER"

# Asegurar que el directorio de salida de cups-pdf exista y sea accesible
mkdir -p /var/spool/cups-pdf/OUT
chmod 1777 /var/spool/cups-pdf/OUT

# Iniciar el daemon CUPS en primer plano
cupsd -f &
CUPSD_PID=$!

# Esperar a que CUPS esté listo (reintentar hasta 15 veces)
for i in $(seq 1 15); do
    if lpstat -h localhost:631 -r &>/dev/null; then
        break
    fi
    sleep 1
done

# Supresión de la advertencia de drivers deprecados
export CUPS_DATADIR=/usr/share/cups

# Verificar que la impresora virtual PDF exista, si no crearla
if ! lpstat -h localhost:631 -p PDF &>/dev/null; then
    echo ">>> Creando impresora virtual PDF..."
    lpadmin -h localhost:631 -p PDF \
        -E \
        -v "cups-pdf:/" \
        -m lsb/usr/cups-pdf/CUPS-PDF_opt.ppd \
        -o printer-is-shared=true \
        -o job-sheets=none
    echo ">>> Impresora virtual PDF creada correctamente."
fi

# Activar la cola para aceptar trabajos
cupsenable -h localhost:631 PDF
cupsaccept -h localhost:631 PDF

echo "============================================"
echo "  Servidor de impresión CUPS iniciado"
echo "  Interfaz web: http://localhost:631"
echo "  Impresora:    PDF (virtual)"
echo "  Admin user:   ${ADMIN_USER}"
echo "============================================"

# Esperar al daemon CUPS manteniendo el contenedor vivo
wait "$CUPSD_PID"