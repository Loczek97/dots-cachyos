# Quickshell Design System

This document defines the visual standards for widgets in this environment. All new widgets must adhere to these patterns to ensure consistency.

## Core Visual Properties

- **Container Radius**: `30` for main popup windows/containers.
- **Component Radius**: `12` for internal elements (buttons, list items, groups).
- **Borders**: 
  - Width: `1`
  - Color: Typically `root.surface0` or a semi-transparent white/gray like `#1affffff`.
- **Backgrounds**: Often semi-transparent, e.g., `#0dffffff` or using `root.base` with opacity.

## Theming Integration

Every widget should use the `MatugenTheme.qml` dynamic loader pattern:

```qml
property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme

Loader {
    id: themeLoader
    source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/MatugenTheme.qml"
}

FileView {
    path: Quickshell.env("HOME") + "/.config/quickshell/MatugenTheme.qml"
    watchChanges: true
    onFileChanged: {
        themeLoader.source = "";
        themeLoader.source = "file://" + Quickshell.env("HOME") + "/.config/quickshell/MatugenTheme.qml?reload=" + Date.now();
    }
}
```

## Typography
- Prefer `font.family: "Eagle Horizon-Personal use"` for large headings (clocks, titles).
- Use `theme.text` or `theme.subtext0` for standard text.
- Standard pixel sizes:
  - Small labels: `12-14`
  - Regular text: `16-18`
  - Large display (clock): `50-90`

## Animation Patterns
- Use `Behavior on opacity` or `Behavior on color` for smooth transitions.
- Common easing: `Easing.InOutQuad` or `Easing.OutExpo` for intros.
