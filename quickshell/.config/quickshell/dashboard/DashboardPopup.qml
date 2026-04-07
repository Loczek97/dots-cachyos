import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

FloatingWindow {
    id: powermenuWindow
    title: "dashboard_win"
    
    color: "transparent"

    MatugenTheme { id: theme }

    // -------------------------------------------------------------------------
    // COLOR MAPPINGS
    // -------------------------------------------------------------------------
    readonly property color base: theme.base
    readonly property color mantle: theme.mantle
    readonly property color crust: theme.crust
    readonly property color text: theme.text
    readonly property color subtext1: theme.subtext1
    readonly property color subtext0: theme.subtext0
    readonly property color surface2: theme.surface2
    readonly property color surface1: theme.surface1
    readonly property color surface0: theme.surface0
    
    readonly property color mauve: theme.mauve
    readonly property color blue: theme.blue
    readonly property color sapphire: theme.sapphire
    readonly property color peach: theme.peach
    readonly property color yellow: theme.yellow
    readonly property color teal: theme.teal
    readonly property color green: theme.green
    readonly property color red: theme.red

    // -------------------------------------------------------------------------
    // LOGIC
    // -------------------------------------------------------------------------
    property string realName: "Użytkownik"
    property string hostName: "linux"
    property string facePath: "file://" + Quickshell.env("HOME") + "/.face"

    Process {
        id: userPoller
        command: ["sh", "-c", "getent passwd $USER | cut -d: -f5 | cut -d, -f1"]
        running: true
        stdout: StdioCollector { 
            onStreamFinished: { 
                let name = this.text.trim()
                if (name !== "") powermenuWindow.realName = name
            } 
        }
    }

    Process {
        id: hostPoller
        command: ["hostname"]
        running: true
        stdout: StdioCollector { 
            onStreamFinished: { 
                let host = this.text.trim()
                if (host !== "") powermenuWindow.hostName = host
            } 
        }
    }

    property var musicData: { 
        "title": "Offline", 
        "artist": "Not Playing", 
        "status": "Stopped", 
        "percent": 0, 
        "lengthStr": "00:00", 
        "positionStr": "00:00", 
        "artUrl": "" 
    }

    Process {
        id: musicPoller
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/music/music_info.sh"]
        running: true
        stdout: StdioCollector { 
            onStreamFinished: { 
                let txt = this.text.trim()
                if (txt !== "") { 
                    try { powermenuWindow.musicData = JSON.parse(txt) } catch(e) {} 
                } 
            } 
        }
    }
    Timer { 
        interval: 1000
        running: true
        repeat: true
        onTriggered: musicPoller.running = true 
    }

    property var weatherData: null
    Process {
        id: weatherPoller
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/calendar/weather.sh", "--json"]
        running: true
        stdout: StdioCollector { 
            onStreamFinished: { 
                let txt = this.text.trim()
                if (txt !== "") { 
                    try { powermenuWindow.weatherData = JSON.parse(txt) } catch(e) {} 
                } 
            } 
        }
    }
    Timer { 
        interval: 300000
        running: true
        repeat: true
        onTriggered: weatherPoller.running = true 
    }

    property string upHours: "0"
    property string upMins: "0"
    Process {
        id: uptimePoller
        command: ["sh", "-c", "awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime"]
        running: true
        stdout: StdioCollector { 
            onStreamFinished: { 
                let txt = this.text.trim()
                if (txt !== "") { 
                    let parts = txt.split("h ")
                    if (parts.length === 2) { 
                        powermenuWindow.upHours = parts[0]
                        powermenuWindow.upMins = parts[1].replace("m", "")
                    } 
                } 
            } 
        }
    }
    Timer { 
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimePoller.running = true 
    }

    function execCmd(cmdStr) { 
        Quickshell.execDetached(["bash", "-c", cmdStr])
    }

    // --- UI LAYOUT ---
    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 20

        // KOLUMNA 1: PROFIL
        ColumnLayout {
            spacing: 20
            Layout.alignment: Qt.AlignTop
            Rectangle {
                Layout.preferredWidth: 220
                Layout.preferredHeight: 300
                radius: 30
                color: powermenuWindow.surface0
                border.color: powermenuWindow.surface1
                border.width: 1
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    Rectangle {
                        id: avatarContainer
                        Layout.alignment: Qt.AlignHCenter
                        width: 130
                        height: 130
                        radius: 65
                        color: powermenuWindow.mantle
                        border.color: powermenuWindow.mauve
                        border.width: 2
                        
                        Item {
                            anchors.fill: parent
                            anchors.margins: 3
                            Image {
                                id: profileImage
                                anchors.fill: parent
                                source: powermenuWindow.facePath
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                                asynchronous: true
                            }
                            Rectangle {
                                id: avatarMask
                                anchors.fill: parent
                                radius: 65
                                visible: false
                                layer.enabled: true
                            }
                            MultiEffect {
                                anchors.fill: parent
                                source: profileImage
                                maskEnabled: true
                                maskSource: avatarMask
                                opacity: profileImage.status === Image.Ready ? 1.0 : 0.0
                            }
                        }
                        Text {
                            visible: profileImage.status !== Image.Ready
                            anchors.centerIn: parent
                            text: "🧔"
                            font.pixelSize: 65
                            color: powermenuWindow.text
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: powermenuWindow.realName
                        font.pixelSize: 22
                        font.bold: true
                        color: powermenuWindow.mauve
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "@" + powermenuWindow.hostName
                        font.pixelSize: 15
                        color: powermenuWindow.blue
                    }
                }
            }
            Rectangle {
                Layout.preferredWidth: 220
                Layout.preferredHeight: 90
                radius: 30
                color: powermenuWindow.surface0
                border.color: powermenuWindow.surface1
                border.width: 1
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    Text {
                        text: "🕒"
                        font.pixelSize: 28
                        color: powermenuWindow.mauve
                    }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: powermenuWindow.upHours + "h " + powermenuWindow.upMins + "min"
                            font.pixelSize: 20
                            font.bold: true
                            color: powermenuWindow.text
                        }
                        Text {
                            text: "UPTIME"
                            font.pixelSize: 11
                            font.bold: true
                            color: powermenuWindow.subtext0
                            font.letterSpacing: 1
                        }
                    }
                }
            }
        }

        // KOLUMNA 2: POGODA I MUZYKA
        ColumnLayout {
            spacing: 20
            Layout.alignment: Qt.AlignTop
            Rectangle {
                Layout.preferredWidth: 420
                Layout.preferredHeight: 180
                radius: 30
                color: powermenuWindow.surface0
                border.color: powermenuWindow.surface1
                border.width: 1
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 25
                        Text {
                            text: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast[0].icon : "󰖐"
                            font.pixelSize: 45
                            color: powermenuWindow.blue
                            font.family: "Iosevka Nerd Font"
                        }
                        Text {
                            text: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast[0].max + "°C" : "--°C"
                            font.pixelSize: 40
                            font.bold: true
                            color: powermenuWindow.text
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 5
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast[0].desc : "Ładowanie..."
                            font.pixelSize: 20
                            font.bold: true
                            color: powermenuWindow.mauve
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Odczuwalna " + (powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast[0].feels_like : "--") + "°C"
                            font.pixelSize: 13
                            color: powermenuWindow.subtext0
                        }
                    }
                }
            }

            // PANEL MUZYCZNY
            Rectangle {
                id: musicTile
                Layout.preferredWidth: 420
                Layout.preferredHeight: 210
                radius: 30
                color: powermenuWindow.base
                border.color: powermenuWindow.surface0
                border.width: 1

                // TŁO KAFELKA - OKŁADKA (ZAOKRĄGLONA)
                Item {
                    id: backgroundWrapper
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: Rectangle {
                            width: backgroundWrapper.width
                            height: backgroundWrapper.height
                            radius: 30
                        }
                    }

                    Image {
                        id: bgArtImg
                        anchors.fill: parent
                        source: powermenuWindow.musicData.artUrl ? (powermenuWindow.musicData.artUrl.startsWith("file://") ? powermenuWindow.musicData.artUrl : "file://" + powermenuWindow.musicData.artUrl) : ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.4
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: 0.6
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 25
                    
                    Rectangle {
                        id: discContainer
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 140
                        radius: 70
                        color: powermenuWindow.surface1
                        border.width: 3
                        border.color: powermenuWindow.musicData.status === "Playing" ? powermenuWindow.mauve : powermenuWindow.surface2
                        
                        Rectangle {
                            z: -1
                            anchors.centerIn: parent
                            width: parent.width + 15
                            height: parent.height + 15
                            radius: 77
                            color: powermenuWindow.mauve
                            opacity: powermenuWindow.musicData.status === "Playing" ? 0.3 : 0.0
                            layer.enabled: true
                            layer.effect: MultiEffect { blurEnabled: true; blurMax: 24; blur: 1.0 }
                        }
                        
                        Item {
                            anchors.fill: parent
                            anchors.margins: 3
                            Image {
                                id: artImg
                                anchors.fill: parent
                                source: bgArtImg.source
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                            }
                            Rectangle {
                                id: discMask
                                anchors.fill: parent
                                radius: 67
                                visible: false
                                layer.enabled: true
                            }
                            MultiEffect {
                                anchors.fill: parent
                                source: artImg
                                maskEnabled: true
                                maskSource: discMask
                                opacity: artImg.status === Image.Ready ? 1.0 : 0.0
                            }
                            Rectangle {
                                width: 30
                                height: 30
                                radius: 15
                                color: powermenuWindow.base
                                opacity: 0.9
                                anchors.centerIn: parent
                            }
                        }
                        NumberAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 6000
                            loops: Animation.Infinite
                            running: powermenuWindow.musicData.status === "Playing"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Text {
                                text: powermenuWindow.musicData.title
                                color: powermenuWindow.text
                                font.pixelSize: 18
                                font.weight: Font.Black
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: powermenuWindow.musicData.artist
                                color: powermenuWindow.subtext1
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 20
                            MouseArea {
                                width: 30
                                height: 30
                                onClicked: powermenuWindow.execCmd("playerctl previous")
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒮"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 22
                                    color: powermenuWindow.text
                                }
                            }
                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: powermenuWindow.mauve
                                Text {
                                    anchors.centerIn: parent
                                    text: powermenuWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 22
                                    color: powermenuWindow.base
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: powermenuWindow.execCmd("playerctl play-pause")
                                }
                            }
                            MouseArea {
                                width: 30
                                height: 30
                                onClicked: powermenuWindow.execCmd("playerctl next")
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒭"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 22
                                    color: powermenuWindow.text
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                color: "#20ffffff"
                                Rectangle {
                                    width: parent.width * (powermenuWindow.musicData.percent / 100)
                                    height: parent.height
                                    radius: 3
                                    color: powermenuWindow.mauve
                                }
                            }
                            RowLayout {
                                Text {
                                    text: powermenuWindow.musicData.positionStr
                                    font.pixelSize: 9
                                    color: powermenuWindow.subtext0
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: powermenuWindow.musicData.lengthStr
                                    font.pixelSize: 9
                                    color: powermenuWindow.subtext0
                                }
                            }
                        }
                    }
                }
            }
        }

        // KOLUMNA 3: AKCJE
        ColumnLayout {
            spacing: 20
            Layout.alignment: Qt.AlignTop
            Repeater {
                model: ListModel {
                    ListElement { icon: "󰍃"; col: "peach"; cmd: "loginctl terminate-user $USER" }
                    ListElement { icon: "󰌾"; col: "green"; cmd: "hyprlock" }
                    ListElement { icon: "󰑓"; col: "blue"; cmd: "systemctl reboot" }
                    ListElement { icon: "󰐥"; col: "red"; cmd: "systemctl poweroff" }
                }
                Rectangle {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 90
                    radius: 25
                    color: btnMa.containsMouse ? powermenuWindow.surface1 : powermenuWindow.surface0
                    border.color: btnMa.containsMouse ? powermenuWindow[model.col] : powermenuWindow.surface1
                    border.width: 2
                    Text {
                        anchors.centerIn: parent
                        text: model.icon
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 32
                        color: powermenuWindow[model.col]
                    }
                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: powermenuWindow.execCmd(model.cmd)
                    }
                }
            }
        }
    }
}
