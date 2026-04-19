# Dynamic Glacier

Dynamic Glacier is an experimental QML/Quickshell island widget for Hyprland.

The goal is a native Linux desktop "dynamic island" style surface that feels at home in end-4 style dotfiles without using Electron, webviews, AGS, EWW, or JS/HTML/CSS as the main UI stack.

The main design philosophy is minimalism: the idle widget should be a small pure-black bump at the top of the screen. On OLED displays it should feel almost invisible until hover, click, or an event expands it.

## Status

Early prototype. The first slice is a standalone Quickshell config with a polished animated shell and manual IPC triggers. Real notification/media/audio service adapters are intentionally not enabled yet, so the prototype can run next to an existing end-4 setup without taking over the notification daemon.

## Run

From the repo root:

```sh
quickshell --path quickshell
```

In another terminal, trigger states:

```sh
quickshell ipc --path quickshell call dynamicGlacier demo
quickshell ipc --path quickshell call dynamicGlacier notify "Build finished" "Dynamic Glacier is alive" "Hello"
quickshell ipc --path quickshell call dynamicGlacier media "Night Drive" "Glacier FM" true
quickshell ipc --path quickshell call dynamicGlacier volume 72 false
quickshell ipc --path quickshell call dynamicGlacier toggleHandle
quickshell ipc --path quickshell call dynamicGlacier idle
```

Toggle the looping demo:

```sh
quickshell ipc --path quickshell call dynamicGlacier demoLoop
```

## Current Scope

- top-center Wayland layer-shell panel
- constant small Hyprland reserved zone for the idle handle
- hover expansion can overlap windows without pushing them down
- pure-black OLED-friendly idle bump
- test switch between `bump` and barely visible `strip` handle
- sharp top corners and rounded bottom corners
- hover-to-peek and click-to-pin interaction
- animated idle, notification, media, and volume states
- focused-monitor placement under Hyprland
- transparent click mask around the island
- IPC functions for manual testing

## Development

Developer workflow and test commands are in [`docs/development.md`](docs/development.md).

## Next Milestones

- add a clean config surface for size, colors, timing, and monitor behavior
- connect MPRIS media state
- connect PipeWire volume state
- decide how to integrate notifications without fighting the end-4 notification service
- document end-4 installation options

## References

- end-4 dots: https://github.com/end-4/dots-hyprland
- Quickshell docs: https://quickshell.outfoxxed.me/docs/
