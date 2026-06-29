# LWSBackup dependency installation
ensure_command() {
    cmd="$1"
    pkg="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    echo "$cmd is missing. Attempting to install package: $pkg"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y "$pkg"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$pkg"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$pkg"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "$pkg"
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install "$pkg"
    else
        fail_exit "No supported package manager found. Install $cmd manually."
    fi
    command -v "$cmd" >/dev/null 2>&1 || fail_exit "Installation failed for $cmd."
}

ensure_command_optional() {
    cmd="$1"
    pkg="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    echo "$cmd is missing. Attempting to install package: $pkg"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y "$pkg" >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$pkg" >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$pkg" >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "$pkg" >/dev/null 2>&1
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install "$pkg" >/dev/null 2>&1
    else
        echo "No supported package manager found. Install $cmd manually."
        return 1
    fi
    command -v "$cmd" >/dev/null 2>&1
}

check_commands_core() {
    ensure_command zip zip
    ensure_command unzip unzip
    ensure_command sha256sum coreutils
}

check_commands_optional() {
    load_config
    if [ "$FTP_ENABLED" = "yes" ]; then
        ensure_command curl curl
    fi
}

install_cron_if_missing() {
    command -v crontab >/dev/null 2>&1 && return 0
    if command -v apt-get >/dev/null 2>&1; then
        ensure_command crontab cron
    else
        ensure_command crontab cronie
    fi
}
