# LWSBackup cron management
read_crontab_without_lws_block() {
    crontab -l 2>/dev/null | awk "/$CRON_MARKER_BEGIN/ {skip=1; next} /$CRON_MARKER_END/ {skip=0; next} skip != 1 {print}"
}

write_crontab_tmp() {
    tmp="$1"
    read_crontab_without_lws_block > "$tmp"
}

install_crontab_from_tmp() {
    tmp="$1"
    if [ ! -s "$tmp" ]; then
        crontab -r 2>/dev/null || true
    else
        crontab "$tmp"
    fi
}

remove_cron_job() {
    tmp="/tmp/lwsbackup_cron.$$"
    write_crontab_tmp "$tmp"
    install_crontab_from_tmp "$tmp"
    rm -f "$tmp"
}

add_cron_job() {
    expr="$1"
    tmp="/tmp/lwsbackup_cron.$$"
    write_crontab_tmp "$tmp"
    {
        echo "$CRON_MARKER_BEGIN"
        echo "$expr /usr/local/sbin/lws-backup --run"
        echo "$CRON_MARKER_END"
    } >> "$tmp"
    install_crontab_from_tmp "$tmp"
    rm -f "$tmp"
}
