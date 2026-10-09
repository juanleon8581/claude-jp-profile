---
name: flow
description: >-
  Orquesta el flujo estandarizado del usuario para desarrollo de software: Spec-Driven Development vía OpenSpec
  (usando el skill opsx:explore para creación/modificación de artefactos) envuelto en Taiga como capa de Scrum/negocio.
  Activar cuando el usuario escriba "/flow", pida iniciar una feature o fix bajo este proceso, pregunte en qué fase
  está un change activo, pida sincronizar OpenSpec con Taiga, o mencione cerrar/archivar un change junto con sus
  tickets de Taiga. Subcomandos: start, explore, review, sync, done, test, release, status. Sin argumentos actúa
  como orquestador: lee el estado del change activo y ejecuta o sugiere el siguiente paso, deteniéndose en los
  gates manuales.
---

# flow — SDD (OpenSpec) + Scrum (Taiga)

Skill de nivel usuario. No vive en ningún proyecto específico — se usa en cualquier repo donde el usuario trabaje
bajo este proceso. El proyecto activo sí necesita tener OpenSpec inicializado (ver Fase 0).

## Principio

Taiga y OpenSpec son dos capas independientes ("islas"):

- **Taiga** = capa de negocio/Scrum. Lenguaje no técnico. Lo que ve gente sin contexto técnico.
- **OpenSpec** = capa técnica. Specs, diseño, tareas atómicas. Fuente de verdad para el desarrollo.

Esta skill sincroniza ambas capas en los puntos justos, sin que ninguna herramienta termine conociendo o
dependiendo de la otra. **Nunca se escriben ni modifican archivos propios de OpenSpec** (`proposal.md`,
`specs/**`, `design.md`, `tasks.md`). El único archivo propio de esta skill dentro de un change de OpenSpec es
`openspec/changes/<change-id>/taiga-sync.json` (ver "Estado").

## Fase 0 — Precondición de proyecto

Antes de correr `flow explore` (o cualquier paso que toque OpenSpec), verificar que el proyecto activo tenga
`openspec/` inicializado:

```bash
test -d openspec && echo OK || echo "falta init"
```

Si falta, avisar al usuario y sugerir `openspec init .` en la raíz del proyecto — el framework OpenSpec vive
siempre a nivel de proyecto, nunca a nivel usuario. No inicializarlo sin que el usuario lo pida explícito.

## Las 7 fases

### Fase 1 — Intake (Taiga)

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

El change-id que resulte queda como **única fuente de verdad** para identificar el trabajo — no tiene que
coincidir con el nombre de la rama git (`release/X.Y.Z`, `feature/X.Y.Z-<slug>`). Si el nombre de rama sirve, se
reutiliza; si no, el que define `opsx:explore` es el que vale.

**Gate de entrada:** Tasks de fase 1 en Done (heredado de fase 1).

### Fase 3 — Gate de aprobación

100% manual. El usuario lee proposal + specs + tasks (+ design si existe). Sin chequeo automático de esta skill.

- **Gap técnico** (algo que dev puede resolver solo) → se le informa a `openspec-explore` para iterar in-place
  sobre los artefactos existentes. No se vuelve a fase 1.
- **Gap de negocio** (requiere una definición que dev no puede tomar solo) → vuelve a fase 1: se crea/escala un
  ticket Taiga hacia el área de negocio para cerrar esa definición. Una vez cerrado, se retoma `openspec-explore`
  con la info nueva.
- **Sin gaps** → commit de los artefactos generados → se invoca directamente el skill `openspec-apply-change`
  (`opsx:apply`) para arrancar la implementación (pasa a fase 5).

### Fase 4 — Sync a Taiga

Dispara **una sola vez**, cuando `tasks.md` ya quedó cerrado/estable post-aprobación (fase 3) — no a mitad de
dev bajo flujo normal.

**Regla de agrupación:** 1 subtask en Taiga = 1 grupo de nivel superior de `tasks.md` (las secciones numeradas
`## N. <nombre del grupo>`), nunca 1 subtask por checkbox individual. Los checkboxes técnicos quedan solo en
`tasks.md`. Resultado esperado: 3-6 subtasks legibles por US, no 15-20 técnicos.

**Traducción:** el título de cada subtask Taiga es el valor de negocio del grupo, no su nombre técnico. Ej: grupo
OpenSpec "Add SMTP retry with exponential backoff" → subtask Taiga "Mejorar confiabilidad de envío de emails en
conexiones inestables".

**Preview y aprobación obligatoria:** antes de llamar a `mcp__taiga__create_task` / `mcp__taiga__update_task`,
mostrar en texto plano el preview completo de lo que se va a crear/actualizar — para cada grupo: título traducido
a lenguaje de negocio + descripción/checklist propuestos — y esperar aprobación explícita del usuario. Nunca crear
ni actualizar subtasks en Taiga como parte automática de `flow sync` o del orquestador sin ese visto bueno previo.
Si el usuario pide cambios al preview, ajustar y volver a mostrarlo antes de ejecutar. Esto aplica cada vez que
`flow sync` corre (primera vez o re-sync idempotente sobre grupos nuevos/cambiados).

Crear/actualizar subtasks con `mcp__taiga__create_task` / `mcp__taiga__update_task` **solo tras esa aprobación**,
y registrar el mapeo `grupo de tasks.md ↔ id del subtask Taiga` en `taiga-sync.json` (ver "Estado") — nunca anotar
esa referencia dentro del propio `tasks.md`.

### Fase 5 — Dev

Ejecutado por `openspec-apply-change` (`opsx:apply`), trabajando `tasks.md` como fuente de verdad técnica.

