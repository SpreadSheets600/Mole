#!/bin/bash
# Mole - Clean command entrypoint (Linux/WSL).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/clean-linux.sh" "$@"
