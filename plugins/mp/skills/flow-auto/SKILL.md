---
name: flow-auto
description: >-
  Versión multiagente de `flow`. Orquesta el mismo flujo estandarizado (Spec-Driven Development vía OpenSpec
  envuelto en Taiga como capa de Scrum/negocio) pero delega el trabajo de la fase de desarrollo a agentes
  especializados (flow-architect, flow-designer, flow-coder, flow-ui-coder, flow-ui-refiner, flow-tester,
  flow-reviewer) en ciclos por bloque de tasks.md, y
  delega la documentación de Taiga en flow-documenter, deteniéndose siempre en los gates manuales. Activar cuando el usuario escriba "/flow-auto", pida ejecutar un
  bloque del change con agentes, o pida el modo multiagente del flow. Subcomandos: start, explore, review, sync,
  apply, approve, docs, sync-check, done, test, release, status. Sin argumentos actúa como orquestador: lee el estado del change
  activo, ejecuta el siguiente paso automatizable y se detiene en el siguiente gate manual.
---

# flow-auto — flow con agentes especializados

Copia de la skill `flow` que agrega la orquestación de agentes. Todo lo que dice `flow` sigue vigente; este archivo
**solo cambia cómo se ejecutan las fases 2, 3, 5 y 6**, agrega los requisitos de UI de la fase 0 y los subcomandos
`apply` y `approve`.

Skill de nivel usuario. No vive en ningún proyecto específico — se usa en cualquier repo donde el usuario trabaje
bajo este proceso. El proyecto activo sí necesita tener OpenSpec inicializado (ver Fase 0).

## Principio

Taiga y OpenSpec son dos capas independientes ("islas"):

- **Taiga** = capa de negocio/Scrum. Lenguaje no técnico. Lo que ve gente sin contexto técnico.
- **OpenSpec** = capa técnica. Specs, diseño, tareas atómicas. Fuente de verdad para el desarrollo.

Esta skill sincroniza ambas capas en los puntos justos, sin que ninguna herramienta termine conociendo o
dependiendo de la otra. **Nunca se escriben ni modifican archivos propios de OpenSpec** (`proposal.md`,
`specs/**`, `design.md`, `tasks.md`), con una única excepción documentada: marcar checkboxes `- [ ]` → `- [x]` en
`tasks.md`, que es el protocolo de `apply` y aquí lo hace el orquestador (ver Fase 5). Los únicos archivos propios de
esta skill dentro de un change de OpenSpec son `openspec/changes/<change-id>/taiga-sync.json` (ver "Estado") y, en
changes con interfaz, `openspec/changes/<change-id>/ui-brief.md` (ver "Brief de diseño").

## Modo multiagente

### Roster

Los agentes viven en `${CLAUDE_PLUGIN_ROOT}/agents/` y se invocan con la tool `Agent` (`subagent_type`):
(Al venir del plugin `mp`, el `subagent_type` lleva prefijo: `mp:flow-coder`, etc.)

| Agente | Rol | Escribe | Modelo |
|---|---|---|---|
| `flow-architect` | Explore y revisión de artefactos, **solo lo técnico**: cruza proposal/specs/design/tasks con el código real | nada (solo lectura) | opus |
| `flow-designer` | Dirección UX/UI del change: sistema de diseño, componentes shadcn, estados, responsive, accesibilidad. Devuelve el brief | nada (el orquestador guarda `ui-brief.md`) | sonnet |
| `flow-coder` | Implementa **un bloque** de `tasks.md`: lógica, datos y servicios (no interfaz) | código no-UI | sonnet |
| `flow-ui-coder` | Construye la **interfaz** de un bloque siguiendo `ui-brief.md` (componentes shadcn vía MCP) | código de UI | sonnet |
| `flow-ui-refiner` | Audita y pule la UI ya construida (a11y, jerarquía, responsive, estados) sin cambiar comportamiento ni dirección visual | correcciones de UI | sonnet |
| `flow-tester` | Escribe y corre tests, `compile` y formato; reporta qué probar a mano | tests | sonnet |
| `flow-reviewer` | Revisa el `git diff` contra specs y design; reporta hallazgos | nada (solo lectura) | opus |
| `flow-documenter` | Documenta en Taiga y mantiene Taiga sincronizado con el proyecto local (modos `draft` / `apply` / `audit`) | Taiga, solo con un payload aprobado | sonnet |

### Principios del orquestador

1. **El orquestador es la sesión principal** (esta skill). Los agentes no lanzan otros agentes ni hablan con el
   usuario: devuelven un informe y nada más. Cualquier pregunta al usuario la hace el orquestador.
2. **Los agentes arrancan en frío.** Cada delegación se escribe autocontenida (ver "Contratos de delegación"):
   change-id, bloque, rutas de los artefactos, decisiones del usuario ya tomadas y, en rondas de corrección, la
   lista exacta de hallazgos. Nunca se asume que "ya saben" algo de la conversación.
3. **El contexto compartido son los archivos del change** (`proposal.md`, `design.md`, `specs/**`, `tasks.md`,
   `taiga-sync.json`) y el `CLAUDE.md` del repo. No se pasa contexto "de memoria".
4. **Los informes de los agentes no son verdad.** Antes de informar al usuario, el orquestador verifica por su
   cuenta con comandos reales (tests, compilación, `git status`, conteo de tareas y archivos desde el disco).
   Nunca se repite un "todo pasa" de un agente sin haberlo comprobado.
5. **Un solo coder a la vez sobre el mismo árbol de trabajo.** Nunca dos agentes que escriben en paralelo en la
   misma carpeta.
6. **Si el `Agent` tool rechaza un `subagent_type`** (los agentes se cargan al iniciar la sesión), avisar al
   usuario que reinicie la sesión; no improvisar el trabajo del agente con otro tipo genérico sin decirlo.

### Quién escribe qué

