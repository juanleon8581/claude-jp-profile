#!/usr/bin/env bash
# PreToolUse(Bash): bloquea `git commit` cuyo mensaje lleve firmas de Claude.
# exit 2 = bloquear y devolver el motivo a Claude por stderr.
set -uo pipefail
command -v jq >/dev/null || exit 0

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# solo comandos que contengan `git ... commit` (incluye `git -C dir commit`)
echo "$cmd" | grep -qE '(^|[;&|(]|\s)git(\s+-[^ ]+(\s+[^ -][^ ]*)?)*\s+commit(\s|$)' || exit 0

text="$cmd"
# mensaje desde archivo: -F <file> / --file[=]<file>
file=$(echo "$cmd" | sed -nE 's/.*(-F|--file)[= ]+([^ ]+).*/\2/p' | head -1 | tr -d "\"'")
[ -n "$file" ] && [ -f "$file" ] && text="$text"$'\n'"$(cat "$file")"

blocked=()
chk() { echo "$text" | grep -qiE "$1" && blocked+=("$2"); return 0; }
chk 'co-authored-by:[^"]*claude'      'Co-Authored-By: Claude'
chk 'claude-session:'                 'Claude-Session:'
chk 'generated with \[?claude code'   'Generated with Claude Code'
chk '🤖'                              'emoji 🤖'

if [ "${#blocked[@]}" -gt 0 ]; then
  {
    echo "✖ Commit bloqueado: las firmas de Claude no están permitidas (${blocked[*]})."
    echo "Quita esas líneas del mensaje y vuelve a ejecutar el commit (ver commit-convention: Golden Rule)."
  } >&2
  exit 2
fi
exit 0
