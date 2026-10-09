#!/usr/bin/env bash
# Prepara un equipo: settings base, statusline, MCPs de Taiga y Context7 (scope user, valores
# literales en ~/.claude.json, independientes del plugin) y ctx7 setup.
# Idempotente: detecta lo ya aplicado y solo ejecuta lo que falta o cambió (reporta "ya aplicado").
# RECONFIGURE=1 vuelve a preguntar los valores de los MCP aunque ya existan.
# Valores de los MCP, en este orden de prioridad:
#   1) variables al ejecutar:  TAIGA_URL=... TAIGA_USERNAME=... TAIGA_PASSWORD=... TAIGA_MCP_PATH=... CONTEXT7_API_KEY=... ./setup.sh
#   2) el registro que ya exista en la config de claude
#   3) prompt interactivo (contraseña y key con lectura silenciosa)
# Con CLAUDE_CONFIG_DIR=<dir> todo se escribe en ese directorio (útil para pruebas aisladas).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then CJ="$CFG/.claude.json"; else CJ="$HOME/.claude.json"; fi
export CLAUDE_CONFIG_DIR="$CFG"
for c in jq claude; do command -v "$c" >/dev/null || { echo "Falta $c"; exit 1; }; done
mkdir -p "$CFG"

# 1) settings.json: deep merge; allow/ask se unen sin duplicar
[ -f "$CFG/settings.json" ] || echo '{}' > "$CFG/settings.json"
MERGED="$(jq -s '
  .[0] as $cur | .[1] as $base
  | ($cur * $base)
  | .permissions.allow = ((($cur.permissions.allow // []) + $base.permissions.allow) | unique)
  | .permissions.ask   = ((($cur.permissions.ask   // []) + $base.permissions.ask)   | unique)
' "$CFG/settings.json" "$DIR/settings.base.json")"
if [ "$(jq -S . "$CFG/settings.json")" = "$(printf '%s' "$MERGED" | jq -S .)" ]; then
  echo "= settings.json ya aplicado"
else
  cp "$CFG/settings.json" "$CFG/settings.json.bak"
  printf '%s\n' "$MERGED" > "$CFG/settings.json"
  echo "+ settings.json actualizado (backup: settings.json.bak)"
fi

# 2) statusline
if cmp -s "$DIR/statusline.sh" "$CFG/statusline.sh" && [ -x "$CFG/statusline.sh" ]; then
  echo "= statusline ya aplicada"
else
  cp "$DIR/statusline.sh" "$CFG/statusline.sh"; chmod +x "$CFG/statusline.sh"; echo "+ statusline instalada"
fi

# 2b) terminal-browser (binario). El plugin y CLAUDE_CODE_ENABLE_FUNCTION_HOOKS van en settings.base.json.
#     Para actualizar el binario: terminal-browser upgrade
if command -v terminal-browser >/dev/null; then
  echo "= terminal-browser ya instalado ($(command -v terminal-browser))"
else
  echo "+ instalando terminal-browser"
  if command -v brew >/dev/null; then brew install terminal-browser
  else curl -fsSL https://terminal-browser.sh/install | bash; fi \
    || echo "!! terminal-browser no se instaló; hazlo a mano: curl -fsSL https://terminal-browser.sh/install | bash"
fi
# `terminal-browser setup` instala la skill del agente ($CFG/skills/terminal-browser); sin ella /browser no funciona
if command -v terminal-browser >/dev/null; then
  if [ -e "$CFG/skills/terminal-browser" ]; then
    echo "= terminal-browser setup ya aplicado"
  else
    echo "+ terminal-browser setup"
    terminal-browser setup || echo "!! terminal-browser setup falló; ejecútalo a mano: terminal-browser setup"
  fi
fi

# 3) MCPs a nivel usuario
prev(){ [ -f "$CJ" ] && jq -r "$1 // empty" "$CJ" 2>/dev/null || true; }
ask(){ # ask VAR "etiqueta" "expr jq del registro previo" [secret] [default]
  local var="$1" label="$2" expr="$3" secret="${4:-}" def="${5:-}" cur
  cur="${!var:-}"; [ -n "$cur" ] || cur="$(prev "$expr")"; [ -n "$cur" ] || cur="$def"
  if [ -z "${!var:-}" ] && [ -t 0 ] && { [ -z "$cur" ] || [ "${RECONFIGURE:-0}" = "1" ]; }; then
    if [ -n "$secret" ]; then
      read -r -s -p "$label${cur:+ [Enter = conservar el actual]}: " in; echo
    else
      read -r -p "$label${cur:+ [$cur]}: " in
    fi
    [ -n "$in" ] && cur="$in"
  fi
  [ -n "$cur" ] || { echo "!! Falta $var (ejecútalo en una terminal o pásalo como variable)"; exit 1; }
  printf -v "$var" '%s' "$cur"
}
ask TAIGA_URL       "URL de Taiga (sin / final)" '.mcpServers.taiga.env.TAIGA_URL'
ask TAIGA_USERNAME  "Usuario de Taiga"           '.mcpServers.taiga.env.TAIGA_USERNAME'
ask TAIGA_PASSWORD  "Contraseña de Taiga"        '.mcpServers.taiga.env.TAIGA_PASSWORD' secret
ask TAIGA_MCP_PATH  "Ruta a taiga-mcp/dist/index.js" '.mcpServers.taiga.args[0]' "" "$HOME/local-mcp/taiga-mcp/dist/index.js"
ask CONTEXT7_API_KEY "API key de Context7 (https://context7.com/dashboard)" '(.mcpServers.context7.headers.CONTEXT7_API_KEY // ((.mcpServers.context7.headers.Authorization // "") | sub("^Bearer +";"")))' secret
[ -f "$TAIGA_MCP_PATH" ] || echo "!! Aviso: $TAIGA_MCP_PATH no existe aún (git clone https://github.com/juanleon8581/taiga-mcp && npm i && npm run build)"

has_mcp(){ [ -f "$CJ" ] && jq -e ".mcpServers.$1" "$CJ" >/dev/null 2>&1; }
TAIGA_JSON="$(jq -nc --arg p "$TAIGA_MCP_PATH" --arg u "$TAIGA_URL" --arg n "$TAIGA_USERNAME" --arg w "$TAIGA_PASSWORD" \
  '{type:"stdio",command:"node",args:[$p],env:{TAIGA_URL:$u,TAIGA_USERNAME:$n,TAIGA_PASSWORD:$w}}')"
if has_mcp taiga && [ "$(jq -cS .mcpServers.taiga "$CJ")" = "$(printf '%s' "$TAIGA_JSON" | jq -cS .)" ]; then
  echo "= MCP taiga ya aplicado"
else
  claude mcp remove taiga --scope user >/dev/null 2>&1 || true
  claude mcp add-json --scope user taiga "$TAIGA_JSON" >/dev/null && echo "+ MCP taiga registrado"
fi
# context7: vale tanto headers.CONTEXT7_API_KEY como Authorization Bearer (formato de ctx7 setup)
C7_URL="https://mcp.context7.com/mcp"
if has_mcp context7 && [ "$(jq -r '.mcpServers.context7.url // empty' "$CJ")" = "$C7_URL" ] \
   && [ "$(prev '(.mcpServers.context7.headers.CONTEXT7_API_KEY // ((.mcpServers.context7.headers.Authorization // "") | sub("^Bearer +";"")))')" = "$CONTEXT7_API_KEY" ]; then
  echo "= MCP context7 ya aplicado"
else
  claude mcp remove context7 --scope user >/dev/null 2>&1 || true
  claude mcp add-json --scope user context7 "$(jq -nc --arg k "$CONTEXT7_API_KEY" --arg u "$C7_URL" \
    '{type:"http",url:$u,headers:{CONTEXT7_API_KEY:$k}}')" >/dev/null && echo "+ MCP context7 registrado"
fi
chmod 600 "$CJ" 2>/dev/null || true

# 4) Context7 con su instalador oficial (OAuth por device flow: link + código). Ver README.
if [ "${SKIP_CTX7:-0}" = "1" ]; then :
elif [ -f "$CFG/rules/context7.md" ] && [ -e "$CFG/skills/find-docs" ]; then
  echo "= ctx7 setup ya aplicado"
else
  npx -y ctx7@latest setup --cli --claude || echo "!! ctx7 setup no terminó; ejecútalo a mano: npx ctx7 setup --cli --claude"
fi

echo "Listo. Verifica con /mp:doctor. Terminal browser: abre claude y corre /browser (requiere ghostty/kitty)."
echo "Siguiente: en claude -> /plugin marketplace add juanleon8581/claude-jp-profile  y  /plugin install mp@mp-marketplace"
