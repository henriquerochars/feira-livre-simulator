#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -n "${GODOT_BIN:-}" ]; then
  BIN="$GODOT_BIN"
elif [ -x "$ROOT/.tools/Godot.app/Contents/MacOS/Godot" ]; then
  BIN="$ROOT/.tools/Godot.app/Contents/MacOS/Godot"
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
  BIN=/Applications/Godot.app/Contents/MacOS/Godot
elif command -v godot >/dev/null 2>&1; then
  BIN=$(command -v godot)
elif command -v godot4 >/dev/null 2>&1; then
  BIN=$(command -v godot4)
else
  echo "Godot 4 não encontrado. Instale Godot ou defina GODOT_BIN." >&2
  exit 1
fi
exec "$BIN" --path "$ROOT" "$@"