| Recurso | Quién | Condición |
|---|---|---|
| Código de producción (lógica, datos) | `flow-coder` | dentro de un bloque |
| Código de UI | `flow-ui-coder` (construye) y `flow-ui-refiner` (solo correcciones) | dentro de un bloque; requiere `ui-brief.md` aprobado |
| `ui-brief.md` | orquestador | a partir del informe de `flow-designer`; solo se guarda tras la aprobación del usuario |
| Tests | `flow-tester` | dentro de un bloque |
| Checkboxes de `tasks.md` | orquestador | solo tras verificar el bloque (excepción única) |
| Resto de artefactos OpenSpec | solo `openspec-explore` | nunca agentes ni el orquestador directo |
| `taiga-sync.json` | orquestador | siempre |
| Taiga (`mcp__taiga__*`) | `flow-documenter` en modo `apply` | solo con un payload que el usuario aprobó (el orquestador lo transmite textual) |
| git (add/commit/push/branch) | orquestador | **solo** por orden directa del usuario |

### Cuándo NO usar agentes

Un bloque de una sola tarea trivial (unas pocas decenas de líneas, sin casos borde) sale más caro por el arranque
en frío de cada agente que hacerlo directo. En ese caso proponer al usuario ejecutarlo con `opsx:apply` normal y
avisarlo antes; no decidirlo en silencio.

## Documentación en Taiga (`flow-documenter`)

Toda la documentación de Taiga la produce `flow-documenter`, no el orquestador ni los otros agentes. Trabaja en
tres modos y **el modo lo fija el orquestador**:

| Modo | Qué hace | Escribe en Taiga |
|---|---|---|
| `draft` | Redacta el texto exacto de lo que se enviaría (payloads) y qué cambia respecto a lo actual | no |
| `apply` | Ejecuta **exactamente** un payload que el usuario ya aprobó y verifica releyendo el ticket | sí, solo lo aprobado |
| `audit` | Compara Taiga con el proyecto local y reporta desincronizaciones | no |

### Flujo con aprobación (el que rige hoy)

```
orquestador ── draft ──► payloads ──► USUARIO aprueba (o pide cambios)
                                           │
orquestador ◄── informe ◄── apply ◄────────┘  (payload aprobado, textual)
```

1. El orquestador lanza `flow-documenter` en `draft` con el evento y el contexto.
2. Muestra al usuario los payloads **completos y textuales** (no resumidos).
3. Solo con aprobación explícita de ese texto lanza `flow-documenter` en `apply` pasándole el payload aprobado
   sin alterarlo. Si el usuario pide cambios, se vuelve al paso 1.
4. El orquestador verifica el informe del `apply` y actualiza `taiga-sync.json` (el documentador no lo escribe).

**Tono de lo que se documenta:** todo texto para Taiga es funcional e informativo, para personas no técnicas de
otras áreas. Los payloads que prepara el orquestador o el documentador no describen el comportamiento de
agentes, el flujo de trabajo, los artefactos internos ni detalles de pruebas o código (ver
`taiga-ticket-docs/references/redaccion.md`). Si un texto aprobado necesita esa corrección, se corrige antes
de mostrarlo al usuario.

### Política de aprobación (todo requerido por defecto)

| Acción en Taiga | Aprobación del usuario |
|---|---|
| Crear épica, US o tasks pre-spec (Fase 1) | requerida: preview del payload |
| Comentarios (definiciones, correcciones, resultados) | requerida: texto completo |
| Crear o actualizar subtasks (Fase 4) | requerida: preview de título y descripción |
| Cambiar un ticket a "Ready for test" | requerida: la orden explícita del usuario cuenta como aprobación |
| Marcar Done | requerida, siempre vía `flow-auto done` |

Relajar la aprobación de una acción es **decisión explícita del usuario**: implica cambiar esta tabla y las reglas
duras. El orquestador nunca la relaja por su cuenta.

### Eventos y checkpoints de documentación

| Cuándo | Qué documenta `flow-documenter` |
|---|---|
| Antes o durante explore: se identifica una definición de negocio | US y tasks pre-spec (Fase 1); un comentario por cada definición cerrada |
| Se cambia una regla ya documentada | Comentario de corrección que indica qué reemplaza |
| Artefactos listos y aprobados (Fase 3 → 4) | Subtasks técnicas: 1 por grupo `## N` de `tasks.md` |
| Bloque aprobado por el usuario (`flow-auto approve`) | Estado del subtask + comentario de resultado |
| **Entre fase y fase** | `audit`; si hay desincronización, `draft` de las correcciones |
| Release (Fase 7) | Documentación de cierre de la US y las subtasks |

**Checkpoint de documentación:** en cada transición de fase (1→2, 2→3, 3→4, cierre de cada bloque, 6→7) el
orquestador corre `flow-documenter` en `audit` y le informa al usuario el resultado antes de dar la fase por
cerrada. El checkpoint no frena por sí solo el avance técnico, pero **no se omite ni se da por hecho sin
correrlo**.

## Fase 0 — Precondición de proyecto

Antes de correr `flow-auto explore` (o cualquier paso que toque OpenSpec), verificar que el proyecto activo tenga
`openspec/` inicializado **y mostrar el resultado del comando** (no afirmar que se verificó sin haberlo corrido):

```bash
test -d openspec && echo OK || echo "falta init"
```

Si falta, avisar al usuario y sugerir `/mp:init` (prepara OpenSpec, el comando de pruebas en `CLAUDE.md` y las reglas
de arquitectura) o, solo para OpenSpec, `openspec init .` en la raíz del proyecto — el framework OpenSpec vive
siempre a nivel de proyecto, nunca a nivel usuario. No inicializarlo sin que el usuario lo pida explícito.

Si `openspec/architecture.md` no existe, `flow-architect` infiere la arquitectura del código y la reporta como
suposición: sugerir `/mp:init` una vez, sin bloquear el flujo.

### Requisitos de UI (solo si el change toca interfaz)

