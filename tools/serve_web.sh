#!/usr/bin/env bash
# Serves build/web on your Wi-Fi so a phone can open it. Prints the URL.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/tools/serve.py"
