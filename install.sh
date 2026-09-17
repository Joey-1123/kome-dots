#!/usr/bin/env bash
# kome — installer entry point.
set -euo pipefail

KOME_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "${KOME_ROOT}/install/main.sh" "$@"