Se verifican antes del primer bloque de UI (y conviene al arrancar `explore` si ya se sabe que habrá UI), igual que
OpenSpec: **mostrar el resultado de cada comando**, avisar si falta algo y **no resolverlo sin que el usuario lo pida**.

```bash
test -f PRODUCT.md && echo "PRODUCT.md OK" || echo "falta PRODUCT.md"
test -f DESIGN.md  && echo "DESIGN.md OK"  || echo "falta DESIGN.md"
python3 --version || echo "falta python3"
```

| Requisito | Para qué | Si falta |
|---|---|---|
| `PRODUCT.md` (impeccable) | Contexto de producto que `impeccable` exige antes de diseñar o construir UI | **Bloquea** los agentes de UI. Pedir al usuario `/impeccable init` (entrevista interactiva: la hace la sesión principal con el usuario, nunca un agente) |
| `DESIGN.md` (impeccable) | Sistema visual vigente del proyecto | No bloquea. Si ya hay UI existente, sugerir `/impeccable document`; si es un proyecto nuevo, lo crea el flujo de diseño de impeccable al definir el mundo visual |
| `python3` | El buscador de `ui-ux-pro-max` (solo biblioteca estándar) | **Bloquea** al `flow-designer`: avisar para que lo instale el usuario; los agentes no instalan software |
| `components.json` (shadcn) | El MCP y la CLI de shadcn lo necesitan para añadir componentes | Sugerir `npx shadcn@latest init`; no ejecutarlo sin orden |
| Hooks de impeccable (`/impeccable hooks on`) | Chequeos automáticos de diseño mientras se edita | Opcional; recomendarlo una vez, nunca bloquea |

Los plugins `ui-ux-pro-max`, `impeccable` y `taste-skill` y el MCP `shadcn` vienen del perfil (`bootstrap/setup.sh`);
`taste-skill` no tiene requisitos adicionales. Si el `Agent` tool no encuentra las skills, ver regla 6 de los
principios.

## Las 7 fases

### Fase 1 — Intake (Taiga)

Misma estructura que en `flow`. La redacción de la US, las tasks pre-spec y de cada definición de negocio
la hace `flow-documenter` (`draft` → aprobación → `apply`); él sigue las reglas de `taiga-ticket-docs`.

Estructura obligatoria antes de poder pasar a fase 2:

1. **Épica** (opcional) — solo si la feature pertenece a una versión/iniciativa mayor.
2. **User Story** (obligatoria) — necesidad en lenguaje de negocio. Texto libre. **No exigir criterios de
   aceptación exhaustivos** — se amplían y cristalizan recién en fase 2-3, es normal y esperado que el alcance
   técnico introduzca criterios nuevos.
3. **Tasks pre-spec** (obligatorias, dentro de la US) — trabajo de definición/negocio previo, indispensable para
   poder arrancar el spec técnico (ej: confirmar alcance con stakeholder, levantar restricciones de negocio). NO
   son diseño técnico. **Deben estar en Done** antes de pasar a fase 2.

**Excepción al flujo completo:** un bug introducido y detectado dentro del mismo ciclo de dev activo (regresión
propia del change en curso, o hallada en pruebas de desarrollo de ese mismo change) se arregla inline — sin
proposal nuevo, sin Taiga nuevo, ya vive dentro del alcance del change activo. Todo lo demás (reportado por Taiga,
QA, usuario, cualquier ente externo, o detectado post-release) pasa el flujo completo desde fase 1, sin importar
el tamaño.

**Gate de salida:** existe la US + al menos 1 task documentada con contenido real, y todas las Tasks de fase 1
están en Done.

### Fase 2 — Exploración técnica (OpenSpec)

Invocar el skill `openspec-explore` (alias `opsx:explore`) vía la tool Skill. Es el único punto de entrada al lado
técnico — él orquesta internamente la creación y modificación de todos los artefactos que hagan falta (proposal,
specs, design, tasks), decide él mismo si el change amerita `design.md`, y consolida ideas / cierra gaps de
negocio y técnicos. No se invocan directamente `opsx:new`, `opsx:propose`, `opsx:continue` ni `opsx:ff` desde
nuestra skill — eso es responsabilidad interna de `opsx:explore`.

**Aporte de agentes en esta fase:** durante la exploración se puede consultar a `flow-architect` (tool `Agent`)
para investigar el código real, cruzar artefactos o evaluar una decisión técnica, y a `flow-designer` cuando el
change tenga interfaz y haya que aclarar decisiones de UX/UI (estados, flujos, componentes). La conversación con el usuario y
la creación/modificación de artefactos **siguen en la sesión principal vía `openspec-explore`**. El informe del
architect se resume al usuario; sus "preguntas de negocio" se le plantean al usuario, nunca se resuelven solas.

El change-id que resulte queda como **única fuente de verdad** para identificar el trabajo — no tiene que
coincidir con el nombre de la rama git (`release/X.Y.Z`, `feature/X.Y.Z-<slug>`). Si el nombre de rama sirve, se
reutiliza; si no, el que define `opsx:explore` es el que vale.

**Documentación durante explore:** cada vez que se cierra una definición de negocio o cambia una regla ya
documentada, el orquestador pide a `flow-documenter` el `draft` del comentario o del ticket correspondiente y lo
presenta al usuario (ver "Documentación en Taiga"). Al terminar explore corre el checkpoint de documentación.

**Gate de entrada:** Tasks de fase 1 en Done (heredado de fase 1).

### Fase 3 — Gate de aprobación

**La aprobación es 100% manual.** El usuario lee proposal + specs + tasks (+ design si existe).

