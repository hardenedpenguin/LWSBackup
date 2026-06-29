# LWSBackup dialog and text UI primitives
setup_dialog_theme() {
    [ "$DIALOG_THEME_READY" -eq 1 ] && return 0
    cat > "$DIALOGRC_FILE" <<'EOD'
use_shadow = OFF
use_colors = ON
screen_color = (BLACK,BLACK,OFF)
shadow_color = (BLACK,BLACK,OFF)
dialog_color = (BLACK,WHITE,OFF)
title_color = (RED,WHITE,ON)
border_color = (BLACK,WHITE,OFF)
border2_color = (BLACK,WHITE,OFF)
button_active_color = (WHITE,RED,ON)
button_inactive_color = (BLACK,WHITE,OFF)
button_key_active_color = (WHITE,RED,ON)
button_key_inactive_color = (RED,WHITE,OFF)
button_label_active_color = (WHITE,RED,ON)
button_label_inactive_color = (BLACK,WHITE,OFF)
inputbox_color = (BLACK,WHITE,OFF)
inputbox_border_color = (BLACK,WHITE,OFF)
menubox_color = (BLACK,WHITE,OFF)
menubox_border_color = (BLACK,WHITE,OFF)
item_color = (RED,WHITE,OFF)
item_selected_color = (WHITE,RED,ON)
tag_color = (RED,WHITE,ON)
tag_selected_color = (WHITE,RED,ON)
tag_key_color = (RED,WHITE,ON)
tag_key_selected_color = (WHITE,RED,ON)
check_color = (BLACK,WHITE,OFF)
check_selected_color = (WHITE,RED,ON)
uarrow_color = (RED,WHITE,ON)
darrow_color = (RED,WHITE,ON)
gauge_color = (RED,WHITE,ON)
EOD
    DIALOG_THEME_READY=1
}

init_ui() {
    if [ -z "$DIALOG_BIN" ] && command -v dialog >/dev/null 2>&1; then
        DIALOG_BIN="$(command -v dialog)"
    fi
    if [ -n "$DIALOG_BIN" ]; then
        setup_dialog_theme
        return 0
    fi
    return 1
}

has_dialog() {
    [ -n "$DIALOG_BIN" ] && return 0
    init_ui
}

dialog_cmd() {
    DIALOGRC="$DIALOGRC_FILE" "$DIALOG_BIN" --ascii-lines --no-shadow --colors "$@"
}

msgbox() {
    title="$1"
    text="$2"
    if has_dialog; then
        dialog_cmd --title "$title" --msgbox "$text" 16 76
        clear_screen
    else
        echo
        echo "==== $title ===="
        echo "$text"
        pause_text
    fi
}

yesno() {
    title="$1"
    text="$2"
    if has_dialog; then
        dialog_cmd --title "$title" --yesno "$text" 12 76
        rc=$?
        clear_screen
        return $rc
    fi
    echo
    echo "$title"
    echo "$text"
    printf "Yes or No? [y/N]: "
    read ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

inputbox() {
    title="$1"
    text="$2"
    default="$3"
    if has_dialog; then
        result="$(dialog_cmd --title "$title" --inputbox "$text" 12 76 "$default" 3>&1 1>&2 2>&3)"
        rc=$?
        clear_screen
        [ $rc -eq 0 ] || return 1
        echo "$result"
        return 0
    fi
    echo
    echo "$title"
    printf "%s [%s]: " "$text" "$default"
    read result
    [ -z "$result" ] && result="$default"
    echo "$result"
    return 0
}

passwordbox() {
    title="$1"
    text="$2"
    if has_dialog; then
        result="$(dialog_cmd --title "$title" --passwordbox "$text" 12 76 3>&1 1>&2 2>&3)"
        rc=$?
        clear_screen
        [ $rc -eq 0 ] || return 1
        echo "$result"
        return 0
    fi
    echo
    echo "$title"
    printf "%s: " "$text"
    stty -echo
    read result
    stty echo
    echo
    echo "$result"
    return 0
}
