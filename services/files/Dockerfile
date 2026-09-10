# Servidor de archivos con Samba (SMB) y Filebrowser (Web)
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends samba curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Instalar Filebrowser
RUN curl -fsSL https://github.com/filebrowser/filebrowser/releases/latest/download/linux-amd64-filebrowser.tar.gz | tar -xzv -C /usr/local/bin filebrowser

COPY smb.conf /etc/samba/smb.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /srv/share /database && chmod -R 777 /srv/share

EXPOSE 445 139 80

ENTRYPOINT ["/entrypoint.sh"]