**Aporte de agentes:** al correr `flow-auto review`, **antes** de entregar el checklist de lectura, se lanza
`flow-architect` para revisar los artefactos del change (contradicciones, casos borde, dependencias no declaradas,
tareas sin criterio de aceptación o de más de 2 horas, riesgos con datos externos). Sus hallazgos se resumen junto
al checklist, separados en técnicos y de negocio. Si el change tiene interfaz, también se lanza `flow-designer` para
revisar que specs y tasks de UI cubran estados (vacío/carga/error), responsive y accesibilidad; sus hallazgos van en
una sección propia. Es informativo: no aprueba ni bloquea por sí mismo.

- **Gap técnico** (algo que dev puede resolver solo) → se le informa a `openspec-explore` para iterar in-place
  sobre los artefactos existentes. No se vuelve a fase 1.
- **Gap de negocio** (requiere una definición que dev no puede tomar solo) → vuelve a fase 1: se crea/escala un
  ticket Taiga hacia el área de negocio para cerrar esa definición. Una vez cerrado, se retoma `openspec-explore`
  con la info nueva.
- **Sin gaps** → commit de los artefactos generados (**solo si el usuario lo ordena**) → pasa a fase 5 con
  `flow-auto apply`.

### Fase 4 — Sync a Taiga

Dispara **una sola vez**, cuando `tasks.md` ya quedó cerrado/estable post-aprobación (fase 3) — no a mitad de
dev bajo flujo normal. El preview de las subtasks lo redacta `flow-documenter` en `draft` (siguiendo
`taiga-ticket-docs`); la creación la hace en `apply` solo tras la aprobación.

**Regla de agrupación:** 1 subtask en Taiga = 1 grupo de nivel superior de `tasks.md` (las secciones numeradas
`## N. <nombre del grupo>`), nunca 1 subtask por checkbox individual. Los checkboxes técnicos quedan solo en
`tasks.md`. Resultado esperado: 3-6 subtasks legibles por US, no 15-20 técnicos.

**Traducción:** el título de cada subtask Taiga es el valor de negocio del grupo, no su nombre técnico, escrito en
lenguaje llano para personas no técnicas (sin jerga). Ej: grupo OpenSpec "Add SMTP retry with exponential
backoff" → subtask Taiga "Mejorar confiabilidad de envío de emails en conexiones inestables".

**Preview y aprobación obligatoria:** antes de llamar a `mcp__taiga__create_task` / `mcp__taiga__update_task`,
mostrar en texto plano el preview completo de lo que se va a crear/actualizar — para cada grupo: título traducido
a lenguaje de negocio + descripción/checklist propuestos — y esperar aprobación explícita del usuario. Nunca crear
ni actualizar subtasks en Taiga como parte automática de `flow-auto sync` o del orquestador sin ese visto bueno
previo. Si el usuario pide cambios al preview, ajustar y volver a mostrarlo antes de ejecutar. Esto aplica cada
vez que `flow-auto sync` corre (primera vez o re-sync idempotente sobre grupos nuevos/cambiados).

Crear/actualizar subtasks con `mcp__taiga__create_task` / `mcp__taiga__update_task` **solo tras esa aprobación**,
y registrar el mapeo `grupo de tasks.md ↔ id del subtask Taiga` en `taiga-sync.json` (ver "Estado") — nunca anotar
esa referencia dentro del propio `tasks.md`.

Al crear subtasks, aplicar los mismos atributos que el usuario pidió para los tickets del change (sprint,
asignado y atributos personalizados, p. ej. DEPARTAMENTO) y mostrarlos en el preview; no asumirlos en silencio.
El título y la descripción de una subtask quedan fijos desde su creación: el avance se documenta con estado +
comentario, nunca reescribiendo el cuerpo.

### Fase 5 — Dev (por bloques, con agentes)

Reemplaza el uso directo de `openspec-apply-change`: aquí el trabajo de un bloque lo ejecuta el ciclo
coder → tester → reviewer. La unidad de trabajo y de revisión es el **bloque** (un grupo `## N` de `tasks.md`,
que corresponde a una subtask de Taiga), no la tarea suelta.

Convención de branch/commit: usar el change-id de OpenSpec para que el agente identifique el trabajo sin
ambigüedad (ramas del usuario son `release/X.Y.Z` y `feature/X.Y.Z-<slug>`, sin obligación de que coincidan con
el change-id — ver fase 2).

**Regla dura:** el marcado de un subtask Taiga como Done **siempre requiere instrucción explícita del usuario**.
Esta skill nunca auto-marca Done por checkboxes tildados en `tasks.md` — evita falsos positivos de "terminado"
sin verificación real. Comando: `flow-auto done <subtask>`.

#### Tipo de bloque

Al elegir el bloque, el orquestador lo clasifica a partir de las rutas y el texto de sus tareas y lo registra en
`taiga-sync.json` (`flow.apply.blocks[].kind`); si es ambiguo, se lo pregunta al usuario:

| Tipo | Qué es | Ciclo |
|---|---|---|
| `logic` | Sin interfaz (servicios, datos, rutas, utilidades) | coder → tester → reviewer |
| `ui` | Solo interfaz (componentes, páginas, estilos) | [designer] → ui-coder → ui-refiner → tester → reviewer |
| `mixed` | Lógica e interfaz | [designer] → coder → ui-coder → ui-refiner → tester → reviewer |

`[designer]` corre solo si todavía no hay un `ui-brief.md` aprobado del change (ver "Brief de diseño"). El refiner va
**antes** del tester para que los tests se escriban sobre la UI final.

#### Ciclo `flow-auto apply [N]`

1. **Precondiciones.** Fase 3 aprobada (`gates.phase3Approved`), el bloque anterior en estado `committed` o
   confirmado explícitamente por el usuario, y `git status` revisado: si hay cambios sin commit de un bloque
   anterior, informarlo y pedir decisión (no mezclar bloques en el mismo árbol sin que el usuario lo sepa).
2. **Elegir el bloque.** El indicado `N`, o el primer grupo de `tasks.md` con checkboxes pendientes. Leer sus
   tareas con sus criterios de aceptación.
