# Informe LaTeX (normas APA · tipografía Arial · papel A4)

Estructura inicial del informe del proyecto. Solo incluye el **formato**
(carátula, texto y página); el contenido se agrega a medida que se redacta.

```
latex/a4/
├── main.tex                  # Integra todo: formato + portada + capítulos + anexos. Datos de portada aquí.
├── Makefile                  # Compila el informe con un solo comando (make).
├── formato/                  # FORMATO: todo lo que define la apariencia.
│   ├── preambulo.sty         # Paquetes, configuración APA + A4 y carátulas de capítulo.
│   ├── portada.tex           # Portada estilo APA (los datos se definen en main.tex).
│   └── referencias.bib       # Fuentes bibliográficas en BibTeX (agregar las citadas en el texto).
├── contenido/                # CONTENIDO: un archivo por sección (plantillas incluidas).
│   ├── 00-resumen.tex        # Resumen y palabras clave (plantilla).
│   ├── 01-ejemplo-seccion.tex# Plantilla de sección para los capítulos.
│   └── 99-conclusiones.tex   # Conclusiones (plantilla).
├── anexos/                   # Material complementario (tras las referencias).
│   └── anexo-a.tex           # Plantilla de anexo.
└── figuras/                  # Imágenes externas (logo institucional, capturas, diagramas).
```

## Formato del documento
- **Papel:** A4.
- **Tipografía:** Arial (se usa Helvetica del paquete `helvet`, el sustituto
  estándar de Arial en LaTeX; el paquete `uarial` fue retirado de TeX Live 2026).
- **Normas APA:** márgenes de 1 pulgada, interlineado doble, número de página
  abajo a la derecha y títulos por niveles. Las referencias se generan con el
  estilo apacite (APA).
- **Idioma:** español (babel), con guionado y nombres de tablas/figuras en
  español.
- Cada capítulo comienza con una carátula que ocupa una hoja completa
  (`\caratulaCapitulo{CAP\'ITULO X}{NOMBRE}`); el contenido inicia en la
  página siguiente.

## Cómo compilar
Desde `latex/a4/`:

```bash
make            # compila el PDF completo (pdflatex + bibtex + 2 pasadas finales)
make view       # compila y abre el PDF
make clean      # borra solo los archivos auxiliares (conserva el PDF)
```

El paso `bibtex` es imprescindible: sin él las citas aparecen como `[?]` y
la sección de referencias queda vacía.

Si prefieres los comandos a mano:

```bash
pdflatex main && bibtex main && pdflatex main && pdflatex main
```

Si usas TeX Live estándar (Debian/Ubuntu), instala:
`sudo apt install texlive-latex-extra texlive-fonts-extra texlive-lang-spanish texlive-pictures latexmk`.
(`texlive-pictures` es necesario para los diagramas TikZ de flujo y wireframes).

## Datos pendientes de editar (marcadores `[ ]`)
En `main.tex`: título, nombre de la app/sistema, equipo, integrantes,
universidad, facultad, carrera, asignatura, docente, ciudad y fecha.
En `contenido/00-resumen.tex`, `contenido/01-ejemplo-seccion.tex` y
`99-conclusiones.tex`: texto real del proyecto.

## Cómo agregar contenido
1. Duplicar `contenido/01-ejemplo-seccion.tex` por cada sección y renombrar
   (ej: `01-antecedentes.tex`, `02-contextualizacion.tex`, ...).
2. En `main.tex`, descomentar el bloque del capítulo correspondiente y listar
   cada archivo con `\input{contenido/...}` después de
   `\caratulaCapitulo{...}`.
3. Colocar las imágenes en `figuras/` y referenciarlas con
   `\includegraphics{nombre.png}`.

| Tipo de material | Carpeta |
|---|---|
| Secciones del cuerpo del informe | `contenido/` (archivos numerados por capítulo) |
| Documentos complementarios | `anexos/` (Anexo A, B, C...) |
| Imágenes y diagramas externos | `figuras/` |
| Datos de portada (equipo, universidad, docente, integrantes...) | `main.tex` |
| Paquetes y estilo (márgenes, fuentes, espaciado, carátulas de capítulo) | `formato/preambulo.sty` |