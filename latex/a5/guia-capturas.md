# Guía de Capturas de Pantalla — Servidor Web (Nginx en Debian)

Ejecuta los siguientes comandos en **la máquina del servidor Debian** o desde los **clientes de prueba** de la red local según corresponda.

---

## 1. Estado de arranque del servicio Nginx

**Archivo:** `captura-web-arranque.png`  
**Ubicación:** `latex/a5/figuras/captura-web-arranque.png`  
**Dónde ejecutar:** En el servidor Debian.  
**Comandos:**
```bash
sudo systemctl status nginx
sudo ss -tulpn | grep nginx
```
**Qué mostrar:** La terminal con la salida de `systemctl status nginx` mostrando `Active: active (running)` y los puertos 80 y 443 en escucha (`LISTEN`).

---

## 2. Sitio web institucional en el navegador

**Archivo:** `captura-web-sitio.png`  
**Ubicación:** `latex/a5/figuras/captura-web-sitio.png`  
**Dónde ejecutar:** En un navegador web de un cliente o del servidor.  
**URL:** `https://web.sudoers.lan` o `https://sudoers.lan`  
**Qué mostrar:** La ventana del navegador mostrando la landing page del proyecto "Grupo 1 Sudoers" con el candado HTTPS y el diseño web completo.

---

## 3. Acceso a servicios internos a través del Proxy Inverso

**Archivo:** `captura-web-proxy.png`  
**Ubicación:** `latex/a5/figuras/captura-web-proxy.png`  
**Dónde ejecutar:** En el navegador web o terminal.  
**URL:** `https://print.sudoers.lan` (CUPS) o `https://files.sudoers.lan`  
**Comando alternativo (terminal):**
```bash
curl -k -I https://print.sudoers.lan
curl -k -I https://files.sudoers.lan
curl -k -I https://portainer.sudoers.lan
curl -k -I https://zabbix.sudoers.lan
```
**Qué mostrar:** La interfaz web de CUPS o Filebrowser accedida bajo HTTPS a través del proxy inverso de Nginx, o la salida `HTTP/1.1 200 OK` de los comandos `curl`.

---

## 4. Verificación del certificado SSL/TLS

**Archivo:** `captura-web-cert.png`  
**Ubicación:** `latex/a5/figuras/captura-web-cert.png`  
**Dónde ejecutar:** En la terminal de Debian o cliente con acceso al puerto 443.  
**Comando:**
```bash
openssl s_client -connect web.sudoers.lan:443 -servername web.sudoers.lan </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```
**Qué mostrar:** La terminal mostrando los datos del certificado auto-firmado:
`subject=CN=sudoers.lan, O=TSO-II, C=AR`, `issuer=CN=sudoers.lan, O=TSO-II, C=AR` y las fechas de validez.
