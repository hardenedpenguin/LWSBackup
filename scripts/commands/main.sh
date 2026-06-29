# LWSBackup CLI entry helpers
show_version() {
    echo "LWSBackup $VERSION"
}

usage() {
    cat <<EOH
LWSBackup v$VERSION

Usage:
  sudo $0 --install     Install to /LWS_Backup/scripts and create /usr/local/sbin/lws-backup
  sudo $0 --menu        Open dialog/text menu
  sudo $0 --setup       Run first-time setup wizard
  sudo $0 --run         Run backup immediately
  sudo $0 --restore     Restore from latest restore kit using menu prompt
  sudo $0 --version     Show script version
  sudo $0 --help        Show this help

No option opens menu when interactive, or runs backup when non-interactive.

Paths:
  Root:          $LWS_ROOT
  Backups:       $BACKUP_DIR
  Restore kits:  $RESTORE_KIT_DIR
  Logs:          $LOG_DIR
  Config:        $CONFIG_DIR
EOH
}

main() {
    case "$1" in
        --install) install_mode ;;
        --run) run_backup_job ;;
        --setup) first_run_setup ;;
        --menu) main_menu ;;
        --restore) restore_local_menu ;;
        --version|-V) show_version ;;
        --help|-h) usage ;;
        "")
            if [ -t 0 ]; then
                main_menu
            else
                run_backup_job
            fi
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}
