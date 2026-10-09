#!/usr/bin/env bash
# Prepara un equipo: settings base, statusline, MCPs de Taiga y Context7 (scope user) y ctx7 setup.
# Es idempotente: se puede volver a correr cuando cambie algo en bootstrap/.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ENVF="$HOME/.claude-mp.env"
for c in jq claude; do command -v "$c" >/dev/null || { echo "Falta $c"; exit 1; }; done
mkdir -p "$CFG"

# 1) settings.json: deep merge; allow/ask se unen sin duplicar
[ -f "$CFG/settings.json" ] || echo '{}' > "$CFG/settings.json"
cp "$CFG/settings.json" "$CFG/settings.json.bak"
jq -s '
  .[0] as $cur | .[1] as $base
  | ($cur * $base)
  | .permissions.allow = ((($cur.permissions.allow // []) + $base.permissions.allow) | unique)
  | .permissions.ask   = ((($cur.permissions.ask   // []) + $base.permissions.ask)   | unique)
' "$CFG/settings.json.bak" "$DIR/settings.base.json" > "$CFG/settings.json"

# 2) statusline
cp "$DIR/statusline.sh" "$CFG/statusline.sh"; chmod +x "$CFG/statusline.sh"

# 3) plantilla de secretos (no se pisa si ya existe)
if [ ! -f "$ENVF" ]; then
  cat > "$ENVF" <<'EOF'
# Cargar desde ~/.zshrc:  [ -f ~/.claude-mp.env ] && source ~/.claude-mp.env
export TAIGA_URL=""        # ej. https://taiga.miempresa.com
export TAIGA_USERNAME=""
export TAIGA_PASSWORD=""
export CONTEXT7_API_KEY="" # dashboard de Context7 (https://context7.com/dashboard)
# Ruta al build del MCP de Taiga (ver README)
export TAIGA_MCP_PATH="$HOME/local-mcp/taiga-mcp/dist/index.js"
EOF
  chmod 600 "$ENVF"
  echo ">> Creado $ENVF: complétalo y haz source en ~/.zshrc."
fi

# 4) MCP de Taiga a nivel usuario (mantiene el nombre mcp__taiga__*). Las ${VAR} se
#    resuelven al iniciar claude, así que no se guardan secretos en ~/.claude.json.
claude mcp remove taiga --scope user >/dev/null 2>&1 || true
claude mcp add-json --scope user taiga '{
  "type": "stdio",
  "command": "node",
  "args": ["${TAIGA_MCP_PATH}"],
  "env": {
    "TAIGA_URL": "${TAIGA_URL}",
    "TAIGA_USERNAME": "${TAIGA_USERNAME}",
    "TAIGA_PASSWORD": "${TAIGA_PASSWORD}"
  }
}'

# 5) MCP de Context7 (remoto, scope user) con la key tomada del entorno al iniciar claude
claude mcp remove context7 --scope user >/dev/null 2>&1 || true
claude mcp add-json --scope user context7 '{
  "type": "http",
  "url": "https://mcp.context7.com/mcp",
  "headers": { "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}" }
}'

# 6) Context7 con su instalador oficial (OAuth por device flow: abre un link y pide un código;
#    genera la API key y deja el skill/MCP según el modo que elijas). Ver README.
if [ "${SKIP_CTX7:-0}" != "1" ]; then
  npx -y ctx7@latest setup --cli --claude || echo "!! ctx7 setup no terminó; ejecútalo a mano: npx ctx7 setup --cli --claude"
fi

echo "Listo. Backup de settings: $CFG/settings.json.bak"
echo "Siguiente: en claude -> /plugin marketplace add juanleon8581/claude-jp-profile  y  /plugin install mp@mp-marketplace"
