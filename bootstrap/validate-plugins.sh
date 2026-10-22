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
  [ -f "$dir/CHANGELOG.md" ] && grep -qF "## [$ver]" "$dir/CHANGELOG.md" && pass "CHANGELOG.md tiene la sección [$ver]" || bad "falta plugins/$name/CHANGELOG.md con la sección [$ver]" "/mp-core:marketplace-release"

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

sec "Consistencia del bootstrap (setup · settings · doctor)"
DOC="$ROOT/plugins/mp-core/scripts/doctor.sh"; SETUP="$ROOT/bootstrap/setup.sh"; SB="$ROOT/bootstrap/settings.base.json"
if [ -f "$DOC" ] && [ -f "$SETUP" ] && [ -f "$SB" ]; then
  jq -e . "$SB" >/dev/null 2>&1 && pass "settings.base.json válido" || bad "settings.base.json inválido"
  doc_plugins=$(grep -E '^for p in ' "$DOC" | head -1 | sed 's/^for p in //; s/; do.*//' | tr ' ' '\n' | sort -u)
  cons=0
  # 1) todo plugin habilitado en settings.base.json lo verifica el doctor y tiene su marketplace declarado
  for p in $(jq -r '.enabledPlugins | keys[]' "$SB"); do
    echo "$doc_plugins" | grep -qx "$p" || { bad "$p está en settings.base.json pero el doctor no lo verifica"; cons=1; }
    mk=${p#*@}
    case "$mk" in claude-plugins-official) ;; *) jq -e --arg m "$mk" '.extraKnownMarketplaces | has($m)' "$SB" >/dev/null 2>&1 || { bad "$p: marketplace '$mk' no declarado en extraKnownMarketplaces"; cons=1; } ;; esac
  done
  # 2) todo plugin que instala setup.sh lo verifica el doctor
  for p in $(grep -oE '"[A-Za-z0-9._-]+/[A-Za-z0-9._-]+ [a-z0-9-]+@[a-z0-9-]+"' "$SETUP" | tr -d '"' | awk '{print $2}'); do
    echo "$doc_plugins" | grep -qx "$p" || { bad "setup.sh instala $p pero el doctor no lo verifica"; cons=1; }
  done
  # 3) todo plugin del marketplace aparece en el doctor (lista de usuario o sección propia, como mp-lp)
  for n in $names; do grep -q "$n@mp-marketplace" "$DOC" || { bad "el doctor no menciona $n@mp-marketplace"; cons=1; }; done
  # 4) la lista de skills de Emil Kowalski coincide entre setup.sh y doctor
  s_emil=$(sed -n 's/^EMIL_SKILLS="\(.*\)"/\1/p' "$SETUP" | tr ' ' '\n' | sort)
  d_emil=$(grep -E 'emil_miss="\$emil_miss' "$DOC" | head -1 | sed 's/^for s in //; s/; do.*//' | tr ' ' '\n' | sort)
  [ -n "$s_emil" ] && [ "$s_emil" = "$d_emil" ] || { bad "la lista EMIL_SKILLS de setup.sh y la del doctor difieren"; cons=1; }
  [ "$cons" -eq 0 ] && pass "setup, settings y doctor cubren los mismos plugins y skills"
else echo "  (bootstrap incompleto, se omite)"; fi

sec "Versionado del repo"
rv=$(jq -r '.metadata.version // empty' "$MJ")
echo "$rv" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' && pass "metadata.version $rv" || bad "marketplace.json sin metadata.version SemVer (${rv:-vacía})"
[ -f "$ROOT/CHANGELOG.md" ] && grep -qF "## [$rv]" "$ROOT/CHANGELOG.md" && pass "CHANGELOG.md raíz tiene la sección [$rv]" || bad "falta CHANGELOG.md raíz con la sección [$rv]"
# la entrada del repo debe listar la versión vigente de cada plugin
if [ -f "$ROOT/CHANGELOG.md" ]; then
  sect=$(awk -v h="## [$rv]" 'index($0,h)==1{f=1;next} /^## \[/{f=0} f' "$ROOT/CHANGELOG.md")
  tab=0
  for name in $names; do
    v=$(jq -r .version "$ROOT/plugins/$name/.claude-plugin/plugin.json" 2>/dev/null)
    echo "$sect" | grep -E "\[?$name\]?(\([^)]*\))? *\| *$v " >/dev/null || { bad "la entrada [$rv] del CHANGELOG raíz no lista $name $v"; tab=1; }
  done
  [ "$tab" -eq 0 ] && pass "la tabla de [$rv] coincide con las versiones de los plugins"
fi

sec "claude plugin validate"
if command -v claude >/dev/null 2>&1; then
  for name in $names; do
    out=$(claude plugin validate "$ROOT/plugins/$name" 2>&1) && pass "$name: validate ok" || bad "$name: validate falló" "$(echo "$out" | head -3 | tr '\n' ' ')"
  done
  out=$(claude plugin validate "$ROOT" 2>&1) && pass "marketplace: validate ok" || bad "marketplace: validate falló" "$(echo "$out" | head -3 | tr '\n' ' ')"
else echo "  (claude no está en PATH, se omite)"; fi

echo; echo "Resumen: ${G}$ok ok${N} · ${R}$fail errores${N}"
[ "$fail" -eq 0 ]
