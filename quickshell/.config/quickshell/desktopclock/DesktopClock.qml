import "."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: desktopClock

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    property int targetX: 100
    property int targetY: 100
    readonly property string posFilePath: Quickshell.env("HOME") + "/.config/quickshell/desktopclock/clock_pos.json"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "desktopclock"
    color: "transparent"
    implicitWidth: 450
    implicitHeight: 500
    anchors.top: true
    anchors.left: true
    margins.left: targetX
    margins.top: targetY
    Component.onCompleted: posReader.running = true

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

        property color text: "#000000"
        property color peach: "#000000"
    }

    Process {
        id: posReader

        command: ["cat", desktopClock.posFilePath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(this.text);
                    let tx = d.isRight ? (Screen.width - desktopClock.width - d.anchorRight) : d.anchorLeft;
                    let ty = d.isBottom ? (Screen.height - desktopClock.height - d.anchorBottom) : d.anchorTop;
                    if (Math.abs(desktopClock.targetX - tx) > 1)
                        desktopClock.targetX = tx;

                    if (Math.abs(desktopClock.targetY - ty) > 1)
                        desktopClock.targetY = ty;

                } catch (e) {
                }
            }
        }

    }

    FileView {
        path: desktopClock.posFilePath
        watchChanges: true
        onFileChanged: posReader.running = true
    }

    Column {
        id: mainLayout

        anchors.centerIn: parent
        spacing: -18

        Text {
            id: dayNameText

            leftPadding: 25
            font.pixelSize: 50
            font.family: "Eagle Horizon-Personal use"
            font.weight: Font.Normal
            color: theme.text
            opacity: 0.8
            anchors.left: parent.left
        }

        Text {
            id: dayNumText

            leftPadding: 25
            font.pixelSize: 90
            font.family: "Eagle Horizon-Personal use"
            font.weight: Font.Normal
            color: theme.text
            anchors.left: parent.left
            topPadding: -10
        }

        Text {
            id: monthNameText

            leftPadding: 25
            font.pixelSize: 32
            font.family: "Eagle Horizon-Personal use"
            font.weight: Font.Normal
            color: theme.text
            opacity: 0.6
            anchors.left: parent.left
            topPadding: -5
        }

        Text {
            id: timeText

            leftPadding: 25
            font.pixelSize: 90
            font.family: "Eagle Horizon-Personal use"
            font.weight: Font.Normal
            color: theme.peach
            anchors.left: parent.left
            topPadding: -10
        }

    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            dayNameText.text = now.toLocaleDateString(Qt.locale(), "ddd").toLowerCase().replace(".", "");
            dayNumText.text = now.getDate();
            monthNameText.text = now.toLocaleDateString(Qt.locale(), "MMMM").toLowerCase();
            timeText.text = now.toLocaleTimeString(Qt.locale(), "HH:mm");
        }
    }

}
