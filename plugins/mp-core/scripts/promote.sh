#!/usr/bin/env bash
# Promueve cambios hechos en caliente en la caché de los plugins del marketplace mp-marketplace hacia el repo, vía Pull Request.
# Las rutas tienen la forma <plugin>/<ruta relativa al plugin>, ej. mp/agents/flow-coder.md
# Subcomandos:
#   scan                         lista los archivos que difieren de la base instalada (solo lectura)
#   diff <plugin/ruta>           muestra el diff de un archivo
#   open <rama> <titulo> <body-file> <plugin/ruta>...   crea la rama desde origin/main, copia, commitea, pushea y abre el PR
# Nunca toca main ni el clon del marketplace (usa un worktree temporal). No sube la versión: eso es de /mp-core:release.
set -uo pipefail
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
IP="$CFG/plugins/installed_plugins.json"
KM="$CFG/plugins/known_marketplaces.json"
MKT="mp-marketplace"
DIRS="agents commands hooks scripts skills"   # plugin.json queda fuera a propósito (la versión se sube al hacer release)

die(){ echo "✖ $1" >&2; exit 1; }
for c in jq git; do command -v "$c" >/dev/null 2>&1 || die "$c no está instalado"; done
[ -f "$IP" ] || die "no existe $IP"

CLONE=$(jq -r --arg m "$MKT" '.[$m].installLocation // empty' "$KM" 2>/dev/null)
[ -d "$CLONE/.git" ] || die "clon del marketplace no encontrado ($CLONE)"
G(){ git -C "$CLONE" "$@"; }

G fetch -q origin 2>/dev/null || echo "⚠ no se pudo hacer fetch de origin; se usa lo que ya hay en el clon" >&2
HEAD_REF=origin/main
G rev-parse -q --verify "$HEAD_REF" >/dev/null || die "no existe $HEAD_REF en el clon"

# plugins instalados desde este marketplace
plugins(){ jq -r --arg s "@$MKT" '.plugins | keys[] | select(endswith($s)) | sub($s;"")' "$IP"; }
# carga CACHE/BASE/VER/SUB del plugin $1
load(){
  PLUGIN="$1"
  CACHE=$(jq -r --arg p "$1@$MKT" '.plugins[$p][0].installPath // empty' "$IP")
  BASE=$(jq -r --arg p "$1@$MKT" '.plugins[$p][0].gitCommitSha // empty' "$IP")
  VER=$(jq -r --arg p "$1@$MKT" '.plugins[$p][0].version // empty' "$IP")
  SUB="plugins/$1"
  [ -d "$CACHE" ] || { echo "⚠ $1: caché no encontrada, se omite" >&2; return 1; }
  [ -n "$BASE" ] || { echo "⚠ $1: sin gitCommitSha en installed_plugins.json, se omite" >&2; return 1; }
  G cat-file -e "$BASE^{commit}" 2>/dev/null || { echo "⚠ $1: el commit base $BASE no está en el clon; corre /plugin marketplace update $MKT. Se omite" >&2; return 1; }
}
# separa <plugin>/<ruta> en $1 (plugin) y $2 (ruta); deja PLUGIN/CACHE/BASE/SUB cargados
split_load(){ P="${1%%/*}"; REL="${1#*/}"; [ "$P" != "$1" ] || die "la ruta debe ser <plugin>/<ruta>: $1"; load "$P" || die "no se pudo cargar el plugin $P"; }

blob(){ G rev-parse -q --verify "$1:$SUB/$2" 2>/dev/null || true; }   # hash del archivo en una ref, vacío si no existe

list_paths(){
  { ( cd "$CACHE" && for d in $DIRS; do [ -d "$d" ] && find "$d" -type f ! -name .DS_Store; done )
    G ls-tree -r --name-only "$BASE" -- $(for d in $DIRS; do printf '%s/%s ' "$SUB" "$d"; done) | sed "s#^$SUB/##"
  } | sort -u
}

