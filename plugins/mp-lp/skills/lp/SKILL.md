---
name: lp
description: Orquesta el flujo ligero de landing pages (Astro + TypeScript + Tailwind + shadcn) con agentes especializados - brief, dirección de diseño, build por secciones, movimiento, medios, SEO y QA - deteniéndose en los gates manuales. Sin OpenSpec; Taiga es opcional y se pregunta al iniciar cada flujo. Activar cuando el usuario escriba "/lp", pida crear o iterar un landing page, pregunte en qué fase está un landing o pida auditar SEO/rendimiento de uno. Subcomandos - start, brief, direction, approve, build, audit, qa, ship, docs, status. Sin argumentos lee el estado y sugiere el siguiente paso.
---

# lp — flujo de landing pages con agentes

Flujo ligero para landings: el repo es la fuente de verdad (carpeta `lp/`), sin OpenSpec. El stack es **Astro + TypeScript estricto + Tailwind**, con shadcn solo donde hay interactividad. Las prioridades son otras que en un producto con backend: mensaje, look and feel, movimiento, medios, SEO y rendimiento.

Skill de nivel usuario, se usa en cualquier proyecto con el plugin `mp-lp` habilitado. Precondición: `/mp-lp:init` sin ✖.

## Principios

- **El orquestador (tú) no escribe el código ni los textos**: delega en agentes y verifica lo que reportan con comandos propios.
- **Taiga es opcional y se decide por flujo.** Al iniciar (`start`) se pregunta; la respuesta queda en `lp/state.json`. Si es "no", **no se llama a ninguna herramienta de Taiga** en todo el flujo.
- **Dos gates manuales** del usuario: la dirección (antes de construir) y el QA (antes de publicar). Nunca se saltan.
- El contenido de marca, textos legales, precios y datos de contacto **no se inventan**: se marcan `_pendiente_` y se preguntan.

## Roster (`Agent` con `subagent_type`, prefijo del plugin)

| Agente | Rol | Escribe |
|---|---|---|
| `mp-lp:lp-strategist` | Analista del brief, sin estado, en tres modos: `analyze` (cobertura y preguntas), `review` (preparación para los demás agentes) y `draft` (brief final). No conversa: la entrevista la llevas tú | nada (devuelve análisis o borrador) |
| `mp-core:ui-designer` | Dirección: mapa de secciones, sistema visual, lenguaje de movimiento, estados, responsive (agente compartido con `mp`; perfil `mp-lp:lp-ui-profile`) | nada (devuelve la dirección) |
| `mp-core:ui-coder` | Construye una sección: `.astro` + Tailwind, islas shadcn si hay interacción (compartido; mismo perfil) | código de la sección |
| `mp-core:ui-refiner` | Una pasada final de calidad de la sección: accesibilidad, responsive, estados, tokens (compartido; mismo perfil) | correcciones de UI |
| `mp-lp:lp-motion` | Animaciones y microinteracciones de una sección | código de movimiento |
| `mp-lp:lp-media` | Imágenes, video, fuentes e iconos: formatos, tamaños, carga | assets y componentes de medios |
| `mp-lp:lp-seo` | Metadatos, datos estructurados, sitemap, robots, Open Graph | solo archivos de SEO |
| `mp-core:manual-tester` | Ejecuta en `terminal-browser` el plan de QA visual que le das; no diseña pruebas (agente compartido de `mp-core`) | nada (devuelve pasa/falla por caso) |
| `mp-lp:lp-documenter` | Redacta y aplica tickets de Taiga (solo si está activo) | Taiga, solo en `apply` |

Quién escribe qué: el orquestador guarda los artefactos de `lp/` (brief, dirección, plan de secciones, informes de auditoría y `state.json`) a partir de lo que devuelven los agentes y **solo tras la aprobación del usuario cuando corresponde**. Los agentes de código no tocan `lp/`.

## Estado y artefactos (carpeta `lp/` del proyecto)

```
lp/
  state.json        estado del flujo (ver abajo)
  brief.draft.md    borrador vivo de la entrevista (cobertura, registro, brief en construcción)
  brief.md          brief aprobado
  brief-log.md      registro de decisiones de la entrevista (respuestas y su fuente)
  cuestionario-cliente.md  preguntas escaladas, listas para enviar al cliente (si las hay)
  insumos-impeccable.md    resumen del brief para /impeccable init
  direction.md      dirección de diseño aprobada (fuente de verdad visual)
  sections.md       plan de secciones, una por bloque, con checkbox - [ ] / - [x]
  audits/           seo.md, qa.md (último informe de cada uno)
```

