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
- `volume`

Transient modes use a collapse timer and return to `idle`. Later service adapters should not resize the island directly. They should request a mode transition through the central controller.

## Service Strategy

The prototype exposes manual IPC commands through `IpcHandler` and also listens to non-owning live desktop services.

Current live adapters:

- MPRIS media changes
- PipeWire default sink volume/mute changes
- UPower battery state/threshold changes

Adapters still to add:

- PipeWire privacy indicators for microphone and screen sharing
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
- The attached-to-top shape should have sharp top corners and rounded bottom corners.
- Avoid generic glassmorphism, glow-heavy effects, and decorative color by default.
- Animate size, radius, content opacity, and progress together.
- Do not let long text cause layout jumps.