3. **Resolver bloqueos de negocio antes de delegar.** Si el bloque depende de una definición que los artefactos
   no cierran (p. ej. un texto, una regla), preguntársela al usuario **antes** de lanzar agentes.
4. **Clasificar y preparar la UI.** Fijar el tipo del bloque. Si es `ui` o `mixed`: verificar los requisitos de UI
   de la Fase 0; si no hay `ui-brief.md` aprobado, correr `flow-designer`, mostrar el brief **completo** al usuario y
   **parar** hasta su aprobación (gate manual, ver "Brief de diseño").
5. **Coder** (`logic` y `mixed`). `Agent(subagent_type: "mp:flow-coder")` con el contrato del coder.
6. **UI** (`ui` y `mixed`). `Agent(subagent_type: "mp:flow-ui-coder")` y luego
   `Agent(subagent_type: "mp:flow-ui-refiner")` con el informe del ui-coder y el brief.
7. **Tester.** `Agent(subagent_type: "mp:flow-tester")` con los informes de coder y/o ui-coder y ui-refiner.
8. **Reviewer.** `Agent(subagent_type: "mp:flow-reviewer")` con todos los informes anteriores (y el brief si es UI).
9. **Evaluar y, si corresponde, corregir.** Hay ronda de corrección si el tester reporta fallos o bugs en el
   código, o el reviewer da `REQUIERE CORRECCIONES` con hallazgos de severidad alta o media **confirmados**. La
   ronda enruta cada hallazgo a su dueño — lógica → `flow-coder`, interfaz → `flow-ui-coder` (y
   `flow-ui-refiner` si el hallazgo es de calidad de UI) — con la lista exacta de hallazgos, y luego se repite
   `flow-tester` → `flow-reviewer`. **Máximo 2 rondas de corrección.** Los hallazgos "plausibles" o de severidad baja no disparan ronda: se reportan tal
   cual. Si tras las rondas quedan hallazgos abiertos, se informan sin esconderlos ni maquillarlos.
10. **Verificación propia del orquestador.** Correr los comandos de test y compilación documentados en el
   `CLAUDE.md` del repo y revisar `git status` / `git diff --stat`. Contar tareas y archivos desde el disco. Lo
   que se informe al usuario sale de esto, no de lo que dijeron los agentes.
11. **Marcar checkboxes.** Solo de las tareas completas y verificadas; dejar sin marcar las parciales o con
   hallazgos graves abiertos. Actualizar `taiga-sync.json` (`flow.apply`, estado `awaiting_user_review`).
12. **Informe al usuario y PARADA** (formato abajo). Sin commit, sin cambios en Taiga, sin arrancar el siguiente
    bloque.

#### Informe al usuario (formato fijo, en español)

```
## Bloque N completo — <nombre del grupo>
**Tareas:** <lista con estado> · **Progreso total:** X de Y

### Verificación (corrida por el orquestador)
- tests: <archivos/tests, pasan o fallan>   - compile: <resultado>   - formato: <resultado>

### Archivos
- <ruta> — nuevo/modificado — <qué hace>

### Rondas y hallazgos
- Rondas de corrección usadas: <0-2>
- Hallazgos abiertos: <severidad, dónde, qué> (o "ninguno")

### Interfaz (solo bloques `ui` / `mixed`)
- Cumplimiento del brief: <checklist cumplido / parcial / no>   - Estados cubiertos: <vacío, carga, error, éxito>
- Verificación visual: <qué viewports y estados se vieron en el navegador, o "no verificado visualmente">

### Decisiones tomadas por los agentes que debes validar
- <lista; distingue "ya está en el código" de "pregunta abierta de negocio">

### Prueba manual pendiente (tuya)
- <pasos concretos>

Siguiente: dime si apruebas (y qué hago: commit, estado en Taiga, documentación) o qué ajustar.
```

#### `flow-auto approve` — tras la revisión manual del usuario

Se ejecuta **solo cuando el usuario aprueba el bloque** y **solo las acciones que él ordenó** en ese mensaje
(commit, pasar el ticket a pruebas, documentar). Si no aclara cuáles, preguntar. Cada una, así:

1. **Commit.** Seguir la convención de commits del repo (`/commit-convention` o la que documente su `CLAUDE.md`,
   y respetar sus reglas, p. ej. no agregar firmas de Claude aunque el entorno lo sugiera). Por defecto separar en
   commits temáticos (código, tests, marca de tareas), añadiendo **por ruta** solo los archivos del bloque; nunca
   `git add -A`. No hacer push ni cambiar de rama.
2. **Estado en Taiga.** Mover el subtask del bloque (mapeo en `taiga-sync.json`) a "Ready for test" vía
   `flow-documenter` (`draft` → aprobación → `apply`): obtener `version` actual, **reenviar la descripción completa** (los updates
   parciales pueden truncarla) y consultar los ids de estado con `list_task_statuses`. **Nunca a Done** sin
   `flow-auto done`.
3. **Documentación.** `flow-documenter` en `draft` redacta, siguiendo `taiga-ticket-docs`, un comentario en lenguaje llano (lo leen personas no
   técnicas): qué quedó resuelto, qué pruebas automáticas hay y qué queda pendiente de prueba manual. **Mostrarlo
   completo y esperar aprobación explícita del texto** antes de `mcp__taiga__add_comment`. Una aprobación general
   del bloque ("todo bien") no es aprobación del texto de un comentario que el usuario no ha visto.
4. **Estado local.** Actualizar `taiga-sync.json` (`flow.apply`: bloque `committed`, subtask `ready_for_test`).
5. **Siguiente bloque.** Ofrecerlo; no arrancarlo sin orden.

#### Brief de diseño (`ui-brief.md`)

- Lo produce `flow-designer` (solo lectura); **el orquestador** lo guarda en
  `openspec/changes/<change-id>/ui-brief.md` **solo después de que el usuario lo apruebe**. Es contexto compartido por
  archivo para `flow-ui-coder`, `flow-ui-refiner` y `flow-reviewer`.
