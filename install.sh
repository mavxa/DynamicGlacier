#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Dynamic Glacier"
CONFIG_NAME="DynamicGlacier"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_ROOT/quickshell"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$CONFIG_NAME"
LAUNCHER_PATH="$XDG_BIN_HOME/dynamic-glacier"
HYPR_CONFIG_PATH="$XDG_CONFIG_HOME/hypr/hyprland.conf"
AUTOSTART_START_MARKER="# >>> Dynamic Glacier autostart >>>"
AUTOSTART_END_MARKER="# <<< Dynamic Glacier autostart <<<"
AUTOSTART_LINE="exec-once = $LAUNCHER_PATH"
COPY_MODE=1
SKIP_DEPS=0
AUTOSTART_ENABLED=1
DOCTOR_MODE=0
WARNINGS=()
DOCTOR_FAILURES=0
DOCTOR_WARNINGS=0
AUTOSTART_REGISTERED=0

usage() {
    cat <<EOF
Usage: ./install.sh [options]

Installs $APP_NAME as a named Quickshell config in:
  $CONFIG_DIR

Options:
  --copy       Copy the config into \$XDG_CONFIG_HOME (default).
  --symlink    Symlink the repo's quickshell directory into \$XDG_CONFIG_HOME.
  --skip-deps  Skip package installation and only install the config files.
  --no-autostart
               Do not modify the Hyprland config.
  --hyprland-conf PATH
               Override the Hyprland config path used for autostart and doctor checks.
  --doctor     Run installation checks without changing anything.
  -h, --help   Show this help text.

Examples:
  ./install.sh
  ./install.sh --symlink
  ./install.sh --skip-deps
  ./install.sh --doctor
EOF
}

log() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
    WARNINGS+=("$*")
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
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

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
        return
    fi

    if has_cmd sudo; then
        sudo "$@"
        return
    fi

    die "Root privileges are required to install packages. Re-run with sudo available or use --skip-deps."
}

