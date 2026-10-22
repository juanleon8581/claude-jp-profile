#!/usr/bin/env bash
# Mide rendimiento, accesibilidad, SEO y buenas prácticas de un landing con Lighthouse (móvil y escritorio) contra los presupuestos de lp-performance.
# Uso:
#   measure.sh --url <url>                      mide una URL ya en marcha
#   measure.sh --build "<cmd>" [--port 4321]    construye, levanta `astro preview` en segundo plano, mide y lo detiene
# Mide siempre producción (nunca astro dev). Solo lectura sobre el repo: los JSON de Lighthouse van a un directorio temporal.
# Exit 0 si se pudo medir (los incumplimientos se marcan ✖ en la tabla); exit 2 si no se pudo medir.
set -uo pipefail
URL=""; BUILD=""; PORT=4321
while [ $# -gt 0 ]; do case "$1" in
  --url) URL="$2"; shift 2;; --build) BUILD="$2"; shift 2;; --port) PORT="$2"; shift 2;;
  *) echo "✖ argumento desconocido: $1" >&2; exit 2;; esac; done
[ -n "$URL" ] || [ -n "$BUILD" ] || { echo "✖ indica --url <url> o --build \"<cmd>\"" >&2; exit 2; }
for c in jq npx curl; do command -v "$c" >/dev/null 2>&1 || { echo "✖ $c no está instalado" >&2; exit 2; }; done
G=$'\e[32m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
T=$(mktemp -d); PID=""
cleanup(){ [ -n "$PID" ] && kill "$PID" >/dev/null 2>&1; rm -rf "$T"; }
trap cleanup EXIT

if [ -z "$URL" ]; then
  echo "· build: $BUILD"; bash -c "$BUILD" >"$T/build.log" 2>&1 || { echo "✖ el build falló:" >&2; tail -15 "$T/build.log" >&2; exit 2; }
  npx astro preview --port "$PORT" >"$T/preview.log" 2>&1 & PID=$!
  URL="http://localhost:$PORT/"
  for _ in $(seq 1 40); do curl -fs -o /dev/null "$URL" && break; sleep 0.5; done
  curl -fs -o /dev/null "$URL" || { echo "✖ astro preview no respondió en $URL" >&2; tail -10 "$T/preview.log" >&2; exit 2; }
fi
echo "· midiendo $URL"

run(){ # run <móvil|escritorio> [flags extra]
  local n="$1"; shift
  npx --yes lighthouse "$URL" --quiet --chrome-flags="--headless=new --no-sandbox" --output=json --output-path="$T/$n.json" "$@" >"$T/$n.log" 2>&1 \
    || { echo "✖ Lighthouse falló ($n); ¿hay Chrome/Chromium instalado?" >&2; tail -5 "$T/$n.log" >&2; return 1; }
}
run movil || exit 2
run escritorio --preset=desktop || exit 2

row(){ # row <etiqueta> <expresión jq> <objetivo texto> <test jq sobre $v> [decimales]
  local vm vd okm okd
  vm=$(jq -r "$2" "$T/movil.json"); vd=$(jq -r "$2" "$T/escritorio.json")
  okm=$(jq -n --argjson v "${vm:-null}" "if \$v == null then false else ($4) end" 2>/dev/null); okd=$(jq -n --argjson v "${vd:-null}" "if \$v == null then false else ($4) end" 2>/dev/null)
  mark(){ [ "$1" = "true" ] && printf '%s✔%s' "$G" "$N" || printf '%s✖%s' "$R" "$N"; }
  printf '  %-26s %10s %s   %10s %s   %s%s%s\n' "$1" "${vm:-n/d}" "$(mark "$okm")" "${vd:-n/d}" "$(mark "$okd")" "$D" "$3" "$N"
}
echo; printf '  %-26s %12s     %12s     %s\n' "Métrica" "Móvil" "Escritorio" "Presupuesto"
row "Rendimiento (0-100)"      '(.categories.performance.score*100|round)'      "≥ 90"   '$v >= 90'
row "Accesibilidad (0-100)"    '(.categories.accessibility.score*100|round)'    "≥ 95"   '$v >= 95'
row "Buenas prácticas (0-100)" '(.categories["best-practices"].score*100|round)' "≥ 95"  '$v >= 95'
row "SEO (0-100)"              '(.categories.seo.score*100|round)'              "≥ 95"   '$v >= 95'
row "LCP (s)"                  '(.audits["largest-contentful-paint"].numericValue/100|round/10)' "≤ 2.5" '$v <= 2.5'
row "CLS"                      '(.audits["cumulative-layout-shift"].numericValue*1000|round/1000)' "≤ 0.1" '$v <= 0.1'
row "TBT (ms)"                 '(.audits["total-blocking-time"].numericValue|round)' "≤ 200" '$v <= 200'
row "JS transferido (KB)"      '([.audits["network-requests"].details.items[]? | select(.resourceType=="Script") | .transferSize] | add // 0) / 1024 | round' "≤ ~100" '$v <= 100'
row "Peso total (KB)"          '(.audits["total-byte-weight"].numericValue/1024|round)' "≤ ~1500" '$v <= 1500'

echo; echo "Audits con puntaje < 1 (móvil), los más relevantes:"
jq -r '[.audits[] | select(.score != null and .score < 1 and .scoreDisplayMode != "informative" and .scoreDisplayMode != "notApplicable" and .scoreDisplayMode != "manual")] | sort_by(.score) | .[0:12][] | "  · \(.id) (\(.score)) — \(.title)"' "$T/movil.json"
echo; echo "${D}Lighthouse $(jq -r .lighthouseVersion "$T/movil.json") · $(jq -r '.environment.hostUserAgent' "$T/movil.json" | grep -oE 'Chrome/[0-9.]+' | head -1) · una corrida por perfil (hay varianza; repite si está borderline)${N}"