- **Gate manual, una vez por change:** se muestra el brief completo y se registra `flow.gates.uiBriefApproved`. Los
  bloques UI siguientes lo reutilizan.
- Si un bloque posterior exige cambiar la dirección, `flow-designer` propone un **delta** y se pide aprobación otra
  vez antes de editar `ui-brief.md`.
- Prioridad ante conflicto: pedido del usuario > `ui-brief.md` aprobado > `PRODUCT.md` / `DESIGN.md` > skills.

#### Bloques independientes en paralelo (opt-in)

Solo si el usuario lo pide y los bloques no comparten archivos ni dependencias: cada coder se lanza con
`isolation: "worktree"` y se trabaja cada bloque en su copia; el merge y la revisión los decide el usuario. Por
defecto, secuencial.

### Fase 6 — Test

No hardcodear ningún framework de test (nada de asumir Gradle, npm, pytest, etc.). Leer el comando documentado
en el `CLAUDE.md` del proyecto activo (sección de comandos) y correr ese. Si el proyecto no tiene `CLAUDE.md` o
no documenta comando de test, preguntar al usuario antes de asumir cualquier cosa.

En `flow-auto` el test automático ya ocurre dentro de cada bloque (`flow-tester` más la verificación propia del
orquestador). `flow-auto test` corre la suite completa al final como comprobación global. Las pruebas manuales en
navegador o plataformas reales **las hace el usuario**; el orquestador solo las lista, nunca las simula.

`/code-review` (el skill de Claude Code) **no es un gate bloqueante** acá — es manual e informativo. El usuario
lo corre por su cuenta; si encuentra un inconveniente, itera con `openspec-explore`; si no, avisa para seguir.
Esta skill no lo dispara ni lo exige. (`flow-reviewer` es una revisión interna de cada bloque y no lo reemplaza.)

### Fase 7 — Release

Orden estricto:

1. **Cerrar y documentar todos los tickets Taiga del change** (US + todas las subtasks de fase 1 y fase 4),
   basado en la info final del change. Lo redacta `flow-documenter` (`draft` → aprobación → `apply`) y los
   comentarios siguen la regla de aprobación explícita.
2. Invocar `openspec-verify-change` (`opsx:verify`) para validar que la implementación coincide con los
   artefactos.
3. Invocar `openspec-archive-change` (`opsx:archive`) — recién ahí, nunca antes de que Taiga esté cerrado.
4. Archive completo = flujo de dev de esa feature terminado.

Fuera de esta skill (manual, no automatizado): PR hacia la rama de release.

## Estado — `taiga-sync.json`

Vive dentro de `openspec/changes/<change-id>/taiga-sync.json`. Es un archivo **propio de esta skill**, nunca leído
ni escrito por el tooling de OpenSpec — se puede borrar sin ningún efecto sobre el resto del framework (de hecho
queda huérfano y se pierde solo al archivar el change, lo cual está bien).

Sin índice central fuera del proyecto activo. Para listar estado, escanear `openspec/changes/*/taiga-sync.json`
del proyecto activo.

Esquema (el bloque `flow.apply` es nuevo en `flow-auto`; si falta, tratarlo como bloque sin empezar. `kind` es
`logic` | `ui` | `mixed`; si falta, clasificarlo al empezar el bloque. `uiBriefApproved` ausente = `false`):

```json
{
  "changeId": "TG-123-add-login",
  "taiga": {
    "projectSlug": "mi-proyecto",
    "epicId": null,
    "userStoryId": 123,
    "defaults": {
      "milestoneId": 52,
      "assignedTo": 6,
      "customAttributes": { "DEPARTAMENTO": "DESARROLLO" }
    },
    "phase1Tasks": [
      { "id": 1001, "title": "Confirmar alcance con stakeholder", "status": "done" }
    ],
    "phase4Subtasks": [
      {
        "taigaTaskId": 2001,
        "tasksGroupHeading": "1. Add SMTP retry with exponential backoff",
        "status": "new"
      }
    ]
  },
  "flow": {
    "currentPhase": 5,
    "gates": {
      "phase1TasksDone": true,
      "phase3Approved": true,
      "phase3RejectionKind": null,
      "uiBriefApproved": false
    },
    "apply": {
      "currentBlock": 3,
      "blocks": [
        {
          "heading": "1. Add SMTP retry with exponential backoff",
          "kind": "logic",
          "state": "committed",
          "correctionRounds": 0,
          "commits": ["ac92e70"]
        }
      ]
    }
  },
  "updatedAt": "2026-09-22T00:00:00Z"
}
```

`taiga.defaults` guarda los atributos que el usuario pidió para todos los tickets del change (sprint, asignado,
atributos personalizados). `flow-documenter` los aplica al crear tickets y los muestra en cada payload, para que
no dependan de la memoria de la conversación. Si falta, el orquestador se los pregunta al usuario y los guarda.

Estados de un bloque: `pending` → `implementing` → `awaiting_user_review` → `committed` (el Done de Taiga es
aparte y siempre manual). `status` de subtask: `new` → `ready_for_test` → `done`.

## Subcomandos

Parsear el argumento recibido tras `/flow-auto`. Si viene vacío, es el modo orquestador (ver abajo).

- **`flow-auto start "<necesidad>"`** — Fase 1. Crea (o ayuda a crear) Épica opcional + US + Tasks pre-spec en
  Taiga vía `mcp__taiga__*`. No avanza de fase hasta que las Tasks estén en Done.
- **`flow-auto explore`** — Fase 2. Verifica Fase 0 (openspec inicializado) y gate de fase 1 (Tasks Done). Invoca
  `openspec-explore`; puede consultar a `flow-architect`.
