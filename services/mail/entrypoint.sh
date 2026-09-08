#!/bin/sh
set -e

echo "___CONFIG_MAIL_DOMAIN=$MAIL_DOMAIN___"
postconf -e "mydomain=$MAIL_DOMAIN"
postconf -e "myorigin=$MAIL_DOMAIN"

# Iniciar Postfix y Dovecot
service rsyslog start
service postfix start
exec dovecot -F