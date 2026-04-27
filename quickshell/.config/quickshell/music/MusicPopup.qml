import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    readonly property color base: theme.base
    readonly property color mantle: theme.mantle
    readonly property color crust: theme.crust
    readonly property color text: theme.text
    readonly property color subtext1: theme.subtext1
    readonly property color subtext0: theme.subtext0
    readonly property color overlay2: theme.overlay2
    readonly property color overlay1: theme.overlay1
    readonly property color overlay0: theme.overlay0
    readonly property color surface2: theme.surface2
    readonly property color surface1: theme.surface1
    readonly property color surface0: theme.surface0
    readonly property color mauve: theme.mauve
    readonly property color pink: theme.pink
    readonly property color blue: theme.blue
    readonly property color sapphire: theme.sapphire
    readonly property color peach: theme.peach
    readonly property color yellow: theme.yellow
    readonly property color teal: theme.teal
    readonly property color green: theme.green
    readonly property color red: theme.red
    // Data State Properties
    property var musicData: {
        "title": "Loading...",
        "artist": "",
        "status": "Stopped",
        "percent": 0,
        "lengthStr": "00:00",
        "positionStr": "00:00",
        "timeStr": "--:-- / --:--",
        "source": "Offline",
        "playerName": "",
        "blur": "",
        "grad": "",
        "textColor": root.text,
        "deviceIcon": "󰓃",
        "deviceName": "Speaker",
        "artUrl": ""
    }
    // UI State for debouncing
    property bool userIsSeeking: false
    property bool userToggledPlay: false
    // Animation States from TaskManager
    property real introState: 0
    property real globalOrbitAngle: 0
    property real catppuccinFlowOffset: 0

    function execCmd(cmdStr) {
        var safeCmd = cmdStr.replace(/`/g, "\\`");
        Qt.createQmlObject(`import Quickshell.Io; Process { command: ["bash", "-c", \`${safeCmd}\` ]; running: true; onExited: destroy() }`, root);
    }

    title: "music_win"
    implicitWidth: 700
    implicitHeight: 280
    color: "transparent"
    Component.onCompleted: introState = 1

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
        property color subtext1: "#000000"
        property color subtext0: "#000000"
        property color mauve: "#000000"
        property color pink: "#000000"
        property color blue: "#000000"
        property color sapphire: "#000000"
        property color peach: "#000000"
        property color yellow: "#000000"
        property color teal: "#000000"
        property color green: "#000000"
        property color red: "#000000"
        property color maroon: "#000000"
    }

    // --- DATA POLLING ---
    Timer {
        id: seekDebounceTimer

        interval: 2500
        onTriggered: root.userIsSeeking = false
    }

    Timer {
        id: playDebounceTimer

        interval: 1500
        onTriggered: root.userToggledPlay = false
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!musicProc.running) {
                musicProc.running = true;
            }
        }
    }

    Process {
        id: musicProc

        running: true
        command: ["bash", "-c", "$HOME/.config/quickshell/music/music_info.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    var outStr = this.text.trim();
                    if (outStr.length > 0) {
                        try {
                            var newData = JSON.parse(outStr);
                            if (root.userToggledPlay)
                                newData.status = root.musicData.status;

                            root.musicData = newData;
                        } catch (e) {
                        }
                    }
                }
            }
        }

    }

    // --- UI LAYOUT ---
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * root.introState)
        opacity: root.introState

        Rectangle {
            anchors.fill: parent
            color: root.base
            radius: 30
            border.color: root.surface0
            border.width: 1
            clip: true

            // --- BACKGROUND ---
            Item {
                anchors.fill: parent

                Image {
                    id: bgArtImg

                    anchors.fill: parent
                    source: root.musicData.artUrl ? "file://" + root.musicData.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.3

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 500
                        }

                    }

                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: bgArtImg.status === Image.Ready ? 0.5 : 0.5

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 500
                        }

                    }

                }

            }

            // --- CONTENT ---
            RowLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 35

                // Cover Art
                Rectangle {
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 180
                    radius: 90
                    color: root.surface1
                    border.width: 3
                    border.color: root.musicData.status === "Playing" ? root.mauve : root.surface2

                    // Glow Effect
                    Rectangle {
                        z: -1
                        anchors.centerIn: parent
                        width: parent.width + 15
                        height: parent.height + 15
                        radius: width / 2
                        color: root.mauve
                        opacity: root.musicData.status === "Playing" ? 0.3 : 0
                        layer.enabled: true

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 500
                            }

                        }

                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blurMax: 24
                            blur: 1
                        }

                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 3

                        Image {
                            id: artImg

                            anchors.fill: parent
                            source: root.musicData.artUrl ? "file://" + root.musicData.artUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        Rectangle {
                            id: maskRect

                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: artImg
                            maskEnabled: true
                            maskSource: maskRect
                            opacity: artImg.status === Image.Ready ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 800
                                }

                            }

                        }

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: root.base
                            opacity: 0.9
                            anchors.centerIn: parent
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 500
                        }

                    }

                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 6000
                        loops: Animation.Infinite
                        running: true
                        paused: root.musicData.status !== "Playing"
                    }

                }

                // Text & Controls
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: root.musicData.title
                            color: root.text
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 22
                            font.weight: Font.Black
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: root.musicData.artist ? root.musicData.artist : ""
                            color: root.subtext1
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 10

                            Rectangle {
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: pillContent.width + 16
                                radius: 8
                                color: "#08ffffff"
                                border.color: "#1affffff"
                                border.width: 1

                                RowLayout {
                                    id: pillContent

                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: root.musicData.deviceIcon || "󰓃"
                                        color: root.mauve
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        text: root.musicData.deviceName || "Speaker"
                                        color: root.subtext0
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                    }

                                }

                            }

                        }

                    }

                    // Progress Slider (TaskManager Style)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Slider {
                            id: progBar

                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            from: 0
                            to: 100
                            value: root.musicData.percent || 0
                            onPressedChanged: {
                                if (pressed) {
                                    root.userIsSeeking = true;
                                    seekDebounceTimer.stop();
                                } else {
                                    root.execCmd(`$HOME/.config/quickshell/music/player_control.sh seek ${value.toFixed(2)} ${root.musicData.length} "${root.musicData.playerName || ""}"`);
                                    seekDebounceTimer.restart();
                                }
                            }

                            background: Rectangle {
                                x: progBar.leftPadding
                                y: progBar.topPadding + (progBar.availableHeight - height) / 2
                                implicitWidth: 200
                                implicitHeight: 6
                                width: progBar.availableWidth
                                radius: 3
                                color: root.surface0

                                Rectangle {
                                    width: progBar.visualPosition * parent.width
                                    height: parent.height
                                    radius: 3
                                    color: root.mauve
                                }

                            }

                            handle: Rectangle {
                                x: progBar.leftPadding + progBar.visualPosition * (progBar.availableWidth - width)
                                y: progBar.topPadding + (progBar.availableHeight - height) / 2
                                width: 14
                                height: 14
                                radius: 7
                                color: root.text
                                scale: progBar.pressed ? 1.3 : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                    }

                                }

                            }

                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: root.musicData.positionStr || "00:00"
                                color: root.overlay2
                                font.family: "CaskaydiaCove Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 11
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.musicData.lengthStr || "00:00"
                                color: root.overlay2
                                font.family: "CaskaydiaCove Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 11
                            }

                        }

                    }

                    // Controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 40

                        MouseArea {
                            width: 32
                            height: 32
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.execCmd("playerctl previous")

                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                color: parent.pressed ? root.text : root.overlay2
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 28
                            }

                        }

                        Rectangle {
                            width: 54
                            height: 54
                            radius: 27
                            color: playMa.containsMouse ? root.mauve : "#08ffffff"
                            border.color: "#1affffff"
                            border.width: 1
                            scale: playMa.pressed ? 0.9 : (playMa.containsMouse ? 1.1 : 1)

                            Text {
                                anchors.centerIn: parent
                                text: root.musicData.status === "Playing" ? "󰏤" : "󰐊"
                                color: playMa.containsMouse ? root.base : root.text
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 32
                            }

                            MouseArea {
                                id: playMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    root.userToggledPlay = true;
                                    playDebounceTimer.restart();
                                    var temp = Object.assign({
                                    }, root.musicData);
                                    temp.status = (temp.status === "Playing" ? "Paused" : "Playing");
                                    root.musicData = temp;
                                    root.execCmd("playerctl play-pause");
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }

                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }

                            }

                        }

                        MouseArea {
                            width: 32
                            height: 32
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.execCmd("playerctl next")

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                color: parent.pressed ? root.text : root.overlay2
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 28
                            }

                        }

                    }

                }

            }

        }

    }

    Behavior on introState {
        NumberAnimation {
            duration: 1200
            easing.type: Easing.OutExpo
        }

    }

    NumberAnimation on globalOrbitAngle {
        from: 0
        to: Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }

    NumberAnimation on catppuccinFlowOffset {
        from: 0
        to: 1
        duration: 3000
        loops: Animation.Infinite
        running: true
    }

}
