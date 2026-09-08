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

# Iniciar el daemon CUPS
cupsd

# Esperar a que CUPS esté listo
sleep 2

# Verificar que la impresora virtual PDF exista, si no crearla
if ! lpstat -p PDF &>/dev/null; then
    echo ">>> Creando impresora virtual PDF..."
    lpadmin -p PDF \
        -E \
        -v "cups-pdf:/" \
        -m lsb/usr/cups-pdf/CUPS-PDF_opt.ppd \
        -o printer-is-shared=true \
        -o job-sheets=none
    echo ">>> Impresora virtual PDF creada correctamente."
fi

# Activar la cola para aceptar trabajos
cupsenable PDF
cupsaccept PDF

echo "============================================"
echo "  Servidor de impresión CUPS iniciado"
echo "  Interfaz web: http://localhost:631"
echo "  Impresora:    PDF (virtual)"
echo "  Admin user:   ${ADMIN_USER}"
echo "============================================"

# Mantener el contenedor ejecutándose
exec tail -f /var/log/cups/error_log
