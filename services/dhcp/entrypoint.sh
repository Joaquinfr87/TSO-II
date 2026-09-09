#!/bin/bash
set -e

# ========================================
# Entrypoint para Kea DHCP
# Reemplaza los tokens de kea-dhcp4.conf
# con las variables de entorno del .env
# ========================================

SUB="${DHCP_SUBNET:-192.168.1.0/24}"
POOL="${DHCP_POOL:-192.168.1.100 - 192.168.1.200}"
DNS_SRV="${DHCP_DNS:-${HOST_IP:-192.168.1.10}}"
DOMAIN="${DNS_DOMAIN:-sudoers.lan}"
ROUTER="${HOST_IP:-192.168.1.10}"

CONF="/etc/kea/kea-dhcp4.conf"

# Directorios de runtime y de concesiones (Kea corre como usuario _kea)
mkdir -p /run/kea /var/lib/kea
chown -R _kea:_kea /run/kea /var/lib/kea

# Reemplazar tokens de la plantilla
sed -i \
    -e "s|__DHCP_SUBNET__|${SUB}|g" \
    -e "s|__DHCP_POOL__|${POOL}|g" \
    -e "s|__DHCP_DNS__|${DNS_SRV}|g" \
    -e "s|__DNS_DOMAIN__|${DOMAIN}|g" \
    -e "s|__HOST_IP__|${ROUTER}|g" \
    "${CONF}"

echo "============================================"
echo "  DHCP Kea"
echo "  Subred:   ${SUB}"
echo "  Pool:     ${POOL}"
echo "  DNS:      ${DNS_SRV}"
echo "  Dominio:  ${DOMAIN}"
echo "  Gateway:  ${ROUTER}"
echo "============================================"

exec /usr/sbin/kea-dhcp4 -c "${CONF}"