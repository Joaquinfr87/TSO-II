# Instalar paquetes en un servidor sin internet: proxy APT y NAT

## Objetivo

Permitir que un servidor Debian sin acceso directo a internet (máquina B) instale paquetes y, si hace falta, acceda a internet de forma temporal, aprovechando otra máquina de la red local (máquina A) que sí tiene conexión. No es necesario mover paquetes manualmente en memorias USB.

## Requisitos previos

- Dos máquinas conectadas por red local: la máquina A (con internet) y el servidor B (sin internet).
- Acceso con privilegios de administración (`sudo`) en ambas.
- Conocer la IP local de la máquina A y el nombre de la interfaz de red que tiene salida a internet (`ip a`).

## Método 1: Proxy APT con `apt-cacher-ng`

Es la opción más limpia si solo quieres instalar paquetes. El servidor sigue sin acceso a internet general, pero redirige sus peticiones de `apt` a la máquina A, la cual descarga y cachea los paquetes.

### En la máquina A (con internet)

1. Instala el servicio de caché:

    ```bash
    sudo apt update
    sudo apt install apt-cacher-ng
    ```

2. Asegúrate de que el servicio esté corriendo:

    ```bash
    sudo systemctl enable --now apt-cacher-ng
    ```

### En la máquina B (servidor offline)

1. Indícale a `apt` que use la máquina A como proxy (reemplaza la IP por la IP local de la máquina A):

    ```bash
    echo 'Acquire::http::Proxy "http://<IP_MAQUINA_A>:3142";' | sudo tee /etc/apt/apt.conf.d/00proxy
    ```

2. Ya puedes actualizar e instalar normalmente:

    ```bash
    sudo apt update
    sudo apt install <nombre_del_paquete>
    ```

## Método 2: Compartir conexión mediante NAT (enrutamiento)

Úsalo si necesitas que el servidor B descargue imágenes de Docker, use `curl` o tenga internet completo de forma temporal. Convierte la máquina A en un router.

### En la máquina A (con internet)

1. Habilita el reenvío de paquetes temporalmente:

    ```bash
    sudo sysctl -w net.ipv4.ip_forward=1
    ```

2. Configura el enmascaramiento. Reemplaza `eth0` por el nombre de la interfaz que **tiene salida a internet** (puedes verla con `ip a`):

    ```bash
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ```

### En la máquina B (servidor offline)

1. Añade la máquina A como puerta de enlace predeterminada (reemplaza la IP por la IP local de la máquina A):

    ```bash
    sudo ip route add default via <IP_MAQUINA_A>
    ```

2. Configura un servidor DNS temporalmente para poder resolver dominios:

    ```bash
    echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
    ```

3. Verifica la conexión e instala lo que necesites:

    ```bash
    ping -c 4 debian.org
    sudo apt update
    ```

## Verificación

- **Método 1:** desde el servidor B, `sudo apt update` funciona sin errores usando el proxy.
- **Método 2:** desde el servidor B, `ping -c 4 debian.org` responde y la navegación/descargas funcionan.

## ¿Cuál elegir?

Utiliza el **Método 1** si quieres mantener el servidor estrictamente aislado de internet por seguridad, pero necesitas gestionar paquetes. Utiliza el **Método 2** si necesitas desplegar contenedores, clonar repositorios de Git o realizar tareas más allá del gestor `apt`.