- **`flow-auto review`** — Fase 3. Lanza `flow-architect` sobre los artefactos y muestra sus hallazgos junto al
  checklist de lectura (proposal/specs/design/tasks) para revisión manual. Según lo que el usuario indique,
  deriva a iteración con `openspec-explore` (gap técnico), a fase 1 (gap de negocio), o a `flow-auto apply`
  (aprobado).
- **`flow-auto sync`** — Fase 4. Agrupa `tasks.md`, muestra el preview de subtasks a crear/actualizar y espera
  aprobación explícita, recién entonces crea/actualiza en Taiga y escribe/actualiza `taiga-sync.json`.
  Idempotente: si un grupo ya tiene `taigaTaskId` registrado, actualiza en vez de duplicar.
- **`flow-auto apply [N]`** — Fase 5. Clasifica el bloque `N` (o el siguiente pendiente) y ejecuta su ciclo
  (coder / designer → ui-coder → ui-refiner / tester → reviewer, según el tipo) y se detiene con el informe para
  revisión manual. No hace commit ni toca Taiga.
- **`flow-auto approve`** — Fase 5. Tras la revisión del usuario, ejecuta solo las acciones que él ordenó:
  commit, ticket a "Ready for test" y/o documentación (con aprobación del texto).
- **`flow-auto done <subtask>`** — Fase 5. Marca un subtask Taiga puntual como Done. Solo por instrucción explícita.
- **`flow-auto test`** — Fase 6. Lee comando de test del `CLAUDE.md` del proyecto activo y lo corre.
- **`flow-auto release`** — Fase 7. Cierra tickets Taiga del change → `openspec-verify-change` →
  `openspec-archive-change`.
- **`flow-auto docs [evento]`** — Transversal. Lanza `flow-documenter` en `draft` para el evento indicado
  (intake, definición de negocio, artefactos, bloque, release) y muestra los payloads para aprobación; tras la
  aprobación, `apply`.
- **`flow-auto sync-check`** — Transversal. Lanza `flow-documenter` en `audit` y muestra las desincronizaciones
  entre Taiga y el proyecto local; propone los `draft` de las correcciones.
- **`flow-auto status`** — Transversal. Lee `taiga-sync.json` del change activo (o escanea todos si no hay uno
  obvio en contexto) y muestra la fase, el bloque actual y el estado de cada bloque.

### `flow-auto` sin argumentos — orquestador

1. Detecta el change activo (rama actual, o `taiga-sync.json` más reciente si hay ambigüedad).
2. Lee su estado (`currentPhase`, gates, `apply`).
3. Si el siguiente paso es automatizable (fase 2, 4, `apply` de un bloque, 6, 7), lo ejecuta. En cada
   transición de fase corre el checkpoint de documentación (`audit`).
4. Si el siguiente paso es un gate manual, se detiene y reporta claramente qué espera del usuario — nunca decide
   por él. Gates manuales: aprobación de la fase 3, **revisión del bloque** (fin de cada `apply`), commit, aprobación
   de textos de comentarios y de previews de Taiga, marcado Done, pruebas manuales y `/code-review`.
5. Repite hasta completar el flujo o toparse con un gate manual. **Nunca encadena dos bloques de `apply` sin que el
   usuario revise y apruebe el anterior.**

## Contratos de delegación

Cada llamada a `Agent` debe ser autocontenida. Plantillas (rellenar entre `<>`):

**flow-coder**
```
Change: <change-id> (openspec/changes/<change-id>/). Bloque: <N> — <nombre del grupo>, tareas <N.1 a N.k>.
Lee CLAUDE.md, openspec/config.yaml, proposal.md, design.md, specs/** y tasks.md antes de escribir.
Decisiones del usuario ya tomadas (respétalas): <lista>.
Restricciones: sin git, sin tests, sin tocar tasks.md ni Taiga. Si el spec no define algo de negocio, elige lo
conservador y repórtalo como "decisión a validar", o detente y pregunta si bloquea.
Devuelve tu informe en el formato definido en tu prompt.
[Ronda de corrección: corrige exactamente estos hallazgos: <lista con archivo:línea y regla afectada>]
```

**flow-designer**
```
Change: <change-id> (openspec/changes/<change-id>/). Alcance de UI: <bloques / pantallas>. [Delta sobre ui-brief.md
aprobado: <qué cambia y por qué>].
Lee CLAUDE.md, PRODUCT.md, DESIGN.md (si existen), specs/** y tasks.md. Si falta PRODUCT.md, detente y repórtalo.
Decisiones del usuario ya tomadas (respétalas): <lista>.
Solo lectura. Devuelve el brief en el formato de tu prompt; no escribas archivos. Los gaps de negocio, como preguntas.
```

**flow-ui-coder**
```
Change: <change-id>. Bloque: <N> — <nombre del grupo>, tareas <N.1 a N.k>. Brief aprobado:
openspec/changes/<change-id>/ui-brief.md. [Informe del coder (lógica lista para consumir): <pegar>].
Lee CLAUDE.md, PRODUCT.md, DESIGN.md, ui-brief.md, specs/** y tasks.md antes de escribir. Usa componentes shadcn
(MCP) y los tokens del proyecto.
Decisiones del usuario ya tomadas (respétalas): <lista>.
Restricciones: sin git, sin tests, sin lógica de negocio, sin tocar tasks.md, ui-brief.md ni Taiga.
Devuelve tu informe en el formato definido en tu prompt.
[Ronda de corrección: corrige exactamente estos hallazgos: <lista con archivo:línea y punto del brief afectado>]
```

**flow-ui-refiner**
```
Change: <change-id>. Bloque: <N>. Brief: openspec/changes/<change-id>/ui-brief.md. Informe del ui-coder: <pegar>.
Audita la UI del bloque contra el checklist del brief y corrige solo desvíos del brief, del piso de calidad y de
accesibilidad. Una pasada de auditoría y como máximo una de confirmación. No cambies comportamiento ni dirección
visual; sin git, sin tests, sin tocar tasks.md, ui-brief.md ni Taiga. Distingue lo visto en el navegador de lo inferido.
[Ronda de corrección: atiende estos hallazgos de UI: <lista>]
```

