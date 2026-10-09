# claude-jp-profile

Mi perfil de Claude Code como plugin privado `mp` (_my-profile_) más un marketplace de un solo plugin (`mp-marketplace`).

## Qué incluye

| Dónde                 | Contenido                                                                                                       |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| `plugins/mp/skills`   | `flow`, `flow-auto`, `taiga-sprint-rollover`, `taiga-ticket-docs`                                               |
| `plugins/mp/agents`   | `flow-architect`, `flow-designer`, `flow-coder`, `flow-ui-coder`, `flow-ui-refiner`, `flow-tester`, `flow-reviewer`, `flow-documenter` |
| `plugins/mp/commands` | `doctor`, `commit`, `commit-changes`, `commit-convention`, `changelog`, `release`, `release-pr`, `ship`                   |
| `plugins/mp/hooks`    | Hook SessionStart que inyecta `profile-instructions.md` (regla de context7)                                     |
| `bootstrap/`          | Lo que un plugin no puede aportar: permisos, plugins de terceros, statusline, MCP de Taiga y skills de Supabase |

Nombres con namespace: `/mp:flow-auto`, `/mp:commit`, agentes `mp:flow-coder`, etc.

Se instalan por fuera del plugin (desde su origen):

- **Context7**: instalador oficial `npx ctx7 setup --cli --claude` (lo lanza `setup.sh`). Modo *CLI + Skills*: crea la API key por OAuth e instala el skill `find-docs` y la regla en `~/.claude/rules`.
- **Supabase**: plugins oficiales `supabase` y `postgres-best-practices` del marketplace `supabase/agent-skills` (activados en `enabledPlugins`).
- **MCP de Context7**: remoto (`https://mcp.context7.com/mcp`), a nivel usuario, con `CONTEXT7_API_KEY` del entorno; lo registra `setup.sh` igual que el de Taiga.
- **terminal-browser**: `setup.sh` instala el binario (brew o `curl -fsSL https://terminal-browser.sh/install | bash`) si falta; el plugin y `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` vienen en `settings.base.json`. Uso: `/browser` dentro de claude (requiere ghostty/kitty, sin tmux). Actualizar el binario: `terminal-browser upgrade`.
- **MCP de shadcn**: local (`npx shadcn@latest mcp`), a nivel usuario y sin secretos; lo registra `setup.sh`. Permite explorar el registry y añadir componentes con lenguaje natural ([docs](https://ui.shadcn.com/docs/mcp)). Para listar registries propios, el proyecto necesita su `components.json`.
- **Taiga**: MCP a nivel usuario, registrado por `setup.sh` (tools `mcp__taiga__*`).
- **Requeridos de terceros** (desde sus marketplaces de GitHub, vía `enabledPlugins`): `context-mode@context-mode` (`mksglu/context-mode`) y `caveman@caveman` (`JuliusBrussee/caveman`). Más `skill-creator@claude-plugins-official`.
- **Flujo de UI en `flow-auto`**: los bloques de interfaz pasan por `flow-designer` (brief, aprobado por ti una vez por change y guardado en `ui-brief.md`) → `flow-ui-coder` → `flow-ui-refiner` → tester → reviewer. Requisitos por proyecto, que `flow-auto` verifica y nunca resuelve solo: `PRODUCT.md` (`/impeccable init`), `DESIGN.md` recomendado (`/impeccable document`), `components.json` de shadcn (`npx shadcn@latest init`) y opcionalmente `/impeccable hooks on`.
- **Diseño UI/UX**: `ui-ux-pro-max@ui-ux-pro-max-skill` (`nextlevelbuilder/ui-ux-pro-max-skill`), `impeccable@impeccable` (`pbakaus/impeccable`) y `taste-skill@taste-skill` (`Leonxlnx/taste-skill`), declarados en `enabledPlugins` e instalados por `setup.sh` (`claude plugin marketplace add` + `claude plugin install`, omite los ya instalados). Impeccable requiere además, por proyecto, correr `/impeccable init` y `/impeccable hooks on` y aprobar sus hooks (paso 2 en https://impeccable.style/#downloads).

## Instalación en un equipo nuevo

Requisitos: `claude` (v1.0.33+), `jq`, `node`/`npx` (22.13+ por la statusline de caveman y context-mode), `gh`, `git`, `python3` (buscador de `ui-ux-pro-max`).

```bash
# 1. Acceso al repo privado (HTTPS con las credenciales de gh)
gh auth login && gh auth setup-git

# 2. Clonar y ejecutar el bootstrap (pide los datos de los MCP; ver sección siguiente)
git clone https://github.com/juanleon8581/claude-jp-profile ~/claude-jp-profile
~/claude-jp-profile/bootstrap/setup.sh

# 3. Dentro de claude
/plugin marketplace add juanleon8581/claude-jp-profile
/plugin install mp@mp-marketplace
/mp:doctor
```

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

Verificación: `/mp:doctor` revisa requisitos, settings, MCPs (que estén registrados y con valores, sin imprimirlos), plugins recomendados, duplicados locales y el hook anti-firma. También sirve fuera de claude: `bash plugins/mp/scripts/doctor.sh` (exit 1 si hay errores).

## Flujo de actualización

1. Editar en `plugins/mp/` (o `bootstrap/`).
2. Subir `version` en `plugins/mp/.claude-plugin/plugin.json`, commit y push.
3. En cada equipo: `/plugin marketplace update mp-marketplace` y `/plugin update mp`.
4. Si cambió algo en `bootstrap/` (permisos, MCP, plugins de terceros): volver a correr `bootstrap/setup.sh`.

## Notas

- Tras migrar, borrar las copias locales de `~/.claude/{skills,agents,commands}` que ahora vienen del plugin, para no duplicar.
- El modelo (`model`) no se fija en `bootstrap/`: cada equipo elige el suyo (p. ej. `/model`).
- Excluido a propósito: `terminal-browser` (se instala con su propia herramienta), `sdd`, `handoff`, `vault`, `pencil`, `obsidian` y `claude-seo` (en desuso).
