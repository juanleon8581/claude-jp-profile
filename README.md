# claude-jp-profile

Mis perfiles de Claude Code como plugins privados (`mp` = _my-profile_) dentro de un marketplace (`mp-marketplace`). Lo común vive en `mp-core`; cada perfil (`mp` técnico, `mp-lp` landing pages) lo declara como dependencia (`"dependencies": ["mp-core"]` en su `plugin.json`).

## Qué incluye

| Dónde                         | Contenido                                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `plugins/mp-core/commands`    | `doctor`, `promote`, `commit`, `commit-changes`, `commit-convention`, `changelog`, `release`, `release-pr`, `ship`, `marketplace-release` |
| `plugins/mp-core/skills`      | `taiga-sprint-rollover`, `taiga-ticket-docs`                                                                    |
| `plugins/mp-core/hooks`       | Hook PreToolUse que bloquea commits firmados por Claude                                                         |
| `plugins/mp/skills`           | `flow`, `flow-auto`, `flow-architecture`                                                                        |
| `plugins/mp-core/agents`      | Compartidos por `flow-auto` y `lp`: `ui-designer`, `ui-coder`, `ui-refiner` y `manual-tester` (planes de prueba en `terminal-browser`) |
| `plugins/mp/agents`           | `flow-architect`, `flow-coder`, `flow-tester`, `flow-reviewer`, `flow-documenter` |
| `plugins/mp/commands`         | `init`                                                                                                          |
| `plugins/mp-lp/skills`        | `lp` (orquestador), `lp-brief-interview` (protocolo de la entrevista), `lp-ui-profile`, `lp-seo`, `lp-motion`, `lp-media`, `lp-performance`                                         |
| `plugins/mp-lp/agents`        | `lp-strategist` (analista del brief), `lp-motion`, `lp-media`, `lp-seo`, `lp-documenter`       |
| `plugins/mp-lp/commands`      | `init`, `audit`                                                                                                 |
| `bootstrap/`                  | Lo que un plugin no puede aportar: permisos, plugins de terceros, statusline, MCP de Taiga y skills de Supabase |
| `bootstrap/validate-plugins.sh` | Valida manifiestos, dependencias y rutas internas de cada plugin (correr antes de cada release)              |

Nombres con namespace: `/mp:flow-auto`, `/mp:init`, agentes `mp:flow-coder`; del perfil de landing `/mp-lp:init`, `/mp-lp:audit`, `/mp-lp:lp`, agentes `mp-lp:lp-motion`; y del núcleo `/mp-core:commit`, `/mp-core:release`, `/mp-core:doctor`, `/mp-core:promote`.

Se instalan por fuera del plugin (desde su origen):

