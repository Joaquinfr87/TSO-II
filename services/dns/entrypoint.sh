#!/bin/bash
set -e

# ========================================
# Entrypoint para Bind9 con Views
# Soporta 2 redes simultáneas (wlo1 + eno1)
# ========================================

DOMAIN="${DNS_DOMAIN:-sudoers.lan}"
IP_WLO1="${DNS_IP_WLO1:-}"
IP_ENO1="${DNS_IP_ENO1:-}"
ZONES_DIR="/etc/bind/zones"

# ========================================
# Detectar IPs si no se especificaron
# ========================================
if [ -z "$IP_WLO1" ]; then
    IP_WLO1=$(ip -4 addr show wlo1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
fi

if [ -z "$IP_ENO1" ]; then
    IP_ENO1=$(ip -4 addr show eno1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
fi

if [ -z "$IP_WLO1" ] && [ -z "$IP_ENO1" ]; then
    echo "ERROR: No se detectó ninguna IP"
    echo "Especificá DNS_IP_WLO1 y/o DNS_IP_ENO1 en .env"
    exit 1
fi

# ========================================
# Función para generar zona directa
# ========================================
generar_zona() {
    local IP=$1
    local LABEL=$2
    local IFS='.'
    read -r i1 i2 i3 i4 <<< "$IP"

    cat > "${ZONES_DIR}/db.${DOMAIN}.${LABEL}" << EOF
; Zona ${LABEL} - ${IP}
\$TTL    604800
@       IN      SOA     ns1.${DOMAIN}. admin.${DOMAIN}. (
                        $(date +%Y%m%d)01
                        604800 86400 2419200 604800 )

@               IN      NS      ns1.${DOMAIN}.
ns1             IN      A       ${IP}
dns             IN      A       ${IP}
dhcp            IN      A       ${IP}
web             IN      A       ${IP}
www             IN      A       ${IP}
files           IN      A       ${IP}
mail            IN      A       ${IP}
print           IN      A       ${IP}
@               IN      A       ${IP}
@               IN      MX      10 mail.${DOMAIN}.
EOF

    cat > "${ZONES_DIR}/db.${i3}.${i2}.${i1}" << EOF
; Zona inversa ${LABEL} - ${i1}.${i2}.${i3}.0/24
\$TTL    604800
@       IN      SOA     ns1.${DOMAIN}. admin.${DOMAIN}. (
                        $(date +%Y%m%d)01
                        604800 86400 2419200 604800 )

@               IN      NS      ns1.${DOMAIN}.
${i4}              IN      PTR     ns1.${DOMAIN}.
${i4}              IN      PTR     dns.${DOMAIN}.
${i4}              IN      PTR     web.${DOMAIN}.
${i4}              IN      PTR     mail.${DOMAIN}.
${i4}              IN      PTR     files.${DOMAIN}.
${i4}              IN      PTR     print.${DOMAIN}.
EOF

    echo ">>> Zonas ${LABEL} generadas (${IP})"
}

# ========================================
# Generar named.conf.options
# ========================================
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    recursion yes;
    allow-query { any; };
    dnssec-validation auto;
    forwarders { 192.168.0.1; 1.1.1.1; };
};
EOF

# ========================================
# Generar named.conf con Views
# ========================================
cat > /etc/bind/named.conf << 'EOF'
// named.conf — Bind9 con Views
// Generado automáticamente por entrypoint.sh
include "/etc/bind/named.conf.options";

EOF

# View WLO1
if [ -n "$IP_WLO1" ]; then
    IFS='.' read -r w1 w2 w3 w4 <<< "$IP_WLO1"
    generar_zona "$IP_WLO1" "wlo1"

    cat >> /etc/bind/named.conf << EOF
view "wlo1" {
    match-clients { ${w1}.${w2}.${w3}.0/24; };

    zone "${DOMAIN}" {
        type primary;
        file "/etc/bind/zones/db.${DOMAIN}.wlo1";
    };
    zone "${w3}.${w2}.${w1}.in-addr.arpa" {
        type primary;
        file "/etc/bind/zones/db.${w3}.${w2}.${w1}";
    };
};

EOF
    echo ">>> View WLO1 configurada"
fi

# View ENO1
if [ -n "$IP_ENO1" ]; then
    IFS='.' read -r e1 e2 e3 e4 <<< "$IP_ENO1"
    generar_zona "$IP_ENO1" "eno1"

    cat >> /etc/bind/named.conf << EOF
view "eno1" {
    match-clients { ${e1}.${e2}.${e3}.0/24; };

    zone "${DOMAIN}" {
        type primary;
        file "/etc/bind/zones/db.${DOMAIN}.eno1";
    };
    zone "${e3}.${e2}.${e1}.in-addr.arpa" {
        type primary;
        file "/etc/bind/zones/db.${e3}.${e2}.${e1}";
    };
};

EOF
    echo ">>> View ENO1 configurada"
fi

# View por defecto
FIRST_IP="${IP_WLO1:-$IP_ENO1}"
IFS='.' read -r f1 f2 f3 f4 <<< "$FIRST_IP"

cat >> /etc/bind/named.conf << EOF
// View por defecto (para consultas desde el contenedor)
view "default" {
    match-clients { any; };

    zone "${DOMAIN}" {
        type primary;
        file "/etc/bind/zones/db.${DOMAIN}.wlo1";
    };
};
EOF

# ========================================
# Verificar configuración
# ========================================
echo ">>> Verificando..."
named-checkconf /etc/bind/named.conf

if [ -n "$IP_WLO1" ]; then
    IFS='.' read -r w1 w2 w3 w4 <<< "$IP_WLO1"
    named-checkzone "${DOMAIN}" "${ZONES_DIR}/db.${DOMAIN}.wlo1"
fi

if [ -n "$IP_ENO1" ]; then
    IFS='.' read -r e1 e2 e3 e4 <<< "$IP_ENO1"
    named-checkzone "${DOMAIN}" "${ZONES_DIR}/db.${DOMAIN}.eno1"
fi

echo ">>> Configuración OK"

# ========================================
# Preparar directorios para named (corre como 'bind')
# ========================================
mkdir -p /run/named
chown bind:bind /run/named
chown -R bind:bind /var/cache/bind

# ========================================
# Resumen
# ========================================
echo "============================================"
echo "  DNS Bind9 con Views"
echo "  Dominio: ${DOMAIN}"
[ -n "$IP_WLO1" ] && echo "  WLO1:    ${IP_WLO1}"
[ -n "$IP_ENO1" ] && echo "  ENO1:    ${IP_ENO1}"
echo "============================================"

cd /var/cache/bind
exec /usr/sbin/named -g -u bind -c /etc/bind/named.conf
