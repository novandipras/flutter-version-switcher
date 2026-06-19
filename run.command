#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

bash "$SCRIPT_DIR/flutter-switcher.sh"
exit_code=$?

# Jika launcher dibuka melalui Finder/Terminal.app, tutup jendelanya setelah selesai.
if [ "${TERM_PROGRAM:-}" = "Apple_Terminal" ]; then
  osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1 &
fi

exit "$exit_code"
