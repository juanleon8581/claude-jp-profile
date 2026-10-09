# claude-jp-profile

Mi perfil de Claude Code como plugin privado `mp` (_my-profile_) más un marketplace de un solo plugin (`mp-marketplace`).

## Qué incluye

| Dónde                 | Contenido                                                                                                       |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| `plugins/mp/skills`   | `flow`, `flow-auto`, `taiga-sprint-rollover`, `taiga-ticket-docs`                                               |
| `plugins/mp/agents`   | `flow-architect`, `flow-coder`, `flow-tester`, `flow-reviewer`, `flow-documenter`                               |
| `plugins/mp/commands` | `commit`, `commit-changes`, `commit-convention`, `changelog`, `release`, `release-pr`, `ship`                   |
| `plugins/mp/hooks`    | Hook SessionStart que inyecta `profile-instructions.md` (regla de context7)                                     |
| `bootstrap/`          | Lo que un plugin no puede aportar: permisos, plugins de terceros, statusline, MCP de Taiga y skills de Supabase |

Nombres con namespace: `/mp:flow-auto`, `/mp:commit`, agentes `mp:flow-coder`, etc.

Se instalan por fuera del plugin (desde su origen):

- **Context7**: instalador oficial `npx ctx7 setup --cli --claude` (lo lanza `setup.sh`). Modo *CLI + Skills*: crea la API key por OAuth e instala el skill `find-docs` y la regla en `~/.claude/rules`.
- **Supabase**: plugins oficiales `supabase` y `postgres-best-practices` del marketplace `supabase/agent-skills` (activados en `enabledPlugins`).
- **MCP de Context7**: remoto (`https://mcp.context7.com/mcp`), a nivel usuario, con `CONTEXT7_API_KEY` del entorno; lo registra `setup.sh` igual que el de Taiga.
- **Taiga**: MCP a nivel usuario, registrado por `setup.sh` (tools `mcp__taiga__*`).
- **Requeridos de terceros** (desde sus marketplaces de GitHub, vía `enabledPlugins`): `context-mode@context-mode` (`mksglu/context-mode`) y `caveman@caveman` (`JuliusBrussee/caveman`). Más `skill-creator@claude-plugins-official`.

## Instalación en un equipo nuevo

Requisitos: `claude` (v1.0.33+), `jq`, `node`/`npx` (22.13+ por la statusline de caveman y context-mode), `gh`, `git`.

```bash
# 1. Acceso al repo privado
gh auth login

# 2. Clonar y ejecutar el bootstrap
git clone https://github.com/juanleon8581/claude-jp-profile ~/claude-jp-profile
~/claude-jp-profile/bootstrap/setup.sh

# 3. Completar secretos (ver sección siguiente) y cargarlos en el shell
echo '[ -f ~/.claude-mp.env ] && source ~/.claude-mp.env' >> ~/.zshrc
source ~/.zshrc

# 4. Dentro de claude
/plugin marketplace add juanleon8581/claude-jp-profile
/plugin install mp@mp-marketplace
```

## Secretos y datos que faltan en cada equipo

Nada sensible vive en este repo. `setup.sh` crea `~/.claude-mp.env` (permisos `600`) con estas variables vacías:

| Variable           | Qué es                                  | De dónde sale                                      |
| ------------------ | --------------------------------------- | -------------------------------------------------- |
| `TAIGA_URL`        | URL de tu Taiga, sin `/` final          | Tu instancia, p. ej. `https://taiga.miempresa.com` |
| `TAIGA_USERNAME`   | Usuario de Taiga                        | Tu cuenta de Taiga                                 |
| `TAIGA_PASSWORD`   | Contraseña de Taiga                     | Tu cuenta de Taiga (gestor de contraseñas)         |
| `CONTEXT7_API_KEY` | API key del MCP de Context7 | https://context7.com/dashboard → API Keys |
| `TAIGA_MCP_PATH`   | Ruta absoluta a `dist/index.js` del MCP | Ver build abajo                                    |

**Build del MCP de Taiga** (una vez por equipo):

```bash
git clone https://github.com/juanleon8581/taiga-mcp ~/local-mcp/taiga-mcp
cd ~/local-mcp/taiga-mcp && npm install && npm run build
# TAIGA_MCP_PATH=$HOME/local-mcp/taiga-mcp/dist/index.js (valor por defecto del env)
```

Cómo funciona: `setup.sh` registra el MCP con `${TAIGA_*}` sin valores; Claude Code las resuelve al iniciar leyendo el entorno del shell. Por eso hay que **abrir claude desde un shell que ya hizo `source`** del archivo. Si `/mcp` muestra `taiga` fallido, revisa primero `echo $TAIGA_URL`.

Otros datos por equipo:

- **GitHub**: `gh auth login` para clonar. Para que el marketplace privado se actualice solo, exporta `GITHUB_TOKEN` (scope `repo`) en el shell.
- **Context7**: `setup.sh` ejecuta `npx ctx7 setup --cli --claude`. Muestra un link y un código (device flow): ábrelo en cualquier navegador e inicia sesión. La key queda gestionada por ctx7; se administra en https://context7.com/dashboard. Para saltarlo: `SKIP_CTX7=1 ./bootstrap/setup.sh`.
- **Plugins de terceros**: se descargan solos al abrir claude la primera vez (confirma la instalación si lo pide).

Verificación rápida: `claude mcp list` (debe mostrar `taiga` conectado) y `/plugin` (debe listar `mp`).

## Flujo de actualización

1. Editar en `plugins/mp/` (o `bootstrap/`).
2. Subir `version` en `plugins/mp/.claude-plugin/plugin.json`, commit y push.
3. En cada equipo: `/plugin marketplace update mp-marketplace` y `/plugin update mp`.
4. Si cambió algo en `bootstrap/` (permisos, MCP, plugins de terceros): volver a correr `bootstrap/setup.sh`.

## Notas

- Tras migrar, borrar las copias locales de `~/.claude/{skills,agents,commands}` que ahora vienen del plugin, para no duplicar.
- El modelo (`model`) no se fija en `bootstrap/`: cada equipo elige el suyo (p. ej. `/model`).
- Excluido a propósito: `terminal-browser` (se instala con su propia herramienta), `sdd`, `handoff`, `vault`, `pencil`, `obsidian` y `claude-seo` (en desuso).
