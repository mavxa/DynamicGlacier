# Dynamic Glacier

Dynamic Glacier is an experimental QML/Quickshell dynamic-island style widget for Hyprland.

It is built for people who want a native Linux island surface without Electron, webviews, AGS, EWW, or a JS/HTML/CSS UI stack. The project focuses on a small OLED-friendly black handle that expands only when you hover, click, or when a useful desktop event appears.

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

## Run

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

## Integration Notes

- Use it as a separate Quickshell config while developing: `quickshell --path quickshell`.
- Add it to Hyprland autostart only after the visual behavior works on your monitor layout.
- If you use end-4 dots, keep its existing notification service enabled and use Dynamic Glacier IPC/bridge hooks for notification experiments.
- If end-4 already shows a volume OSD, keep Dynamic Glacier volume feedback subtle. The island should complement that setup, not duplicate it.

## Development

Developer workflow and test commands are in [`docs/development.md`](docs/development.md).

## References

- end-4 dots: https://github.com/end-4/dots-hyprland
- Quickshell docs: https://quickshell.outfoxxed.me/docs/
