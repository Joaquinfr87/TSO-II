# Guia de Capturas de Pantalla - Servidor de Correo

Ejecuta los comandos en **la maquina donde esta instalado el servidor** (Debian).
Si el servidor corre en un contenedor Docker, reemplaza `systemctl` por los
comandos correspondientes del contenedor.

---

## 1. Levantamiento del servicio (Docker o systemctl)

**Archivo:** `captura-docker-compose.png`
**Comando:**
```bash
docker compose up -d mail
```
**Que mostrar:** la salida del terminal donde se levanta el contenedor.
Si no usas Docker, usa:
```bash
systemctl restart postfix dovecot
systemctl status postfix dovecot
```
y captura la salida de `systemctl status`.

---

## 2. Verificacion DNS con dig

**Archivo:** `captura-dig-mx.png`
**Comando:**
```bash
dig +short MX sudoers.lan
dig +short mail.sudoers.lan
```
**Que mostrar:** las dos lineas de resultado mostrando que resuelve a
`10 mail.sudoers.lan` y `192.168.0.105`.

---

## 3. Configuracion de Postfix (postconf)

**Archivo:** `captura-postconf.png`
**Comando (dentro del contenedor o en el servidor):**
```bash
postconf -n
```
**Que mostrar:** la lista de parametros efectivos de Postfix,
especialmente `myhostname`, `mydomain`, `mynetworks`, `smtpd_sasl_*`.
Si el servidor esta en Docker: `docker exec tso-mail postconf -n`

---

## 4. Configuracion de Dovecot (doveconf)

**Archivo:** `captura-doveconf.png`
**Comando:**
```bash
doveconf -n
```
**Que mostrar:** los parametros activos de Dovecot (`protocols`,
`mail_location`, `ssl`, `auth_mechanisms`).
Docker: `docker exec tso-mail doveconf -n`

---

## 5. Prueba de conectividad a puertos

**Archivo:** `captura-puertos.png`
**Comando (desde la maquina CLIENTE, no el servidor):**
```bash
for p in 25 110 143 587 993 995; do
  timeout 3 bash -c "echo > /dev/tcp/192.168.0.105/$p" \
    && echo "puerto $p: ABIERTO"
done
```
**Que mostrar:** los 6 puertos marcados como ABIERTO.

---

## 6. Banner SMTP (prueba con nc)

**Archivo:** `captura-smtp-banner.png`
**Comando (desde la maquina CLIENTE):**
```bash
echo "QUIT" | nc 192.168.0.105 25
```
**Que mostrar:** la respuesta `220 mail.sudoers.lan ESMTP Postfix`.

---

## 7. Capacidades IMAP (prueba con nc)

**Archivo:** `captura-imap.png`
**Comando (desde la maquina CLIENTE):**
```bash
echo "LOGOUT" | nc 192.168.0.105 143
```
**Que mostrar:** la respuesta `* OK [... CAPABILITY IMAP4rev1 ...] Dovecot ready.`

---

## 8. Verificacion STARTTLS (openssl)

**Archivo:** `captura-starttls.png`
**Comando (desde la maquina CLIENTE):**
```bash
openssl s_client -connect 192.168.0.105:587 -starttls smtp
```
**Que mostrar:** las lineas con `subject=CN=mail.sudoers.lan` y
`Verify return code: 18 (self-signed certificate)`. Puedes hacer
scroll y mostrar solo esas lineas.

---

## 9. Envio de correo con swaks

**Archivo:** `captura-swaks.png`
**Comando (desde la maquina CLIENTE, necesita `apt install swaks`):**
```bash
swaks --to joaquin@sudoers.lan \
  --from nicolas@sudoers.lan \
  --server 192.168.0.105 --port 587 \
  --auth LOGIN --auth-user nicolas \
  --auth-password adminpass123 \
  --header "Subject: Prueba" \
  --body "Hola Joaquin, esto es una prueba."
```
**Que mostrar:** el intercambio completo SMTP, incluyendo
`250 2.0.0 Ok` y la respuesta final de exito.

---

## 10. Buzon Maildir con el correo recibido

**Archivo:** `captura-maildir.png`
**Comando (en el SERVIDOR):**
```bash
ls /home/joaquin/Maildir/new/
```
**Que mostrar:** el archivo del correo recibido con el nombre largo
que genera Postfix (timestamp + dominio).

---

## 11. Cliente Thunderbird conectado

**Archivo:** `captura-thunderbird.png`
**Proceso:**
1. Abre Thunderbird en la maquina cliente
2. Crea una cuenta nueva -> Configuracion manual
3. Entrada: `mail.sudoers.lan`, puerto 143, STARTTLS
4. Salida: `mail.sudoers.lan`, puerto 587, STARTTLS
5. Usuario: `joaquin`, password: `adminpass123`
6. Acepta la excepcion del certificado auto-firmado
7. Entra a la bandeja de entrada y abre el correo de prueba

**Que mostrar:** la ventana de Thunderbird con la bandeja de entrada
y el correo de prueba visible.

---

## Consejos generales

- Usa **ctrl+shift+s** (GNOME) o **scrot** / **flameshot** para tomar
  capturas de区域 selectiva.
- Si el terminal tiene mucho texto, muestra solo la parte relevante
  (scrolla hacia arriba si es necesario).
- Para capturar el terminal completo, usa la opcion "Exportar como
  imagen" del menu del terminal.
- Todas las capturas se guardan en `latex/a4/figuras/` y el PDF las
  muestra automaticamente al compilar.