`lp/state.json`:

```json
{
  "slug": "landing-x",
  "phase": "brief | direction | build | audit | qa | ship | done",
  "brief": { "status": "none | interviewing | waiting-client | approved", "round": 0, "depth": "core", "escalated": 0 },
  "gates": { "direction": false, "qa": false },
  "sections": [{ "id": "hero", "name": "Hero", "status": "pending | built | approved", "motion": true, "media": true }],
  "rounds": { "audit": 0 },
  "taiga": { "enabled": false, "projectId": null, "usId": null, "milestoneId": null, "assignedTo": null,
             "subtasks": { "hero": { "id": null, "status": null } } }
}
```

Lo escribe solo el orquestador. Los archivos de `lp/` se versionan con el proyecto.

## Fase 0 — Precondición

Corre `bash "${CLAUDE_PLUGIN_ROOT}/scripts/project-check.sh"`. Con ✖ detente y sugiere `/mp-lp:init`. `PRODUCT.md` **no bloquea el brief** (la entrevista cubre lo esencial del negocio y deja `lp/insumos-impeccable.md` para `/impeccable init`). Sí es requisito de la fase de dirección: su creación es una entrevista del usuario con `impeccable`, no se inventa. `DESIGN.md` es recomendado.

## Las fases

### 1. Brief (`lp start` y `lp brief`) — entrevista guiada
La fase de **exploración y definición**, y la más importante del flujo: se conduce como una conversación, no como un informe. **Carga la skill `mp-lp:lp-brief-interview`** y sigue su protocolo (el subagente no conversa: la entrevista la llevas tú en el hilo principal con `AskUserQuestion`).

1. Pregunta el nombre/slug del landing y **"¿Quieres seguimiento documental en Taiga para este flujo?"**. Si sí, pregunta proyecto, sprint y asignado (consulta Taiga en solo lectura) y guárdalos en `state.json.taiga`. Si Taiga no responde, dilo y continúa sin él. Acepta un archivo inicial (`lp start --from <archivo>`).
2. **Analiza** (`lp-strategist` modo `analyze`), **entrevista por rondas** (bloqueantes primero, con opción "No lo sé, preguntar al cliente"), **revisa** (`review`) y **cierra** (`draft`), como dice la skill. Profundidad adaptativa: siempre el núcleo; las dimensiones profundas se activan por señales o cuando el usuario lo pida.
3. El estado vive en `lp/brief.draft.md` (retomable en otra sesión). Las preguntas escaladas generan `lp/cuestionario-cliente.md`; las respuestas del cliente se integran con `lp brief --from`.
4. Con la aprobación explícita del brief completo: `lp/brief.md`, `lp/brief-log.md`, `lp/insumos-impeccable.md` (para que el usuario ejecute `/impeccable init`, que **no se reemplaza**) y `state.json` actualizado.
5. Taiga activo: checkpoint de documentación (ver abajo): crea la US en lenguaje de negocio.

### 2. Dirección (`lp direction`) → **Gate 1**
0. **Precondición:** `lp/brief.md` aprobado y `PRODUCT.md` existente. Si falta `PRODUCT.md`, detente y pide al usuario ejecutar `/impeccable init` (con `lp/insumos-impeccable.md` como evidencia); no lo escribas tú.
1. Lanza `Agent(subagent_type: "mp-core:ui-designer")` indicándole el **perfil** `mp-lp:lp-ui-profile` y pasándole `lp/brief.md`, `PRODUCT.md`, `DESIGN.md` y el estado actual del repo.
2. Presenta la dirección completa al usuario. Con su aprobación explícita guárdala en `lp/direction.md`, genera `lp/sections.md` (una sección por bloque, en orden de página, marcando cuáles llevan movimiento y medios) y la lista en `state.json`. `gates.direction = true`.
3. Sin esta aprobación **no se escribe UI**.
4. Taiga activo: tras el gate, draft de subtasks por sección (ver "Taiga").