- **Context7**: instalador oficial `npx ctx7 setup --cli --claude` (lo lanza `setup.sh`). Modo *CLI + Skills*: crea la API key por OAuth e instala el skill `find-docs` y la regla en `~/.claude/rules`.
- **Supabase**: plugins oficiales `supabase` y `postgres-best-practices` del marketplace `supabase/agent-skills` (activados en `enabledPlugins`).
- **MCP de Context7**: remoto (`https://mcp.context7.com/mcp`), a nivel usuario, con `CONTEXT7_API_KEY` del entorno; lo registra `setup.sh` igual que el de Taiga.
- **terminal-browser**: `setup.sh` instala el binario (brew o `curl -fsSL https://terminal-browser.sh/install | bash`) si falta; el plugin y `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` vienen en `settings.base.json`. Uso: `/browser` dentro de claude (requiere ghostty/kitty, sin tmux). Actualizar el binario: `terminal-browser upgrade`.
- **MCP de shadcn**: local (`npx shadcn@latest mcp`), a nivel usuario y sin secretos; lo registra `setup.sh`. Permite explorar el registry y añadir componentes con lenguaje natural ([docs](https://ui.shadcn.com/docs/mcp)). Para listar registries propios, el proyecto necesita su `components.json`.
- **Taiga**: MCP a nivel usuario, registrado por `setup.sh` (tools `mcp__taiga__*`).
- **Requeridos de terceros** (desde sus marketplaces de GitHub, vía `enabledPlugins`): `context-mode@context-mode` (`mksglu/context-mode`) y `caveman@caveman` (`JuliusBrussee/caveman`). Más `skill-creator@claude-plugins-official`.
- **Flujo de UI en `flow-auto`**: los bloques de interfaz pasan por `ui-designer` (compartido con `lp`, en `mp-core`; brief, aprobado por ti una vez por change y guardado en `ui-brief.md`) → `ui-coder` → `ui-refiner` → tester → reviewer. Requisitos por proyecto, que `flow-auto` verifica y nunca resuelve solo: `PRODUCT.md` (`/impeccable init`), `DESIGN.md` recomendado (`/impeccable document`), `components.json` de shadcn (`npx shadcn@latest init`) y opcionalmente `/impeccable hooks on`.
- **Promover cambios hechos en caliente**: `/mp-core:promote` compara la copia instalada del plugin (`~/.claude/plugins/cache/...`) contra la versión base y contra `origin/main` con `plugins/mp-core/scripts/promote.sh`, te deja elegir archivo por archivo (marca `CONFLICTO` si `main` también cambió ese archivo) y abre un **Pull Request** desde un worktree temporal (con fork si no tienes permiso de escritura). Nunca hace push a `main` ni sube la versión: en la rama del PR, `/mp-core:marketplace-release` versiona y cada equipo recibe el cambio con `/plugin marketplace update mp-marketplace`.
- **Escritura natural**: `humanizer@humanizer` (`blader/humanizer`), declarado en `enabledPlugins` e instalado por `setup.sh` como los de diseño. Lo usan `flow-documenter` y `lp-documenter` para que los tickets de Taiga no suenen a texto generado: solo en `draft`, nunca en `apply`, y siempre por debajo de las reglas de `taiga-ticket-docs`.
- **Skills de Emil Kowalski** (`emilkowalski/skills`): no es un marketplace de plugins, así que `setup.sh` las instala con la CLI `skills` en `~/.claude/skills` (subconjunto web de 12: `emil-design-eng`, `animate`, `review-animations`, `improve-animations`, `find-animation-opportunities`, `animation-performance`, `animation-vocabulary`, `apple-design`, `pick-ui-library`, `prototype`, `mobile-native`, `break-ui`; se omiten las de Swift, Expo y Sonner). Detección idempotente y verificación en `/mp-core:doctor`. Las usan `ui-designer`, `ui-coder`, `ui-refiner` y `lp-motion`. Revisa el contenido de skills de terceros antes de usarlas: corren con los permisos del agente.
- **Perfil de landing pages (`mp-lp`)**: flow ligero `lp` sin OpenSpec para Astro + TypeScript estricto + Tailwind (shadcn solo en islas interactivas). Estado y artefactos en `lp/` del proyecto (`brief.md`, `direction.md`, `sections.md`, `audits/`, `state.json`). Fases: **brief como entrevista guiada** (el orquestador conversa con rondas de preguntas, profundidad adaptativa, opción de escalar al cliente con un cuestionario y resumen para `/impeccable init`; `lp-strategist` solo analiza) → dirección (**gate 1**) → build por secciones con `ui-coder`, `lp-media`, `lp-motion` y `ui-refiner` → auditoría de SEO y rendimiento (`lp-seo` más `scripts/measure.sh` con Lighthouse) → QA visual con `mp-core:manual-tester` y `terminal-browser` (**gate 2**) → publicación. **Taiga es opcional**: `lp start` pregunta por flujo si se quiere seguimiento documental; si no, no se llama a Taiga. Para usarlo en un proyecto: `/mp-lp:init` (diagnóstico más `claude plugin install mp-lp@mp-marketplace --scope project` y `claude plugin disable mp@mp-marketplace --scope project`, para que ese proyecto no cargue los agentes de backend). `/mp-lp:audit` audita un landing existente sin correr el flujo.
- **Preparar un proyecto para el flow**: `/mp:init` (en la raíz del proyecto) diagnostica con `scripts/project-check.sh` y, con tu aprobación, completa lo que falte: OpenSpec (`openspec init`), `CLAUDE.md` con los comandos de prueba/build/formato, `openspec/architecture.md` (capas, dependencias y excepciones que usa `flow-architect`) y la referencia a ese archivo en `openspec/config.yaml`. Es idempotente, no sobrescribe y no hace commit. Los requisitos de UI (`PRODUCT.md`, `DESIGN.md`, `components.json`) solo se reportan.
- **Arquitecto**: `flow-architect` carga por su cuenta la skill `flow-architecture` (Clean Architecture como lente por defecto, dominio, seguridad y datos como referencias que elige según el change). Manda siempre lo que el proyecto declare en `openspec/architecture.md`; sin ese archivo infiere del código y lo marca como suposición. La skill destila `clean-architecture` y `domain-driven-design` (wondelai, MIT) y `security-threat-model` (OpenAI, Apache-2.0).
- **Diseño UI/UX**: `ui-ux-pro-max@ui-ux-pro-max-skill` (`nextlevelbuilder/ui-ux-pro-max-skill`), `impeccable@impeccable` (`pbakaus/impeccable`) y `taste-skill@taste-skill` (`Leonxlnx/taste-skill`), declarados en `enabledPlugins` e instalados por `setup.sh` (`claude plugin marketplace add` + `claude plugin install`, omite los ya instalados). Impeccable requiere además, por proyecto, correr `/impeccable init` y `/impeccable hooks on` y aprobar sus hooks (paso 2 en https://impeccable.style/#downloads).

## Perfiles y combinaciones

Hay tres plugins en el marketplace. `mp-core` es la base y los otros dos son **perfiles** que lo declaran como dependencia: al instalar un perfil, `mp-core` se instala solo.

| Plugin | Para qué | Contenido principal |
| --- | --- | --- |
| `mp-core` | Base común, sin flujo propio | Commits, releases, changelog, `promote`, `doctor`, skills de Taiga, hook anti-firma y los agentes compartidos (`ui-designer`, `ui-coder`, `ui-refiner`, `manual-tester`) |
| `mp` | Perfil técnico: apps y backend | Flujo `flow` / `flow-auto` (OpenSpec + Taiga) y sus agentes `flow-*` |
| `mp-lp` | Perfil de landing pages | Flujo ligero `lp` (Astro + TypeScript + Tailwind + shadcn), entrevista de brief y agentes de SEO, medios y movimiento |

Qué plugins quedan activos según el caso:

| Escenario | `mp-core` | `mp` | `mp-lp` | Cómo se consigue |
| --- | :---: | :---: | :---: | --- |
| **Equipo con el perfil técnico** (el caso general) | sí | sí | no | `/plugin install mp@mp-marketplace` (nivel usuario; trae `mp-core`) |
| **Solo utilidades** (commits, releases, Taiga), sin flujos | sí | no | no | `/plugin install mp-core@mp-marketplace` |
| **Proyecto de landing** | sí | **apagado en ese proyecto** | sí, solo ahí | `claude plugin install mp-lp@mp-marketplace --scope project` en la raíz del proyecto y luego `/mp-lp:init`, que apaga `mp` ahí (equivale a añadir `claude plugin disable mp@mp-marketplace --scope project`) |
| **Proyecto que mezcla app y landing** | sí | sí | sí, solo ahí | Solo `claude plugin install mp-lp@mp-marketplace --scope project`, sin apagar `mp` |

Cómo funciona la separación: `mp` se instala a nivel usuario (se carga en todos los proyectos), pero el ajuste de **proyecto** manda sobre el de usuario. Por eso en un landing se apaga `mp` (sobran el arquitecto, el tester y el reviewer de backend) y se activa `mp-lp` solo ahí. Los agentes compartidos de `mp-core` sirven a ambos flujos: en `lp` se les indica el perfil `mp-lp:lp-ui-profile` para que trabajen con Astro; en `flow-auto` usan su modo por defecto (OpenSpec).

Primer paso en cada proyecto, según el perfil: `/mp:init` (OpenSpec, `CLAUDE.md`, arquitectura) o, en un landing, instalar `mp-lp` en el proyecto, `/mp-lp:init` (stack Astro, `CLAUDE.md`, apagar `mp`) y luego `/mp-lp:lp start`.

## Instalación en un equipo nuevo

Requisitos generales: `claude` (v1.0.33+), `jq`, `node`/`npx` (22.13+ por la statusline de caveman y context-mode), `gh`, `git`, `python3` (buscador de `ui-ux-pro-max`).
Para el perfil de landing, además: Chrome o Chromium (Lighthouse mide rendimiento con él) y, opcional, `ffmpeg` (solo si hay video). `terminal-browser` (ghostty o kitty, sin tmux) lo usa el `manual-tester` de ambos flujos.

```bash
# 1. Acceso al repo privado (HTTPS con las credenciales de gh)
gh auth login && gh auth setup-git

# 2. Clonar y ejecutar el bootstrap (una vez por equipo; pide los datos de los MCP, ver sección siguiente)
#    Instala plugins de terceros (diseño, humanizer), las skills de Emil Kowalski, MCPs, settings y statusline
git clone https://github.com/juanleon8581/claude-jp-profile ~/claude-jp-profile
~/claude-jp-profile/bootstrap/setup.sh

# 3. Dentro de claude: el marketplace y el perfil técnico (instala también mp-core)
/plugin marketplace add juanleon8581/claude-jp-profile
/plugin install mp@mp-marketplace
/mp-core:doctor
```

**Por proyecto, para un landing** (`mp-lp` no se instala a nivel usuario). Un comando de un plugin no existe hasta que el plugin está instalado, así que el primer paso va **fuera de claude**, en la raíz del proyecto:

```bash
claude plugin install mp-lp@mp-marketplace --scope project   # instala mp-lp (y mp-core si faltara) solo en este proyecto
```

Luego abre claude (o `/reload-plugins`) y corre `/mp-lp:init`: diagnostica el stack Astro, propone completar `CLAUDE.md` y, con tu aprobación, apaga `mp` en ese proyecto. Después `/mp-lp:lp start` (con `--from <archivo>` si ya tienes un brief inicial).

## Datos de los MCP (Taiga y Context7)

Los MCP son **independientes del plugin**: `setup.sh` los registra a nivel usuario con los valores literales en `~/.claude.json` (permisos `600`). No hay archivo `.env` ni variables de entorno que cargar, y funcionan desde cualquier shell, `tmux` o daemon. Nada sensible vive en este repo.

`setup.sh` es idempotente: compara contra lo ya aplicado (settings, statusline, binario, MCPs, ctx7) y solo ejecuta lo que falta o cambió; los valores ya registrados no se vuelven a preguntar (`RECONFIGURE=1` fuerza el prompt). Cada valor se obtiene, en este orden: (1) variables pasadas al ejecutarlo, (2) el registro que ya exista en la config de claude, (3) prompt interactivo (contraseña y key con lectura silenciosa).

| Dato | Qué es | De dónde sale |
| --- | --- | --- |
| `TAIGA_URL` | URL de Taiga, sin `/` final | Tu instancia, p. ej. `https://taiga.miempresa.com` |
| `TAIGA_USERNAME` | Usuario de Taiga | Tu cuenta |
| `TAIGA_PASSWORD` | Contraseña de Taiga | Tu cuenta (gestor de contraseñas) |
| `TAIGA_MCP_PATH` | Ruta a `dist/index.js` del MCP | Build de abajo (por defecto `~/local-mcp/taiga-mcp/dist/index.js`) |
| `CONTEXT7_API_KEY` | API key de Context7 | https://context7.com/dashboard → API Keys |

Sin preguntas (p. ej. por SSH sin TTY):
```bash
TAIGA_URL=... TAIGA_USERNAME=... TAIGA_PASSWORD=... TAIGA_MCP_PATH=... CONTEXT7_API_KEY=... ./bootstrap/setup.sh
```
(Los valores pasan brevemente por la lista de procesos al registrar el MCP; es una limitación de `claude mcp add-json`.)

**Build del MCP de Taiga** (una vez por equipo):

```bash
git clone https://github.com/juanleon8581/taiga-mcp ~/local-mcp/taiga-mcp
cd ~/local-mcp/taiga-mcp && npm install && npm run build
```

Prueba aislada sin tocar la config real: `CLAUDE_CONFIG_DIR=~/.claude-test ./bootstrap/setup.sh` y luego `CLAUDE_CONFIG_DIR=~/.claude-test claude` (pide login aparte).

Otros datos por equipo:

- **GitHub**: `gh auth login` para clonar. Para que el marketplace privado se actualice solo, exporta `GITHUB_TOKEN` (scope `repo`) en el shell.
- **Context7**: `setup.sh` ejecuta `npx ctx7 setup --cli --claude`. Muestra un link y un código (device flow): ábrelo en cualquier navegador e inicia sesión. La key queda gestionada por ctx7; se administra en https://context7.com/dashboard. Para saltarlo: `SKIP_CTX7=1 ./bootstrap/setup.sh`.
- **Plugins de terceros**: se descargan solos al abrir claude la primera vez (confirma la instalación si lo pide).

Verificación: `/mp-core:doctor` revisa requisitos, settings, MCPs (que estén registrados y con valores, sin imprimirlos), plugins recomendados (incluido `mp-core`, `humanizer`), las skills de Emil Kowalski, el perfil `mp-lp` si está instalado (dependencia, Chrome, ffmpeg), duplicados locales y el hook anti-firma. También sirve fuera de claude: `bash plugins/mp-core/scripts/doctor.sh` (exit 1 si hay errores).

## Migración desde `mp` 1.x

La versión 2.0 de `mp` separa el núcleo y cambia nombres. Tras `/plugin marketplace update mp-marketplace` y `/plugin update mp`:

- Si `/mp-core:doctor` dice que falta `mp-core`, instálalo: `/plugin install mp-core@mp-marketplace`.
- Los comandos de commit, release, doctor y promote pasan de `/mp:*` a `/mp-core:*` (por ejemplo `/mp:commit` → `/mp-core:commit`). `/mp:init`, `/mp:flow` y `/mp:flow-auto` no cambian.
- Los agentes de UI de `flow-auto` ahora son compartidos: `mp:flow-designer`, `mp:flow-ui-coder`, `mp:flow-ui-refiner` y `mp:flow-manual-tester` pasan a `mp-core:ui-designer`, `ui-coder`, `ui-refiner` y `manual-tester`.
- Vuelve a correr `bootstrap/setup.sh` para instalar lo nuevo de terceros (`humanizer` y las skills de Emil Kowalski).

## Versionado

Dos niveles (SemVer en ambos):

- **Plugin:** `version` en `plugins/<p>/.claude-plugin/plugin.json`, `plugins/<p>/CHANGELOG.md` y tag `<plugin>-v<x.y.z>` (por ejemplo `mp-core-v1.0.0`). Claude Code usa esta versión para detectar actualizaciones.
- **Repo:** `metadata.version` en `marketplace.json`, tag `v<x.y.z>` y [`CHANGELOG.md`](CHANGELOG.md) raíz, cuya tabla dice qué versión de cada plugin iba junta. Sube con el mayor bump de los plugins: major si alguno rompe compatibilidad, minor si hay plugin o función nueva, patch si solo hay correcciones.

`/mp-core:marketplace-release` propone los bumps desde los commits de cada carpeta, escribe los CHANGELOG y las versiones, y deja los tags y el push a tu confirmación. `bash plugins/mp-core/scripts/release-status.sh` muestra el estado sin tocar nada, y el validador comprueba que versiones, CHANGELOG y tabla coinciden. Los tags se ponen sobre el commit de `main` (tras el merge del PR).

## Flujo de actualización

1. Editar en `plugins/<plugin>/` (o `bootstrap/`) y correr `bash bootstrap/validate-plugins.sh`.
2. En la rama del cambio, antes del PR: `/mp-core:marketplace-release` sube las versiones (plugins y repo) y escribe los CHANGELOG, para que viajen en el mismo PR. Commit y PR a `main`.
3. Tras el merge, sobre el commit de `main`: crear y subir los tags (`<plugin>-vX.Y.Z` y `vX.Y.Z`). El mismo comando los propone al final.
4. En cada equipo: `/plugin marketplace update mp-marketplace` y `/plugin update <plugin>`. Un cambio en `mp-core` llega a todos los perfiles.
5. Si cambió algo en `bootstrap/` (permisos, MCP, plugins de terceros): volver a correr `bootstrap/setup.sh`.

## Notas

- Tras migrar, borrar las copias locales de `~/.claude/{skills,agents,commands}` que ahora vienen del plugin, para no duplicar.
- El modelo (`model`) no se fija en `bootstrap/`: cada equipo elige el suyo (p. ej. `/model`).
- Excluido a propósito: `terminal-browser` (se instala con su propia herramienta), `sdd`, `handoff`, `vault`, `pencil`, `obsidian` y `claude-seo` (en desuso).
