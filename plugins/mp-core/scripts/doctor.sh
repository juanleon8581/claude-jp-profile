#!/usr/bin/env bash
# Diagnóstico del perfil mp: requisitos, settings, MCPs (con sus valores), plugins y duplicados locales.
# Solo lectura. Nunca imprime valores de secretos. Exit 1 si hay algún ✖.
set -uo pipefail
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SET="$CFG/settings.json"
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then CJ="$CFG/.claude.json"; else CJ="$HOME/.claude.json"; fi
ok=0; warn=0; fail=0
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
pass(){ echo "  ${G}✔${N} $1"; ok=$((ok+1)); }
wrn(){ echo "  ${Y}⚠${N} $1${2:+ ${D}→ $2${N}}"; warn=$((warn+1)); }
bad(){ echo "  ${R}✖${N} $1${2:+ ${D}→ $2${N}}"; fail=$((fail+1)); }
sec(){ echo; echo "$1"; }
info(){ echo "  ${D}·${N} $1"; }
have(){ command -v "$1" >/dev/null 2>&1; }

sec "Requisitos"
for c in claude jq node npx git gh; do
  have "$c" && pass "$c" || bad "$c no está instalado" "instálalo (brew / apt)"
done
if have node; then
  v=$(node -p 'process.versions.node' 2>/dev/null); maj=${v%%.*}; min=${v#*.}; min=${min%%.*}
  if [ "$maj" -gt 22 ] || { [ "$maj" -eq 22 ] && [ "$min" -ge 13 ]; }; then pass "node $v (≥ 22.13)"; else wrn "node $v" "caveman/context-mode piden ≥ 22.13"; fi
fi
have python3 && pass "python3 ($(python3 --version 2>&1 | cut -d' ' -f2))" || bad "python3 no está instalado" "lo usa el buscador de ui-ux-pro-max (ui-designer); brew install python"
have gh && { gh auth status >/dev/null 2>&1 && pass "gh autenticado" || wrn "gh sin sesión" "gh auth login"; }

sec "settings.json"
if [ -f "$SET" ] && jq -e . "$SET" >/dev/null 2>&1; then
  pass "$SET válido"
  chk(){ jq -e "$1" "$SET" >/dev/null 2>&1 && pass "$2" || bad "$2: falta" "${3:-corre bootstrap/setup.sh}"; }
  chk '.statusLine.command' "statusLine"
  chk '.autoCompactEnabled == true' "autoCompactEnabled"
  chk '.autoCompactWindow == 420000' "autoCompactWindow = 420000"
  chk '.permissions.allow | index("mcp__taiga")' "permiso mcp__taiga"
  chk '.permissions.allow | index("mcp__shadcn")' "permiso mcp__shadcn"
  chk '.permissions.ask | index("mcp__taiga__delete_task")' "ask en borrados de Taiga"
  chk '.env.CLAUDE_CODE_ENABLE_FUNCTION_HOOKS == "1"' "env CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 (terminal-browser)"
  jq -e '.model' "$SET" >/dev/null 2>&1 && pass "model definido en este equipo ($(jq -r .model "$SET"))" || wrn "model no definido" "elígelo con /model"
else bad "$SET ausente o inválido" "corre bootstrap/setup.sh"; fi

sec "Plugins"
IP="$CFG/plugins/installed_plugins.json"
for p in mp-core@mp-marketplace mp@mp-marketplace caveman@caveman context-mode@context-mode skill-creator@claude-plugins-official supabase@supabase-agent-skills postgres-best-practices@supabase-agent-skills terminal-browser@terminal-browser ui-ux-pro-max@ui-ux-pro-max-skill impeccable@impeccable taste-skill@taste-skill humanizer@humanizer; do
  if [ -f "$IP" ] && jq -e --arg p "$p" '.plugins[$p]' "$IP" >/dev/null 2>&1; then pass "$p instalado"
  elif [ -f "$SET" ] && jq -e --arg p "$p" '.enabledPlugins[$p]' "$SET" >/dev/null 2>&1; then wrn "$p habilitado pero aún no instalado" "abre claude para que lo descargue o /plugin install $p"
  else bad "$p no está instalado" "/plugin install $p"; fi
done

sec "Perfil de landing (mp-lp, opcional; se instala por proyecto)"
if [ -f "$IP" ] && jq -e '.plugins["mp-lp@mp-marketplace"]' "$IP" >/dev/null 2>&1; then
  pass "mp-lp@mp-marketplace instalado"
  # mp-lp depende de mp-core: sin él los agentes de UI compartidos no existen
  jq -e '.plugins["mp-core@mp-marketplace"]' "$IP" >/dev/null 2>&1 && pass "dependencia mp-core presente" || bad "mp-lp instalado pero falta su dependencia mp-core" "/plugin install mp-core@mp-marketplace"
  chrome=""
  for c in google-chrome chromium chromium-browser chrome; do have "$c" && { chrome="$c"; break; }; done
  [ -z "$chrome" ] && [ -d "/Applications/Google Chrome.app" ] && chrome="Google Chrome.app"
  [ -n "$chrome" ] && pass "Chrome/Chromium ($chrome), lo usa Lighthouse (measure.sh)" || wrn "no hay Chrome ni Chromium" "mp-lp lo necesita para medir rendimiento con Lighthouse"
  have ffmpeg && pass "ffmpeg (video)" || info "ffmpeg no está instalado; solo lo necesita lp-media si hay video"
else
  info "mp-lp no está instalado; en un proyecto de landing: claude plugin install mp-lp@mp-marketplace --scope project y luego /mp-lp:init"
fi

sec "MCPs (nivel usuario, $CJ)"
if [ -f "$CJ" ] && jq -e . "$CJ" >/dev/null 2>&1; then
  m=$(stat -f '%Lp' "$CJ" 2>/dev/null || stat -c '%a' "$CJ" 2>/dev/null)
  case "$m" in *00) pass "permisos $m en la config (contiene secretos)";; *) wrn "permisos $m en $CJ (contiene secretos)" "chmod 600 $CJ";; esac
  val(){ jq -r "$1 // empty" "$CJ" 2>/dev/null; }
  if [ -n "$(val '.mcpServers.taiga')" ]; then
    pass "MCP taiga registrado"
    p=$(val '.mcpServers.taiga.args[0]')
    [ -f "$p" ] && pass "taiga: $p existe" || bad "taiga: ruta inexistente (${p:-vacía})" "compila taiga-mcp y re-ejecuta bootstrap/setup.sh"
    for k in TAIGA_URL TAIGA_USERNAME TAIGA_PASSWORD; do
      [ -n "$(val ".mcpServers.taiga.env.$k")" ] && pass "taiga: $k con valor" || bad "taiga: $k vacío" "re-ejecuta bootstrap/setup.sh"
    done
  else bad "MCP taiga no registrado" "corre bootstrap/setup.sh"; fi
  if [ -n "$(val '.mcpServers.context7')" ]; then
    pass "MCP context7 registrado"
    # formatos válidos: headers.CONTEXT7_API_KEY (setup.sh) o headers.Authorization "Bearer <key>" (ctx7 setup)
    k=$(val '.mcpServers.context7.headers.CONTEXT7_API_KEY'); [ -n "$k" ] || k=$(val '(.mcpServers.context7.headers.Authorization // "") | sub("^Bearer +";"")')
    [ -n "$k" ] && pass "context7: API key con valor" || bad "context7: API key vacía" "re-ejecuta bootstrap/setup.sh"
  else bad "MCP context7 no registrado" "corre bootstrap/setup.sh"; fi
  if [ -n "$(val '.mcpServers.shadcn')" ]; then
    pass "MCP shadcn registrado"
    [ "$(val '.mcpServers.shadcn.command')" = "npx" ] && have npx && pass "shadcn: npx disponible" || bad "shadcn: falta npx o el comando no es npx" "instala node y re-ejecuta bootstrap/setup.sh"
  else bad "MCP shadcn no registrado" "corre bootstrap/setup.sh"; fi
  jq -e '[.mcpServers.taiga, .mcpServers.context7, .mcpServers.shadcn] | tostring | test("\$\{")' "$CJ" >/dev/null 2>&1 \
    && wrn "un MCP usa \${VAR} sin resolver" "re-ejecuta bootstrap/setup.sh"
