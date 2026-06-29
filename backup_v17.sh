#!/bin/bash
# Development/repo wrapper — runs the modular LWSBackup entrypoint.
exec "$(cd "$(dirname "$0")" && pwd)/scripts/lws-backup" "$@"
