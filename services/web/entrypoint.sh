#!/bin/sh
set -e

DOMAIN="${WEB_DOMAIN:-sudoers.lan}"

SSL_DIR="/etc/ssl"
CERT_FILE="${SSL_DIR}/certs/web.pem"
KEY_FILE="${SSL_DIR}/private/web.key"

if [ ! -f "$CERT_FILE" ]; then
    echo ">>> Generando certificado SSL auto-firmado para ${DOMAIN}..."
    mkdir -p "${SSL_DIR}/certs" "${SSL_DIR}/private"
    openssl req -new -x509 -days 3650 -nodes \
        -out "$CERT_FILE" \
        -keyout "$KEY_FILE" \
        -subj "/CN=${DOMAIN}/O=TSO-II/C=AR" \
        -addext "subjectAltName = DNS:${DOMAIN}, DNS:*.${DOMAIN}" \
        2>/dev/null
    chmod 600 "$KEY_FILE"
    echo ">>> Certificado generado: ${CERT_FILE}"
else
    echo ">>> Certificado SSL ya existe, omitiendo generación"
fi

exec "$@"