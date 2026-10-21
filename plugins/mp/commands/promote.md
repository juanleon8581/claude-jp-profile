---
description: "Promueve a un Pull Request los cambios hechos en caliente en skills/agentes/comandos del plugin mp, para que lleguen a todos tus equipos"
allowed-tools: Bash(bash:*), Read, Write
---

# /mp:promote

Toma los cambios que hiciste en caliente sobre la copia instalada del plugin (`~/.claude/plugins/cache/mp-marketplace/mp/<ver>/`) y los lleva al repo **vía Pull Request**. Nunca hace push a `main`, no sube la versión del plugin (eso se hace con `/mp:release` al hacer merge) y no toca el clon del marketplace (trabaja en un worktree temporal).

Argumentos opcionales: `$ARGUMENTS` (descripción corta del cambio, útil para el nombre de rama y el título).

## 1. Detectar

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/promote.sh" scan
```

Compara la caché contra la base instalada (`gitCommitSha`) y contra `origin/main`. La salida es `estado<TAB>marca<TAB>ruta`:
- Estado: `M` modificado, `A` nuevo, `D` borrado localmente.
- Marca `ok`: solo cambió tu copia. Marca `CONFLICTO`: `main` también cambió ese archivo desde tu base.

Si no hay cambios, termina. Los archivos que `main` ya tiene idénticos, o que no cambiaste, no aparecen.

## 2. Revisar y elegir

Para cada archivo muestra el diff:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/promote.sh" diff <ruta>
```

Resume en una línea qué cambió y por qué (infiérelo del diff). Presenta la lista y pide al usuario qué archivos promover; solo lo aceptado entra. Reglas:
- `CONFLICTO`: explícalo con ambos diffs y recomienda `reconciliar` o `omitir`. Si el usuario decide promoverlo, tu versión sobrescribirá la de `main`: ofrece primero fusionar a mano (aplicar los dos cambios en el archivo de la caché con `Edit`) y repetir el scan.
- `D`: confirma que el borrado es intencional (puede ser limpieza de la caché y no un cambio deseado).
- Si `main` va por delante de la base (lo indica el encabezado del scan), avísalo: tras el merge, los equipos reciben todo junto.

## 3. Abrir el PR

Con la selección aprobada, arma:
- **Rama**: `promote/<slug-corto>-<YYYYMMDD>`.
- **Título**: convención de commit con emoji (ver skill `commit-convention`), sin firmas de Claude. Ej.: `✨ feat: flow-coder valida tasks.md antes de escribir`.
- **Body** en un archivo temporal (Write en el scratchpad): resumen, lista de archivos con el motivo de cada uno y, si los hay, los `CONFLICTO` resueltos y cómo. Nada de firmas ni "Generated with".

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/promote.sh" open "<rama>" "<título>" "<body-file>" <ruta> [<ruta>...]
```

El script crea el worktree desde `origin/main`, copia los archivos, commitea, hace push (o fork si no hay permiso de escritura) y abre el PR con `gh`.

## 4. Cierre

Muestra la URL del PR. Recuerda al usuario:
- Tras el merge: `/mp:release` (o subir `plugin.json` a mano) para versionar, y luego `/plugin marketplace update mp-marketplace` más update del plugin en cada equipo.
- No hagas merge ni subas la versión por tu cuenta.
