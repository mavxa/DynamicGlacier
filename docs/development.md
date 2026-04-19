# Developer Notes

This project is a standalone Quickshell config while the widget is still being shaped. Keep it runnable next to an existing end-4 dots setup.

## Start The Widget

Run from the repository root:

```sh
quickshell --path quickshell
```

For a short smoke test that exits automatically:

```sh
timeout 5 quickshell --path quickshell --verbose
```

Expected successful load:

```text
INFO: Configuration Loaded
```

Quickshell reloads when QML files change, so keep this process open while editing.

Idle behavior:

- the default shape is a small pure-black bump at the top center
- it reserves only a small constant top zone through layer-shell
- hover expansion can overlap windows; this avoids Hyprland pushing windows down on every hover
- the visible strip can be very thin, but the idle hitbox remains as tall as the reserved zone
- top corners are sharp because the shape is attached to the screen edge
- bottom corners are rounded because the visible bump grows downward
- hover the bump to expand it temporarily
- click the bump to pin or unpin the expanded idle state
- click while an event state is visible to collapse back to idle

## Trigger Test States

Run these in another terminal from the repository root:

```sh
quickshell ipc --path quickshell show
```

The output should include `target dynamicGlacier`.

Manual state triggers:

```sh
quickshell ipc --path quickshell call dynamicGlacier demo
quickshell ipc --path quickshell call dynamicGlacier notify "Build finished" "Dynamic Glacier is alive" "Codex"
quickshell ipc --path quickshell call dynamicGlacier media "Night Drive" "Glacier FM" true
quickshell ipc --path quickshell call dynamicGlacier volume 72 false
quickshell ipc --path quickshell call dynamicGlacier handle bump
quickshell ipc --path quickshell call dynamicGlacier handle strip
quickshell ipc --path quickshell call dynamicGlacier toggleHandle
quickshell ipc --path quickshell call dynamicGlacier idle
```

Looping demo:

```sh
quickshell ipc --path quickshell call dynamicGlacier demoLoop
```

Run `demoLoop` again to stop the loop.

## Inspect And Stop Instances

List this config's instances:

```sh
quickshell list --path quickshell
```

List every Quickshell instance, including end-4's shell:

```sh
quickshell list --all
```

Follow logs for this config:

```sh
quickshell log --path quickshell --follow
```

Stop only this config:

```sh
quickshell kill --path quickshell
```

Do not kill all Quickshell instances unless you intentionally want to stop the main end-4 shell too.

## Where To Change Things

- `quickshell/shell.qml`: root entrypoint. Keep this small.
- `quickshell/modules/dynamicGlacier/DynamicGlacier.qml`: state machine, timers, window placement, IPC API.
- `quickshell/modules/dynamicGlacier/IslandSurface.qml`: outer shape, glow, background, animation of shell geometry.
- `quickshell/modules/dynamicGlacier/IslandContent.qml`: per-mode content layout for idle, notification, media, and volume.
- `docs/architecture.md`: bigger design decisions and integration notes.

If a change affects runtime behavior, test it with `timeout 5 quickshell --path quickshell --verbose` and at least one IPC command.

## Development Rules

- Do not create repo-local `AGENTS.md`; project memory belongs in `/home/mavxa/zed/agents/`.
- Keep the prototype standalone until integration points are clear.
- Do not add `NotificationServer` by default yet. It can conflict with the existing end-4 notification daemon.
- Do not depend on JS/HTML/CSS, Electron, webviews, AGS, or EWW for the main UI.
- Prefer a small runnable QML slice over speculative architecture.
- Keep state changes centralized in `DynamicGlacier.qml`; services should request mode transitions, not resize the island directly.
- Keep the visual identity minimal, OLED-friendly, and distinct from Apple's Dynamic Island.
- Default visuals should be pure black first; add visible decoration only when it materially improves interaction clarity.
- Keep the island in normal `WlrLayer.Top` with `ExclusionMode.Normal`, but keep `exclusiveZone` constant and small.
- Do not bind `exclusiveZone` to expanded island height; that makes Hyprland push windows down during hover.
- Keep the attached-top silhouette: sharp top corners, rounded bottom corners.

## Common Failure Modes

`No running instances for ".../quickshell/shell.qml"` means the widget process is not running or already exited. Start it again with `quickshell --path quickshell`.

`IpcHandler is not a type` usually means `DynamicGlacier.qml` is missing `import Quickshell.Io`.

`Module path contains invalid characters` means a QML import directory probably contains a hyphen. Keep the module directory named `dynamicGlacier`, not `dynamic-glacier`.

If the island does not appear but logs say `Configuration Loaded`, check whether it is hidden behind another layer or on the focused monitor. Current placement follows `Hyprland.focusedMonitor` and falls back to the first Quickshell screen.

If tiled windows move too much on hover, check `DynamicGlacier.qml` first. `exclusiveZone` should be `root.reservedZone`, not `implicitHeight`.

If the idle handle is too hard to find, test strip mode:

```sh
quickshell ipc --path quickshell call dynamicGlacier handle strip
```

If a gap appears between the island and the top screen edge, check `expandedTopMargin` in `DynamicGlacier.qml`. It should stay `0`; the island should grow downward from the top edge.

If text looks clipped or deformed, check `IslandSurface.qml` z-ordering. Background shape rectangles should stay below `IslandContent`.

## Next Useful Tests

- Run with the main end-4 shell active and verify there is no notification daemon conflict.
- Test on each monitor by focusing a window there before starting the widget.
- Test long notification and media strings for clipping and layout jumps.
- Test volume values `0`, `1`, `50`, `100`, and muted state.
- Keep an eye on animation feel after each visual change; aggressive motion will get annoying quickly.
