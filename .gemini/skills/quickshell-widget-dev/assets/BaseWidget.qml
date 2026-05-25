import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    // --- Theming ---
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

    QtObject {
        id: dummyTheme
        property color text: "#ffffff"
        property color base: "#1e1e2e"
        property color surface0: "#313244"
        property color primary: "#cba6f7"
    }
    // --- End Theming ---

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-widget"
    color: "transparent"
    
    implicitWidth: 300
    implicitHeight: 200

    Rectangle {
        anchors.fill: parent
        radius: 30
        color: root.theme.base
        opacity: 0.9
        border.color: root.theme.surface0
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: "New Widget"
                font.pixelSize: 24
                font.family: "Eagle Horizon-Personal use"
                color: root.theme.text
            }
        }
    }
}
