# Documentación técnica: servidor Debian

Esta repo reúne documentación sobre la instalación y configuración de un servidor Debian. El objetivo es mantener una parte teórica clara y, por separado, guías prácticas paso a paso.

## Estructura del proyecto

```text
.
├── README.md
└── docs
    ├── theory
    │   ├── index.md
    │   ├── teoria-base.md
    │   └── usuarios-y-permisos.md
    └── guides
        ├── index.md
        ├── instalacion-debian.md
        ├── configuracion-debian.md
        ├── agregar-usuarios.md
        ├── laptop-siempre-encendida.md
        └── proxy-apt-y-nat.md
```

- `docs/theory/`: documentación conceptual y referencias teóricas.
- `docs/guides/`: guías prácticas de instalación y configuración.

## Convención de documentos

- Usar un `index.md` por carpeta para describir el propósito de la sección y enlazar los documentos.
- Cada guía debe incluir, cuando aplique:
  - Objetivo
  - Requisitos previos
  - Pasos
  - Verificación

## Próximos pasos

- Ampliar `docs/theory/index.md` con los temas teóricos a cubrir.
- Agregar guías de instalación y configuración dentro de `docs/guides/`.
- Mantener el lenguaje en español y coherencia entre la parte teórica y las guías prácticas.
