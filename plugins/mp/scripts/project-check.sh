#!/usr/bin/env bash
# Diagnóstico de PROYECTO para el flujo flow/flow-auto: OpenSpec, CLAUDE.md, reglas de arquitectura y requisitos de UI.
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

echo "Proyecto: $ROOT"

sec "OpenSpec"
have openspec && pass "CLI openspec ($(openspec --version 2>/dev/null))" || wrn "CLI openspec no está instalado" "npm i -g @fission-ai/openspec"
if [ -d openspec ]; then
  pass "openspec/ inicializado"
  [ -d openspec/specs ] && [ -d openspec/changes ] && pass "openspec/specs y openspec/changes" || wrn "faltan openspec/specs u openspec/changes" "openspec init ."
else
  bad "openspec/ no existe" "/mp:init (o openspec init .)"
fi
if [ -f openspec/config.yaml ]; then
  pass "openspec/config.yaml"
  grep -qE '^schema:' openspec/config.yaml && pass "config.yaml declara schema" || wrn "config.yaml sin schema" "agrega 'schema: spec-driven'"
  grep -q 'architecture.md' openspec/config.yaml && pass "config.yaml referencia openspec/architecture.md" || wrn "config.yaml no referencia la arquitectura" "/mp:init lo agrega en context y rules"
else
  [ -d openspec ] && wrn "openspec/config.yaml no existe" "/mp:init lo crea"
fi

sec "CLAUDE.md"
if [ -f CLAUDE.md ]; then
  pass "CLAUDE.md"
  grep -qiE 'test|prueba' CLAUDE.md && pass "menciona comando de pruebas (lo usa 'flow test')" || wrn "no se ve comando de pruebas" "/mp:init propone una sección de comandos"
  grep -q 'architecture.md' CLAUDE.md && pass "apunta a openspec/architecture.md" || wrn "no apunta a la arquitectura" "/mp:init agrega el puntero"
else
  bad "CLAUDE.md no existe" "/mp:init lo crea"
fi

sec "Arquitectura (flow-architect)"
if [ -f openspec/architecture.md ]; then
  pass "openspec/architecture.md"
  grep -qiE 'capa|layer' openspec/architecture.md && pass "declara capas" || wrn "no declara capas" "edítalo o vuelve a correr /mp:init"
else
  wrn "openspec/architecture.md no existe" "/mp:init lo crea; sin él flow-architect infiere y marca suposición"
fi

sec "Requisitos de UI (solo si el proyecto tiene interfaz)"
ui=0
{ [ -f package.json ] && grep -qE '"(react|vue|svelte|next|nuxt|astro|solid-js)"' package.json; } && ui=1
[ -f manifest.json ] && ui=1
if [ "$ui" -eq 1 ]; then
  [ -f PRODUCT.md ] && pass "PRODUCT.md" || wrn "PRODUCT.md falta" "/impeccable init (flow-auto lo exige para UI)"
  [ -f DESIGN.md ] && pass "DESIGN.md" || wrn "DESIGN.md falta (recomendado)" "/impeccable document"
  [ -f components.json ] && pass "components.json (shadcn)" || wrn "components.json falta" "npx shadcn@latest init"
else info "sin señales de UI; se omite"; fi

sec "Señales del repo (para proponer la arquitectura)"
stack=""
[ -f package.json ] && stack="$stack node"
[ -f manifest.json ] && stack="$stack extension"
[ -f pyproject.toml ] || [ -f requirements.txt ] && stack="$stack python"
[ -f go.mod ] && stack="$stack go"
[ -f pom.xml ] || [ -f build.gradle ] || [ -f build.gradle.kts ] && stack="$stack jvm"
[ -f Cargo.toml ] && stack="$stack rust"
info "stack:${stack:- no detectado}"
for d in src app lib packages apps; do
  [ -d "$d" ] && info "$d/: $(find "$d" -maxdepth 2 -mindepth 1 -type d -not -path '*/node_modules/*' -not -path '*/.*' 2>/dev/null | sed "s|^$d/||" | sort | head -15 | tr '\n' ' ')"
done
if [ -f package.json ] && have jq; then
  s=$(jq -r '.scripts // {} | to_entries[] | select(.key|test("^(test|build|lint|format|typecheck|dev)")) | "\(.key)=\(.value)"' package.json 2>/dev/null | head -8 | tr '\n' ';')
  [ -n "$s" ] && info "scripts: $s"
fi

echo
echo "Resumen: ${ok} ok, ${warn} avisos, ${fail} errores"
[ "$fail" -eq 0 ]
