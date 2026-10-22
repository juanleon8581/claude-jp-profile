#!/usr/bin/env bash
# Valida el marketplace y sus plugins: manifiestos, dependencias, rutas internas y referencias entre plugins.
# Solo lectura. Exit 1 si hay algún ✖. Úsalo antes de cada release.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MJ="$ROOT/.claude-plugin/marketplace.json"
ok=0; fail=0
G=$'\e[32m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
pass(){ echo "  ${G}✔${N} $1"; ok=$((ok+1)); }
bad(){ echo "  ${R}✖${N} $1${2:+ ${D}→ $2${N}}"; fail=$((fail+1)); }
sec(){ echo; echo "$1"; }
command -v jq >/dev/null 2>&1 || { echo "✖ jq no está instalado"; exit 1; }

sec "Marketplace"
jq -e . "$MJ" >/dev/null 2>&1 && pass "marketplace.json válido" || { bad "marketplace.json ausente o inválido"; exit 1; }
names=$(jq -r '.plugins[].name' "$MJ")
alt=$(echo "$names" | awk '{print length, $0}' | sort -rn | cut -d" " -f2- | paste -sd"|" -)   # nombres de plugin, el más largo primero
dup=$(echo "$names" | sort | uniq -d)
[ -z "$dup" ] && pass "nombres de plugin únicos" || bad "nombres repetidos: $dup"

for name in $names; do
  src=$(jq -r --arg n "$name" '.plugins[]|select(.name==$n)|.source' "$MJ")
  dir="$ROOT/${src#./}"
  sec "Plugin $name ($src)"
  pj="$dir/.claude-plugin/plugin.json"
  [ -f "$pj" ] && jq -e . "$pj" >/dev/null 2>&1 || { bad "plugin.json ausente o inválido"; continue; }
  [ "$(jq -r .name "$pj")" = "$name" ] && pass "plugin.json name = $name" || bad "plugin.json name no coincide con el marketplace"
  ver=$(jq -r '.version // empty' "$pj")
  echo "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' && pass "versión $ver" || bad "versión inválida (${ver:-vacía})"

  # dependencias: deben existir en este marketplace y no ser él mismo
  for dep in $(jq -r '.dependencies[]? | if type=="string" then . else .name end' "$pj"); do
    d=${dep%%@*}
    if [ "$d" = "$name" ]; then bad "depende de sí mismo"
    elif echo "$names" | grep -qx "$d"; then pass "dependencia $d existe en el marketplace"
    else bad "dependencia $d no está en el marketplace"; fi
  done

  # rutas ${CLAUDE_PLUGIN_ROOT}/... deben existir dentro del propio plugin
  refs=$(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' "$dir" 2>/dev/null | sed 's#^\${CLAUDE_PLUGIN_ROOT}/##; s#[./]*$##' | sort -u)
  miss=0
  for r in $refs; do [ -e "$dir/$r" ] || { bad "CLAUDE_PLUGIN_ROOT/$r no existe en $name" "¿vive en otro plugin?"; miss=1; }; done
  [ "$miss" -eq 0 ] && pass "rutas CLAUDE_PLUGIN_ROOT resuelven"

  # hooks.json: cada comando apunta a un archivo existente y ejecutable
  hj="$dir/hooks/hooks.json"
  if [ -f "$hj" ]; then
    jq -e . "$hj" >/dev/null 2>&1 || bad "hooks.json inválido"
    for c in $(jq -r '.. | .command? // empty' "$hj" | grep -oE 'hooks/[A-Za-z0-9_.-]+' | sort -u); do
      [ -x "$dir/$c" ] && pass "hook $c ejecutable" || bad "hook $c ausente o sin permiso de ejecución"
    done
  fi
  # carpeta hooks vacía o sin hooks.json no debe existir
  [ -d "$dir/hooks" ] && [ ! -f "$hj" ] && bad "hooks/ sin hooks.json"

  # el name del frontmatter de agentes y skills coincide con su archivo/carpeta
  nm=0
  for f in "$dir"/agents/*.md; do [ -e "$f" ] || continue
    n=$(sed -n 's/^name: *//p' "$f" | head -1); [ "$n" = "$(basename "$f" .md)" ] || { bad "agente $(basename "$f"): name '$n' no coincide con el archivo"; nm=1; }
  done
  for f in "$dir"/skills/*/SKILL.md; do [ -e "$f" ] || continue
    n=$(sed -n 's/^name: *//p' "$f" | head -1); [ "$n" = "$(basename "$(dirname "$f")")" ] || { bad "skill $(basename "$(dirname "$f")"): name '$n' no coincide con la carpeta"; nm=1; }
  done
  [ "$nm" -eq 0 ] && pass "name de agentes y skills coincide con su archivo"

  # referencias a comandos/skills/agentes de plugins: <plugin>:<nombre> debe existir
  badref=0
  for ref in $(grep -rhoE "(^|[^A-Za-z0-9_/-])/?($alt):[a-z][a-z-]*" "$dir" 2>/dev/null | sed -E 's#^[^a-z]*/?##' | sort -u); do
    pl=${ref%%:*}; it=${ref#*:}
    t="$ROOT/plugins/$pl"
    if [ -e "$t/commands/$it.md" ] || [ -e "$t/skills/$it/SKILL.md" ] || [ -e "$t/agents/$it.md" ]; then :
    else bad "referencia $ref no existe" "¿se movió a otro plugin?"; badref=1; fi
  done
  [ "$badref" -eq 0 ] && pass "referencias plugin:nombre resuelven"
done

# nombres de comando/skill/agente repetidos entre un plugin y sus dependencias (se pisarían)
sec "Colisiones"
col=0
for name in $names; do
  pj="$ROOT/plugins/$name/.claude-plugin/plugin.json"; [ -f "$pj" ] || continue
  for dep in $(jq -r '.dependencies[]? | if type=="string" then . else .name end' "$pj"); do
    d=${dep%%@*}
    for kind in commands agents; do
      for f in "$ROOT/plugins/$name/$kind"/*.md; do [ -e "$f" ] || continue
        [ -e "$ROOT/plugins/$d/$kind/$(basename "$f")" ] && { bad "$kind/$(basename "$f") existe en $name y en $d"; col=1; }
      done
    done
    for s in "$ROOT/plugins/$name/skills"/*/; do [ -d "$s" ] || continue
      [ -d "$ROOT/plugins/$d/skills/$(basename "$s")" ] && { bad "skill $(basename "$s") existe en $name y en $d"; col=1; }
    done
  done
done
[ "$col" -eq 0 ] && pass "sin nombres repetidos entre plugin y dependencias"

sec "claude plugin validate"
if command -v claude >/dev/null 2>&1; then
  for name in $names; do
    out=$(claude plugin validate "$ROOT/plugins/$name" 2>&1) && pass "$name: validate ok" || bad "$name: validate falló" "$(echo "$out" | head -3 | tr '\n' ' ')"
  done
  out=$(claude plugin validate "$ROOT" 2>&1) && pass "marketplace: validate ok" || bad "marketplace: validate falló" "$(echo "$out" | head -3 | tr '\n' ' ')"
else echo "  (claude no está en PATH, se omite)"; fi

echo; echo "Resumen: ${G}$ok ok${N} · ${R}$fail errores${N}"
[ "$fail" -eq 0 ]
