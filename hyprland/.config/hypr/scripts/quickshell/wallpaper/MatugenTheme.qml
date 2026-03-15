import QtQuick

QtObject {
    // ============================================
    // BASE COLORS (backgrounds)
    // ============================================
    readonly property color base: "#17130b"
    readonly property color mantle: "#17130b"
    readonly property color crust: "#120e07"
    
    readonly property color surface0: "#201b13"
    readonly property color surface1: "#241f17"
    readonly property color surface2: "#4e4639"
    
    // ============================================
    // OVERLAY COLORS
    // ============================================
    readonly property color overlay0: "#4e4639"
    readonly property color overlay1: "#4e4639"
    readonly property color overlay2: "#9a8f80"
    
    // ============================================
    // TEXT COLORS
    // ============================================
    readonly property color text: "#ebe1d4"
    readonly property color subtext0: "#9a8f80"
    readonly property color subtext1: "#d1c5b4"
    
    // ============================================
    // ACCENT COLORS (from wallpaper!)
    // ============================================
    readonly property color primary: "#ecc06c"
    readonly property color secondary: "#d9c4a0"
    readonly property color tertiary: "#b2cfa8"
    
    readonly property color primaryContainer: "#5d4200"
    readonly property color secondaryContainer: "#53452a"
    readonly property color tertiaryContainer: "#344d2f"
    
    readonly property color error: "#ffb4ab"
    readonly property color errorContainer: "#93000a"
    
    // ============================================
    // CATPPUCCIN-STYLE ALIASES
    // Using .light variants for better contrast on dark backgrounds
    // ============================================
    readonly property color lavender: "#ebe1d4"
    readonly property color blue: "#79590c"
    readonly property color sapphire: "#ffdea4"
    readonly property color sky: "#4c6545"
    readonly property color teal: "#cdebc2"
    readonly property color green: "#f6e0bb"
    readonly property color yellow: "#ffdea4"
    readonly property color peach: "#cdebc2"
    readonly property color maroon: "#ffdad6"
    readonly property color red: "#ffdad6"
    readonly property color mauve: "#6c5c3f"
    readonly property color pink: "#4c6545"
    readonly property color flamingo: "#ffdad6"
    readonly property color rosewater: "#cdebc2"
}