### 3. Build por secciones (`lp build [sección]`)
Sin argumento toma la siguiente sección `pending`. Por sección:
1. `mp-core:ui-coder`, con el perfil `mp-lp:lp-ui-profile`, la sección, `direction.md` y `brief.md`.
2. Si la sección lleva `media: true`: `lp-media` (antes o junto al builder, según haya assets).
3. Si lleva `motion: true`: `lp-motion` sobre lo que dejó el builder.
4. `mp-core:ui-refiner` (perfil `mp-lp:lp-ui-profile`): **una** pasada de calidad sobre la sección ya con medios y movimiento; si encuentra un problema de movimiento o de medios, lo reporta y vuelve a su dueño en la ronda de corrección.
5. **Verificación propia** del orquestador: corre los comandos de `CLAUDE.md` (tipos y build). No des por bueno un informe sin esto.
6. Informe de la sección (formato abajo) y **parada**: el usuario revisa. No encadenes secciones salvo que el usuario lo ordene ("construye todo"); aun así, cada sección reporta por separado y un fallo detiene la cadena.
7. Con la aprobación de la sección: marca `- [x]` en `lp/sections.md`, estado `approved` y, con Taiga activo, estado y comentario de resultado.

### 4. Auditoría (`lp audit`)
Dos fuentes en paralelo, siempre sobre un build de producción (nunca `astro dev`):
1. `lp-seo` en modo `audit`.
2. Las métricas: tú corres `bash "${CLAUDE_PLUGIN_ROOT}/scripts/measure.sh" --build "<comando de build de CLAUDE.md>"` (o `--url <url>`). Construye, levanta `astro preview`, mide con Lighthouse móvil y escritorio contra los presupuestos de `lp-performance` y lo detiene. Es determinista: no necesita agente. Si no hay Chrome, repórtalo y no inventes números.

Guarda ambos informes en `lp/audits/` (`seo.md`, `metricas.md`). Los hallazgos bloqueantes e importantes se corrigen en rondas: `lp-seo` (modo `fix`) para SEO, `mp-core:ui-coder`/`lp-motion`/`lp-media` para el resto. **Máximo 2 rondas**; lo que quede se informa tal cual.

### 5. QA visual (`lp qa`) → **Gate 2**
1. **Tú armas el plan de pruebas** a partir del checklist de `lp/direction.md`: un caso por sección y viewport (360, 768, 1280, 1920), más los estados (foco por teclado, formulario con error y con éxito, menú móvil) y el comportamiento con movimiento reducido. Cada caso con pasos y resultado esperado; el `manual-tester` no inventa pruebas.
2. Pregunta el modo de navegador (`inline` por defecto o `visual` si el usuario quiere verlo en vivo) y lanza `Agent(subagent_type: "mp-core:manual-tester")` con el plan y la URL (`astro preview` ya levantado por ti, que detienes al terminar).
3. Presenta el informe (pasa / falla / bloqueado) con las métricas de la auditoría. Los fallos se corrigen en rondas como en la fase 4. La aprobación explícita del usuario pone `gates.qa = true`.

### 6. Publicación (`lp ship`)
Solo con ambos gates. Checklist: `site` correcto en `astro.config`, `noindex` retirado de producción, `robots.txt` y sitemap, vista previa de Open Graph, analítica acordada, formularios apuntando al destino real, `astro build` sin errores. El despliegue y el git los hace el usuario. Con Taiga activo: documentación de cierre.

## Informe de sección (lo que ve el usuario)

```
## Sección <nombre> completa
### Archivos          <ruta — qué hace>
### Verificación      tipos: <ok/falla> · build: <ok/falla>
### Medios y movimiento  <qué se hizo / no aplica>
### Decisiones tomadas por los agentes que debes validar
### Qué revisar a mano   <viewports, estados, interacciones>
### Pendientes           <_pendiente_ y bloqueos>
```

## Taiga (solo si `state.json.taiga.enabled`)

La documentación la produce `lp-documenter` en tres modos fijados por el orquestador: `draft` (redacta el texto exacto, no escribe), `apply` (ejecuta exactamente un payload ya aprobado) y `audit` (compara Taiga con `lp/`, solo lectura). Antes de redactar, el orquestador carga la skill `mp-core:taiga-ticket-docs`.

Flujo: `draft` → muestras al usuario el payload **completo y textual** → aprobación explícita → `apply` con ese texto sin alterar → verificas el informe y actualizas `state.json.taiga`.

