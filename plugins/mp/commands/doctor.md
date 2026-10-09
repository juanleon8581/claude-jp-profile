---
description: "Diagnostica el perfil mp: requisitos, secretos, settings, MCPs, plugins recomendados y duplicados locales"
allowed-tools: Bash(bash:*)
---

# /mp:doctor

Ejecuta el diagnóstico (solo lectura, no imprime valores de secretos):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh"
```

Después:
1. Muestra el resumen tal cual (✔ ok, ⚠ aviso, ✖ error).
2. Agrupa los ✖ y ⚠ por causa y da los comandos exactos para corregirlos, en orden.
3. No modifiques nada sin que el usuario lo pida. Si falta algo que `bootstrap/setup.sh` resuelve, propón correrlo.
4. Los MCP (Taiga y Context7) se leen del registro de claude (`~/.claude.json`, o `$CLAUDE_CONFIG_DIR/.claude.json`), no del entorno ni de ningún `.env`. Si falta algo, la solución es re-ejecutar `bootstrap/setup.sh`.
