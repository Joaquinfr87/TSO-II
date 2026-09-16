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

echo "==> [1/5] Validando sintaxis de nftables.conf ..."
if sudo nft -c -f "$DIR/nftables.conf" 2>/dev/null; then
    echo "    sintaxis OK"
else
    echo "    ERROR: sintaxis inválida en $DIR/nftables.conf"
    echo "    No se aplica NADA para no perder conectividad."
    exit 1
fi

echo "==> [2/5] Aplicando firewall ..."
sudo cp "$DIR/nftables.conf" /etc/nftables.conf
# Borra SOLO nuestra tabla (ip tso_filter) para no arrastrar las cadenas
# internas de Docker. Un "flush ruleset" global rompería el NAT de los
# contenedores (error "No chain/target/match by that name").
sudo nft delete table ip tso_filter 2>/dev/null || true
sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables >/dev/null 2>&1 || true
echo "    firewall activo (tabla ip tso_filter)"

echo "==> [3/5] Respaldo y validación de sshd_config ..."
if [ -f /etc/ssh/sshd_config ]; then
    BACKUP="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
    sudo cp /etc/ssh/sshd_config "$BACKUP"
    echo "    respaldo en $BACKUP"
fi
sudo cp "$DIR/sshd_config" /etc/ssh/sshd_config

echo "==> [4/5] Verificando y reiniciando ssh ..."
if sudo sshd -t; then
    sudo systemctl restart ssh
    echo "    ssh reiniciado correctamente"
else
    echo "    ERROR: sshd -t falló. No se reinicia ssh."
    echo "    Restaurar respaldo:"
    echo "      sudo cp $BACKUP /etc/ssh/sshd_config && sudo systemctl restart ssh"
    exit 1
fi

echo "==> [5/5] Instalando y configurando zabbix-agent2 ..."
# Instala el agente Zabbix en el host (métricas reales: CPU, RAM, disco, red).
# El server corre en el contenedor tso-zabbix-server y expone 10051 en el host.
if ! command -v zabbix_agent2 >/dev/null 2>&1; then
    if [ ! -f /tmp/zabbix-release.deb ]; then
        wget -q -O /tmp/zabbix-release.deb \
            https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian13_all.deb
    fi
    sudo dpkg -i /tmp/zabbix-release.deb >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq zabbix-agent2
else
    echo "    zabbix-agent2 ya instalado"
fi
sudo cp "$DIR/zabbix_agent2.conf" /etc/zabbix/zabbix_agent2.conf
sudo systemctl enable zabbix-agent2 >/dev/null 2>&1 || true
sudo systemctl restart zabbix-agent2
if systemctl is-active --quiet zabbix-agent2; then
    echo "    zabbix-agent2 corriendo (hostname: ts-server)"
else
    echo "    ERROR: zabbix-agent2 no inició. Ver: systemctl status zabbix-agent2"
fi

echo
echo "===================================================================="
echo "  Deploy completado."
echo "  * Firewall nftables: tabla inet filter aplicada y habilitada"
echo "  * SSH: config endurecida (claves, sin root, solo admins)"
echo "  * Zabbix agent2: instalado en el host (métricas del servidor físico)"
echo "  * Probar en OTRA terminal: ssh joaquin@<server>"
echo
echo "  Para el monitoreo: levantar el stack con docker compose"
echo "    docker compose up -d --build"
echo "  Y configurar las alertas en https://zabbix.sudoers.lan"
echo
echo "  Si los contenedores pierden red tras aplicar el firewall,"
echo "  reiniciar Docker (recrea sus cadenas):"
echo "    sudo systemctl restart docker"
echo "===================================================================="