| Evento | Qué se documenta |
|---|---|
| Brief aprobado | US del landing en lenguaje de negocio |
| Dirección aprobada | Un subtask por sección con comportamiento visible (hero, formulario, precios...), sin los técnicos |
| Sección aprobada | Estado del subtask y comentario de resultado |
| Entre fases | `audit` y, si hay desajuste, `draft` de correcciones |
| Publicación | Cierre de la US y los subtasks |

Audiencia no técnica: nada de archivos, comandos, librerías, agentes ni jerga de proceso. Hechos y resultados que alguien de negocio entienda.

## Subcomandos

| Comando | Qué hace |
|---|---|
| `lp start [--from <archivo>]` | Fase 0 + pregunta de Taiga + entrevista de brief (con archivo inicial opcional) |
| `lp brief` / `lp direction` | Retoma o ajusta esa fase (si cambia algo ya aprobado, avisa que invalida los gates posteriores) |
| `lp brief --from <respuestas>` | Integra las respuestas del cliente al cuestionario y continúa la entrevista |
| `lp brief --cuestionario` | Regenera `lp/cuestionario-cliente.md` con las preguntas escaladas aún abiertas |
| `lp approve` | Registra la aprobación de la fase o sección en curso |
| `lp build [sección]` | Fase 3 de una sección |
| `lp audit` / `lp qa` | Fases 4 y 5 |
| `lp ship` | Fase 6 |
| `lp docs` | Con Taiga activo: `audit` y `draft` de lo pendiente |
| `lp status` | Fase, gates, secciones y rondas |
| `lp` (sin argumentos) | Lee `state.json`, resume y ejecuta o sugiere el siguiente paso, parando en el siguiente gate |

## Reglas duras (no romper)

- **Nunca inventar una respuesta de la entrevista**: lo que no se sabe queda `abierto`, `escalado` al cliente o `supuesto` confirmado por el usuario. El brief no se aprueba con bloqueantes escaladas abiertas salvo que el usuario decida asumirlas.
- **Nunca lanzar `ui-designer`, `ui-coder` o `ui-refiner` sin el perfil `mp-lp:lp-ui-profile`.**
- **Nunca escribir UI sin `lp/direction.md` aprobado** ni guardar un artefacto que el usuario no vio.
- **Nunca hacer git** (add, commit, push, branch, deploy) sin orden directa del usuario. Los agentes no hacen git jamás.
- **Nunca llamar a Taiga si `taiga.enabled` es falso.** Si está activo: nunca enviar un ticket o comentario sin mostrar su texto completo y recibir aprobación explícita; nunca marcar Done por cuenta propia; nunca borrar; reenviar siempre la descripción completa en `update_*`.
- **Nunca instalar software** (`astro add`, `shadcn init`, paquetes, ffmpeg) ni correr `/impeccable init`/`document` por tu cuenta ni por un agente: se avisa y decide el usuario.
- **Nunca auditar con `astro dev`**: solo build de producción.
- **No inventar** marca, textos legales, precios, testimonios, cifras ni datos de contacto.
- Máximo 2 rondas de corrección por auditoría; no encadenar secciones sin orden del usuario.
- No repetir como hecho lo que dice un informe de agente sin verificarlo.
- No lanzar agentes sin que el usuario haya invocado `lp` (o pedido uno explícitamente).

## Herramientas

- Agentes: tool `Agent` con los `subagent_type` del roster (prefijo `mp-lp:`).
- Skill de la fase de brief (la cargas tú): `mp-lp:lp-brief-interview`. Skills de referencia (las cargan los agentes): `mp-lp:lp-seo`, `mp-lp:lp-motion`, `mp-lp:lp-media`, `mp-lp:lp-performance`.
- **Perfil de los agentes de UI compartidos:** cada vez que lances `mp-core:ui-designer`, `ui-coder` o `ui-refiner` incluye en el prompt `Perfil: mp-lp:lp-ui-profile` (ellos lo cargan). Sin perfil se comportarían como en `flow-auto` (OpenSpec).
- Diseño: `impeccable`, `ui-ux-pro-max`, `taste-skill`, las skills de `emilkowalski/skills` y MCP `shadcn` (los usan los agentes de UI); `terminal-browser` (lo usa `mp-core:manual-tester`).
- Taiga (opcional): `mcp__taiga__*` a través de `lp-documenter`; el orquestador solo lee.
- Medición: `scripts/measure.sh` (Lighthouse). Proyecto: `CLAUDE.md` para comandos de tipos, build y preview.
