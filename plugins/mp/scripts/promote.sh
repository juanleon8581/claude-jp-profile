#!/usr/bin/env bash
# Promueve cambios hechos en caliente en la caché del plugin mp hacia el repo, vía Pull Request.
# Subcomandos:
#   scan                         lista los archivos que difieren de la base instalada (solo lectura)
#   diff <ruta>                  muestra el diff de un archivo (ruta relativa a plugins/mp)
#   open <rama> <titulo> <body-file> <ruta>...   crea la rama desde origin/main, copia, commitea, pushea y abre el PR
# Nunca toca main ni el clon del marketplace (usa un worktree temporal). No sube la versión: eso es de /mp:release.
set -uo pipefail
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
IP="$CFG/plugins/installed_plugins.json"
KM="$CFG/plugins/known_marketplaces.json"
PLUGIN="mp@mp-marketplace"
MKT="mp-marketplace"
SUB="plugins/mp"
DIRS="agents commands hooks scripts skills"   # plugin.json queda fuera a propósito (la versión se sube al hacer release)

die(){ echo "✖ $1" >&2; exit 1; }
for c in jq git; do command -v "$c" >/dev/null 2>&1 || die "$c no está instalado"; done
[ -f "$IP" ] || die "no existe $IP"

CACHE=$(jq -r --arg p "$PLUGIN" '.plugins[$p][0].installPath // empty' "$IP")
BASE=$(jq -r --arg p "$PLUGIN" '.plugins[$p][0].gitCommitSha // empty' "$IP")
VER=$(jq -r --arg p "$PLUGIN" '.plugins[$p][0].version // empty' "$IP")
CLONE=$(jq -r --arg m "$MKT" '.[$m].installLocation // empty' "$KM" 2>/dev/null)
[ -d "$CACHE" ] || die "caché del plugin no encontrada ($PLUGIN)"
[ -n "$BASE" ] || die "installed_plugins.json no trae gitCommitSha para $PLUGIN"
[ -d "$CLONE/.git" ] || die "clon del marketplace no encontrado ($CLONE)"

G(){ git -C "$CLONE" "$@"; }
blob(){ G rev-parse -q --verify "$1:$SUB/$2" 2>/dev/null || true; }   # hash del archivo en una ref, vacío si no existe

G fetch -q origin 2>/dev/null || echo "⚠ no se pudo hacer fetch de origin; se usa lo que ya hay en el clon" >&2
HEAD_REF=origin/main
G rev-parse -q --verify "$HEAD_REF" >/dev/null || die "no existe $HEAD_REF en el clon"
G cat-file -e "$BASE^{commit}" 2>/dev/null || die "el commit base $BASE no está en el clon; actualiza el marketplace (/plugin marketplace update $MKT) y reintenta"

list_paths(){
  { ( cd "$CACHE" && for d in $DIRS; do [ -d "$d" ] && find "$d" -type f ! -name .DS_Store; done )
    G ls-tree -r --name-only "$BASE" -- $(for d in $DIRS; do printf '%s/%s ' "$SUB" "$d"; done) | sed "s#^$SUB/##"
  } | sort -u
}

cmd_scan(){
  echo "plugin $PLUGIN v$VER  base $(echo "$BASE" | cut -c1-7)  main $(G rev-parse --short "$HEAD_REF")  (main va $(G rev-list --count "$BASE..$HEAD_REF") commits por delante de tu base)"
  n=0
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    b=$(blob "$BASE" "$p"); m=$(blob "$HEAD_REF" "$p")
    c=""; [ -f "$CACHE/$p" ] && c=$(git hash-object "$CACHE/$p")
    [ "$c" = "$b" ] && continue                 # sin cambios locales
    [ "$c" = "$m" ] && continue                 # main ya tiene exactamente eso
    if   [ -z "$b" ]; then st=A; elif [ -z "$c" ]; then st=D; else st=M; fi
    fl=ok; [ "$m" != "$b" ] && fl=CONFLICTO     # main también cambió este archivo desde tu base
    printf '%s\t%s\t%s\n' "$st" "$fl" "$p"; n=$((n+1))
  done < <(list_paths)
  [ "$n" -eq 0 ] && echo "(sin cambios locales para promover)"
  return 0
}

cmd_diff(){
  p="${1:?ruta requerida}"
  t=$(mktemp -d); trap 'rm -rf "$t"' RETURN
  G show "$BASE:$SUB/$p" >"$t/base" 2>/dev/null || : >"$t/base"
  G show "$HEAD_REF:$SUB/$p" >"$t/main" 2>/dev/null || : >"$t/main"
  c="$CACHE/$p"; [ -f "$c" ] || c=/dev/null
  echo "── tu cambio (base → caché) ──"; diff -u --label "base/$p" --label "local/$p" "$t/base" "$c"
  if ! cmp -s "$t/base" "$t/main"; then
    echo; echo "── lo que cambió en main desde tu base (base → main) ──"
    diff -u --label "base/$p" --label "main/$p" "$t/base" "$t/main"
  fi
  return 0
}

cmd_open(){
  [ "$#" -ge 4 ] || die "uso: open <rama> <titulo> <body-file> <ruta>..."
  branch="$1"; title="$2"; body="$3"; shift 3
  command -v gh >/dev/null 2>&1 || die "gh no está instalado"
  gh auth status >/dev/null 2>&1 || die "gh sin sesión (gh auth login)"
  [ -f "$body" ] || die "no existe el body $body"
  wt=$(mktemp -d)
  cleanup(){ G worktree remove --force "$wt" >/dev/null 2>&1; rm -rf "$wt"; G branch -D "$branch" >/dev/null 2>&1; }
  trap cleanup EXIT
  G worktree add -q -b "$branch" "$wt" "$HEAD_REF" || die "no se pudo crear el worktree"
  for p in "$@"; do
    case " $DIRS " in *" ${p%%/*} "*) ;; *) die "ruta fuera de alcance: $p";; esac
    if [ -f "$CACHE/$p" ]; then mkdir -p "$wt/$SUB/$(dirname "$p")"; cp -p "$CACHE/$p" "$wt/$SUB/$p"
    else rm -f "$wt/$SUB/$p"; fi
    git -C "$wt" add -A -- "$SUB/$p"
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
  *) die "uso: promote.sh scan | diff <ruta> | open <rama> <titulo> <body-file> <ruta>...";;
esac
