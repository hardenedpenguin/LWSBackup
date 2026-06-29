# LWSBackup library bootstrap — sets LWS_SCRIPT_ROOT for sourced modules.
if [ -z "${LWS_SCRIPT_ROOT:-}" ]; then
    LWS_SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
