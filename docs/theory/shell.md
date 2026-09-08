# El Shell en Linux

Este documento explica qué es un shell, cómo funciona y por qué es relevante en un servidor Debian. Para los pasos prácticos de instalación de Zsh, ver la guía [Instalar Zsh con Oh My Zsh](../guides/zsh-ohmyzsh.md).

## ¿Qué es un shell?

Un shell es un programa que interpreta los comandos que escribes en la terminal y los traduce en acciones que el sistema operativo puede ejecutar. Actúa como intermediario entre el usuario y el kernel de Linux. Cuando abres una terminal, estás dentro de un shell.

No confundir la terminal con el shell: la terminal es la aplicación gráfica (o emulador de terminal) que muestra la interfaz de texto, mientras que el shell es el intérprete que procesa lo que escribes dentro de ella.

## Cómo funciona un shell

1. El shell muestra un **prompt** (el símbolo `$` o algo similar) indicando que está listo para recibir comandos.
2. El usuario escribe un comando.
3. El shell busca el programa correspondiente en los directorios definidos en la variable `PATH`.
4. El shell ejecuta el programa, pasándole los argumentos que se indicaron.
5. El programa imprime su salida (éxito o error) y el shell vuelve a mostrar el prompt.
6. El shell también gestiona variables de entorno,-redirecciones, tuberías (`|`) y la ejecución de scripts.

## La relación entre login shell y no-login shell

Cuando un usuario inicia sesión, el sistema ejecuta un **login shell**. Este lee los archivos de configuración global y del usuario para preparar el entorno:

**Login shell** (al iniciar sesión):
- `/etc/profile` (configuración global).
- `~/.bash_profile`, `~/.bash_login` o `~/.profile` (del usuario, en ese orden de precedencia).

**No-login shell** (al abrir una nueva terminal o ejecutar `bash` sin iniciar sesión):
- `/etc/bash.bashrc` (configuración global, solo Debian).
- `~/.bashrc` (del usuario).

En Debian, `~/.profile` suele cargar `~/.bashrc` para que ambos entornos compartan la misma configuración.

## Variables de entorno relevantes

Las variables de entorno son pares clave-valor que el shell mantiene en memoria y que los programas leen para adaptar su comportamiento:

| Variable | Función | Ejemplo típico |
|---|---|---|
| `PATH` | Directorios donde el shell busca ejecutables | `/usr/local/bin:/usr/bin:/bin` |
| `HOME` | Directorio personal del usuario | `/home/joaquin` |
| `USER` | Nombre del usuario actual | `joaquin` |
| `SHELL` | Ruta al shell por defecto del usuario | `/bin/bash` |
| `PS1` | Prompt de comandos (solo bash) | `\u@\h:\w$ ` |
| `LANG` | Idioma y codificación del sistema | `es_AR.UTF-8` |
| `EDITOR` | Editor de texto por defecto | `nano` |

Ver el valor de una variable:

```bash
echo $PATH
printenv HOME
```

Exportar una variable (hacerla disponible para todos los procesos hijos):

```bash
export EDITOR=nano
```

## Archivos de configuración del shell

### `/etc/profile`

Configuración global del login shell. Se ejecuta una vez al iniciar sesión y puede cargar scripts adicionales de `/etc/profile.d/`. Aquí se definen variables como `PATH` o `LANG` que aplican a todos los usuarios.

### `~/.profile`

Configuración personal del login shell. Es el lugar donde el usuario puede personalizar su entorno de inicio de sesión. En Debian, suele contener una línea que carga `~/.bashrc` para que la configuración de la terminal también esté disponible en sesiones de login.

### `~/.bashrc`

Configuración del shell interactivo (no-login). Se carga cada vez que se abre una nueva terminal. Aquí van los alias, funciones, y la personalización del prompt. Es el archivo que más modificaciones recibe en el día a día.

### `~/.bash_logout`

Se ejecuta al cerrar la sesión de login. Se usa para tareas de limpieza, como borrar archivos temporales.

## Shells alternativos en Debian

Debian trae `bash` como shell por defecto, pero existen alternativas populares:

### Zsh (Z Shell)

- Extensión de `bash` con mejoras significativas.
- Sugerencias de completado basadas en el historial.
- Completado con menú interactivo.
- Globbing más potente (expansión de patrones).
- Temas y plugins a través de frameworks como Oh My Zsh.
- Es el shell por defecto en macOS desde Catalina.

### Fish (Friendly Interactive Shell)

- Diseñado para ser fácil de usar desde el primer momento.
- Autocompletado predictivo sin necesidad de configuración.
- Historial de comandos persistente entre sesiones.
- No es compatible con scripts POSIX (no ejecuta scripts de bash directamente).

### Dash

- Shell muy ligero y rápido, implementación de POSIX sh.
- Debian lo usa como `/bin/sh` para scripts del sistema por su velocidad.
- No es interactivo: no tiene historial ni autocompletado.
- Ideal para scripts, no para uso diario.

## Por qué cambiar de shell en un servidor

Bash es completo y confiable para servidores, pero Zsh ofrece ventajas concretas para el uso interactivo:

- **Historial compartido entre terminales**: por defecto, Zsh escribe el historial inmediatamente en el archivo, no al cerrar la terminal. Esto evita perder comandos si la conexión se corta.
- **Completado mejorado**: Zsh puede sugerir completados mientras escribes y navegar por las opciones con las flechas.
- **Alias y funciones mejorados**: Zsh permite definir alias que se expanden de forma más flexible.
- **Comunidad y plugins**: Oh My Zsh y otros frameworks facilitan la instalación de plugins útiles (git, docker, ssh, etc.) sin configuración manual.

Para un servidor donde se trabaja frecuentemente por terminal, estas mejoras reducen errores y agilizan tareas repetitivas.

## El shell y la seguridad en servidores

- **Usuarios de servicio**: los usuarios que ejecutan daemons suelen tener el shell configurado en `/usr/sbin/nologin` o `/bin/false` para impedir inicios de sesión interactivos. Si un atacante obtiene credenciales de un servicio, no podrá obtener una terminal.
- **Shell por defecto**: al crear un usuario nuevo, el sistema asigna el shell definido en `/etc/passwd`. Cambiar el shell por defecto del sistema afecta a todos los usuarios nuevos; es mejor cambiarlo usuario por usuario.
- **Variables sensibles**: el shell expone variables como `PATH`. Un `PATH` mal configurado puede ejecutar binarios de ubicaciones no seguras, por eso `/usr/local/bin` y los directorios estándar deben tener permisos restrictivos.

## Comandos útiles

```bash
# Ver el shell actual del usuario
echo $SHELL

# Ver todos los shells disponibles en el sistema
cat /etc/shells

# Cambiar el shell por defecto de un usuario
chsh -s /bin/zsh usuario

# Ver el historial de comandos
history

# Buscar un comando en el historial
history | grep "apt"
```

## Referencias

- `man bash` — documentación completa de bash incluida en el sistema.
- `man zsh` — documentación de Zsh.
- GNU Bash Reference Manual: <https://www.gnu.org/software/bash/manual/>
- Oh My Zsh: <https://ohmyz.sh>
- Documentación de Zsh: <https://zsh.sourceforge.io/Doc/>
