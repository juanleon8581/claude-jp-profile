---
description: "Audita SEO, rendimiento, accesibilidad y medios de un landing Astro ya existente, sin correr el flujo completo (solo lectura)"
allowed-tools: Bash, Read, Grep, Glob, Agent
---

# /mp-lp:audit

Auditoría independiente del flujo `lp`: sirve para un landing existente o para revisar uno a medio construir. **Solo lectura**: no corrige nada, no hace git y no llama a Taiga. Argumentos opcionales: `$ARGUMENTS` (una URL ya publicada o en marcha; si se omite se audita el build local).

## 1. Precondición

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/project-check.sh"
```

Si hay ✖, muéstralos y detente. No instales nada.

## 2. Preparar el objetivo

- Si `$ARGUMENTS` trae una URL, úsala como objetivo.
- Si no: corre el build del proyecto (comando de `CLAUDE.md`, por defecto `astro build`). Si falla, repórtalo y detente. Levanta `astro preview` **en segundo plano** (puerto 4321 por defecto) y espera a que responda. Al terminar, detén ese proceso.
- Audita siempre un build de producción (`preview`), nunca `astro dev`: los números de rendimiento del servidor de desarrollo no valen.

## 3. Auditar (en paralelo)

En el mismo mensaje:
- `Agent(subagent_type: "mp-lp:lp-seo")` en modo `audit`, con la URL o ruta de `dist/` (no debe editar nada).
- Las métricas, con el script (Lighthouse móvil y escritorio contra los presupuestos): `bash "${CLAUDE_PLUGIN_ROOT}/scripts/measure.sh" --url <objetivo>`. Si ya levantaste `astro preview` en el paso 2, pásale esa URL; el script no lo levanta si le das `--url`.

## 4. Informe

Une el informe de SEO y las métricas en una sola tabla por severidad (bloqueante / importante / sugerencia) con ubicación, problema y arreglo propuesto. Indica qué **no se pudo verificar**. Cierra proponiendo, si el usuario quiere corregir, empezar el flujo con `/mp-lp:lp start`.
