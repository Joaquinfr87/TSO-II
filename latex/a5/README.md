# Informe — Actividad 5: DHCP + Servidor Web

Documentación LaTeX del informe de la Actividad 5 del Taller de Sistemas
Operativos II. Cubre la configuración del servicio DHCP (Kea) y del
servidor web (Nginx) del proyecto **Grupo 1 Sudoers**.

## Estructura

```
a5/
├── main.tex              # Documento principal (integra los módulos)
├── Makefile              # Compilar con: make
├── contenido/
│   ├── 01-introduccion.tex   # Capítulo I: Introducción
│   ├── 02-objetivos.tex      # Capítulo II: Objetivos
│   ├── 03-alcance.tex        # Capítulo II: Alcance y Límites
│   ├── 04-desarrollo.tex     # Capítulo III: Desarrollo (DHCP + Web)
│   └── 05-conclusiones.tex   # Capítulo IV: Conclusiones
├── formato/
│   ├── preambulo.sty         # Configuración de formato (APA + Arial)
│   ├── portada.tex           # Portada institucional
│   └── referencias.bib       # Referencias bibliográficas
├── figuras/
│   ├── logo.png              # Logo institucional
│   └── (capturas pendientes)
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

## Capturas pendientes

El informe incluye placeholders para capturas de pantalla que deben
realizarse durante las pruebas. Los archivos esperados en `figuras/`:

| Archivo | Descripción |
|---|---|
| `captura-dhcp-config.png` | Configuración aplicada de Kea DHCP |
| `captura-dhcp-cliente.png` | Asignación de IP desde un cliente |
| `captura-dhcp-leases.png` | Tabla de concesiones del servidor |
| `captura-web-arranque.png` | Logs de arranque de Nginx |
| `captura-web-sitio.png` | Sitio web del proyecto en el navegador |
| `captura-web-proxy.png` | Acceso a servicios via proxy inverso |
| `captura-web-cert.png` | Verificación del certificado SSL |

Si una captura no existe, el PDF mostrará un recuadro con la descripción
de la captura pendiente y el nombre del archivo esperado.
