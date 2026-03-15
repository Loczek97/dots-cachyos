import QtQuick

QtObject {
    // ============================================
    // BASE COLORS (backgrounds)
    // ============================================
    readonly property color base: "#191114"
    readonly property color mantle: "#191114"
    readonly property color crust: "#130c0f"
    
    readonly property color surface0: "#21191c"
    readonly property color surface1: "#261d20"
    readonly property color surface2: "#504348"
    
    // ============================================
    // OVERLAY COLORS
    // ============================================
    readonly property color overlay0: "#504348"
    readonly property color overlay1: "#504348"
    readonly property color overlay2: "#9d8c91"
    
    // ============================================
    // TEXT COLORS
    // ============================================
    readonly property color text: "#eedfe2"
    readonly property color subtext0: "#9d8c91"
    readonly property color subtext1: "#d5c2c7"
    
    // ============================================
    // ACCENT COLORS (from wallpaper!)
    // ============================================
    readonly property color primary: "#ffb0cf"
    readonly property color secondary: "#e1bdc9"
    readonly property color tertiary: "#f1bb97"
    
    readonly property color primaryContainer: "#6e334e"
    readonly property color secondaryContainer: "#593f49"
    readonly property color tertiaryContainer: "#633e23"
    
    readonly property color error: "#ffb4ab"
    readonly property color errorContainer: "#93000a"
    
    // ============================================
    // CATPPUCCIN-STYLE ALIASES
    // Using .light variants for better contrast on dark backgrounds
    // ============================================
    readonly property color lavender: "#eedfe2"
    readonly property color blue: "#8a4a66"
    readonly property color sapphire: "#ffd8e5"
    readonly property color sky: "#7e5538"
    readonly property color teal: "#ffdcc5"
    readonly property color green: "#fed9e5"
    readonly property color yellow: "#ffd8e5"
    readonly property color peach: "#ffdcc5"
    readonly property color maroon: "#ffdad6"
    readonly property color red: "#ffdad6"
    readonly property color mauve: "#735761"
    readonly property color pink: "#7e5538"
    readonly property color flamingo: "#ffdad6"
    readonly property color rosewater: "#ffdcc5"
}
