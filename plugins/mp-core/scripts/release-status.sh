#!/usr/bin/env bash
# Estado de versiones de un repo marketplace con varios plugins. Solo lectura.
# Uso: release-status.sh [raíz-del-repo]
# Por plugin: versión actual, último tag <plugin>-v*, commits desde ese tag que tocan su carpeta y bump sugerido.
# Del repo: metadata.version de marketplace.json y último tag v*.
set -uo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
MP="$ROOT/.claude-plugin/marketplace.json"
[ -f "$MP" ] || { echo "✖ no hay .claude-plugin/marketplace.json en $ROOT"; exit 1; }
command -v jq >/dev/null || { echo "✖ falta jq"; exit 1; }
cd "$ROOT" || exit 1

# bump sugerido a partir de los asuntos de commit (conventional commits con emoji opcional)
suggest() {
  local subjects="$1" bump=none s
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    if grep -qiE '^[^a-z]*[a-z]+(\([^)]*\))?!:|BREAKING' <<<"$s"; then echo major; return; fi
    if grep -qiE '^[^a-z]*feat(\(|:)' <<<"$s"; then bump=minor
    elif [ "$bump" = none ]; then bump=patch; fi
  done <<<"$subjects"
  echo "$bump"
}

echo "Repo: $(jq -r '.name' "$MP")"
RV="$(jq -r '.metadata.version // "(sin definir)"' "$MP")"
RT="$(git tag -l 'v[0-9]*' --sort=-v:refname | head -1)"
echo "  versión del repo (marketplace.json): $RV · último tag v*: ${RT:-ninguno}"
echo
printf '%-12s %-9s %-18s %-9s %s\n' PLUGIN VERSIÓN ÚLTIMO-TAG COMMITS BUMP-SUGERIDO

jq -r '.plugins[].source' "$MP" | while read -r src; do
  dir="${src#./}"
  pj="$dir/.claude-plugin/plugin.json"
  [ -f "$pj" ] || { echo "✖ falta $pj"; continue; }
  name="$(jq -r .name "$pj")"; ver="$(jq -r .version "$pj")"
  tag="$(git tag -l "${name}-v[0-9]*" --sort=-v:refname | head -1)"
  range="${tag:+$tag..}HEAD"
  subjects="$(git log --pretty=%s "$range" -- "$dir" 2>/dev/null)"
  n="$(grep -c . <<<"$subjects")"; [ -z "$subjects" ] && n=0
  b="$(suggest "$subjects")"
  printf '%-12s %-9s %-18s %-9s %s\n' "$name" "$ver" "${tag:-ninguno}" "$n" "$b"
done
echo
echo "Bump del repo sugerido: el mayor de los bumps de plugin (major si alguno rompe compatibilidad, minor si hay plugin o función nueva, patch si solo correcciones)."
