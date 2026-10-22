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

### b) Apagar `mp` en este proyecto
Si este comando está corriendo, `mp-lp` ya está instalado y habilitado aquí (se instala **antes**, por fuera de claude: `claude plugin install mp-lp@mp-marketplace --scope project`; no puede instalarse a sí mismo). Lo que falta es separar los perfiles: en un landing sobran los agentes de backend de `mp` (arquitecto, tester, reviewer).

Comprueba si `mp` sigue habilitado en el proyecto (`.claude/settings.json` y el de usuario). Si lo está, propón y, con aprobación, ejecuta desde la raíz del proyecto:

```bash
claude plugin disable mp@mp-marketplace --scope project
```

Equivalente sin la CLI: fusionar con `jq` en `.claude/settings.json` del proyecto `{ "enabledPlugins": { "mp@mp-marketplace": false } }` sin perder otras claves. Si el proyecto mezcla app y landing, no lo apagues: pregunta al usuario. Los cambios se ven tras `/reload-plugins`.

### c) Requisitos que solo se reportan
Nunca se resuelven aquí, indica el comando al usuario: `astro` y dependencias (`npx astro add tailwind|react|sitemap`), `components.json` (`npx shadcn@latest init`), `PRODUCT.md` (`/impeccable init`, es una entrevista) y `DESIGN.md` (`/impeccable document`).

## 3. Cierre

Resume qué se completó y qué queda por hacer al usuario. Termina sugiriendo `/mp-lp:lp start` para empezar el primer landing.
