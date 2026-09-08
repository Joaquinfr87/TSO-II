# Servidor de correo con Postfix (SMTP) y Dovecot (IMAP/POP3)
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends postfix dovecot-imapd dovecot-pop3d && \
    rm -rf /var/lib/apt/lists/*

COPY main.cf /etc/postfix/main.cf
COPY 10-mail.conf /etc/dovecot/conf.d/10-mail.conf

EXPOSE 25 110 143

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]