**flow-tester**
```
Change: <change-id>. Bloque: <N>. Informe del coder / ui-coder / ui-refiner: <pegar los que apliquen>.
Escribe los tests del bloque a partir de los escenarios de los specs y de los criterios de aceptación; corre
tests del bloque, suite completa, compile y prettier (solo los archivos tocados). No modifiques código de
producción: reporta bugs con diagnóstico. Lista la prueba manual pendiente por tarea.
```

**flow-reviewer**
```
Change: <change-id>. Bloque: <N> (tipo <logic|ui|mixed>). Informes: coder / ui-coder / ui-refiner <pegar los que
apliquen>, tester <pegar>. [Bloque de UI: brief en openspec/changes/<change-id>/ui-brief.md.]
Revisa el git diff y los archivos nuevos contra specs y design. Solo lectura. Verifica cada hallazgo antes de
reportarlo y distingue confirmado de plausible.
```

**flow-architect**
```
Change: <change-id>. Pedido: <explorar X / revisar artefactos / evaluar decisión Y>.
Solo lectura. Ancla todo en el código real. Separa gaps técnicos de gaps de negocio y formula estos últimos como
preguntas para el usuario.
```

**flow-documenter**
```
Modo: <draft | apply | audit>. Change: <change-id>. Evento: <intake / definición de negocio / corrección de regla /
artefactos listos / bloque aprobado / release / chequeo entre fases>.
Defaults de Taiga del change (de taiga-sync.json): <milestoneId, assignedTo, customAttributes>.
Contexto: <qué se decidió, qué bloque, qué estado pidió el usuario>.
[apply: payload aprobado por el usuario, textual e inalterable: <pegar>]
Lee las reglas de ${CLAUDE_PLUGIN_ROOT}/skills/taiga-ticket-docs/. En draft y audit NO llames herramientas de Taiga que
escriban. En apply ejecuta solo el payload aprobado y verifica releyendo. Nunca Done, nunca borres.
```

## Reglas duras (no romper)

- Nunca escribir ni modificar archivos propios de OpenSpec, salvo marcar checkboxes de `tasks.md` tras verificar un
  bloque (Fase 5).
- Nunca auto-marcar un subtask Taiga como Done sin instrucción explícita (tampoco `flow-documenter`).
- Nunca omitir el checkpoint de documentación entre fases ni darlo por hecho sin correrlo.
- Nunca crear/actualizar subtasks Taiga en fase 4 sin mostrar antes el preview (título + descripción por grupo)
  y esperar aprobación explícita del usuario.
- **Nunca enviar un comentario de Taiga (`add_comment`) sin mostrar su texto completo y recibir aprobación
  explícita de ese texto.** Cero excepciones. Lo mismo vale para `flow-documenter`: solo escribe en Taiga en modo
  `apply` con un payload aprobado y transmitido textual; en `draft` y `audit` no escribe.
- **Nunca hacer git (add, commit, push, branch) sin orden directa del usuario.** Los agentes no hacen git jamás.
- **Nunca encadenar bloques de `apply`:** tras cada bloque, informe y parada hasta la revisión del usuario.
- **Los agentes no deciden definiciones de negocio**; el orquestador las pregunta al usuario.
- **No repetir como hecho lo que dice un informe de agente sin verificarlo** con comandos propios.
- Máximo 2 rondas de corrección por bloque; si quedan hallazgos, se informan tal cual.
- **Nunca escribir UI sin un `ui-brief.md` aprobado por el usuario**, ni guardar un brief que el usuario no vio.
- **Nunca correr `/impeccable init` ni `document`, `npx shadcn@latest init` o instalar software** por cuenta del
  orquestador o de un agente: se avisa y lo decide el usuario. `init` es una entrevista con el usuario.
- **Los agentes de UI no deciden definiciones de negocio ni textos legales**; los textos de UI propuestos se
  presentan como "a validar".
- No lanzar agentes sin que el usuario haya invocado `flow-auto` (o pedido explícitamente un agente).
- `/code-review` nunca es bloqueante en esta skill.
- Ante falla parcial en llamadas `mcp__taiga__*` (ej: se crea la US pero falla una Task): reintentar; si ya se
  creó algo parcialmente, reconciliar/corregir sin duplicar; si no hay fallback posible, informar al usuario
  para que decida manualmente — nunca abortar ni revertir sin avisar.
- En `update_*` de Taiga, reenviar siempre la descripción completa (los updates parciales pueden truncarla).
- El nombre de rama nunca bloquea ni tiene que coincidir con el change-id de OpenSpec.
- La skill `openspec-explore` (`opsx:explore`) es el único punto de entrada para creación/modificación de
  artefactos OpenSpec. `opsx:verify` y `opsx:archive` son invocaciones directas y separadas, propias de fase 7.
  En `flow-auto` el rol de `opsx:apply` lo cumple el ciclo por bloques de la fase 5.

## Herramientas

- Agentes: tool `Agent` con `subagent_type` `flow-architect`, `flow-designer`, `flow-coder`, `flow-ui-coder`,
  `flow-ui-refiner`, `flow-tester`, `flow-reviewer`, `flow-documenter`.
- Diseño: skills `impeccable`, `ui-ux-pro-max` y `taste-skill` (las usan los agentes de UI) y MCP `shadcn`.
- Taiga: `mcp__taiga__*`, usado a través de `flow-documenter` (el orquestador solo lee para verificar), con las
  reglas de la skill `taiga-ticket-docs`.
- OpenSpec: Skill tool con `skill: "openspec-explore"`, `"openspec-verify-change"`, `"openspec-archive-change"`.
- Proyecto: `Read` del `CLAUDE.md` para comandos de test, compilación y formato; `Bash` para correrlos y para git
  (solo con orden del usuario) y `openspec status`.
