//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "."

PanelWindow {
    id: barWindow
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    implicitHeight: 48
    margins { top: 8; bottom: 0; left: 4; right: 4 }
    exclusiveZone: 52
    color: "transparent"

    MatugenTheme {
        id: theme
    }

    property bool isStartupReady: false
    Timer { interval: 1; running: true; onTriggered: barWindow.isStartupReady = true }
    
    property bool startupCascadeFinished: false
    Timer { interval: 300; running: true; onTriggered: barWindow.startupCascadeFinished = true }
    
    property string timeStr: ""
    property string fullDateStr: ""
    property int typeInIndex: 0
    property string dateStr: fullDateStr.substring(0, typeInIndex)

    property string weatherIcon: ""
    property string weatherTemp: "--°"
    property string weatherHex: theme.yellow
    
    property string wifiStatus: "Off"
    property string wifiIcon: "󰤮"
    property string wifiSsid: ""
    
    property string btStatus: "Off"
    property string btIcon: "󰂲"
    property string btDevice: ""
    
    property string volPercent: "0%"
    property string volIcon: "󰕾"
    property bool isMuted: false
    property string batPercent: "100%"
    property string batIcon: "󰁹"
    property string kbLayout: "us"
    
    property var workspacesData: []
    property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }

    property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
    property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
    property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"

    Process {
        id: wsDaemon
        command: ["bash", "-c", "~/.config/quickshell/scripts/workspaces.sh > /tmp/qs_workspaces.json"]
        running: true
    }

    Process {
        id: wsPoller
        command: ["bash", "-c", "tail -n 1 /tmp/qs_workspaces.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { barWindow.workspacesData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 100; running: true; repeat: true; onTriggered: wsPoller.running = true }

    Process {
        id: musicPoller
        command: ["bash", "-c", "cat /tmp/music_info.json 2>/dev/null || bash ~/.config/quickshell/scripts/music_info.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: musicPoller.running = true }

    Process {
        id: slowSysPoller
        command: ["bash", "-c", `
            echo "$(~/.config/quickshell/scripts/sys_info.sh --wifi-status)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --wifi-icon)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --wifi-ssid)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --bt-status)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --bt-icon)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --bt-connected)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --battery-percent)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --battery-icon)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 8) {
                    barWindow.wifiStatus = lines[0];
                    barWindow.wifiIcon = lines[1];
                    barWindow.wifiSsid = lines[2];
                    barWindow.btStatus = lines[3];
                    barWindow.btIcon = lines[4];
                    barWindow.btDevice = lines[5];
                    barWindow.batPercent = lines[6];
                    barWindow.batIcon = lines[7];
                }
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: slowSysPoller.running = true }

    Process {
        id: fastSysPoller
        command: ["bash", "-c", `
            echo "$(~/.config/quickshell/scripts/sys_info.sh --volume)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --volume-icon)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --kb-layout)"
            echo "$(~/.config/quickshell/scripts/sys_info.sh --is-muted)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 4) {
                    barWindow.volPercent = lines[0];
                    barWindow.volIcon = lines[1];
                    barWindow.kbLayout = lines[2];
                    barWindow.isMuted = (lines[3].toLowerCase() === "true");
                }
            }
        }
    }
    Timer { interval: 150; running: true; repeat: true; triggeredOnStart: true; onTriggered: fastSysPoller.running = true }

    Process {
        id: weatherPoller
        command: ["bash", "-c", `
            echo "$(~/.config/scripts/weather.sh --icon)"
            echo "$(~/.config/scripts/weather.sh --temp)"
            echo "$(~/.config/scripts/weather.sh --hex)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    barWindow.weatherIcon = lines[0];
                    barWindow.weatherTemp = lines[1];
                    barWindow.weatherHex = lines[2] || theme.yellow;
                }
            }
        }
    }
    Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            let pl = Qt.locale("pl_PL");
            barWindow.timeStr = Qt.formatDateTime(d, "HH:mm:ss");
            barWindow.fullDateStr = d.toLocaleString(pl, "dddd, d MMMM");
            if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                barWindow.typeInIndex = barWindow.fullDateStr.length;
            }
        }
    }

    Timer {
        id: typewriterTimer
        interval: 40
        running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
        repeat: true
        onTriggered: barWindow.typeInIndex += 1
    }

    Item {
        anchors.fill: parent
        RowLayout {
            id: leftLayout
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 

            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                x: leftLayout.showLayout ? 0 : -20
                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
            
            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: leftLayout.showLayout = true
            }

            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            property int moduleHeight: 48

            Rectangle {
                property bool isHovered: notifMouse.containsMouse
                color: isHovered ? theme.surface1 : theme.surface0
                radius: 14; border.width: 1; border.color: isHovered ? theme.overlay0 : theme.surface2
                Layout.preferredHeight: parent.moduleHeight; Layout.preferredWidth: 48
                
                scale: isHovered ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 18
                    color: parent.isHovered ? theme.blue : theme.sapphire
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: notifMouse
                    anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
                        if (mouse.button === Qt.RightButton) Quickshell.execDetached(["swaync-client", "-d"]);
                    }
                }
            }

            // Workspaces
            Rectangle {
                color: theme.surface0
                radius: 14; border.width: 1; border.color: theme.surface2
                Layout.preferredHeight: parent.moduleHeight
                clip: true
                
                property real targetWidth: barWindow.workspacesData.length > 0 ? wsLayout.implicitWidth + 20 : 0
                Layout.preferredWidth: targetWidth
                visible: targetWidth > 0
                opacity: barWindow.workspacesData.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

                        RowLayout {
                            id: wsLayout
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Repeater {
                                model: barWindow.workspacesData
                                delegate: Rectangle {
                                    id: wsPill
                                    property bool isHovered: wsPillMouse.containsMouse
                                    
                                    property real targetWidth: modelData.state === "active" ? 36 : 32
                                    Layout.preferredWidth: targetWidth
                                    Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                    
                                    Layout.preferredHeight: 32; radius: 10
                                    color: modelData.state === "active"
                                           ? (isHovered ? theme.pink : theme.sapphire)
                                           : (modelData.state === "occupied"
                                              ? (isHovered ? theme.overlay0 : theme.surface2)
                                              : (isHovered ? theme.surface1 : "transparent"))
                                    
                                    // Safe Instantiation Cascade logic
                                    property bool initAnimTrigger: barWindow.startupCascadeFinished
                                    opacity: initAnimTrigger ? 1 : 0
                                    transform: Translate {
                                        y: wsPill.initAnimTrigger ? 0 : 15
                                        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                    }

                                    Component.onCompleted: {
                                        if (!barWindow.startupCascadeFinished) {
                                            animTimer.interval = index * 60;
                                            animTimer.start();
                                        }
                                    }

                                    Timer {
                                        id: animTimer
                                        running: false
                                        repeat: false
                                        onTriggered: wsPill.initAnimTrigger = true
                                    }
                                    
                                    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 250 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.id
                                        font.family: "CaskaydiaCoveNerdFont-Regular"
                                        font.pixelSize: 14
                                        font.weight: modelData.state === "active" ? Font.Black : Font.Bold
                                        color: modelData.state === "active"
                                               ? theme.base
                                               : ((modelData.state === "occupied" || parent.isHovered) ? theme.text : theme.sapphire)
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                    }
                                    MouseArea {
                                        id: wsPillMouse
                                        hoverEnabled: true
                                        anchors.fill: parent
                                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", modelData.id.toString()])
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        color: theme.surface0
                        radius: 14; border.width: 1; border.color: theme.surface2
                        Layout.preferredHeight: parent.moduleHeight
                        clip: true 
                        
                        property real targetWidth: barWindow.isMediaActive ? mediaLayoutContainer.width + 24 : 0
                        Layout.preferredWidth: targetWidth
                        visible: Layout.preferredWidth > 0 

                        Behavior on targetWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        
                        Item {
                            id: mediaLayoutContainer
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            height: parent.height
                            width: innerMediaLayout.implicitWidth

                            RowLayout {
                                id: innerMediaLayout
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 16
                                
                                MouseArea {
                                    id: mediaInfoMouse
                                    Layout.preferredWidth: infoLayout.implicitWidth
                                    Layout.fillHeight: true
                                    hoverEnabled: true
                                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle music"])
                                    
                                    RowLayout {
                                        id: infoLayout
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        
                                        scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                                        Rectangle {
                                            Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 8; color: theme.surface1
                                            border.width: barWindow.musicData.status === "Playing" ? 1 : 0
                                            border.color: theme.mauve
                                            clip: true
                                            Image { anchors.fill: parent; source: barWindow.musicData.artUrl || ""; fillMode: Image.PreserveAspectCrop }
                                        }
                                        ColumnLayout {
                                            spacing: -2
                                            Layout.preferredWidth: 180 
                                            
                                            Text { 
                                                text: barWindow.musicData.title; 
                                                font.family: "CaskaydiaCoveNerdFont-Regular"; 
                                                font.weight: Font.Black; 
                                                font.pixelSize: 13; 
                                                color: theme.sapphire; 
                                                elide: Text.ElideRight; 
                                                Layout.fillWidth: true
                                            }
                                            Text { 
                                                text: barWindow.musicData.timeStr; 
                                                font.family: "CaskaydiaCoveNerdFont-Regular"; 
                                                font.weight: Font.Black; 
                                                font.pixelSize: 10; 
                                                color: theme.overlay1;
                                                elide: Text.ElideRight;
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    spacing: 8
                                    Item { 
                                        Layout.preferredWidth: 24; Layout.preferredHeight: 24; 
                                        Text { 
                                            anchors.centerIn: parent; text: "󰒮"; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 26; 
                                            color: prevMouse.containsMouse ? theme.text : theme.overlay2; 
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            scale: prevMouse.containsMouse ? 1.1 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        }
                                        MouseArea { id: prevMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "previous"]) } 
                                    }
                                    Item { 
                                        Layout.preferredWidth: 28; Layout.preferredHeight: 28; 
                                        Text { 
                                            anchors.centerIn: parent; text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 30; 
                                            color: playMouse.containsMouse ? theme.green : theme.text; 
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            scale: playMouse.containsMouse ? 1.15 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        }
                                        MouseArea { id: playMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "play-pause"]) } 
                                    }
                                    Item { 
                                        Layout.preferredWidth: 24; Layout.preferredHeight: 24; 
                                        Text { 
                                            anchors.centerIn: parent; text: "󰒭"; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 26; 
                                            color: nextMouse.containsMouse ? theme.text : theme.overlay2; 
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            scale: nextMouse.containsMouse ? 1.1 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        }
                                        MouseArea { id: nextMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "next"]) } 
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: centerBox
                    anchors.centerIn: parent
                    property bool isHovered: centerMouse.containsMouse
                    color: isHovered ? theme.surface1 : theme.base
                    radius: 14; border.width: 1; border.color: isHovered ? theme.overlay0 : theme.surface2
                    height: 48
                    
                    width: centerLayout.implicitWidth + 48
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                    
                    property bool showLayout: false
                    opacity: showLayout ? 1 : 0
                    transform: Translate {
                        y: centerBox.showLayout ? 0 : -20
                        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    }

                    Timer {
                        running: barWindow.isStartupReady
                        interval: 10
                        onTriggered: centerBox.showLayout = true
                    }

                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    scale: isHovered ? 1.03 : 1.0
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                    Behavior on color { ColorAnimation { duration: 250 } }
                    
                    MouseArea {
                        id: centerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle calendar"])
                    }

                    RowLayout {
                        id: centerLayout
                        anchors.centerIn: parent
                        spacing: 24

                        ColumnLayout {
                            spacing: -2
                            Text { text: barWindow.timeStr; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 16; font.weight: Font.Black; color: centerBox.isHovered ? theme.sky : theme.sapphire }
                            Text { text: barWindow.dateStr; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 11; font.weight: Font.Bold; color: theme.subtext0 }
                        }

                        RowLayout {
                            spacing: 8
                            Text { text: barWindow.weatherIcon; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 24; color: barWindow.weatherHex }
                            Text { text: barWindow.weatherTemp; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 17; font.weight: Font.Black; color: theme.peach }
                        }
                    }
                }

                RowLayout {
                    id: rightLayout
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    property bool showLayout: false
                    opacity: showLayout ? 1 : 0
                    transform: Translate {
                        x: rightLayout.showLayout ? 0 : 20
                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                    
                    Timer {
                        running: barWindow.isStartupReady
                        interval: 10
                        onTriggered: rightLayout.showLayout = true
                    }

                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    Rectangle {
                        height: 48
                        radius: 24
                        color: theme.surface0
                        border.color: theme.surface2
                        border.width: 1
                        
                        property real targetWidth: trayRepeater.count > 0 ? trayLayout.implicitWidth + 24 : 0
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        
                        visible: targetWidth > 0
                        opacity: targetWidth > 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        RowLayout {
                            id: trayLayout
                            anchors.centerIn: parent
                            spacing: 10

                            Repeater {
                                id: trayRepeater
                                model: SystemTray.items
                                delegate: Image {
                                    id: trayIcon
                                    source: modelData.icon || ""
                                    fillMode: Image.PreserveAspectFit
                                    
                                    sourceSize: Qt.size(18, 18)
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    Layout.alignment: Qt.AlignVCenter
                                    
                                    property bool isHovered: trayMouse.containsMouse
                                    property bool initAnimTrigger: barWindow.startupCascadeFinished
                                    opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
                                    scale: initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0

                                    Component.onCompleted: {
                                        if (!barWindow.startupCascadeFinished) {
                                            trayAnimTimer.interval = index * 50;
                                            trayAnimTimer.start();
                                        }
                                    }
                                    Timer {
                                        id: trayAnimTimer
                                        running: false
                                        repeat: false
                                        onTriggered: trayIcon.initAnimTrigger = true
                                    }

                                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                    QsMenuAnchor {
                                        id: menuAnchor
                                        anchor.window: barWindow
                                        anchor.item: trayIcon
                                        menu: modelData.menu
                                    }

                                    MouseArea {
                                        id: trayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                        onPressed: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                if (modelData.hasMenu && modelData.menu) {
                                                    menuAnchor.open();
                                                } else if (typeof modelData.secondaryActivate === "function") {
                                                    modelData.secondaryActivate();
                                                } else if (typeof modelData.contextMenu === "function") {
                                                    modelData.contextMenu(mouse.x, mouse.y);
                                                }
                                                mouse.accepted = true;
                                            }
                                        }
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.LeftButton) {
                                                if (modelData.onlyMenu && modelData.hasMenu && modelData.menu) {
                                                    menuAnchor.open();
                                                } else if (typeof modelData.activate === "function") {
                                                    modelData.activate();
                                                }
                                            } else if (mouse.button === Qt.MiddleButton) {
                                                if (typeof modelData.secondaryActivate === "function") {
                                                    modelData.secondaryActivate();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        height: 48
                        radius: 24
                        color: theme.surface0
                        border.color: theme.surface2
                        border.width: 1
                        
                        property real targetWidth: sysLayout.implicitWidth + 20
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                        RowLayout {
                            id: sysLayout
                            anchors.centerIn: parent
                            spacing: 8 

                            property int pillHeight: 34

                            Rectangle {
                                id: wifiPill
                                property bool isHovered: wifiMouse.containsMouse
                                radius: 17; Layout.preferredHeight: sysLayout.pillHeight; 
                                color: isHovered ? theme.surface2 : theme.surface1
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 17
                                    opacity: barWindow.isWifiOn ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: theme.blue }
                                        GradientStop { position: 1.0; color: theme.sapphire }
                                    }
                                }

                                property real targetWidth: wifiLayoutRow.implicitWidth + 24
                                Layout.preferredWidth: targetWidth
                                Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                
                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                RowLayout { id: wifiLayoutRow; anchors.centerIn: parent; spacing: 8
                                    Text { 
                                        text: barWindow.wifiIcon
                                        font.family: "CaskaydiaCoveNerdFont-Regular"
                                        font.pixelSize: 16
                                            color: barWindow.isWifiOn ? theme.crust : theme.subtext0
                                    }
                                    Text { 
                                        text: {
                                            if (barWindow.wifiIcon === "󰤮") return "Wył."
                                            if (barWindow.wifiIcon === "󰤯") return "Brak sieci"
                                            if (barWindow.wifiSsid !== "") return barWindow.wifiSsid
                                            return "Połączone"
                                        }
                                        font.family: "CaskaydiaCoveNerdFont-Regular"
                                        font.pixelSize: 13
                                        font.weight: Font.Black
                                        color: barWindow.isWifiOn ? theme.crust : theme.text
                                        Layout.maximumWidth: 100
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea { id: wifiMouse; acceptedButtons: Qt.LeftButton | Qt.RightButton; hoverEnabled: true; anchors.fill: parent; onClicked: (mouse) => { if (mouse.button === Qt.LeftButton) Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle network"]); else if (mouse.button === Qt.RightButton) Quickshell.execDetached(["nm-connection-editor"]); } }
                            }

                            Rectangle {
                                id: btPill
                                property bool isHovered: btMouse.containsMouse
                                property bool isRevealed: barWindow.isBtOn && barWindow.btDevice !== ""
                                radius: 17; Layout.preferredHeight: sysLayout.pillHeight
                                clip: true
                                color: isHovered ? theme.surface2 : theme.surface1
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 17
                                    opacity: barWindow.isBtOn ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: theme.mauve }
                                        GradientStop { position: 1.0; color: theme.pink }
                                    }
                                }

                                property real targetWidth: btPill.isRevealed ? 160 : 40
                                Layout.preferredWidth: targetWidth
                                Behavior on targetWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                RowLayout { 
                                    id: btMainLayout
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8
                                    
                                    Item {
                                        id: btIconBox
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        Layout.alignment: Qt.AlignVCenter
                                        
                                        Text { 
                                            anchors.centerIn: parent
                                            text: barWindow.btIcon
                                            font.family: "CaskaydiaCoveNerdFont-Regular"
                                            font.pixelSize: 16
                                            color: barWindow.isBtOn ? theme.crust : theme.subtext0
                                        }
                                    }
                                    
                                    Item {
                                        id: btRevealer
                                        Layout.preferredWidth: btPill.isRevealed ? 110 : 0
                                        Layout.preferredHeight: 16
                                        Layout.alignment: Qt.AlignVCenter
                                        clip: true
                                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                                        
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 4
                                            
                                            Text {
                                                text: barWindow.btDevice
                                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                                font.pixelSize: 13
                                                font.weight: Font.Black
                                                color: barWindow.isBtOn ? theme.crust : theme.text
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            
                                            Rectangle {
                                                Layout.preferredWidth: 20
                                                Layout.preferredHeight: 20
                                                radius: 4
                                                color: btDisconnectMouse.containsMouse ? Qt.rgba(255/255, 255/255, 255/255, 0.3) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰅖"
                                                    font.family: "CaskaydiaCoveNerdFont-Regular"
                                                    font.pixelSize: 12
                                                       color: barWindow.isBtOn ? theme.base : theme.text
                                                }
                                                
                                                MouseArea {
                                                    id: btDisconnectMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/scripts/sys_info.sh --bt-disconnect"])
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea { 
                                    id: btMouse
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    hoverEnabled: true
                                    anchors.fill: parent
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.LeftButton) Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle network"]);
                                        else if (mouse.button === Qt.RightButton) Quickshell.execDetached(["blueman-manager"]);
                                    }
                                }
                            }

                            Rectangle {
                                property bool isHovered: volMouse.containsMouse
                                color: barWindow.isMuted ? theme.surface2 : (isHovered ? theme.surface2 : theme.surface1)
                                radius: 17; Layout.preferredHeight: sysLayout.pillHeight;
                                
                                property real targetWidth: volLayoutRow.implicitWidth + 24
                                Layout.preferredWidth: targetWidth
                                Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                
                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                RowLayout { id: volLayoutRow; anchors.centerIn: parent; spacing: 8
                                        Text { text: barWindow.volIcon; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 16; color: barWindow.isMuted ? theme.overlay0 : (volMouse.containsMouse ? theme.rosewater : theme.peach) }
                                    Text { 
                                        text: barWindow.volPercent; 
                                        font.family: "CaskaydiaCoveNerdFont-Regular"; 
                                        font.pixelSize: 13; 
                                        font.weight: Font.Black; 
                                            color: barWindow.isMuted ? theme.overlay0 : theme.text; 
                                        font.strikeout: barWindow.isMuted 
                                    }
                                }
                                MouseArea { id: volMouse; acceptedButtons: Qt.LeftButton | Qt.RightButton; hoverEnabled: true; anchors.fill: parent; onClicked: (mouse) => { if (mouse.button === Qt.LeftButton) Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle mixer"]); else if (mouse.button === Qt.RightButton) Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/scripts/sys_info.sh --toggle-mute"]); } }
                            }

                            Rectangle {
                                property bool isHovered: batMouse.containsMouse
                                color: isHovered ? theme.surface2 : theme.surface1; 
                                radius: 17; Layout.preferredHeight: sysLayout.pillHeight;
                                
                                property real targetWidth: batLayoutRow.implicitWidth + 24
                                Layout.preferredWidth: targetWidth
                                Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                
                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                RowLayout { id: batLayoutRow; anchors.centerIn: parent; spacing: 8
                                       Text { text: "󰐥"; font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 16; color: theme.green }
                                }
                                MouseArea { id: batMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle battery"]) }
                            }
                        }
                    }
                }
            }
        }
