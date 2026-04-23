# Dynamic Glacier

Dynamic Glacier is an experimental QML/Quickshell dynamic-island style widget for Hyprland.

It is built for people who want a native Linux island surface without Electron, webviews, AGS, EWW, or a JS/HTML/CSS UI stack. The project focuses on a small OLED-friendly black handle that expands only when you hover, click, or when a useful desktop event appears.

## What it looks like

<img width="1918" height="1198" alt="privacy" src="https://github.com/user-attachments/assets/fcf5b5ba-191a-44bc-99b0-56d352f4ddce" />
<img width="1918" height="1198" alt="playerHover" src="https://github.com/user-attachments/assets/e310a109-2ee7-45ce-8a28-3c1b6b02524a" />
<img width="1918" height="1198" alt="player" src="https://github.com/user-attachments/assets/551736ff-dfba-46b5-952a-58a7ce3fc64c" />
<img width="1918" height="1198" alt="indleHover" src="https://github.com/user-attachments/assets/815159de-281e-4252-920a-d6d6bd41be0e" />
<img width="1918" height="1198" alt="idle" src="https://github.com/user-attachments/assets/950bb078-0058-49fd-896d-9f01fe634323" />


## end-4 Friendly

Dynamic Glacier is designed to run nicely next to [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland).

The current prototype deliberately avoids owning global desktop services that end-4 already handles well. For example, it does not register a standalone notification daemon by default, and volume feedback is only a subtle trace around the island instead of a second full volume OSD.

The goal is to be an optional companion widget for end-4 style Hyprland setups: minimal, black, Quickshell-native, and easy to wire into an existing dotfiles tree.

## Status

Early prototype. Dynamic Glacier currently ships as a standalone Quickshell config with animated island states, manual IPC triggers, and live links for MPRIS media, PipeWire volume/privacy state, and UPower battery data.

Notifications are intentionally bridge/IPC-first for now. A direct notification server may be added later, but it should not fight existing notification services in end-4 based setups.

## Features

- Pure-black top-center island for Hyprland.
- Small constant reserved zone so normal windows do not jump around.
- Hover expansion may overlap windows instead of resizing the layout.
- OLED-friendly idle handle with `bump` and barely visible `strip` modes.
- Compact media player for MPRIS players with artwork, timeline, seek, previous, play/pause, and next.
- Subtle open U-shaped volume trace instead of a duplicate volume mixer.
- Battery text on hover through UPower.
- Microphone/camera privacy dot through PipeWire plus small local fallbacks.
- Focused-monitor placement under Hyprland.
- IPC commands for manual testing and integration scripts.

## Install

Dynamic Glacier is distributed as a named Quickshell config, which matches the official Quickshell distribution guidance for dotfile-style shells.

1. Download the repository:

```sh
git clone https://github.com/mavxa/DynamicGlacier.git
cd DynamicGlacier
```

2. Run the installer:

```sh
bash install.sh
```

What the installer does:

- installs runtime dependencies on supported distros
- refreshes the font cache so `Noto Sans` is available
- installs the config into `~/.config/quickshell/DynamicGlacier`
- installs a launcher into `~/.local/bin/dynamic-glacier`
- registers `exec-once = ~/.local/bin/dynamic-glacier` in `~/.config/hypr/hyprland.conf` when that file exists

Supported dependency setup:

- Arch Linux: installs main runtime packages with `pacman`, then installs `quickshell` from the AUR via `yay` or `paru` if available
- Fedora: enables the official `errornointernet/quickshell` COPR and installs `quickshell` plus runtime packages with `dnf`
- Debian/Ubuntu: installs runtime packages, but Quickshell still needs to be installed manually because the official Quickshell docs do not currently document an apt package path

Installer options:

```sh
bash install.sh --symlink
bash install.sh --skip-deps
bash install.sh --doctor
```

- `--symlink`: use a symlink to the repo instead of copying files into `~/.config`
- `--skip-deps`: only install the config and launcher
- `--no-autostart`: do not modify the Hyprland config
- `--hyprland-conf /path/to/hyprland.conf`: use a non-default Hyprland config file
- `--doctor`: verify that Quickshell, the installed config, fonts, helper tools, and Hyprland autostart are in place

If your distro is not covered by the script, install Quickshell first from the official docs, then run:

```sh
bash install.sh --skip-deps
```

Official references:

- Quickshell install/setup: https://quickshell.outfoxxed.me/docs/guide/install-setup/
- Quickshell distribution paths: https://quickshell.outfoxxed.me/docs/guide/distribution/

## Run

After installation:

```sh
~/.local/bin/dynamic-glacier
```

By default the installer appends an `exec-once` entry to `~/.config/hypr/hyprland.conf`. If you use a different Hyprland config path, pass it during install:

```sh
bash install.sh --hyprland-conf /path/to/hyprland.conf
```

## Run From The Repo

From the repo root:

```sh
quickshell --path quickshell
```

Trigger states from another terminal:

```sh
quickshell ipc --path quickshell call dynamicGlacier demo
quickshell ipc --path quickshell call dynamicGlacier notify "Build finished" "Dynamic Glacier is alive" "Hello"
quickshell ipc --path quickshell call dynamicGlacier media "Night Drive" "Glacier FM" true ""
quickshell ipc --path quickshell call dynamicGlacier volume 72 false
quickshell ipc --path quickshell call dynamicGlacier toggleHandle
quickshell ipc --path quickshell call dynamicGlacier live true
quickshell ipc --path quickshell call dynamicGlacier idle
```

Toggle the looping demo:

```sh
quickshell ipc --path quickshell call dynamicGlacier demoLoop
```

## Verify The Install

Run the doctor mode:

```sh
bash install.sh --doctor
```

It checks `quickshell`, the installed config, launcher, `Noto Sans`, helper commands (`playerctl`, `upower`, `pactl`, `fuser`), and whether the Hyprland autostart entry is present.

## Uninstall

To remove the installed config, launcher, and managed Hyprland autostart entry:

```sh
bash uninstall.sh
```

For non-interactive removal:

```sh
bash uninstall.sh --yes
```

If you use a non-default Hyprland config path, pass it here too:

```sh
bash uninstall.sh --hyprland-conf /path/to/hyprland.conf
```

## Integration Notes

- Use it as a separate Quickshell config while developing: `quickshell --path quickshell`.
- If you want to test manually before enabling autostart, install with `bash install.sh --no-autostart` and add autostart later.
- If you use end-4 dots, keep its existing notification service enabled and use Dynamic Glacier IPC/bridge hooks for notification experiments.
- If end-4 already shows a volume OSD, keep Dynamic Glacier volume feedback subtle. The island should complement that setup, not duplicate it.

## Development

Developer workflow and test commands are in [`docs/development.md`](docs/development.md).

## References

- end-4 dots: https://github.com/end-4/dots-hyprland
- Quickshell docs: https://quickshell.outfoxxed.me/docs/
