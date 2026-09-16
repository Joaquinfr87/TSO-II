# Monitoreo con Zabbix

Este documento cubre la teoría detrás del monitoreo de servidores y por qué usamos Zabbix en el proyecto TSO-II. Para la configuración práctica, ver [Servicio: Monitoreo](../../services/zabbix/README.md).

## ¿Qué es el monitoreo y por qué importa?

El monitoreo es el proceso de **observar el estado de un sistema** de forma continua para detectar problemas antes de que impacten a los usuarios. En un servidor que aloja múltiples servicios (DNS, correo, web, archivos, impresión), un fallo en un componente puede pasar desapercibido hasta que un usuario se queja. El monitoreo automático resuelve esto: avisa cuando algo no está bien, incluso si nadie está mirando el panel.

Un sistema de monitoreo típico hace tres cosas:

1. **Recolectar datos** (métricas) de forma periódica.
2. **Almacenar** esas métricas en una base de datos con marcas de tiempo.
3. **Evaluar reglas** (triggers) que disparan alertas cuando los datos superan un umbral.

## ¿Qué es Zabbix?

Zabbix es una plataforma de monitoreo de código abierto que monitorea:
- Infraestructura (CPU, RAM, disco, red)
- Aplicaciones (bases de datos, servidores web, servidores de correo)
- Contenedores y servicios en tiempo real
- Dispositivos de red (switches, routers vía SNMP)

Funciona con una arquitectura cliente-servidor:

| Componente | Rol |
|---|---|
| **Zabbix Server** | Coordinador central. Recoge datos de agentes, evalúa triggers, envía alertas. |
| **Base de datos** | Almacena toda la configuración y las métricas históricas. |
| **Web frontend** | Interfaz gráfica para configurar, visualizar y administrar. |
| **Zabbix Agent** | Software instalado en cada host que reporta métricas al server. |
| **Zabbix Proxy** | Intermediario para redes distribuidas (no lo usamos en este proyecto). |

## Agentes: pasivo vs activo

Zabbix soporta dos modos de comunicación entre el agent y el server:

- **Modo pasivo**: el server le pide al agente "dame el valor de X", y el agente responde. El agente escucha en el puerto 10050.
- **Modo activo**: el agente se conecta al server (puerto 10051) y le pregunta "¿qué métricas necesitás?". Es más eficiente y el recomendado.

En nuestro proyecto usamos **modo activo** (el agente se conecta al server en el puerto 10051).

## Templates y triggers

### Templates

Un **template** es un conjunto predefinido de:
- **Ítems** (métricas a recolectar): uso de CPU, espacio en disco, conexiones a la DB, etc.
- **Triggers** (reglas de alerta): "si CPU > 90% por 5 minutos, hay un problema".
- **Grafanas**: visualización de las métricas del template.

Zabbix tiene **templates oficiales** para prácticamente cualquier servicio. Nosotros usamos:

| Template | Servicio |
|---|---|
| Linux by Zabbix agent 2 | Host Debian (CPU, RAM, disco, red, processes) |
| Docker by Zabbix agent 2 | Contenedores Docker |
| PostgreSQL by Zabbix agent 2 | Base de datos PostgreSQL |
| HTTP Service by Zabbix agent 2 | Verificación de endpoints HTTP/HTTPS |

### Triggers

Un **trigger** es una expresión lógica que evalúa si algo está mal. Ejemplos:

- `avg(/host/system.cpu.util,5m)>90` → CPU promedio mayor a 90% en los últimos 5 minutos.
- `last(/host/vfs.fs.size[/,pfree])<20` → Menos del 20% de espacio libre en disco.
- `nodata(/host/net.if.in[eth0],5m)=1` → Sin datos de red por 5 minutos (posible caída).

Los triggers tienen severidad: `Information`, `Warning`, `Average`, `High`, `Disaster`.

## Monitoreo de contenedores Docker

Zabbix puede monitorear contenedores Docker a través de `zabbix-agent2` con el plugin de Docker. El agente se conecta al socket `/var/run/docker.sock` y reporta:

- Contenedores corriendo / detenidos
- Uso de CPU y memoria por contenedor
- Operaciones de red y disco
- Reinicios inesperados
- Imágenes y volúmenes

Esto permite detectar, por ejemplo, que el contenedor de correo se cayó y no se levantó solo, o que un contenedor está consumiendo demasiada memoria.

## Alertas por email

Zabbix puede enviar notificaciones por email cuando un trigger se dispara. Usa un **media type** configurado con un servidor SMTP. En nuestro proyecto, el media type se configura para usar el mail server propio del proyecto (Postfix en el contenedor `tso-mail`, puerto 587 con autenticación).

El flujo es:
1. Un trigger se dispara (ej: disco > 80%).
2. Zabbix evalúa las **reglas de notificación**: a quién avisar, por qué medio, y en qué horario.
3. Envía un email al mailbox del administrador.

## Métricas clave a observar

| Métrica | Qué indica | Umbral típico |
|---|---|---|
| CPU utilization | Sobrecarga del procesador | > 90% por 5+ min |
| Memory utilization | Memoria RAM agotándose | > 85% |
| Disk space | Disco llenándose | > 80% |
| Swap usage | Sistema intercambiando (lento) | > 50% |
| Network traffic | Anomalías de tráfico | Picos inusuales |
| Service TCP checks | Servicio no responde | Timeout o connection refused |
| Container restarts | Contenedores inestables | > 0 reinicios en 10 min |

## Referencias

- Servicio de monitoreo: [Zabbix en TSO-II](../../services/zabbix/README.md)
- Docker: [Docker en un servidor Debian](./docker.md)
- Documentación Zabbix: https://www.zabbix.com/documentation/7.4
- Templates: https://www.zabbix.com/integrations
