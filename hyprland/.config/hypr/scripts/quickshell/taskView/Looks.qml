pragma Singleton
import QtQuick

QtObject {
    property QtObject colors: QtObject {
        // Kolory bazowe - dopasowane do MatugenTheme
        readonly property color bg1Base: "#171d1a"
        readonly property color bg1: "#0f1512"
        readonly property color bg2: "#1b211e"
        readonly property color bg2Border: "#404944"
        readonly property color bgPanelFooterBackground: "#1b211e"
        readonly property color accent: "#89d6b8"
        readonly property color text: "#dee4df"
    }
    
    property QtObject radius: QtObject {
        readonly property real xLarge: 16
        readonly property real large: 12
        readonly property real medium: 8
    }
    
    property QtObject transition: QtObject {
        readonly property Component enter: Component {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutExpo
            }
        }
        readonly property Component color: Component {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        readonly property QtObject easing: QtObject {
            readonly property QtObject bezierCurve: QtObject {
                readonly property var easeIn: [0.4, 0.0, 0.2, 1.0]
            }
        }
    }
}
