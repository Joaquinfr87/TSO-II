# Evitar la suspensión al cerrar la tapa (laptop como servidor)

## Objetivo

Configurar Debian para que una laptop usada como servidor no se suspenda al cerrar la tapa, modificando el comportamiento del gestor de sesiones de `systemd`.

## Requisitos previos

- Laptop con Debian funcionando como servidor.
- Acceso con privilegios de administración (`sudo`).
- Una segunda máquina desde donde verificar la conexión (opcional, pero recomendado).

## Pasos

1. Abre el archivo de configuración principal de `logind`:

    ```bash
    sudo nvim /etc/systemd/logind.conf
    ```

2. Busca la línea `#HandleLidSwitch=suspend` (por lo general está comentada con un `#`). Quita el símbolo `#` y cambia el valor a `ignore` para que quede exactamente así:

    ```ini
    HandleLidSwitch=ignore
    ```

    *(Opcional: para mayor seguridad si la laptop está conectada a la corriente, también puedes buscar y modificar `HandleLidSwitchExternalPower=ignore`.)*

3. Guarda los cambios y cierra el archivo (`:wq`).

4. Reinicia el servicio para que Debian aplique la nueva configuración de inmediato:

    ```bash
    sudo systemctl restart systemd-logind
    ```

## Verificación

Desde tu otra máquina, deja corriendo un ping continuo (`ping <IP_DEL_SERVER>`) y cierra la bisagra de la laptop. El ping no debería interrumpirse.

> **Advertencia:** al reiniciar el servicio `systemd-logind` (paso 4), es posible que tu sesión actual de SSH o terminal se cierre abruptamente. Esto es normal; solo vuelve a conectarte de inmediato.
