# Quickshell Technical Patterns

## Wayland Protocols & Layer Shell

Widgets in Quickshell use the **wlr-layer-shell** protocol to manage their position relative to other windows.

### Layer Selection (`WlrLayershell.layer`)
- **`WlrLayer.Background`**: Used for wallpapers.
- **`WlrLayer.Bottom`**: Used for desktop widgets like clocks (`DesktopClock.qml`). They sit behind regular windows.
- **`WlrLayer.Top`**: Used for bars (`TopBar.qml`) and panels that should stay above windows but below full-screen overlays.
- **`WlrLayer.Overlay`**: Used for popups, notification centers, or lock screens that must stay on top of everything.

### Exclusivity & Interaction
- **`WlrLayershell.exclusive: true`**: Reserves space on the screen so other windows don't overlap the widget (crucial for Bars).
- **`WlrLayershell.namespace`**: Always set a unique namespace (e.g., `"notifications"`, `"dashboard"`) for debugging and CSS/Hyprland rules.
- **`WlrLayershell.keyboardFocus`**: Set to `WlrKeyboardFocus.None` for passive widgets (clocks) or `WlrKeyboardFocus.Exclusive` for interactive ones (launchers).

## Dynamic Positioning (The DesktopClock Pattern)


Used when a widget needs to be moved without restarting the shell. It relies on a JSON configuration file and `FileView`.

### Implementation:
1. Define a JSON path: `readonly property string posFilePath: Quickshell.env("HOME") + "/path/to/pos.json"`
2. Use a `Process` to `cat` and parse the JSON.
3. Use a `FileView` to trigger the `Process` on file changes.

### JSON Schema for Positioning:
```json
{
  "isRight": false,
  "isBottom": false,
  "anchorLeft": 100,
  "anchorTop": 100,
  "anchorRight": 0,
  "anchorBottom": 0
}
```

## Shell Script Integration
- Use `Process` for executing system commands (e.g., getting battery, network status).
- Use `StdioCollector` to handle stdout and parse data (JSON preferred).

## Notification Integration
- Many widgets use a `NotificationService` or similar to relay system states. Look at `network` or `battery` for examples of service-based architecture.