backup_existing_path() {
    local target="$1"
    local backup

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return
    fi

    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$target" "$backup"
    log "Backed up $target -> $backup"
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

ensure_hyprland_autostart() {
    local temp_file

    if [ "$AUTOSTART_ENABLED" -eq 0 ]; then
        log "Skipping Hyprland autostart registration"
        return
    fi

    if [ ! -f "$HYPR_CONFIG_PATH" ]; then
        warn "Hyprland config not found at $HYPR_CONFIG_PATH. Add this line manually: $AUTOSTART_LINE"
        return
    fi

    if grep -Fqx "$AUTOSTART_LINE" "$HYPR_CONFIG_PATH"; then
        AUTOSTART_REGISTERED=1
        log "Hyprland autostart already points to $LAUNCHER_PATH"
        return
    fi

    if grep -Fq "$AUTOSTART_START_MARKER" "$HYPR_CONFIG_PATH"; then
        temp_file="$(mktemp)"
        strip_managed_autostart_block "$HYPR_CONFIG_PATH" "$temp_file"
        mv "$temp_file" "$HYPR_CONFIG_PATH"
    fi

    {
        printf '\n%s\n' "$AUTOSTART_START_MARKER"
        printf '%s\n' "$AUTOSTART_LINE"
        printf '%s\n' "$AUTOSTART_END_MARKER"
    } >> "$HYPR_CONFIG_PATH"

    AUTOSTART_REGISTERED=1
    log "Registered Hyprland autostart in $HYPR_CONFIG_PATH"
}

install_with_apt() {
    local packages=(
        fontconfig
        fonts-noto-core
        playerctl
        psmisc
        pulseaudio-utils
        upower
    )

    log "Installing runtime packages with apt"
    run_as_root apt-get update
    run_as_root apt-get install -y "${packages[@]}"

    if ! has_cmd quickshell; then
        warn "Quickshell is not installed. The official Quickshell docs currently document Arch, Fedora, Guix, Nix, and manual build paths."
    fi
}

install_with_dnf() {
    local packages=(
        fontconfig
        google-noto-sans-fonts
        playerctl
        psmisc
        pulseaudio-utils
        quickshell
        upower
    )

    log "Enabling the official Quickshell COPR for Fedora"
    run_as_root dnf -y copr enable errornointernet/quickshell
    log "Installing runtime packages with dnf"
    run_as_root dnf install -y "${packages[@]}"
}

install_with_pacman() {
    local packages=(
        fontconfig
        libpulse
        noto-fonts
        playerctl
        psmisc
        upower
    )

    log "Installing runtime packages from the main Arch repositories"
    run_as_root pacman -S --needed --noconfirm "${packages[@]}"

    if has_cmd quickshell; then
        return
    fi

    if has_cmd yay; then
        log "Installing Quickshell from the AUR with yay"
        yay -S --needed --noconfirm quickshell
        return
    fi

    if has_cmd paru; then
        log "Installing Quickshell from the AUR with paru"
        paru -S --needed --noconfirm quickshell
        return
    fi

    warn "Quickshell is not installed. Install quickshell from the AUR with yay/paru, or install it manually from the official Quickshell docs."
}

install_dependencies() {
    if [ "$SKIP_DEPS" -eq 1 ]; then
        log "Skipping dependency installation"
        return
    fi

    if has_cmd pacman; then
        install_with_pacman
    elif has_cmd dnf; then
        install_with_dnf
    elif has_cmd apt-get; then
        install_with_apt
    else
        warn "No supported package manager detected. Install Quickshell, Noto Sans, UPower, playerctl, pactl, and fuser manually."
    fi

    if has_cmd fc-cache; then
        log "Refreshing the font cache"
        fc-cache -f >/dev/null 2>&1 || warn "Failed to refresh the font cache automatically"
    fi
}

install_config() {
    mkdir -p "$(dirname "$CONFIG_DIR")" "$XDG_BIN_HOME"

    if [ "$COPY_MODE" -eq 1 ]; then
        backup_existing_path "$CONFIG_DIR"
        cp -R "$SOURCE_DIR" "$CONFIG_DIR"
        log "Copied config to $CONFIG_DIR"
        return
    fi

    if [ -L "$CONFIG_DIR" ] && [ "$(readlink "$CONFIG_DIR")" = "$SOURCE_DIR" ]; then
        log "Symlink already points to $SOURCE_DIR"
        return
    fi

    backup_existing_path "$CONFIG_DIR"
    ln -s "$SOURCE_DIR" "$CONFIG_DIR"
    log "Symlinked config to $CONFIG_DIR"
}

install_launcher() {
    cat > "$LAUNCHER_PATH" <<EOF
#!/usr/bin/env sh
exec quickshell --config $CONFIG_NAME "\$@"
EOF
    chmod +x "$LAUNCHER_PATH"
    log "Installed launcher to $LAUNCHER_PATH"
}

doctor_ok() {
    printf '[ok]   %s\n' "$1"
}

doctor_warn() {
    printf '[warn] %s\n' "$1"
    DOCTOR_WARNINGS=$((DOCTOR_WARNINGS + 1))
}

doctor_fail() {
    printf '[fail] %s\n' "$1"
    DOCTOR_FAILURES=$((DOCTOR_FAILURES + 1))
}

run_doctor() {
    printf '%s doctor\n\n' "$APP_NAME"

    if has_cmd quickshell; then
        doctor_ok "quickshell is available"
    else
        doctor_fail "quickshell is missing from PATH"
    fi

    if [ -x "$LAUNCHER_PATH" ]; then
        doctor_ok "launcher exists at $LAUNCHER_PATH"
    else
        doctor_fail "launcher is missing at $LAUNCHER_PATH"
    fi

    if [ -f "$CONFIG_DIR/shell.qml" ]; then
        doctor_ok "installed config exists at $CONFIG_DIR"
    else
        doctor_fail "installed config is missing at $CONFIG_DIR"
    fi

    if has_cmd fc-match; then
        if fc-match "Noto Sans" 2>/dev/null | grep -qi 'NotoSans'; then
            doctor_ok "Noto Sans is available through fontconfig"
        else
            doctor_warn "Noto Sans is missing; the widget will fall back to another sans font"
        fi
    else
        doctor_warn "fc-match is missing; cannot verify fonts"
    fi

    for helper in playerctl upower pactl fuser; do
        if has_cmd "$helper"; then
            doctor_ok "$helper is available"
        else
            doctor_warn "$helper is missing; related widget features will be limited"
        fi
    done

    if [ -f "$HYPR_CONFIG_PATH" ]; then
        if grep -Fqx "$AUTOSTART_LINE" "$HYPR_CONFIG_PATH" || grep -Fq "$AUTOSTART_START_MARKER" "$HYPR_CONFIG_PATH"; then
            doctor_ok "Hyprland autostart is registered in $HYPR_CONFIG_PATH"
        else
            doctor_warn "Hyprland autostart is not registered in $HYPR_CONFIG_PATH"
        fi
    else
        doctor_warn "Hyprland config not found at $HYPR_CONFIG_PATH"
    fi

    printf '\n'

    if [ "$DOCTOR_FAILURES" -gt 0 ]; then
        printf 'Doctor result: FAIL\n'
        return 1
    fi

    if [ "$DOCTOR_WARNINGS" -gt 0 ]; then
        printf 'Doctor result: OK with warnings\n'
        return 0
    fi

    printf 'Doctor result: OK\n'
}

print_summary() {
    printf '\n'
    log "$APP_NAME install complete"
    printf 'Config path: %s\n' "$CONFIG_DIR"
    printf 'Launcher:    %s\n' "$LAUNCHER_PATH"
    printf '\n'
    printf 'Run now:\n'
    printf '  %s\n' "$LAUNCHER_PATH"
    printf '\n'
    if [ "$AUTOSTART_ENABLED" -eq 0 ]; then
        printf 'Hyprland autostart:\n'
        printf '  skipped (--no-autostart)\n'
        printf '\n'
    elif [ "$AUTOSTART_REGISTERED" -eq 1 ]; then
        printf 'Hyprland autostart:\n'
        printf '  %s\n' "$AUTOSTART_LINE"
        printf '  file: %s\n' "$HYPR_CONFIG_PATH"
        printf '\n'
    else
        printf 'Hyprland autostart:\n'
        printf '  not registered automatically\n'
        printf '  expected file: %s\n' "$HYPR_CONFIG_PATH"
        printf '\n'
    fi

    if ! has_cmd quickshell; then
        warn "quickshell is still missing, so the widget cannot start yet."
    fi

    if has_cmd fc-match && ! fc-match "Noto Sans" 2>/dev/null | grep -qi 'NotoSans'; then
        warn "Noto Sans is not available in fontconfig. The widget will fall back to another sans font."
    fi

    if [ "${#WARNINGS[@]}" -gt 0 ]; then
        printf 'Warnings:\n'
        for warning in "${WARNINGS[@]}"; do
            printf '  - %s\n' "$warning"
        done
        printf '\n'
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --copy)
            COPY_MODE=1
            ;;
        --symlink)
            COPY_MODE=0
            ;;
        --skip-deps)
            SKIP_DEPS=1
            ;;
        --no-autostart)
            AUTOSTART_ENABLED=0
            ;;
        --hyprland-conf)
            shift
            [ "$#" -gt 0 ] || die "--hyprland-conf requires a path"
            HYPR_CONFIG_PATH="$(expand_path "$1")"
            ;;
        --hyprland-conf=*)
            HYPR_CONFIG_PATH="$(expand_path "${1#*=}")"
            ;;
        --doctor)
            DOCTOR_MODE=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            die "Unknown option: $1"
            ;;
    esac
    shift
done

AUTOSTART_LINE="exec-once = $LAUNCHER_PATH"

if [ "$DOCTOR_MODE" -eq 1 ]; then
    run_doctor
    exit $?
fi

if [ ! -f "$SOURCE_DIR/shell.qml" ]; then
    die "Could not find quickshell/shell.qml. Run this script from the repository root."
fi

install_dependencies
install_config
install_launcher
ensure_hyprland_autostart
print_summary

if ! has_cmd quickshell; then
    exit 1
fi
