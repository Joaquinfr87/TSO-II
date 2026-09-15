#!/bin/bash
set -euo pipefail

# ===================================================================
# reset.sh — Restaura SSH y firewall a configuración por defecto
# (sin restricciones) para recuperar el acceso al servidor.
#
# Uso (EN EL SERVIDOR, dentro del repo clonado):
#   git pull
#   sudo bash server/reset.sh
#
# Deja:
#   * SSH accesible por contraseña (sin AllowUsers, sin AuthMethods)
#   * Firewall nftables con todo abierto (policy accept)
# Hace respaldo de lo que haya antes de reemplazar.
# ===================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

echo "==> [1/5] Respaldo de configuración actual ..."
if [ -f /etc/ssh/sshd_config ]; then
    sudo cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$TS"
    echo "    respaldo sshd_config -> /etc/ssh/sshd_config.bak.$TS"
fi
if [ -f /etc/nftables.conf ]; then
    sudo cp /etc/nftables.conf "/etc/nftables.conf.bak.$TS"
    echo "    respaldo nftables.conf -> /etc/nftables.conf.bak.$TS"
fi

echo "==> [2/5] Restaurando sshd_config por defecto ..."
sudo tee /etc/ssh/sshd_config > /dev/null <<'EOF'
# sshd_config — configuración por defecto (permissiva)
# Restaurada por server/reset.sh para recuperar el acceso.
Port 22
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
EOF
echo "    sshd_config restaurado (contraseña habilitada)"

echo "==> [3/5] Limpiando restricciones en sshd_config.d/*.conf ..."
for f in /etc/ssh/sshd_config.d/*.conf; do
    [ -e "$f" ] || continue
    echo "    limpiando $f"
    sudo sed -i.bak \
        -e 's/^[[:space:]]*\(PasswordAuthentication\).*/# &/' \
        -e 's/^[[:space:]]*\(KbdInteractiveAuthentication\).*/# &/' \
        -e 's/^[[:space:]]*\(AuthenticationMethods\).*/# &/' \
        -e 's/^[[:space:]]*\(PubkeyAuthentication\).*/# &/' \
        -e 's/^[[:space:]]*\(AllowUsers\).*/# &/' \
        -e 's/^[[:space:]]*\(AllowGroups\).*/# &/' \
        -e 's/^[[:space:]]*\(DenyUsers\).*/# &/' \
        -e 's/^[[:space:]]*\(DenyGroups\).*/# &/' \
        "$f" || true
done

echo "==> [4/5] Restaurando firewall (todo abierto) ..."
# Borra SOLO la tabla inet filter (la que creaba deploy.sh). NO toca las
# cadenas de Docker (nat, forward) para no romper los contenedores.
sudo nft delete table inet filter 2>/dev/null || true

sudo tee /etc/nftables.conf > /dev/null <<'EOF'
#!/usr/sbin/nft -f

# nftables — por defecto (todo abierto).
# Restaurada por server/reset.sh para recuperar el acceso.
table inet filter {
    chain input {
        type filter hook input priority filter; policy accept;
    }
    chain forward {
        type filter hook forward priority filter; policy accept;
    }
    chain output {
        type filter hook output priority filter; policy accept;
    }
}
EOF

sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables > /dev/null 2>&1 || true
echo "    firewall abierto (policy accept)"

echo "==> [5/5] Verificando y reiniciando ssh ..."
if sudo sshd -t; then
    sudo systemctl restart ssh
    echo "    ssh reiniciado correctamente"
else
    echo "    ERROR: sshd -t falló. No se reinicia ssh."
    echo "    Revisar /etc/ssh/sshd_config y volver a intentar."
    exit 1
fi

echo
echo "===================================================================="
echo "  Reset completado."
echo "  * SSH: permite contraseña, sin AllowUsers ni AuthMethods"
echo "  * Firewall: todo abierto"
echo "  Probar ahora:  ssh joaquin@<ip-del-servidor>"
echo "  Respaldos:     /etc/ssh/sshd_config.bak.$TS"
echo "                 /etc/nftables.conf.bak.$TS"
echo "===================================================================="