# Architecture

Dynamic Glacier starts as a standalone Quickshell config. The first design goal is to make the visual state machine reliable before binding it to live desktop services.

## Runtime Shape

```text
quickshell/shell.qml
  DynamicGlacier.qml
    PanelWindow
      IslandSurface.qml
        IslandContent.qml
```

## State Model

The island has one active mode at a time:

- `idle`
- `notify`
- `media`

Transient modes use a collapse timer and return to `idle`. Later service adapters should not resize the island directly. They should request a mode transition through the central controller.

Volume is not a mode. It is a temporary overlay controlled by `volumeIndicatorVisible`, so the widget does not duplicate the existing end-4 volume OSD.

There is also a visual-only hover override: when the real mode is `idle` and a MPRIS player has active media, the surface can render the `media` layout on hover without committing the controller mode to `media`. Live track changes update cached media fields but must not expand the island by themselves.

## Service Strategy

The prototype exposes manual IPC commands through `IpcHandler` and also listens to non-owning live desktop services.

Current live adapters:

- MPRIS media changes
- PipeWire default sink volume/mute changes
- PipeWire link groups plus small shell fallbacks for microphone/video privacy activity
- UPower battery state/threshold changes

Volume is intentionally not a full expanded island mode while end-4's OSD is active. It should be a quiet open U-shaped trace just inside the current island perimeter, with no top connection.

Privacy is also not a full mode. It renders one small green status dot to the right of the island when microphone or camera activity is detected. The dot disappears during hover and must not animate its position back into place.

Media controls are direct MPRIS actions on the active player:

- previous
- play/pause
- next
- progress from player position/length
- absolute seek by setting player position from the progress bar

Adapters still to add:

- Hyprland workspace/window adapter
- notification adapter or end-4 integration hook

Notifications need special care because only one notification server should own `org.freedesktop.Notifications`. A standalone Dynamic Glacier notification server can conflict with end-4 dots if both are running. Prefer an end-4 module integration path or a passive bridge before enabling a standalone notification daemon by default.

## Visual Rules

- Keep the island visually distinct from Apple's Dynamic Island.
- The primary design principle is minimalism.
- Idle state should be a small pure-black bump attached to the top-center area.
- On OLED displays the idle state should look almost invisible until the user hovers, clicks, or an event arrives.
- The island should reserve only a small constant top space in Hyprland for the idle handle.
- Hover expansion may overlap windows; do not let Hyprland push windows down on every hover.
- Hover chrome should stay tiny and live inside the island content: use it for bump/strip controls and battery charge only, not for a full settings panel.
- The bump/strip switch should be reused in idle and media layouts through the same text-style control.
- The layer-shell mask must include the island and privacy dot while the dot is visible; privacy dots intentionally disappear during hover.
- The attached-to-top shape should keep sharp top corners at the screen edge and use a capped lower radius, not `height / 2`, so large media sizes do not become over-rounded.
- Volume indication should follow the lower/sides shape just inside the edge. It must not draw a top line or form a closed loop.
- Avoid generic glassmorphism, glow-heavy effects, and decorative color by default.
- Animate size, radius, content opacity, and progress together.
- Do not let long text cause layout jumps.
