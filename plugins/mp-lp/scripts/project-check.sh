#!/usr/bin/env bash
# Diagnóstico de PROYECTO para el flujo lp (landing pages): Astro + TypeScript + Tailwind + shadcn, SEO base y herramientas de auditoría.
# Solo lectura. Uso: project-check.sh [ruta-del-proyecto]. Exit 1 si falta algo obligatorio (✖).
set -uo pipefail
ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" 2>/dev/null || { echo "✖ no existe la ruta $ROOT"; exit 1; }
ok=0; warn=0; fail=0
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; N=$'\e[0m'
pass(){ echo "  ${G}✔${N} $1"; ok=$((ok+1)); }
wrn(){ echo "  ${Y}⚠${N} $1${2:+ ${D}→ $2${N}}"; warn=$((warn+1)); }
bad(){ echo "  ${R}✖${N} $1${2:+ ${D}→ $2${N}}"; fail=$((fail+1)); }
info(){ echo "  ${D}·${N} $1"; }
sec(){ echo; echo "$1"; }
have(){ command -v "$1" >/dev/null 2>&1; }
dep(){ [ -f package.json ] && jq -e --arg d "$1" '(.dependencies // {}) + (.devDependencies // {}) | has($d)' package.json >/dev/null 2>&1; }

echo "Proyecto: $ROOT"

sec "Stack (Astro + TypeScript + Tailwind)"
if [ -f package.json ]; then
  pass "package.json"
  dep astro && pass "astro ($(jq -r '(.dependencies.astro // .devDependencies.astro)' package.json))" || bad "astro no está en package.json" "el flujo lp asume Astro (npm create astro@latest)"
  dep typescript && pass "typescript" || wrn "typescript no está en package.json" "npm i -D typescript@6 (astro check aún no soporta TypeScript 7)"
  dep @astrojs/check && pass "@astrojs/check (astro check)" || wrn "falta @astrojs/check" "npm i -D @astrojs/check; lo usan los agentes para compilar tipos"
  { dep tailwindcss || dep @tailwindcss/vite; } && pass "tailwindcss" || bad "tailwindcss no está en package.json" "npx astro add tailwind"
  dep @astrojs/sitemap && pass "@astrojs/sitemap" || wrn "falta @astrojs/sitemap" "npx astro add sitemap (lo configura lp-seo)"
  dep @astrojs/react && pass "@astrojs/react (islas de shadcn)" || wrn "falta @astrojs/react" "npx astro add react; shadcn lo necesita para componentes interactivos"
else bad "package.json no existe" "no es un proyecto Node; crea uno con npm create astro@latest"; fi
[ -f tsconfig.json ] && { grep -qE 'astro/tsconfigs/(strict|strictest)' tsconfig.json && pass "tsconfig extiende astro/tsconfigs/strict" || wrn "tsconfig sin astro/tsconfigs/strict" "el flujo lp trabaja con TypeScript estricto"; } || wrn "tsconfig.json no existe"
ac=$(ls astro.config.* 2>/dev/null | head -1)
if [ -n "$ac" ]; then
  pass "$ac"
  grep -qE '\bsite\s*:' "$ac" && pass "astro.config define site (canonical, sitemap, OG)" || wrn "astro.config sin 'site'" "lp-seo lo necesita para canonical y sitemap; pregúntalo al usuario"
else wrn "astro.config.* no existe"; fi

sec "shadcn y diseño"
[ -f components.json ] && pass "components.json (shadcn)" || wrn "components.json no existe" "npx shadcn@latest init (lo decide el usuario; solo hace falta si habrá componentes interactivos)"
[ -f PRODUCT.md ] && pass "PRODUCT.md" || wrn "PRODUCT.md no existe" "/impeccable init (entrevista con el usuario); no bloquea el brief; ui-designer lo exige antes de la dirección"
[ -f DESIGN.md ] && pass "DESIGN.md" || wrn "DESIGN.md no existe" "/impeccable document (recomendado una vez exista UI)"

sec "CLAUDE.md"
if [ -f CLAUDE.md ]; then
  pass "CLAUDE.md"
  grep -qiE 'check|astro check|compile' CLAUDE.md && pass "menciona comando de chequeo de tipos" || wrn "no se ve comando de chequeo de tipos" "/mp-lp:init lo agrega"
  grep -qiE 'build' CLAUDE.md && pass "menciona comando de build" || wrn "no se ve comando de build" "/mp-lp:init lo agrega"
else bad "CLAUDE.md no existe" "/mp-lp:init lo crea"; fi

sec "Herramientas de auditoría"
have node && pass "node $(node -v)" || bad "node no está instalado"
have npx && pass "npx" || bad "npx no está instalado"
chrome=""
for c in google-chrome chromium chromium-browser chrome; do have "$c" && { chrome="$c"; break; }; done
[ -z "$chrome" ] && [ -d "/Applications/Google Chrome.app" ] && chrome="Google Chrome.app"
[ -n "$chrome" ] && pass "Chrome/Chromium ($chrome), lo usa Lighthouse" || wrn "no se encontró Chrome ni Chromium" "lp-qa necesita uno para Lighthouse"
have ffmpeg && pass "ffmpeg (video)" || info "ffmpeg no está instalado; solo lo necesita lp-media si hay video"
dep sharp && pass "sharp" || info "sharp no está como dependencia directa (Astro lo trae para astro:assets)"

sec "Flujo lp"
if [ -d lp ]; then
  pass "lp/ existe"
  [ -f lp/state.json ] && jq -e . lp/state.json >/dev/null 2>&1 && info "estado: fase $(jq -r '.phase // "?"' lp/state.json), Taiga $(jq -r 'if .taiga.enabled then "sí" else "no" end' lp/state.json)" || wrn "lp/state.json ausente o inválido" "/mp-lp:lp start lo crea"
else info "lp/ no existe todavía: /mp-lp:lp start lo crea"; fi

echo; echo "Resumen: ${G}$ok ok${N} · ${Y}$warn avisos${N} · ${R}$fail errores${N}"
[ "$fail" -eq 0 ]
