---
description: "Prepara el proyecto actual para el flujo lp de landing pages: diagnóstico del stack Astro + TS + Tailwind + shadcn, CLAUDE.md con comandos y plugins habilitados por proyecto"
allowed-tools: Bash(bash:*), Bash(claude plugin:*), Read, Write, Edit, Glob, Grep
---

# /mp-lp:init

Prepara el **proyecto activo** (no el entorno de usuario; eso es `/mp-core:doctor`) para el flujo `lp`. Es idempotente: solo completa lo que falta y **nunca sobrescribe** contenido existente. No hace commit, no toca Taiga y **no instala nada**.

## 1. Diagnóstico

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/project-check.sh"
```

Muestra el resumen tal cual. Si todo está en ✔, ve directo al paso 3.

## 2. Propuesta (antes de escribir nada)

Con el diagnóstico y leyendo el repo (`package.json`, `astro.config.*`, `CLAUDE.md`), arma un plan con **solo lo que falta**, di qué archivo se crea o edita y espera la aprobación del usuario. Si algo ya existe, complétalo con `Edit`, nunca con `Write` sobre el archivo.

### a) `CLAUDE.md`
- Si falta, créalo con título y las secciones de abajo; si existe, agrega solo lo que no esté.
- **Comandos:** tipos (`astro check`), build (`astro build`), preview (`astro preview`, puerto 4321 por defecto) y desarrollo (`astro dev`), con el gestor del proyecto (`pnpm`/`npm`/`yarn`, según el lockfile). Propón los que salgan de `package.json` y pide confirmación.
- **Stack y reglas del flujo lp:** una sección corta: Astro + TypeScript estricto + Tailwind; shadcn solo en islas interactivas; las secciones estáticas son `.astro`; el estado del flujo vive en `lp/`.

### b) Plugins por proyecto
La separación de perfiles se hace habilitando plugins **por proyecto**. Propón estos comandos (con aprobación, los ejecutas con Bash desde la raíz del proyecto):

```bash
claude plugin install mp-lp@mp-marketplace --scope project
claude plugin disable mp@mp-marketplace --scope project
```

El primero instala y habilita `mp-lp` (y `mp-core`, su dependencia) solo en este proyecto; el segundo apaga `mp` aquí. Explica por qué: en un landing sobran sus agentes de backend (arquitecto, tester, reviewer). Si prefieres no usar la CLI, el equivalente es fusionar con `jq` en `.claude/settings.json` del proyecto `{ "enabledPlugins": { "mp-core@mp-marketplace": true, "mp-lp@mp-marketplace": true, "mp@mp-marketplace": false } }` sin perder otras claves. Los cambios se ven tras `/reload-plugins`.

### c) Requisitos que solo se reportan
Nunca se resuelven aquí, indica el comando al usuario: `astro` y dependencias (`npx astro add tailwind|react|sitemap`), `components.json` (`npx shadcn@latest init`), `PRODUCT.md` (`/impeccable init`, es una entrevista) y `DESIGN.md` (`/impeccable document`).

## 3. Cierre

Resume qué se completó y qué queda por hacer al usuario. Termina sugiriendo `/mp-lp:lp start` para empezar el primer landing.
