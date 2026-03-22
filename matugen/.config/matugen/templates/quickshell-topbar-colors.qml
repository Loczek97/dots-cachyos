import QtQuick

QtObject {
    // BASE COLORS (backgrounds) – 1:1 z eww-colors.scss
    readonly property color base: "#{{colors.surface.default.hex_stripped}}"
    readonly property color mantle: "#{{colors.surface_dim.default.hex_stripped}}"
    readonly property color crust: "#{{colors.surface_container_lowest.default.hex_stripped}}"

    readonly property color surface0: "#{{colors.surface_container_low.default.hex_stripped}}"
    readonly property color surface1: "#{{colors.surface_container.default.hex_stripped}}"
    readonly property color surface2: "#{{colors.surface_variant.default.hex_stripped}}"

    // OVERLAY COLORS
    readonly property color overlay0: "#{{colors.surface_variant.default.hex_stripped}}"
    readonly property color overlay1: "#{{colors.outline_variant.default.hex_stripped}}"
    readonly property color overlay2: "#{{colors.outline.default.hex_stripped}}"

    // TEXT COLORS
    readonly property color text: "#{{colors.on_surface.default.hex_stripped}}"
    readonly property color subtext0: "#{{colors.outline.default.hex_stripped}}"
    readonly property color subtext1: "#{{colors.on_surface_variant.default.hex_stripped}}"

    // ACCENT COLORS – Catppuccin-style aliasy jak w eww-colors.scss
    readonly property color lavender: "#{{colors.on_surface.default.hex_stripped}}"
    readonly property color blue: "#{{colors.primary.light.hex_stripped}}"
    readonly property color sapphire: "#{{colors.on_primary_container.default.hex_stripped}}"
    readonly property color sky: "#{{colors.tertiary.light.hex_stripped}}"
    readonly property color teal: "#{{colors.on_tertiary_container.default.hex_stripped}}"
    readonly property color green: "#{{colors.on_secondary_container.default.hex_stripped}}"
    readonly property color yellow: "#{{colors.on_primary_container.default.hex_stripped}}"
    readonly property color peach: "#{{colors.on_tertiary_container.default.hex_stripped}}"
    readonly property color maroon: "#{{colors.on_error_container.default.hex_stripped}}"
    readonly property color red: "#{{colors.on_error_container.default.hex_stripped}}"
    readonly property color mauve: "#{{colors.secondary.light.hex_stripped}}"
    readonly property color pink: "#{{colors.tertiary.light.hex_stripped}}"
    readonly property color flamingo: "#{{colors.on_error_container.default.hex_stripped}}"
    readonly property color rosewater: "#{{colors.on_tertiary_container.default.hex_stripped}}"
}
