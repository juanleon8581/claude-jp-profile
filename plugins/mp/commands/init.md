---
description: "Prepara el proyecto actual para el flujo flow: OpenSpec, CLAUDE.md (comandos) y reglas de arquitectura para flow-architect"
allowed-tools: Bash(bash:*), Bash(openspec:*), Read, Write, Edit, Glob, Grep
---

# /mp:init

Prepara el **proyecto activo** (no el entorno de usuario; eso es `/mp-core:doctor`) con lo que `flow` y `flow-auto` necesitan. Es idempotente: solo completa lo que falta y **nunca sobrescribe** contenido existente. No hace commit y no toca Taiga.

## 1. Diagnóstico

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/project-check.sh"
```

Muestra el resumen tal cual. Si todo está en ✔, termina.

## 2. Propuesta (antes de escribir nada)

Con el diagnóstico y leyendo el repo (`CLAUDE.md`, `package.json`, estructura de `src/`, código representativo), arma un plan con **solo lo que falta**, di qué archivo se crea o se edita, y espera la aprobación del usuario. Si algo ya existe, se complementa con `Edit`, jamás con `Write` sobre el archivo.

### a) OpenSpec
- Si falta `openspec/`: ofrece `openspec init .` y ejecútalo solo tras la confirmación. Si `openspec` no está instalado, indica el comando de instalación y detente en este punto.
- Si falta `openspec/config.yaml`, créalo con `schema: spec-driven`. `openspec update` no lo modifica.

### b) `CLAUDE.md` del proyecto
- Si falta, créalo con título y las secciones de abajo. Si existe, agrega solo lo que no esté.
- **Comandos:** sección con los comandos de prueba, build y formato (`flow test` lee de aquí). Propón los que salgan de `package.json` u otro manifiesto y pide confirmación; si no los puedes inferir, pregunta.
- **Arquitectura:** una línea de puntero: ``Reglas de arquitectura: ver `openspec/architecture.md`.`` No copies las reglas aquí (`CLAUDE.md` se carga en toda sesión).

### c) `openspec/architecture.md`
Es la fuente de verdad de `flow-architect`. Propón un borrador **inferido del código real**, marca como `(suposición)` lo que no puedas confirmar, y haz **2 o 3 preguntas** al usuario para fijar: capas reales, excepciones aceptadas y si el proyecto tiene dominio rico. No inventes capas que el repo no tenga. Plantilla:

```markdown
# Arquitectura del proyecto

> Reglas que usa `flow-architect` al revisar cada change. Edítalas a mano; `/mp:init` no las sobrescribe.

## Estilo
<Clean Architecture / por capas / modular / simple (sin capas formales) - una línea de por qué>

## Capas y dirección de dependencias
| Capa | Ruta | Puede depender de |
|---|---|---|
| <dominio> | <ruta> | nada |
| <aplicación> | <ruta> | dominio |
| <infraestructura/UI> | <ruta> | aplicación, dominio |

Regla: las dependencias apuntan hacia el dominio.

## Convenciones
- <nombres, estructura de carpetas, formato de errores, etc.>

## Excepciones aceptadas
- <lo que el proyecto decidió hacer distinto y no debe marcarse como defecto>

## Qué referencias aplican
- Dominio rico (invariantes, agregados): <sí / no>
- Seguridad (entrada externa, permisos): <sí / no / dónde>
- Datos: <motor y dónde vive el esquema, o "no aplica">
```

### d) `openspec/config.yaml`
Complementa con `Edit` sin tocar lo existente:

```yaml
context: |
  Arquitectura del proyecto: ver openspec/architecture.md (capas, dependencias, excepciones).
rules:
  design:
    - Declarar las capas que toca el change y la dirección de las dependencias, conforme a openspec/architecture.md
  tasks:
    - Cada tarea indica la capa o el módulo donde vive
```

Si ya hay `context:` o `rules:`, agrega líneas dentro de esas claves; no dupliques claves.

### e) Requisitos de UI
Solo se **reportan**, nunca se resuelven aquí: `PRODUCT.md` (`/impeccable init`), `DESIGN.md` (`/impeccable document`), `components.json` (`npx shadcn@latest init`). Indica el comando al usuario si faltan.

## 3. Verificación

Tras escribir, vuelve a correr el script del paso 1 y `openspec validate` si el CLI existe. Muestra el resultado y un resumen de lo creado o modificado.

## Reglas

- Sin aprobación del usuario no se escribe nada.
- Nunca borres ni reemplaces contenido existente.
- Sin commit. Deja los cambios en el working tree.
- Lo que no puedas inferir o verificar se declara como suposición, no se inventa.
