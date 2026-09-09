# Documentación técnica: servidor Debian

Esta repo reúne documentación sobre la instalación y configuración de un servidor Debian, además de la implementación de los servicios de la materia con Docker y la organización del equipo. El objetivo es mantener una parte teórica clara, guías prácticas paso a paso y el propio código de los servicios versionado.

## Estructura del proyecto

```text
.
├── docker-compose.yml        ← punto de entrada: declara todos los servicios
├── .env.example              ← variables de entorno de ejemplo (copiar a .env)
├── README.md
├── docs
│   ├── theory                ← documentación conceptual
│   │   ├── index.md
│   │   ├── teoria-base.md
│   │   ├── shell.md
│   │   ├── docker.md
│   │   ├── usuarios-y-permisos.md
│   │   └── sistema-de-archivos.md
│   └── guides                ← guías prácticas
│       ├── index.md
│       ├── instalacion-debian.md
│       ├── configuracion-debian.md
│       ├── instalacion-docker.md
│       ├── comandos-docker.md
│       ├── docker-compose-flujo.md
│       ├── zsh-ohmyzsh.md
│       ├── agregar-usuarios.md
│       ├── laptop-siempre-encendida.md
│       └── proxy-apt-y-nat.md
├── services                  ← Dockerfiles y configuración por servicio
│   ├── dns/                  ← Bind9 (Nicolás)
│   ├── dhcp/                 ← Kea (Nicolás)
│   ├── database/             ← PostgreSQL (Nicolás)
│   ├── web/                  ← Nginx (David)
│   ├── files/                ← Samba (David)
│   ├── mail/                 ← Postfix + Dovecot (Joaquín)
│   ├── iis/                  ← documentación: IIS no corre en Docker Linux
│   └── domain/               ← documentación: controlador de dominio (AD)
└── teams                     ← documentación del equipo
    ├── index.md
    └── reparticion-tareas.md
```

- `docs/theory/`: documentación conceptual y referencias teóricas.
- `docs/guides/`: guías prácticas de instalación y configuración.
- `services/`: el código real de los servicios (Dockerfiles, configuraciones, contenido).
- `teams/`: documentación del equipo, repartición de tareas y decisiones.

## ¡Levantar los servicios!

El corazón del proyecto es el `docker-compose.yml` de la raíz. Para desplegar todos los servicios en una máquina con Docker instalado:

```bash
cp .env.example .env   # primer vez: completar los valores locales
docker compose up -d --build
```

Ver el detalle del flujo de trabajo en [Uso colaborativo de Docker en el equipo](./docs/guides/docker-compose-flujo.md).

## Convención de documentos

- Usar un `index.md` por carpeta para describir el propósito de la sección y enlazar los documentos.
- Cada guía debe incluir, cuando aplique:
  - Objetivo
  - Requisitos previos
  - Pasos
  - Verificación
- Cada servicio en `services/` tiene su propio `README.md` con responsable, uso y estado.

## Referencias rápidas

- [Equipo de trabajo y repartición de tareas](./teams/index.md)
- [Teoría de Docker](./docs/theory/docker.md)
- [Instalación de Docker en Debian](./docs/guides/instalacion-docker.md)

## Próximos pasos

- Configurar a fondo cada servicio (zonas DNS, pool DHCP, usuarios de correo/Samba, contenido web).
- Resolver la decisión de IIS y controlador de dominio (ver `teams/reparticion-tareas.md`).
- Probar la integración completa de todos los servicios en la máquina física.
