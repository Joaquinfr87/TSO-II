# Guía de Capturas de Pantalla — Configuración DHCP y Servidor Web

Ejecuta los siguientes comandos en **la máquina del servidor Debian** o desde los **clientes de prueba** de la red local según corresponda.

---

## 1. Estado de arranque del servicio Kea DHCP

**Archivo:** `captura-systemctl-kea.png`  
**Ubicación:** `latex/a5/figuras/captura-systemctl-kea.png`  
**Dónde ejecutar:** En el servidor Debian.  
**Comandos:**
```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl restart kea-dhcp4-server
sudo systemctl status kea-dhcp4-server
```
**Qué mostrar:** La terminal con la salida de la comprobación de sintaxis `Configuration check successful` y el estado `Active: active (running)` del servicio. Se puede capturar antes y después de configurar Kea.

---

## 2. Asignación de dirección IP a un cliente (DHCP)

**Archivo:** `captura-cliente-ip.png`  
**Ubicación:** `latex/a5/figuras/captura-cliente-ip.png`  
**Dónde ejecutar:** En un equipo cliente de la red local.  
**Comandos:**
```bash
sudo dhclient -v eth0
ip a
ip route
resolvectl status
```
**Qué mostrar:** La terminal del cliente mostrando la dirección IP asignada dentro del ámbito dinámico (`192.168.0.110`–`192.168.0.254`), la máscara `/24`, la puerta de enlace y el servidor DNS entregados por Kea.

---

## 3. Registro de concesiones en el servidor

**Archivo:** `captura-leases.png`  
**Ubicación:** `latex/a5/figuras/captura-leases.png`  
**Dónde ejecutar:** En el servidor Debian.  
**Comando:**
```bash
cat /var/lib/kea/kea-leases4.csv
```
**Qué mostrar:** El contenido del archivo de concesiones de Kea con la dirección IP entregada, la dirección MAC del cliente y los tiempos de renovación/expiración de cada lease.

---

## 4. Estado de arranque del servicio Nginx

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

## 5. Sitio web institucional en el navegador

**Archivo:** `captura-web-sitio.png`  
**Ubicación:** `latex/a5/figuras/captura-web-sitio.png`  
**Dónde ejecutar:** En un navegador web de un cliente o del servidor.  
**URL:** `https://web.sudoers.lan` o `https://sudoers.lan`  
**Qué mostrar:** La ventana del navegador mostrando la landing page del proyecto "Grupo 1 Sudoers" con el candado HTTPS y el diseño web completo.

---

## 6. Acceso a servicios internos a través del Proxy Inverso

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

## 7. Verificación del certificado SSL/TLS

**Archivo:** `captura-web-cert.png`  
**Ubicación:** `latex/a5/figuras/captura-web-cert.png`  
**Dónde ejecutar:** En la terminal de Debian o cliente con acceso al puerto 443.  
**Comando:**
```bash
openssl s_client -connect web.sudoers.lan:443 -servername web.sudoers.lan </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```
**Qué mostrar:** La terminal mostrando los datos del certificado auto-firmado:
`subject=CN=sudoers.lan, O=TSO-II, C=AR`, `issuer=CN=sudoers.lan, O=TSO-II, C=AR` y las fechas de validez.
