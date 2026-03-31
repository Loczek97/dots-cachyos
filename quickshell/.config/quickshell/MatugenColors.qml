import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string colorFilePath: Quickshell.env("HOME") + "/.config/quickshell/config.json"

    // PROPERTIES (ALL CATPPUCCIN AND MATUGEN COLORS)
    property color base: "#000000"
    property color mantle: "#000000"
    property color crust: "#000000"
    property color surface0: "#000000"
    property color surface1: "#000000"
    property color surface2: "#000000"
    property color overlay0: "#000000"
    property color overlay1: "#000000"
    property color overlay2: "#000000"
    property color text: "#000000"
    property color subtext0: "#000000"
    property color subtext1: "#000000"
    property color primary: "#000000"
    property color secondary: "#000000"
    property color tertiary: "#000000"
    property color primaryContainer: "#000000"
    property color secondaryContainer: "#000000"
    property color tertiaryContainer: "#000000"
    property color error: "#000000"
    property color errorContainer: "#000000"
    property color lavender: "#000000"
    property color blue: "#000000"
    property color sapphire: "#000000"
    property color sky: "#000000"
    property color teal: "#000000"
    property color green: "#000000"
    property color yellow: "#000000"
    property color peach: "#000000"
    property color maroon: "#000000"
    property color red: "#000000"
    property color mauve: "#000000"
    property color pink: "#000000"
    property color flamingo: "#000000"
    property color rosewater: "#000000"

    function loadColors() {
        const file = Io.open(colorFilePath);
        if (file) {
            const content = file.read();
            if (content) {
                try {
                    const colors = JSON.parse(content);
                    for (let key in colors) {
                        if (root.hasOwnProperty(key)) {
                            root[key] = colors[key];
                        }
                    }
                } catch (e) {
                    console.warn("MatugenColors: Error parsing config.json", e);
                }
            }
            file.close();
        }
    }

    Component.onCompleted: loadColors()
}
