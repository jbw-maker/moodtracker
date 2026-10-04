#!/usr/bin/env bash
# Start the Mood Tracker on a local web server and open it in the browser.
# The only dependency is python3 (for its built-in web server).
set -euo pipefail

# Keep the port fixed: browser storage is tied to the address, so changing
# the port would make previously saved entries seem to disappear.
PORT="${MOODTRACKER_PORT:-8765}"
URL="http://localhost:${PORT}/"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required but was not found."
  echo "Install it with your package manager, e.g.:  sudo apt install python3"
  exit 1
fi

if [[ ! -f "$DIR/index.html" ]]; then
  echo "index.html not found in $DIR"
  exit 1
fi

open_browser() {
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$URL"
  else
    echo "Open $URL in your browser."
  fi
}

# Already running (e.g. in another terminal)? Just open the page.
if python3 -c "import socket,sys; s=socket.socket(); s.settimeout(0.5); sys.exit(s.connect_ex(('127.0.0.1', $PORT)))" 2>/dev/null; then
  echo "Mood Tracker is already running at $URL"
  open_browser
  exit 0
fi

echo "Starting Mood Tracker at $URL  (press Ctrl+C to stop)"
# Bind to 127.0.0.1 so the app is only reachable from this computer.
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$DIR" >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null; echo; echo "Stopped."' EXIT
trap 'exit 130' INT TERM

# Wait for the server to come up before opening the browser.
for _ in $(seq 1 20); do
  if python3 -c "import socket,sys; s=socket.socket(); s.settimeout(0.2); sys.exit(s.connect_ex(('127.0.0.1', $PORT)))" 2>/dev/null; then
    open_browser
    break
  fi
  sleep 0.2
done

wait "$SERVER_PID"
