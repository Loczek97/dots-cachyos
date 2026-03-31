import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // PROPERTIES
    property color base: "#000000"; property color mantle: "#000000"; property color crust: "#000000"
    property color surface0: "#000000"; property color surface1: "#000000"; property color surface2: "#000000"
    property color overlay0: "#000000"; property color overlay1: "#000000"; property color overlay2: "#000000"
    property color text: "#000000"; property color subtext0: "#000000"; property color subtext1: "#000000"
    property color primary: "#000000"; property color secondary: "#000000"; property color tertiary: "#000000"
    property color primaryContainer: "#000000"; property color secondaryContainer: "#000000"; property color tertiaryContainer: "#000000"
    property color error: "#000000"; property color errorContainer: "#000000"
    property color lavender: "#000000"; property color blue: "#000000"; property color sapphire: "#000000"
    property color sky: "#000000"; property color teal: "#000000"; property color green: "#000000"
    property color yellow: "#000000"; property color peach: "#000000"; property color maroon: "#000000"
    property color red: "#000000"; property color mauve: "#000000"; property color pink: "#000000"
    property color flamingo: "#000000"; property color rosewater: "#000000"

    property string rawJson: ""
    readonly property string colorFilePath: Quickshell.env("HOME") + "/.config/quickshell/config.json"

    Process {
        id: themeReader
        command: ["cat", root.colorFilePath]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && txt !== root.rawJson) {
                    root.rawJson = txt;
                    try {
                        let c = JSON.parse(txt);
                        // Safe assignment for every property
                        for (let key in c) {
                            if (key in root) {
                                root[key] = c[key];
                            }
                        }
                    } catch(e) {
                        console.warn("MatugenColors: Error parsing config.json", e);
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: themeReader.running = true
    }
}
