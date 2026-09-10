# Servidor de archivos multi-protocolo: Samba (SMB), Filebrowser (Web) y NFS
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends samba nfs-kernel-server rpcbind curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Instalar Filebrowser
RUN curl -fsSL https://github.com/filebrowser/filebrowser/releases/latest/download/linux-amd64-filebrowser.tar.gz | tar -xzv -C /usr/local/bin filebrowser

COPY smb.conf /etc/samba/smb.conf
COPY exports /etc/exports
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /srv/share /database /var/lib/nfs/v4recovery && chmod -R 777 /srv/share

EXPOSE 445 139 80 2049 111

ENTRYPOINT ["/entrypoint.sh"]