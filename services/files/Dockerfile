# Servidor de archivos con Samba
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends samba && \
    rm -rf /var/lib/apt/lists/*

# Crear usuarios de Linux y darles alta en Samba con la contraseña 'sudoers123'
RUN useradd -M -s /usr/sbin/nologin nicolas && \
    useradd -M -s /usr/sbin/nologin joaquin && \
    useradd -M -s /usr/sbin/nologin david && \
    (echo "sudoers123"; echo "sudoers123") | smbpasswd -a -s nicolas && \
    (echo "sudoers123"; echo "sudoers123") | smbpasswd -a -s joaquin && \
    (echo "sudoers123"; echo "sudoers123") | smbpasswd -a -s david

COPY smb.conf /etc/samba/smb.conf
RUN mkdir -p /srv/share && chmod -R 777 /srv/share

EXPOSE 445 139

CMD ["/usr/sbin/smbd", "--foreground", "--no-process-group"]