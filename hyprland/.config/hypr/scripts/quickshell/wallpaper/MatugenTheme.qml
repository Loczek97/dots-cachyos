import QtQuick

QtObject {
    // ============================================
    // BASE COLORS (backgrounds)
    // ============================================
    readonly property color base: "#111318"
    readonly property color mantle: "#111318"
    readonly property color crust: "#0c0e13"
    
    readonly property color surface0: "#191c20"
    readonly property color surface1: "#1d2024"
    readonly property color surface2: "#43474e"
    
    // ============================================
    // OVERLAY COLORS
    // ============================================
    readonly property color overlay0: "#43474e"
    readonly property color overlay1: "#43474e"
    readonly property color overlay2: "#8d9199"
    
    // ============================================
    // TEXT COLORS
    // ============================================
    readonly property color text: "#e1e2e8"
    readonly property color subtext0: "#8d9199"
    readonly property color subtext1: "#c3c6cf"
    
    // ============================================
    // ACCENT COLORS (from wallpaper!)
    // ============================================
    readonly property color primary: "#a4c9fe"
    readonly property color secondary: "#bcc7db"
    readonly property color tertiary: "#d9bde3"
    
    readonly property color primaryContainer: "#1f4876"
    readonly property color secondaryContainer: "#3c4758"
    readonly property color tertiaryContainer: "#543f5e"
    
    readonly property color error: "#ffb4ab"
    readonly property color errorContainer: "#93000a"
    
    // ============================================
    // CATPPUCCIN-STYLE ALIASES
    // Using .light variants for better contrast on dark backgrounds
    // ============================================
    readonly property color lavender: "#e1e2e8"
    readonly property color blue: "#3a608f"
    readonly property color sapphire: "#d3e3ff"
    readonly property color sky: "#6d5677"
    readonly property color teal: "#f5d9ff"
    readonly property color green: "#d8e3f8"
    readonly property color yellow: "#d3e3ff"
    readonly property color peach: "#f5d9ff"
    readonly property color maroon: "#ffdad6"
    readonly property color red: "#ffdad6"
    readonly property color mauve: "#545f70"
    readonly property color pink: "#6d5677"
    readonly property color flamingo: "#ffdad6"
    readonly property color rosewater: "#f5d9ff"
}