Convención de branch/commit: usar el change-id de OpenSpec para que el agente identifique el trabajo sin
ambigüedad (ramas del usuario son `release/X.Y.Z` y `feature/X.Y.Z-<slug>`, sin obligación de que coincidan con
el change-id — ver fase 2).

**Regla dura:** el marcado de un subtask Taiga como Done **siempre requiere instrucción explícita del usuario**.
Esta skill nunca auto-marca Done por checkboxes tildados en `tasks.md` — evita falsos positivos de "terminado"
sin verificación real. Comando: `flow done <subtask>`.

### Fase 6 — Test

No hardcodear ningún framework de test (nada de asumir Gradle, npm, pytest, etc.). Leer el comando documentado
en el `CLAUDE.md` del proyecto activo (sección de comandos) y correr ese. Si el proyecto no tiene `CLAUDE.md` o
no documenta comando de test, preguntar al usuario antes de asumir cualquier cosa.

`/code-review` (el skill de Claude Code) **no es un gate bloqueante** acá — es manual e informativo. El usuario
lo corre por su cuenta; si encuentra un inconveniente, itera con `openspec-explore`; si no, avisa para seguir.
Esta skill no lo dispara ni lo exige.

### Fase 7 — Release

Orden estricto:

1. **Cerrar y documentar todos los tickets Taiga del change** (US + todas las subtasks de fase 1 y fase 4),
   basado en la info final del change.
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

Esquema:

```json
{
  "changeId": "TG-123-add-login",
  "taiga": {
    "projectSlug": "mi-proyecto",
    "epicId": null,
    "userStoryId": 123,
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
    "currentPhase": 4,
    "gates": {
      "phase1TasksDone": true,
      "phase3Approved": null,
      "phase3RejectionKind": null
    }
  },
  "updatedAt": "2026-09-22T00:00:00Z"
}
```

## Subcomandos

Parsear el argumento recibido tras `/flow`. Si viene vacío, es el modo orquestador (ver abajo).

- **`flow start "<necesidad>"`** — Fase 1. Crea (o ayuda a crear) Épica opcional + US + Tasks pre-spec en Taiga
  vía `mcp__taiga__*`. No avanza de fase hasta que las Tasks estén en Done.
- **`flow explore`** — Fase 2. Verifica Fase 0 (openspec inicializado) y gate de fase 1 (Tasks Done). Invoca
  `openspec-explore`.
- **`flow review`** — Fase 3. Muestra checklist de lectura (proposal/specs/design/tasks) para revisión manual.
  Según lo que el usuario indique, deriva a iteración con `openspec-explore` (gap técnico), a fase 1 (gap de
  negocio), o a commit + `openspec-apply-change` (aprobado).
- **`flow sync`** — Fase 4. Agrupa `tasks.md`, muestra el preview de subtasks a crear/actualizar y espera
  aprobación explícita, recién entonces crea/actualiza en Taiga y escribe/actualiza `taiga-sync.json`.
  Idempotente: si un grupo ya tiene `taigaTaskId` registrado, actualiza en vez de duplicar.
- **`flow done <subtask>`** — Fase 5. Marca un subtask Taiga puntual como Done. Solo por instrucción explícita.
- **`flow test`** — Fase 6. Lee comando de test del `CLAUDE.md` del proyecto activo y lo corre.
- **`flow release`** — Fase 7. Cierra tickets Taiga del change → `openspec-verify-change` → `openspec-archive-change`.
- **`flow status`** — Transversal. Lee `taiga-sync.json` del change activo (o escanea todos si no hay uno obvio
  en contexto) y muestra en qué fase está cada uno.

### `flow` sin argumentos — orquestador

1. Detecta el change activo (rama actual, o `taiga-sync.json` más reciente si hay ambigüedad).
2. Lee su estado (`currentPhase`, gates).
3. Si el siguiente paso es automatizable (fase 2, 4, 5-apply, 6, 7), lo ejecuta.
4. Si el siguiente paso es un gate manual (fase 3 aprobación, fase 5 marcado Done, fase 6 code-review), se
   detiene y reporta claramente qué está esperando del usuario — nunca decide por él.
5. Repite hasta completar el flujo o toparse con un gate manual.

## Reglas duras (no romper)

- Nunca escribir ni modificar archivos propios de OpenSpec.
- Nunca auto-marcar un subtask Taiga como Done sin instrucción explícita.
- Nunca crear/actualizar subtasks Taiga en fase 4 sin mostrar antes el preview (título + descripción por grupo)
  y esperar aprobación explícita del usuario.
- `/code-review` nunca es bloqueante en esta skill.
- Ante falla parcial en llamadas `mcp__taiga__*` (ej: se crea la US pero falla una Task): reintentar; si ya se
  creó algo parcialmente, reconciliar/corregir sin duplicar; si no hay fallback posible, informar al usuario
  para que decida manualmente — nunca abortar ni revertir sin avisar.
- El nombre de rama nunca bloquea ni tiene que coincidir con el change-id de OpenSpec.
- La skill `openspec-explore` (`opsx:explore`) es el único punto de entrada para creación/modificación de
  artefactos OpenSpec. `opsx:apply`, `opsx:verify` y `opsx:archive` son invocaciones directas y separadas,
  propias de fases 3(salida)/5, 6-7 y 7 respectivamente — no pasan por `opsx:explore`.

## Herramientas

- Taiga: `mcp__taiga__*` (crear/actualizar épicas, user stories, tasks; comentarios).
- OpenSpec: Skill tool con `skill: "openspec-explore"`, `"openspec-apply-change"`, `"openspec-verify-change"`,
  `"openspec-archive-change"`.
- Proyecto: `Read` del `CLAUDE.md` para comando de test; `Bash` para correrlo y para git (branch actual).
