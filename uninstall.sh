#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Dynamic Glacier"
CONFIG_NAME="DynamicGlacier"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$CONFIG_NAME"
LAUNCHER_PATH="$XDG_BIN_HOME/dynamic-glacier"
HYPR_CONFIG_PATH="$XDG_CONFIG_HOME/hypr/hyprland.conf"
AUTOSTART_START_MARKER="# >>> Dynamic Glacier autostart >>>"
AUTOSTART_END_MARKER="# <<< Dynamic Glacier autostart <<<"
AUTOSTART_LINE="exec-once = $LAUNCHER_PATH"
ASSUME_YES=0

usage() {
    cat <<EOF
Usage: ./uninstall.sh [options]

Removes $APP_NAME from:
  $CONFIG_DIR
  $LAUNCHER_PATH

Options:
  --yes               Skip the confirmation prompt.
  --hyprland-conf PATH
                      Override the Hyprland config path used for autostart cleanup.
  -h, --help          Show this help text.

Examples:
  ./uninstall.sh
  ./uninstall.sh --yes
EOF
}

log() {
    printf '==> %s\n' "$*"
}

expand_path() {
    case "$1" in
        "~")
            printf '%s\n' "$HOME"
            ;;
        "~/"*)
            printf '%s/%s\n' "$HOME" "${1#~/}"
            ;;
        *)
            printf '%s\n' "$1"
            ;;
    esac
}

strip_managed_autostart_block() {
    local input_file="$1"
    local output_file="$2"

    awk -v start="$AUTOSTART_START_MARKER" -v end="$AUTOSTART_END_MARKER" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$input_file" > "$output_file"
}

confirm() {
    local reply

    if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
        return
    fi

    printf 'Remove %s config, launcher, and Hyprland autostart entry? [y/N] ' "$APP_NAME"
    read -r reply

    case "$reply" in
        y|Y|yes|YES)
            ;;
        *)
            printf 'Aborted.\n'
            exit 1
            ;;
    esac
}

remove_config() {
    if [ -e "$CONFIG_DIR" ] || [ -L "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        log "Removed $CONFIG_DIR"
        return
    fi

    log "Config not present at $CONFIG_DIR"
}

remove_launcher() {
    if [ -e "$LAUNCHER_PATH" ] || [ -L "$LAUNCHER_PATH" ]; then
        rm -f "$LAUNCHER_PATH"
        log "Removed $LAUNCHER_PATH"
        return
    fi

    log "Launcher not present at $LAUNCHER_PATH"
}

remove_hyprland_autostart() {
    local temp_file

    if [ ! -f "$HYPR_CONFIG_PATH" ]; then
        log "Hyprland config not found at $HYPR_CONFIG_PATH"
        return
    fi

    if grep -Fq "$AUTOSTART_START_MARKER" "$HYPR_CONFIG_PATH"; then
        temp_file="$(mktemp)"
        strip_managed_autostart_block "$HYPR_CONFIG_PATH" "$temp_file"
        mv "$temp_file" "$HYPR_CONFIG_PATH"
        log "Removed managed Hyprland autostart block from $HYPR_CONFIG_PATH"
        return
    fi

    if grep -Fqx "$AUTOSTART_LINE" "$HYPR_CONFIG_PATH"; then
        temp_file="$(mktemp)"
        grep -Fvx "$AUTOSTART_LINE" "$HYPR_CONFIG_PATH" > "$temp_file" || true
        mv "$temp_file" "$HYPR_CONFIG_PATH"
        log "Removed Hyprland autostart line from $HYPR_CONFIG_PATH"
        return
    fi

    log "No Dynamic Glacier autostart entry found in $HYPR_CONFIG_PATH"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --yes)
            ASSUME_YES=1
            ;;
        --hyprland-conf)
            shift
            [ "$#" -gt 0 ] || {
                printf 'error: --hyprland-conf requires a path\n' >&2
                exit 1
            }
            HYPR_CONFIG_PATH="$(expand_path "$1")"
            ;;
        --hyprland-conf=*)
            HYPR_CONFIG_PATH="$(expand_path "${1#*=}")"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            printf 'error: Unknown option: %s\n' "$1" >&2
            exit 1
            ;;
    esac
    shift
done

AUTOSTART_LINE="exec-once = $LAUNCHER_PATH"

confirm
remove_config
remove_launcher
remove_hyprland_autostart

printf '\n'
log "$APP_NAME uninstall complete"
