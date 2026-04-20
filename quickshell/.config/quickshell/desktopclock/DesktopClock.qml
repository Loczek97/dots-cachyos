import QtQuick
import Quickshell
import Quickshell.Wayland 
import Quickshell.Io
import "."

PanelWindow {
    id: desktopClock
    WlrLayershell.layer: WlrLayer.Bottom 
    color: "transparent"
    
    MatugenTheme { id: theme }

    implicitWidth: 400
    implicitHeight: 500
    
    anchors.top: true
    anchors.left: true
    
    property int targetX: 100
    property int targetY: 100
    
    margins.left: targetX
    margins.top: targetY

    Behavior on margins.left { NumberAnimation { duration: 1500; easing.type: Easing.OutQuint } }
    Behavior on margins.top { NumberAnimation { duration: 1500; easing.type: Easing.OutQuint } }

    Process {
        id: posReader
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/desktopclock/clock_pos.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(this.text);
                    let tx = d.isRight ? (Screen.width - desktopClock.width - d.anchorRight) : d.anchorLeft;
                    let ty = d.isBottom ? (Screen.height - desktopClock.height - d.anchorBottom) : d.anchorTop;
                    
                    if (Math.abs(desktopClock.targetX - tx) > 1) desktopClock.targetX = tx;
                    if (Math.abs(desktopClock.targetY - ty) > 1) desktopClock.targetY = ty;
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: posReader.running = true
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
