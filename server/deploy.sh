#!/bin/bash
set -euo pipefail

# ===================================================================
# deploy.sh — Aplica la configuración de servidor versionada en el repo.
#
# Uso (EN EL SERVIDOR, dentro del repo clonado):
#   git pull
#   sudo bash server/deploy.sh
#
# Hace validaciones antes de aplicar para no dejar el server sin acceso.
# ===================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> [1/4] Validando sintaxis de nftables.conf ..."
if sudo nft -c -f "$DIR/nftables.conf" 2>/dev/null; then
    echo "    sintaxis OK"
else
    echo "    ERROR: sintaxis inválida en $DIR/nftables.conf"
    echo "    No se aplica NADA para no perder conectividad."
    exit 1
fi

echo "==> [2/4] Aplicando firewall ..."
sudo cp "$DIR/nftables.conf" /etc/nftables.conf
# Borra SOLO nuestra tabla (inet filter) para no arrastrar las cadenas
# internas de Docker. Un "flush ruleset" global rompería el NAT de los
# contenedores (error "No chain/target/match by that name").
sudo nft delete table inet filter 2>/dev/null || true
sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables >/dev/null 2>&1 || true
echo "    firewall activo (tabla inet filter)"

echo "==> [3/4] Respaldo y validación de sshd_config ..."
if [ -f /etc/ssh/sshd_config ]; then
    BACKUP="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
    sudo cp /etc/ssh/sshd_config "$BACKUP"
    echo "    respaldo en $BACKUP"
fi
sudo cp "$DIR/sshd_config" /etc/ssh/sshd_config

echo "==> [4/4] Verificando y reiniciando ssh ..."
if sudo sshd -t; then
    sudo systemctl restart ssh
    echo "    ssh reiniciado correctamente"
else
    echo "    ERROR: sshd -t falló. No se reinicia ssh."
    echo "    Restaurar respaldo:"
    echo "      sudo cp $BACKUP /etc/ssh/sshd_config && sudo systemctl restart ssh"
    exit 1
fi

echo
echo "===================================================================="
echo "  Deploy completado."
echo "  * Firewall nftables: tabla inet filter aplicada y habilitada"
echo "  * SSH: config endurecida (claves, sin root, solo admins)"
echo "  * Probar en OTRA terminal: ssh joaquin@<server>"
echo
echo "  Si los contenedores pierden red tras aplicar el firewall,"
echo "  reiniciar Docker (recrea sus cadenas):"
echo "    sudo systemctl restart docker"
echo "===================================================================="