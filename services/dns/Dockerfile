# Servidor DNS con Bind9
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends bind9 bind9utils dnsutils && \
    rm -rf /var/lib/apt/lists/*

# Zonas del dominio
COPY zones/ /etc/bind/zones/

# Configuración de opciones generales
COPY named.conf /etc/bind/named.conf

EXPOSE 53/udp 53/tcp

USER root
CMD ["/usr/sbin/named", "-g", "-u", "bind", "-c", "/etc/bind/named.conf"]