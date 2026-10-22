---
argument-hint: "[plugin ...]  (sin argumentos: todos los plugins con cambios)"
description: "Versiona un repo marketplace con varios plugins: sube cada plugin que cambió (SemVer), escribe su CHANGELOG, la versión del repo y la tabla de versiones, y propone los tags"
allowed-tools: Bash(bash:*), Bash(git:*), Bash(jq:*), Read, Write, Edit, Glob, Grep
---

# /mp-core:marketplace-release

Esquema de **dos niveles** para un repo con varios plugins (`.claude-plugin/marketplace.json`):

1. **Cada plugin** tiene su SemVer en `plugins/<p>/.claude-plugin/plugin.json`, su `CHANGELOG.md` y su tag `<plugin>-v<x.y.z>`. Claude Code usa esta versión para detectar actualizaciones.
2. **El repo** tiene un SemVer en `marketplace.json` → `metadata.version`, un tag `v<x.y.z>` y una entrada en el `CHANGELOG.md` raíz con la **tabla de qué versión de cada plugin iba junta**. Es la trazabilidad general.

Para proyectos normales (una app, un solo paquete) usa `/mp-core:release`; este comando es solo para repos marketplace. No hace push ni commit sin que lo confirmes.

## 1. Estado

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/release-status.sh"
```

Muestra el resultado tal cual. Si el árbol tiene cambios sin commitear, avísalo y detente: el release se hace sobre commits. Si `$ARGUMENTS` nombra plugins, limita el release a esos; si no, a los que tengan commits desde su último tag (o todos, si no hay tags todavía).

## 2. Propuesta de versiones (antes de escribir nada)

Por cada plugin del alcance, con `git log <tag>..HEAD -- plugins/<p>` (sin tag: todo su historial):

- Bump sugerido: **major** si hay `!:` o `BREAKING` (también si cambió o se quitó un comando, skill o agente público, o una dependencia incompatible); **minor** si hay `feat` o un componente nuevo; **patch** si son correcciones, docs o refactors internos.
- Si el plugin nunca tuvo tag, su versión actual en `plugin.json` es la base: no la subas si todavía no fue publicada; solo comprueba que su CHANGELOG la tenga.
- Si un plugin sube de major, revisa los que lo declaran en `dependencies` y dilo.

Versión del repo: el **mayor** de los bumps de plugin (major / minor / patch). Primera vez sin `metadata.version`: propón `2.0.0` solo si el repo ya traía una línea 1.x; si no, `1.0.0`.

Presenta una tabla `plugin · actual → nueva · motivo (commits clave)` y la versión del repo. **Espera aprobación o ajustes.**

## 3. Escribir (tras aprobar)

Para cada plugin con versión nueva:
- `plugin.json` → `version`.
- `plugins/<p>/CHANGELOG.md`: sección nueva arriba, `## [x.y.z] - AAAA-MM-DD`, con las categorías de keepachangelog (Added / Changed / Deprecated / Removed / Fixed / Security) a partir de los commits que tocan su carpeta, mismo mapeo que `/mp-core:changelog`, entradas `- descripción (hash)` en prosa de usuario, sin secciones vacías. Si el archivo no existe, créalo con el encabezado `# Changelog — <plugin>`.

Para el repo:
- `marketplace.json` → `metadata.version`.
- `CHANGELOG.md` raíz: sección nueva arriba, `## [x.y.z] - AAAA-MM-DD`, con un párrafo de qué trae el conjunto y la tabla:

```
| Plugin | Versión | Cambio |
|---|---|---|
| mp-core | 1.1.0 | minor — … |
| mp | 2.0.0 | sin cambios |
```

  Incluye **todos** los plugins (también los que no cambiaron, con su versión vigente): así cada versión del repo es una instantánea completa.

Corre `bash bootstrap/validate-plugins.sh` (comprueba que versiones, CHANGELOG y `metadata.version` coinciden) y muestra el diff.

## 4. Commit y tags (confirmación explícita)

Pregunta antes de cada paso; ninguno es automático:
1. Commit de los cambios de versión (`/mp-core:commit-changes` / convención del repo, sin firma de Claude).
2. Tags **anotados** sobre ese commit, uno por plugin que subió y uno del repo:
   `git tag -a <plugin>-v<x.y.z> -m "<plugin> <x.y.z>"` y `git tag -a v<x.y.z> -m "<repo> <x.y.z>"`.
3. Push de la rama y de los tags (`git push origin <rama> --follow-tags` o los tags por nombre). Solo si el usuario lo pide.
4. Opcional: `gh release create v<x.y.z>` con la sección del CHANGELOG raíz como notas.

Los tags se ponen en el commit que quedará en `main`: si el release va por PR, etiqueta **después del merge** (sobre el commit de `main`), no antes.

## Reglas

- Nunca subas la versión de un plugin sin cambios propios.
- Nunca reescribas ni muevas un tag ya publicado; si hubo un error, publica un patch.
- No inventes entradas: salen de los commits. Si un commit no deja claro el efecto para el usuario, pregunta.
- Una versión del repo no se reutiliza ni se reordena: el historial de versiones es solo hacia adelante.
