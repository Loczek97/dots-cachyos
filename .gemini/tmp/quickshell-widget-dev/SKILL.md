---
name: quickshell-widget-dev
description: Develops and maintains Quickshell widgets consistent with the system's design language. Use when creating new widgets, refactoring existing ones, or ensuring UI consistency across the Quickshell environment.
---

# Quickshell Widget Developer

This skill enables you to create and maintain Quickshell widgets that seamlessly blend into the existing desktop environment. It requires expert knowledge of **Wayland protocols**, specifically **Layer Shell**, to ensure correct window stacking and interaction.

## Workflow

1. **Research Phase**:
   - Reference `references/design-system.md` for visual constants (radii, colors, fonts).
   - Reference `references/patterns.md` for technical implementations (Wayland layers, dynamic positioning, theme reloading).

2. **Architectural Decisions**:
   - Select the appropriate **Wayland Layer**: `Bottom` for desktop elements, `Top` for bars, `Overlay` for interactive popups.
   - Determine if the widget needs **exclusive space** or **keyboard focus**.

2. **Creation Phase**:
   - Use `assets/BaseWidget.qml` as a starting point for any new widget.
   - Ensure `MatugenTheme.qml` is properly integrated for dynamic coloring.

3. **Validation**:
   - Check if the `radius` values match (30 for containers, 12 for inner elements).
   - Verify that colors are pulled from the `theme` object, not hardcoded.

## Common Tasks

### Creating a New Popup Widget
- Copy `assets/BaseWidget.qml`.
- Adjust `implicitWidth` and `implicitHeight`.
- Add functionality using `Process` or `Quickshell.Io` modules if needed.

### Implementing Dynamic Positioning
- Follow the pattern in `references/patterns.md`.
- Ensure a `.json` file exists in the widget's directory to store coordinates.
