#!/usr/bin/env bash
# Diagnóstico del perfil mp: requisitos, secretos, settings, MCPs, plugins y duplicados locales.
# Solo lectura. Nunca imprime valores de secretos. Exit 1 si hay algún ✖.
set -uo pipefail
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SET="$CFG/settings.json"
ENVF="$HOME/.claude-mp.env"
ok=0; warn=0; fail=0
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
pass(){ echo "  ${G}✔${N} $1"; ok=$((ok+1)); }
wrn(){ echo "  ${Y}⚠${N} $1${2:+ ${D}→ $2${N}}"; warn=$((warn+1)); }
bad(){ echo "  ${R}✖${N} $1${2:+ ${D}→ $2${N}}"; fail=$((fail+1)); }
sec(){ echo; echo "$1"; }
have(){ command -v "$1" >/dev/null 2>&1; }

sec "Requisitos"
for c in claude jq node npx git gh; do
  have "$c" && pass "$c" || bad "$c no está instalado" "instálalo (brew / apt)"
done
if have node; then
  v=$(node -p 'process.versions.node' 2>/dev/null); maj=${v%%.*}; min=${v#*.}; min=${min%%.*}
  if [ "$maj" -gt 22 ] || { [ "$maj" -eq 22 ] && [ "$min" -ge 13 ]; }; then pass "node $v (≥ 22.13)"; else wrn "node $v" "caveman/context-mode piden ≥ 22.13"; fi
fi
have gh && { gh auth status >/dev/null 2>&1 && pass "gh autenticado" || wrn "gh sin sesión" "gh auth login"; }

sec "Secretos (entorno del shell que lanzó claude)"
[ -f "$ENVF" ] && pass "$ENVF existe" || bad "$ENVF no existe" "corre bootstrap/setup.sh"
if [ -f "$ENVF" ]; then
  m=$(stat -f '%Lp' "$ENVF" 2>/dev/null || stat -c '%a' "$ENVF" 2>/dev/null)
  [ "$m" = "600" ] && pass "permisos 600" || wrn "permisos $m en $ENVF" "chmod 600 $ENVF"
  grep -q 'claude-mp.env' "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zprofile" "$HOME/.bash_profile" 2>/dev/null \
    && pass "se carga desde el rc del shell" || wrn "no se encontró 'source' en el rc del shell" "echo '[ -f ~/.claude-mp.env ] && source ~/.claude-mp.env' >> ~/.zshrc"
fi
for v in TAIGA_URL TAIGA_USERNAME TAIGA_PASSWORD CONTEXT7_API_KEY; do
  [ -n "${!v:-}" ] && pass "$v definida" || bad "$v vacía o ausente en el entorno" "complétala en $ENVF y reabre el shell"
done
if [ -n "${TAIGA_MCP_PATH:-}" ]; then
  [ -f "$TAIGA_MCP_PATH" ] && pass "TAIGA_MCP_PATH apunta a un archivo existente" || bad "TAIGA_MCP_PATH no existe: $TAIGA_MCP_PATH" "clona y compila taiga-mcp (ver README)"
else bad "TAIGA_MCP_PATH vacía" "defínela en $ENVF"; fi

sec "settings.json"
if [ -f "$SET" ] && jq -e . "$SET" >/dev/null 2>&1; then
  pass "$SET válido"
  chk(){ jq -e "$1" "$SET" >/dev/null 2>&1 && pass "$2" || bad "$2: falta" "${3:-corre bootstrap/setup.sh}"; }
  chk '.statusLine.command' "statusLine"
  chk '.autoCompactEnabled == true' "autoCompactEnabled"
  chk '.autoCompactWindow == 420000' "autoCompactWindow = 420000"
  chk '.permissions.allow | index("mcp__taiga")' "permiso mcp__taiga"
  chk '.permissions.ask | index("mcp__taiga__delete_task")' "ask en borrados de Taiga"
  jq -e '.model' "$SET" >/dev/null 2>&1 && pass "model definido en este equipo ($(jq -r .model "$SET"))" || wrn "model no definido" "elígelo con /model"
else bad "$SET ausente o inválido" "corre bootstrap/setup.sh"; fi

sec "Plugins"
IP="$CFG/plugins/installed_plugins.json"
for p in mp@mp-marketplace caveman@caveman context-mode@context-mode skill-creator@claude-plugins-official supabase@supabase-agent-skills postgres-best-practices@supabase-agent-skills; do
  if [ -f "$IP" ] && jq -e --arg p "$p" '.plugins[$p]' "$IP" >/dev/null 2>&1; then pass "$p instalado"
  elif [ -f "$SET" ] && jq -e --arg p "$p" '.enabledPlugins[$p]' "$SET" >/dev/null 2>&1; then wrn "$p habilitado pero aún no instalado" "abre claude para que lo descargue o /plugin install $p"
  else bad "$p no está instalado" "/plugin install $p"; fi
done

sec "MCPs (nivel usuario, ~/.claude.json)"
CJ="$HOME/.claude.json"
for s in taiga context7; do
  [ -f "$CJ" ] && jq -e --arg s "$s" '.mcpServers[$s]' "$CJ" >/dev/null 2>&1 && pass "MCP $s registrado" || bad "MCP $s no registrado" "corre bootstrap/setup.sh"
done
if [ -f "$CJ" ]; then
  for s in taiga context7; do
    jq -e --arg s "$s" '.mcpServers[$s] | tostring | test("[A-Za-z0-9]{24,}")' "$CJ" >/dev/null 2>&1 \
      && wrn "MCP $s parece tener un secreto en texto plano en ~/.claude.json" "re-registra con setup.sh (usa \${VAR})"
  done
fi

sec "Context7 (ctx7 setup --cli)"
[ -f "$CFG/rules/context7.md" ] && pass "regla rules/context7.md" || bad "falta $CFG/rules/context7.md" "npx ctx7 setup --cli --claude"
[ -e "$CFG/skills/find-docs" ] && pass "skill find-docs" || bad "falta skill find-docs" "npx ctx7 setup --cli --claude"

sec "Duplicados locales (el plugin ya los provee)"
dups=0
for s in flow flow-auto taiga-sprint-rollover taiga-ticket-docs; do [ -e "$CFG/skills/$s" ] && { wrn "skill local duplicado: $s" "bórralo de $CFG/skills"; dups=1; }; done
for a in "$CFG"/agents/flow-*.md; do [ -e "$a" ] && { wrn "agente local duplicado: $(basename "$a")" "bórralo de $CFG/agents"; dups=1; }; done
for c in changelog commit commit-changes commit-convention release release-pr ship; do [ -e "$CFG/commands/$c.md" ] && { wrn "comando local duplicado: $c" "bórralo de $CFG/commands"; dups=1; }; done
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
