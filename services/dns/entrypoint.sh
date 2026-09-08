#!/bin/bash
set -e

# ========================================
# Entrypoint para Bind9 - DNS dinámico
# Detecta la IP del servidor y genera
# los archivos de zona automáticamente
# ========================================

DOMAIN="${DNS_DOMAIN:-sudoers.local}"
SERVER_IP="${DNS_SERVER_IP:-}"
REVERSE_ZONE_DIR="/etc/bind/zones"

# Si no se especificó IP, detectarla automáticamente
if [ -z "$SERVER_IP" ]; then
    # Obtener la IP de la interfaz por defecto (la que tiene ruta por defecto)
    SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
    
    if [ -z "$SERVER_IP" ]; then
        # Fallback: usar la primera IP que no sea loopback
        SERVER_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    fi
fi

if [ -z "$SERVER_IP" ]; then
    echo "ERROR: No se pudo detectar la IP del servidor"
    echo "Especificá la variable DNS_SERVER_IP en docker-compose.yml"
    exit 1
fi

echo ">>> IP del servidor detectada: $SERVER_IP"

# Calcular la zona inversa (ej: 192.168.1.0/24 -> 1.168.192.in-addr.arpa)
IFS='.' read -r i1 i2 i3 i4 <<< "$SERVER_IP"
REVERSE_ZONE="${i3}.${i2}.${i1}.in-addr.arpa"
REVERSE_FILE="${REVERSE_ZONE_DIR}/db.${i3}.${i2}.${i1}"

# Calcular la red (asumimos /24)
NETWORK="${i1}.${i2}.${i3}.0/24"

echo ">>> Dominio: $DOMAIN"
echo ">>> Zona inversa: $REVERSE_ZONE"
echo ">>> Red: $NETWORK"

# ========================================
# Generar zona directa
# ========================================
cat > "${REVERSE_ZONE_DIR}/db.${DOMAIN}" << EOF
; Zona directa para ${DOMAIN}
; Generada automáticamente por entrypoint.sh
; IP del servidor: ${SERVER_IP}
\$TTL    604800
@       IN      SOA     ns1.${DOMAIN}. admin.${DOMAIN}. (
                        $(date +%Y%m%d)01  ; Serial (YYYYMMDDNN)
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL

; Nameservers
@               IN      NS      ns1.${DOMAIN}.

; Registros A - Servidores (usando IP detectada)
ns1             IN      A       ${SERVER_IP}
dns             IN      A       ${SERVER_IP}
dhcp            IN      A       ${SERVER_IP}
web             IN      A       ${SERVER_IP}
www             IN      A       ${SERVER_IP}
files           IN      A       ${SERVER_IP}
mail            IN      A       ${SERVER_IP}
print           IN      A       ${SERVER_IP}

; Registro MX - Correo
@               IN      MX      10 mail.${DOMAIN}.

; Registro CNAME (alias)
$(echo $DOMAIN | cut -d. -f1)    IN      CNAME   www.${DOMAIN}.
EOF

echo ">>> Zona directa generada: db.${DOMAIN}"

# ========================================
# Generar zona inversa
# ========================================
cat > "${REVERSE_FILE}" << EOF
; Zona inversa para ${NETWORK}
; Generada automáticamente por entrypoint.sh
; IP del servidor: ${SERVER_IP}
\$TTL    604800
@       IN      SOA     ns1.${DOMAIN}. admin.${DOMAIN}. (
                        $(date +%Y%m%d)01  ; Serial (YYYYMMDDNN)
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL

; Nameservers
@               IN      NS      ns1.${DOMAIN}.

; Registros PTR - Resolución inversa
${i4}              IN      PTR     ns1.${DOMAIN}.
${i4}              IN      PTR     dns.${DOMAIN}.
${i4}              IN      PTR     web.${DOMAIN}.
${i4}              IN      PTR     mail.${DOMAIN}.
${i4}              IN      PTR     files.${DOMAIN}.
${i4}              IN      PTR     print.${DOMAIN}.
EOF

echo ">>> Zona inversa generada: ${REVERSE_FILE}"

# ========================================
# Generar named.conf con la zona inversa correcta
# ========================================
cat > /etc/bind/named.conf << EOF
// named.conf — configuración de Bind9 para ${DOMAIN}
// Generada automáticamente por entrypoint.sh
options {
    directory "/var/cache/bind";
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    recursion yes;
    allow-query { any; };
    dnssec-validation auto;

    forwarders {
        1.1.1.1;
    };
};

// Zona directa
zone "${DOMAIN}" {
    type primary;
    file "/etc/bind/zones/db.${DOMAIN}";
};

// Zona inversa para ${NETWORK}
zone "${REVERSE_ZONE}" {
    type primary;
    file "${REVERSE_FILE}";
};
EOF

echo ">>> named.conf generado"

# ========================================
# Verificar configuración antes de iniciar
# ========================================
echo ">>> Verificando configuración de Bind9..."
named-checkconf /etc/bind/named.conf
named-checkzone "${DOMAIN}" "${REVERSE_ZONE_DIR}/db.${DOMAIN}"
named-checkzone "${REVERSE_ZONE}" "${REVERSE_FILE}"

echo ">>> Configuración correcta"

# ========================================
# Iniciar Bind9 en primer plano
# ========================================
echo "============================================"
echo "  Servidor DNS Bind9 iniciado"
echo "  Dominio:    ${DOMAIN}"
echo "  IP:         ${SERVER_IP}"
echo "  Zona:       ${REVERSE_ZONE}"
echo "============================================"

exec /usr/sbin/named -g -u bind -c /etc/bind/named.conf
