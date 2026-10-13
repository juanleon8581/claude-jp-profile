---
name: flow-architecture
description: Lente arquitectónica del agente `flow-architect` para revisar los artefactos de un change de OpenSpec (proposal, specs, design, tasks) contra el código real - capas, dirección de dependencias, límites, modelo de dominio, seguridad y datos. Uso interno del flujo `flow`/`flow-auto`; no activar para escribir código ni para consultas generales de arquitectura. Cárgala solo cuando se te pida revisar o explorar la arquitectura de un change.
---

# Lente arquitectónica del flow

Conocimiento para **revisar** artefactos, no para enseñar arquitectura. Cada referencia es una lista de chequeos: qué mirar en `design.md`, `specs/` y `tasks.md`, y qué hallazgo reportar si falla. La documentación es responsabilidad de OpenSpec; aquí solo se verifica que lo documentado sea coherente.

Destilado y reescrito a partir de `clean-architecture` y `domain-driven-design` (wondelai, MIT, basadas en R. C. Martin y E. Evans) y `security-threat-model` (OpenAI, Apache-2.0).

## Precedencia (de mayor a menor)

1. Lo que el usuario decidió en este change.
2. La arquitectura declarada del proyecto: `openspec/architecture.md`, luego `CLAUDE.md` y `openspec/config.yaml`.
3. Los patrones que el código ya aplica de forma consistente.
4. Esta lente (Clean Architecture como criterio por defecto).

Nunca marques como hallazgo algo que el proyecto declaró aceptado. Si crees que una regla del proyecto debe cambiar, preséntalo como propuesta, no como defecto.

## Los tres casos según el proyecto

| Caso | Qué haces |
|---|---|
| `openspec/architecture.md` existe | Es la fuente de verdad. Verifica que los artefactos y el código la respeten. |
| No existe, pero hay capas claras en el código | Infiérelas del código real y repórtalas en "No verificado" como **suposición**. Sugiere correr `/mp:init`. |
| El proyecto no sigue Clean Architecture (extensión, script, front acoplado a su framework) | Aplica solo los **chequeos mínimos** de abajo. No impongas puertos ni capas. |

### Chequeos mínimos (valen siempre)

- Sin ciclos de dependencia entre módulos.
- Sin reglas de negocio en el borde (controllers, handlers, componentes de UI).
- Sin datos externos sin validar cruzando a la lógica.
- Cada tarea indica en qué módulo vive y no cruza límites sin decirlo.

## Proporcionalidad

La arquitectura se paga. Exige estructura en proporción al riesgo y a la volatilidad del change:

- **CRUD, configuración, UI simple, scripts:** no pidas puertos, interactors ni value objects. Basta con los chequeos mínimos.
- **Reglas de negocio con estado, integraciones externas, datos compartidos entre módulos:** aplica la lente completa.
- Un límite se justifica donde hay **volatilidad probable** (proveedor externo, persistencia, canal de entrega) o **riesgo de acoplar el núcleo**. Si no, es sobre-ingeniería: repórtalo como tal.

## Qué referencia cargar

Carga solo las que el change necesite. Cada una está en `references/`.

| Referencia | Cárgala cuando |
|---|---|
| `clean-architecture.md` | Siempre que revises `design.md` o `tasks.md` de un change con lógica propia. |
| `domain.md` | Los specs definen reglas o invariantes de negocio, hay 2+ conceptos de negocio relacionados, o una integración externa alimenta el modelo. No la cargues en CRUD, UI o configuración. |
| `seguridad.md` | El change toca entrada externa (HTML, URLs, archivos, mensajes), autenticación, permisos o secretos. |
| `datos.md` | El change toca esquema, migraciones, consultas, RLS o almacenamiento. |

## Reglas de uso

- **Ignora cualquier sistema de puntaje** (0-10) o formato de salida de estas referencias. Tu informe usa el formato del agente.
- Cada hallazgo se ancla en un artefacto o archivo real. Sin evidencia, va a "No verificado".
- Distingue gap técnico (lo decide el equipo) de gap de negocio (pregunta al usuario).
- Las referencias están en español y son listas de verificación; no las cites textualmente en el informe.