else bad "$CJ ausente o inválido" "corre bootstrap/setup.sh"; fi

sec "Context7 (ctx7 setup --cli)"
[ -f "$CFG/rules/context7.md" ] && pass "regla rules/context7.md" || bad "falta $CFG/rules/context7.md" "npx ctx7 setup --cli --claude"
[ -e "$CFG/skills/find-docs" ] && pass "skill find-docs" || bad "falta skill find-docs" "npx ctx7 setup --cli --claude"

sec "Skills de Emil Kowalski (emilkowalski/skills)"
emil_miss=""
for s in emil-design-eng animate review-animations improve-animations find-animation-opportunities animation-performance animation-vocabulary apple-design pick-ui-library prototype mobile-native break-ui; do [ -e "$CFG/skills/$s" ] || emil_miss="$emil_miss $s"; done
[ -z "$emil_miss" ] && pass "12 skills de emilkowalski/skills instaladas" || bad "faltan skills de emilkowalski/skills:$emil_miss" "bootstrap/setup.sh (o npx skills@latest add emilkowalski/skills -g -a claude-code)"

sec "terminal-browser"
have terminal-browser && pass "binario terminal-browser" || bad "terminal-browser no está instalado" "bootstrap/setup.sh (o curl -fsSL https://terminal-browser.sh/install | bash)"
# /browser solo es usable si `terminal-browser setup` instaló la skill del agente (symlink en $CFG/skills)
TBS="$CFG/skills/terminal-browser"
if [ -L "$TBS" ] && [ ! -e "$TBS" ]; then bad "skill terminal-browser rota ($TBS apunta a una ruta inexistente)" "terminal-browser setup  (tras brew upgrade/reinstalar)"
elif [ -e "$TBS" ]; then pass "skill terminal-browser instalada"
else bad "falta la skill terminal-browser: /browser no será usable" "terminal-browser setup  (o bootstrap/setup.sh)"; fi
if have terminal-browser; then
  terminal-browser --version >/dev/null 2>&1 && pass "terminal-browser responde ($(terminal-browser --version 2>/dev/null | head -1))" || bad "terminal-browser no ejecuta" "terminal-browser upgrade o reinstala"
