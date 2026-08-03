#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Dynamic Glacier"
CONFIG_NAME="DynamicGlacier"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$CONFIG_NAME"
LAUNCHER_PATH="$XDG_BIN_HOME/dynamic-glacier"
HYPR_CONFIG_DIR="$XDG_CONFIG_HOME/hypr"
HYPR_CONFIG_PATH="$HYPR_CONFIG_DIR/hyprland.conf"
HYPR_CONFIG_EXPLICIT=0
AUTOSTART_START_MARKER="# >>> Dynamic Glacier autostart >>>"
AUTOSTART_END_MARKER="# <<< Dynamic Glacier autostart <<<"
AUTOSTART_LINE="exec-once = $LAUNCHER_PATH"
PACKAGE_AUTOSTART_LINE="exec-once = dynamic-glacier"
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
                      Without it, both ~/.config/hypr/custom/execs.conf (end-4 dots
                      layout) and ~/.config/hypr/hyprland.conf are cleaned.
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

autostart_candidates() {
    if [ "$HYPR_CONFIG_EXPLICIT" -eq 1 ]; then
        printf '%s\n' "$HYPR_CONFIG_PATH"
        return
    fi

    printf '%s\n' "$HYPR_CONFIG_DIR/custom/execs.conf" "$HYPR_CONFIG_PATH"
}

clean_autostart_file() {
    local target="$1"
    local temp_file
    local cleaned=0

    if grep -Fq "$AUTOSTART_START_MARKER" "$target"; then
        temp_file="$(mktemp)"
        strip_managed_autostart_block "$target" "$temp_file"
        mv "$temp_file" "$target"
        log "Removed managed Hyprland autostart block from $target"
        cleaned=1
    fi

    # Bare lines written by the packaged launcher or by install.sh before markers existed.
    if grep -Fqx "$AUTOSTART_LINE" "$target" || grep -Fqx "$PACKAGE_AUTOSTART_LINE" "$target"; then
        temp_file="$(mktemp)"
        grep -Fvx "$AUTOSTART_LINE" "$target" | grep -Fvx "$PACKAGE_AUTOSTART_LINE" > "$temp_file" || true
        mv "$temp_file" "$target"
        log "Removed Hyprland autostart line from $target"
        cleaned=1
    fi

    return $((1 - cleaned))
}

remove_hyprland_autostart() {
    local target
    local found=0
    local cleaned=0

    while IFS= read -r target; do
        [ -f "$target" ] || continue
        found=1
        if clean_autostart_file "$target"; then
            cleaned=1
        fi
    done <<EOF
$(autostart_candidates)
EOF

    if [ "$found" -eq 0 ]; then
        log "Hyprland config not found at $HYPR_CONFIG_PATH"
        return
    fi

    if [ "$cleaned" -eq 0 ]; then
        log "No Dynamic Glacier autostart entry found"
    fi
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
            HYPR_CONFIG_EXPLICIT=1
            ;;
        --hyprland-conf=*)
            HYPR_CONFIG_PATH="$(expand_path "${1#*=}")"
            HYPR_CONFIG_EXPLICIT=1
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
