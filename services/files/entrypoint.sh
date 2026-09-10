#!/bin/bash
set -e

mkdir -p /srv/share /database /var/lib/nfs/v4recovery /run/samba
chmod -R 777 /srv/share

USERS="nicolas joaquin david"
PASS="sudoers123"

# Crear usuarios Linux y registrar contraseñas Samba
for u in $USERS; do
    if ! id "$u" >/dev/null 2>&1; then
        useradd -M -g users -s /usr/sbin/nologin "$u"
    fi
    (echo "$PASS"; echo "$PASS") | smbpasswd -a -s "$u"
done

# Inicializar base de datos de Filebrowser si no existe
DB_FILE="/database/filebrowser.db"

if [ ! -f "$DB_FILE" ]; then
    echo ">>> Inicializando Filebrowser DB..."
    filebrowser config init --db "$DB_FILE" --root /srv/share --address 0.0.0.0 --port 80 --signup=false
    
    for u in $USERS; do
        filebrowser users add "$u" "$PASS" --perm.admin=true --db "$DB_FILE"
    done
else
    for u in $USERS; do
        filebrowser users update "$u" --password "$PASS" --perm.admin=true --db "$DB_FILE" 2>/dev/null || \
        filebrowser users add "$u" "$PASS" --perm.admin=true --db "$DB_FILE" 2>/dev/null || true
    done
fi

# Inicializar y arrancar servidor NFS (Kernel)
echo ">>> Iniciando servicios NFS..."
cp -f /etc/exports.bak /etc/exports 2>/dev/null || true
rpcbind 2>/dev/null || true
exportfs -arv 2>/dev/null || true
rpc.nfsd 8 2>/dev/null || true
rpc.mountd 2>/dev/null || true

# Arrancar Filebrowser en segundo plano
echo ">>> Iniciando Filebrowser (Web) en el puerto 80..."
filebrowser --db "$DB_FILE" --root /srv/share --address 0.0.0.0 --port 80 &

# Arrancar Samba en primer plano
echo ">>> Iniciando Samba (SMB) para Thunar / Windows..."
exec /usr/sbin/smbd --foreground --no-process-group