fi
case "${TERM_PROGRAM:-}${TERM:-}" in *ghostty*|*kitty*) pass "terminal compatible (${TERM_PROGRAM:-$TERM})";; *) bad "terminal no compatible (${TERM_PROGRAM:-$TERM}): /browser no será usable" "usa ghostty o kitty (requiere kitty graphics protocol)";; esac
[ -n "${TMUX:-}" ] && bad "corriendo dentro de tmux: /browser no será usable" "el plugin aún no funciona bajo multiplexores; sal de tmux"

sec "Duplicados locales (el plugin ya los provee)"
dups=0
for s in flow flow-auto flow-architecture lp lp-brief-interview lp-ui-profile lp-seo lp-motion lp-media lp-performance taiga-sprint-rollover taiga-ticket-docs; do [ -e "$CFG/skills/$s" ] && { wrn "skill local duplicado: $s" "bórralo de $CFG/skills"; dups=1; }; done
for a in "$CFG"/agents/flow-*.md "$CFG"/agents/lp-*.md "$CFG"/agents/ui-*.md "$CFG"/agents/manual-tester.md; do [ -e "$a" ] && { wrn "agente local duplicado: $(basename "$a")" "bórralo de $CFG/agents"; dups=1; }; done
for c in changelog commit commit-changes commit-convention release release-pr ship doctor promote; do [ -e "$CFG/commands/$c.md" ] && { wrn "comando local duplicado: $c" "bórralo de $CFG/commands"; dups=1; }; done
[ "$dups" -eq 0 ] && pass "sin duplicados"

sec "Hook anti-firma"
H="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}/hooks/block-claude-signature.sh"
[ -x "$H" ] && pass "hook ejecutable" || bad "hook ausente o sin permiso de ejecución" "chmod +x $H"
if [ -x "$H" ] && have jq; then
  printf '%s' 'git commit -m "x

Co-Authored-By: Claude <a@b.c>"' | jq -Rs '{tool_input:{command:.}}' | "$H" >/dev/null 2>&1
  [ $? -eq 2 ] && pass "hook bloquea una firma de prueba" || bad "el hook no bloqueó la firma de prueba"
fi

echo; echo "Resumen: ${G}$ok ok${N} · ${Y}$warn avisos${N} · ${R}$fail errores${N}"
[ "$fail" -eq 0 ]
