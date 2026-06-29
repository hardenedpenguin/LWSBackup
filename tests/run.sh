#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
if ! command -v bats >/dev/null 2>&1; then
    echo "bats is required. Install with: apt-get install bats" >&2
    exit 1
fi
exec bats "$root"
