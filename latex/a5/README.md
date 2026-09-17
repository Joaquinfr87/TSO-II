# Informe — Actividad 5: Servidor Web (Nginx en Debian)

Documentación LaTeX del informe de la Actividad 5 del Taller de Sistemas
Operativos II. Cubre la instalación nativa, configuración y verificación
del servidor web (Nginx) y proxy inverso del proyecto **Grupo 1 Sudoers**
sobre Debian GNU/Linux 12 (Bookworm).

## Estructura

```
a5/
├── main.tex              # Documento principal (integra los módulos)
├── Makefile              # Compilar con: make
├── guia-capturas.md      # Guía de comandos para obtener las capturas
├── contenido/
│   ├── 01-introduccion.tex   # Capítulo I: Introducción
│   ├── 02-objetivos.tex      # Capítulo II: Objetivos
│   ├── 03-alcance.tex        # Capítulo II: Alcance y Límites
│   ├── 04-desarrollo.tex     # Capítulo III: Desarrollo (Nginx en Debian)
│   └── 05-conclusiones.tex   # Capítulo IV: Conclusiones
├── formato/
│   ├── preambulo.sty         # Configuración de formato (APA + Arial)
│   ├── portada.tex           # Portada institucional
│   └── referencias.bib       # Referencias bibliográficas
├── figuras/
│   ├── logo.png              # Logo institucional
│   └── (capturas esperadas)
└── anexos/
    └── anexo-a.tex           # Material complementario
```

## Compilar

```bash
# Desde latex/a5/
make           # compila el PDF
make view      # compila y abre el PDF
make clean     # borra auxiliares
make cleanall  # borra auxiliares + PDF
```

O manualmente:

```bash
pdflatex main && bibtex main && pdflatex main && pdflatex main
```

## Capturas esperadas

El informe incluye placeholders para capturas de pantalla que deben
realizarse durante las pruebas del servidor en Debian. Los archivos esperados en `figuras/`:

| Archivo | Descripción | Comando / Acción |
|---|---|---|
| `captura-web-arranque.png` | Estado activo de Nginx y puertos en Debian | `systemctl status nginx` y `ss -tulpn \| grep nginx` |
| `captura-web-sitio.png` | Sitio web del proyecto en el navegador | Navegador en `https://web.sudoers.lan` |
| `captura-web-proxy.png` | Acceso a servicios via proxy inverso | Navegador en `https://print.sudoers.lan` o consola con `curl` |
| `captura-web-cert.png` | Verificación del certificado SSL | `openssl s_client -connect web.sudoers.lan:443 ...` |

Si una captura no existe en `figuras/`, el PDF mostrará un recuadro con la descripción
de la captura pendiente y el nombre del archivo esperado.
