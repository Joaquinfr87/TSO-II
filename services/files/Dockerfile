# Servidor de archivos con Samba
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends samba && \
    rm -rf /var/lib/apt/lists/*

COPY smb.conf /etc/samba/smb.conf
RUN mkdir -p /srv/share

EXPOSE 445 139

CMD ["/usr/sbin/smbd", "--foreground", "--no-process-group"]