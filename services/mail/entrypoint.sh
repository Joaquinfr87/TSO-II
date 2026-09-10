#!/bin/bash
set -e

# ========================================
# Entrypoint del servidor de correo
# Postfix (SMTP) + Dovecot (IMAP/POP3)
# ========================================

DOMAIN="${MAIL_DOMAIN:-mail.sudoers.lan}"
BASE_DOMAIN="${DOMAIN#*.}"      # "sudoers.lan"

echo "============================================"
echo "  Servidor de Correo"
echo "  Dominio:    ${DOMAIN}"
echo "  Base domain: ${BASE_DOMAIN}"
echo "============================================"

# ========================================
# 1. Generar certificado SSL auto-firmado
# ========================================
SSL_DIR="/etc/ssl"
CERT_FILE="${SSL_DIR}/certs/mail.pem"
KEY_FILE="${SSL_DIR}/private/mail.key"

if [ ! -f "$CERT_FILE" ]; then
    echo ">>> Generando certificado SSL auto-firmado..."
    openssl req -new -x509 -days 3650 -nodes \
        -out "$CERT_FILE" \
        -keyout "$KEY_FILE" \
        -subj "/CN=${DOMAIN}/O=TSO-II/C=AR" \
        2>/dev/null
    chmod 600 "$KEY_FILE"
    echo ">>> Certificado generado: ${CERT_FILE}"
else
    echo ">>> Certificado SSL ya existe, omitiendo generación"
fi

# ========================================
# 2. Configurar Postfix
# ========================================
echo ">>> Configurando Postfix..."
postconf -e "myhostname=${DOMAIN}"
postconf -e "mydomain=${BASE_DOMAIN}"
postconf -e "myorigin=${BASE_DOMAIN}"

# ========================================
# 3. Configurar Dovecot
# ========================================
echo ">>> Configurando Dovecot..."
# Los archivos de configuración ya están copiados por el Dockerfile.

# ========================================
# 4. Crear usuarios de correo
# ========================================
echo ">>> Creando usuarios de correo..."

USERS="joaquin:joaquin:adminpass123 nicolas:nicolas:adminpass123 david:david:adminpass123"

for ENTRY in $USERS; do
    IFS=: read -r USERNAME _ PASSWORD <<< "$ENTRY"

    if id "$USERNAME" &>/dev/null; then
        echo "    Usuario ${USERNAME} ya existe, omitiendo"
    else
        useradd -m -s /bin/bash "$USERNAME"
        echo "${USERNAME}:${PASSWORD}" | chpasswd
        echo "    Usuario ${USERNAME} creado"
    fi

    # Crear estructura Maildir
    MAILDIR="/home/${USERNAME}/Maildir"
    mkdir -p "${MAILDIR}/"{cur,new,tmp}
    chown -R "${USERNAME}:${USERNAME}" "${MAILDIR}"
    chmod -R 700 "${MAILDIR}"
    echo "    Maildir configurado para ${USERNAME}"
done

# ========================================
# 5. Configurar aliases
# ========================================
echo ">>> Configurando aliases..."
cat > /etc/aliases << 'EOF'
root: joaquin
mailer-daemon: postmaster
postmaster: root
EOF
newaliases 2>/dev/null || true

# ========================================
# 6. Crear directorio para el socket de autenticación de Dovecot
# ========================================
mkdir -p /var/run/dovecot
rm -f /var/run/dovecot/auth-master
chown dovecot:dovecot /var/run/dovecot
chmod 755 /var/run/dovecot

# Crear directorio de logs
mkdir -p /var/log
touch /var/log/mail.log /var/log/dovecot.log

# ========================================
# 7. Iniciar servicios
# ========================================
echo ">>> Iniciando Postfix..."
postfix start

echo ">>> Verificando configuración Postfix..."
postconf -n | head -20

echo "============================================"
echo "  Servidor de correo listo"
echo "  SMTP:       ${DOMAIN}:25"
echo "  Submission: ${DOMAIN}:587"
echo "  IMAP:       ${DOMAIN}:143"
echo "  IMAPS:      ${DOMAIN}:993"
echo "  POP3:       ${DOMAIN}:110"
echo "  POP3S:      ${DOMAIN}:995"
echo ""
echo "  Usuarios: joaquin, nicolas, david"
echo "============================================"

# Dovecot en foreground (PID 1)
exec dovecot -F
