#!/bin/bash
set -e

mkdir -p /srv/share /database
chmod -R 777 /srv/share

USERS="nicolas joaquin david"
PASS="sudoers123"

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
    
    # Crear usuarios en Filebrowser con permisos de administracion/escritura
    for u in $USERS; do
        filebrowser users add "$u" "$PASS" --perm.admin=true --db "$DB_FILE"
    done
else
    # Asegurar que las contraseñas esten actualizadas si ya existe la DB
    for u in $USERS; do
        filebrowser users update "$u" --password "$PASS" --perm.admin=true --db "$DB_FILE" 2>/dev/null || \
        filebrowser users add "$u" "$PASS" --perm.admin=true --db "$DB_FILE" 2>/dev/null || true
    done
fi

echo ">>> Iniciando Filebrowser (Web) en el puerto 80..."
filebrowser --db "$DB_FILE" --root /srv/share --address 0.0.0.0 --port 80 &

echo ">>> Iniciando Samba (SMB) para Thunar / Explorador de archivos..."
exec /usr/sbin/smbd --foreground --no-process-group