cmd_scan(){
  n=0
  for pl in $(plugins); do
    load "$pl" || continue
    echo "plugin $pl@$MKT v$VER  base $(echo "$BASE" | cut -c1-7)  main $(G rev-parse --short "$HEAD_REF")  (main va $(G rev-list --count "$BASE..$HEAD_REF") commits por delante de tu base)"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      b=$(blob "$BASE" "$p"); m=$(blob "$HEAD_REF" "$p")
      c=""; [ -f "$CACHE/$p" ] && c=$(git hash-object "$CACHE/$p")
      [ "$c" = "$b" ] && continue                 # sin cambios locales
      [ "$c" = "$m" ] && continue                 # main ya tiene exactamente eso
      if   [ -z "$b" ]; then st=A; elif [ -z "$c" ]; then st=D; else st=M; fi
      fl=ok; [ "$m" != "$b" ] && fl=CONFLICTO     # main también cambió este archivo desde tu base
      printf '%s\t%s\t%s/%s\n' "$st" "$fl" "$pl" "$p"; n=$((n+1))
    done < <(list_paths)
  done
  [ "$n" -eq 0 ] && echo "(sin cambios locales para promover)"
  return 0
}

cmd_diff(){
  split_load "${1:?ruta requerida}"; p="$REL"
  t=$(mktemp -d); trap 'rm -rf "$t"' RETURN
  G show "$BASE:$SUB/$p" >"$t/base" 2>/dev/null || : >"$t/base"
  G show "$HEAD_REF:$SUB/$p" >"$t/main" 2>/dev/null || : >"$t/main"
  c="$CACHE/$p"; [ -f "$c" ] || c=/dev/null
  echo "── tu cambio (base → caché) ──"; diff -u --label "base/$P/$p" --label "local/$P/$p" "$t/base" "$c"
  if ! cmp -s "$t/base" "$t/main"; then
    echo; echo "── lo que cambió en main desde tu base (base → main) ──"
    diff -u --label "base/$P/$p" --label "main/$P/$p" "$t/base" "$t/main"
  fi
  return 0
}

cmd_open(){
  [ "$#" -ge 4 ] || die "uso: open <rama> <titulo> <body-file> <plugin/ruta>..."
  branch="$1"; title="$2"; body="$3"; shift 3
  command -v gh >/dev/null 2>&1 || die "gh no está instalado"
  gh auth status >/dev/null 2>&1 || die "gh sin sesión (gh auth login)"
  [ -f "$body" ] || die "no existe el body $body"
  wt=$(mktemp -d)
  cleanup(){ G worktree remove --force "$wt" >/dev/null 2>&1; rm -rf "$wt"; G branch -D "$branch" >/dev/null 2>&1; }
  trap cleanup EXIT
  G worktree add -q -b "$branch" "$wt" "$HEAD_REF" || die "no se pudo crear el worktree"
  for full in "$@"; do
    split_load "$full"
    case " $DIRS " in *" ${REL%%/*} "*) ;; *) die "ruta fuera de alcance: $full";; esac
    if [ -f "$CACHE/$REL" ]; then mkdir -p "$wt/$SUB/$(dirname "$REL")"; cp -p "$CACHE/$REL" "$wt/$SUB/$REL"
    else rm -f "$wt/$SUB/$REL"; fi
    git -C "$wt" add -A -- "$SUB/$REL"
  done
  git -C "$wt" diff --cached --quiet && die "no hay cambios que commitear contra main"
  git -C "$wt" commit -q -m "$title" || die "falló el commit"
  repo=$(jq -r --arg m "$MKT" '.[$m].source.repo // empty' "$KM")
  head="$branch"
  if ! git -C "$wt" push -q -u origin "$branch" 2>/dev/null; then
    echo "⚠ sin permiso de escritura en origin; intento con un fork"
    gh repo fork "$repo" --clone=false >/dev/null 2>&1
    me=$(gh api user -q .login)
    git -C "$wt" remote add fork "git@github.com:$me/${repo#*/}.git" 2>/dev/null
    git -C "$wt" push -q -u fork "$branch" || die "no se pudo subir la rama ni al repo ni a un fork"
    head="$me:$branch"
  fi
  gh pr create --repo "$repo" --base main --head "$head" --title "$title" --body-file "$body"
}

case "${1:-}" in
  scan) cmd_scan;;
  diff) shift; cmd_diff "$@";;
  open) shift; cmd_open "$@";;
  *) die "uso: promote.sh scan | diff <plugin/ruta> | open <rama> <titulo> <body-file> <plugin/ruta>...";;
esac
