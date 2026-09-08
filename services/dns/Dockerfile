# Servidor DNS con Bind9
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bind9 \
        bind9utils \
        dnsutils \
        iproute2 && \
    rm -rf /var/lib/apt/lists/*

# Directorio para zonas
RUN mkdir -p /etc/bind/zones

# Copiar entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 53/udp 53/tcp

USER root
CMD ["/entrypoint.sh"]