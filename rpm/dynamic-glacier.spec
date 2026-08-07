# The COPR workflow stamps these values from the exact Git revision being built.
# Keeping a concrete fallback also makes the checked-in spec reproducible by hand.
%global commit     d3487f52f64fb97abf016c1834975be37a3cb9c6
%global shortcommit d3487f5
%global commitdate  20260526000000
%global archive     DynamicGlacier-%{commit}

# The QML tree is data, not compiled code.
%global debug_package %{nil}

Name:           dynamic-glacier
Version:        0
Release:        0.%{commitdate}.%{shortcommit}%{?dist}
Summary:        Dynamic-island style widget for Hyprland, built with QML + Quickshell

License:        MIT
URL:            https://github.com/mavxa/DynamicGlacier
Source0:        %{url}/archive/%{commit}.tar.gz#/%{name}-%{commit}.tar.gz

BuildArch:      noarch

Requires:       quickshell
Requires:       qt6-qtdeclarative
Requires:       qt6-qt5compat
Requires:       playerctl
Requires:       upower
Requires:       psmisc
Requires:       pulseaudio-utils
Requires:       pipewire
Requires:       pipewire-utils
Requires:       NetworkManager
Requires:       NetworkManager-tui
Requires:       bluez
Requires:       fontconfig
Requires:       google-noto-sans-fonts

# Material Symbols has no Fedora package; the widget falls back to blank icon
# glyphs without it. See README.md for the manual font install.
Recommends:     kitty
Recommends:     bluedevil

%description
Dynamic Glacier is a native QML/Quickshell island widget for Hyprland. The idle
state is a small black handle that expands on hover, click, or useful desktop
activity: MPRIS media controls, battery and audio indicators, WiFi and Bluetooth
status, and microphone/camera privacy dots.

It ships no notification daemon and no second volume OSD, so it can run beside
an existing end-4/dots-hyprland setup without fighting it.

%prep
%autosetup -n %{archive}

%build
# Nothing to build: the payload is a QML/Quickshell config tree.

%install
install -dm 755 %{buildroot}%{_datadir}/%{name}
cp -r quickshell %{buildroot}%{_datadir}/%{name}/

install -dm 755 %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/%{name} <<'EOF'
#!/usr/bin/env sh
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
EXEC_LINE="exec-once = dynamic-glacier"
MARKER_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dynamic-glacier/autostart-done"

# First-run autostart registration
if [ ! -f "$MARKER_FILE" ] && [ -d "$HYPR_DIR" ]; then
    target=""
    if [ -f "$HYPR_DIR/custom/execs.conf" ]; then
        target="$HYPR_DIR/custom/execs.conf"
    elif [ -f "$HYPR_DIR/hyprland.conf" ]; then
        target="$HYPR_DIR/hyprland.conf"
    fi

    if [ -n "$target" ] && ! grep -qF "dynamic-glacier" "$target" 2>/dev/null; then
        printf '\n%%s\n' "$EXEC_LINE" >> "$target"
    fi

    mkdir -p "$(dirname "$MARKER_FILE")"
    touch "$MARKER_FILE"
fi

exec quickshell --path /usr/share/dynamic-glacier/quickshell "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md docs/architecture.md docs/development.md
%{_bindir}/%{name}
%{_datadir}/%{name}/

%changelog
* Mon Aug 03 2026 mavxa <mafvacurse@gmail.com> - 0-0.20260803.d3487f5
- Initial Fedora/COPR snapshot package
