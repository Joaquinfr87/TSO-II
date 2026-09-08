# Instalar Zsh con Oh My Zsh

## Objetivo

Documentar el proceso para instalar y configurar Zsh como shell por defecto en un servidor Debian, junto con Oh My Zsh para gestionar plugins y temas de forma sencilla.

## Requisitos previos

- Servidor Debian instalado y accesible por SSH.
- Usuario con privilegios de administración (grupo `sudo`).
- Conexión a internet para descargar los paquetes.
- Conceptos básicos de shells. Ver [El Shell en Linux](../theory/shell.md).

## Pasos

### 1. Actualizar el sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Instalar Zsh

```bash
sudo apt install zsh -y
```

### 3. Verificar la instalación

```bash
zsh --version
```

También es posible verificar que Zsh aparece en la lista de shells disponibles:

```bash
cat /etc/shells
```

La salida debe incluir una línea con `/bin/zsh` o `/usr/bin/zsh`.

### 4. Cambiar el shell por defecto del usuario

```bash
chsh -s $(which zsh)
```

Este comando cambia el shell del usuario actual. El cambio surtirá efecto al cerrar y volver a iniciar sesión. Para aplicarlo inmediatamente en la sesión actual:

```bash
exec zsh
```

### 5. Instalar curl (si no está disponible)

Oh My Zsh necesita `curl` para descargarse. En Debian mínimos puede no estar instalado:

```bash
sudo apt install curl -y
```

### 6. Instalar Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

El script interactivo preguntará si se desea cambiar el shell a Zsh (ya hecho en el paso 4) y si se quiere usar el tema `robbyrussell` por defecto. Seleccionar las opciones que correspondan.

### 7. Explorar la estructura de Oh My Zsh

Después de la instalación, los archivos de configuración quedan en:

```text
~/.oh-my-zsh/
├── custom/
│   ├── plugins/      ← plugins propios
│   └── themes/       ← temas propios
├── plugins/          ← plugins incluidos
└── themes/           ← temas incluidos
```

El archivo de configuración principal del shell es `~/.zshrc`.

### 8. Configurar el tema

El tema controla cómo se ve el prompt. Para cambiarlo, editar la variable `ZSH_THEME` en `~/.zshrc`:

```bash
# Abrir el archivo de configuración
nano ~/.zshrc
```

Cambiar la línea:

```bash
ZSH_THEME="robbyrussell"
```

Algunos temas populares incluidos en Oh My Zsh:

| Tema | Descripción |
|---|---|
| `robbyrussell` | Minimalista, por defecto. Muestra rama de git. |
| `agnoster` | Tema con powerline, muestra usuario, directorio y git. Requiere una fuente con símbolos. |
| `bira` | Muestra usuario, directorio, git y hora. |
| `ys` | Detallado con colores, usuario y directorio abreviado. |

Después de cambiar el tema, recargar la configuración:

```bash
source ~/.zshrc
```

### 9. Habilitar plugins

Los plugins se definen en la variable `plugins` de `~/.zshrc`. Para habilitar un plugin, agregar su nombre a la lista:

```bash
plugins=(
    git
    docker
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
)
```

Plugins útiles incluidos en Oh My Zsh:

| Plugin | Función |
|---|---|
| `git` | Alias para comandos de git, muestra estado en el prompt. |
| `docker` | Alias para comandos de Docker y completado. |
| `sudo` | Presiona Escape dos veces para agregar `sudo` al inicio del comando. |
| `ssh` | Completado de hosts SSH. |
| `history` | Navegación en el historial mejorada con flechas. |
| `extract` | Un solo comando para descomprimir cualquier formato. |

### 10. Instalar plugins externos (opcional)

Dos plugins externos muy populares no vienen con Oh My Zsh:

**zsh-autosuggestions** (sugerencias basadas en el historial):

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
    ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
```

**zsh-syntax-highlighting** (resalta comandos válidos en tiempo real):

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

Después de clonarlos, agregar sus nombres al array `plugins` en `~/.zshrc` y recargar:

```bash
source ~/.zshrc
```

### 11. Variables útiles en ~/.zshrc

Algunas configuraciones útiles para agregar a `~/.zshrc`:

```bash
# Guardar historial entre sesiones (Oh My Zsh ya configura esto por defecto)
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# No guard duplicados en el historial
setopt HIST_IGNORE_DUPS

# Compartir historial entre terminales
setopt SHARE_HISTORY

# Completado con flechas
zstyle ':completion:*' menu select
```

## Verificación

1. Cerrar la sesión SSH y volver a conectarse. El prompt debe mostrar el tema configurado.
2. Verificar que el shell activo es Zsh:

```bash
echo $SHELL
```

3. Probar que los plugins funcionan:
   - Escribir `gi` y esperar a ver si aparece una sugerencia de `git`.
   - Escribir un comando válido como `ls` y verificar que se resalta en color (syntax-highlighting).
   - Escribir `extract` y ver que aparece como comando reconocido.
4. Confirmar que el historial persiste entre sesiones abriendo una nueva terminal y ejecutando `history`.

## Desinstalar Oh My Zsh (si es necesario)

```bash
uninstall_oh_my_zsh
```

Este comando quita Oh My Zsh pero mantiene Zsh instalado y como shell por defecto.

## Solución de problemas

**El cambio de shell no surte efecto:**
- Verificar con `grep $USER /etc/passwd` que la línea del usuario muestra `/bin/zsh`.
- Si no se cambió, ejecutar `sudo chsh -s /bin/zsh $USER`.

**Oh My Zsh no se instala:**
- Verificar que `curl` está instalado: `which curl`.
- Verificar conexión a internet: `curl -I https://github.com`.

**El prompt no se ve bien después del cambio:**
- Algunos temas requieren fuentes especiales. Si se usa `agnoster`, instalar una fuente Powerline compatible y configurar el emulador de terminal para usarla.

## Referencias

- Oh My Zsh: <https://ohmyz.sh>
- Repositorio de Oh My Zsh: <https://github.com/ohmyzsh/ohmyzsh>
- Lista de plugins: <https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins>
- Lista de temas: <https://github.com/ohmyzsh/ohmyzsh/wiki/Themes>
- zsh-autosuggestions: <https://github.com/zsh-users/zsh-autosuggestions>
- zsh-syntax-highlighting: <https://github.com/zsh-users/zsh-syntax-highlighting>
