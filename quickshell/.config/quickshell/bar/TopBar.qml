//@ pragma UseQApplication
import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Wayland

PanelWindow {
    id: barWindow

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    property int _popupCounter: 0
    property bool isStartupReady: false
    property bool startupCascadeFinished: false
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
    property var musicData: {
        "status": "Stopped",
        "title": "",
        "artUrl": "",
        "timeStr": ""
    }
    property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
    property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
    property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"

    function removePopup(uid) {
        for (let i = 0; i < activePopupsModel.count; i++) {
            if (activePopupsModel.get(i).uid === uid) {
                activePopupsModel.remove(i);
                break;
            }
        }
    }

    implicitHeight: 48
    exclusiveZone: 52
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 8
        bottom: 0
        left: 4
        right: 4
    }

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

    // =========================================================
    // --- NOTIFICATION HANDLING
    // =========================================================
    ListModel {
        id: globalNotificationHistory
    }

    ListModel {
        id: activePopupsModel
    }

    NotificationServer {
        id: globalNotificationServer

        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: (n) => {
            let icon = "";
            if (n.image && n.image.toString() !== "")
                icon = n.image.toString();
            else if (n.appIcon && n.appIcon !== "")
                icon = n.appIcon;
            let notifData = {
                "appName": n.appName || "System",
                "summary": n.summary || "No Title",
                "body": n.body || "",
                "iconPath": icon,
                "urgency": n.urgency || 1,
                "notif": n
            };
            globalNotificationHistory.insert(0, notifData);
            barWindow._popupCounter++;
            let popupData = Object.assign({
                "uid": barWindow._popupCounter
            }, notifData);
            activePopupsModel.append(popupData);
        }
    }

    NotificationPopups {
        id: osdPopups

        popupModel: activePopupsModel
        uiScale: 1
    }

    NotificationCenter {
        id: notifCenter

        notifModel: globalNotificationHistory
        isVisible: false
    }
    // =========================================================

    Timer {
        interval: 1
        running: true
        onTriggered: barWindow.isStartupReady = true
    }

    Timer {
        interval: 300
        running: true
        onTriggered: barWindow.startupCascadeFinished = true
    }

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
                    try {
                        barWindow.workspacesData = JSON.parse(txt);
                    } catch (e) {
                    }
                }
            }
        }

    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: wsPoller.running = true
    }

    Process {
        id: musicPoller

        command: ["bash", "-c", "cat /tmp/music_info.json 2>/dev/null || bash ~/.config/quickshell/scripts/music_info.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        barWindow.musicData = JSON.parse(txt);
                    } catch (e) {
                    }
                }
            }
        }

    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: musicPoller.running = true
    }

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

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: slowSysPoller.running = true
    }

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

    Timer {
        interval: 150
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fastSysPoller.running = true
    }

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

    Timer {
        interval: 150000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherPoller.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            let pl = Qt.locale("pl_PL");
            barWindow.timeStr = Qt.formatDateTime(d, "HH:mm:ss");
            barWindow.fullDateStr = d.toLocaleString(pl, "dddd, d MMMM");
            if (barWindow.typeInIndex >= barWindow.fullDateStr.length)
                barWindow.typeInIndex = barWindow.fullDateStr.length;

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

            property bool showLayout: false
            property int moduleHeight: 48

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            opacity: showLayout ? 1 : 0

            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: leftLayout.showLayout = true
            }

            Rectangle {
                property bool isHovered: notifMouse.containsMouse

                color: isHovered ? theme.surface1 : theme.surface0
                radius: 14
                border.width: 1
                border.color: isHovered ? theme.overlay0 : theme.surface2
                Layout.preferredHeight: parent.moduleHeight
                Layout.preferredWidth: 48
                scale: isHovered ? 1.05 : 1

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "CaskaydiaCoveNerdFont-Regular"
                    font.pixelSize: 18
                    color: parent.isHovered ? theme.blue : theme.sapphire

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                }

                MouseArea {
                    id: notifMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            notifCenter.isVisible = !notifCenter.isVisible;

                        if (mouse.button === Qt.RightButton)
                            Quickshell.execDetached(["swaync-client", "-d"]);
 // DND zostawiamy na razie w swaync
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

            // Workspaces
            Rectangle {
                property real targetWidth: barWindow.workspacesData.length > 0 ? wsLayout.implicitWidth + 20 : 0

                color: theme.surface0
                radius: 14
                border.width: 1
                border.color: theme.surface2
                Layout.preferredHeight: parent.moduleHeight
                clip: true
                Layout.preferredWidth: targetWidth
                visible: targetWidth > 0
                opacity: barWindow.workspacesData.length > 0 ? 1 : 0

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
                            // Safe Instantiation Cascade logic
                            property bool initAnimTrigger: barWindow.startupCascadeFinished

                            Layout.preferredWidth: targetWidth
                            Layout.preferredHeight: 32
                            radius: 10
                            color: modelData.state === "active" ? (isHovered ? theme.pink : theme.sapphire) : (modelData.state === "occupied" ? (isHovered ? theme.overlay0 : theme.surface2) : (isHovered ? theme.surface1 : "transparent"))
                            opacity: initAnimTrigger ? 1 : 0
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

                            Text {
                                anchors.centerIn: parent
                                text: modelData.id
                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                font.pixelSize: 14
                                font.weight: modelData.state === "active" ? Font.Black : Font.Bold
                                color: modelData.state === "active" ? theme.base : ((modelData.state === "occupied" || parent.isHovered) ? theme.text : theme.sapphire)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 250
                                    }

                                }

                            }

                            MouseArea {
                                id: wsPillMouse

                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", modelData.id.toString()])
                            }

                            Behavior on targetWidth {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                }

                            }

                            transform: Translate {
                                y: wsPill.initAnimTrigger ? 0 : 15

                                Behavior on y {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutBack
                                    }

                                }

                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 500
                                    easing.type: Easing.OutCubic
                                }

                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 250
                                }

                            }

                        }

                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }

                }

                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutExpo
                    }

                }

            }

            Rectangle {
                property real targetWidth: barWindow.isMediaActive ? mediaLayoutContainer.width + 24 : 0

                color: theme.surface0
                radius: 14
                border.width: 1
                border.color: theme.surface2
                Layout.preferredHeight: parent.moduleHeight
                clip: true
                Layout.preferredWidth: targetWidth
                visible: Layout.preferredWidth > 0

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
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle music"]);
                            }

                            RowLayout {
                                id: infoLayout

                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                scale: mediaInfoMouse.containsMouse ? 1.02 : 1

                                Rectangle {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: theme.surface1
                                    border.width: barWindow.musicData.status === "Playing" ? 1 : 0
                                    border.color: theme.mauve
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: barWindow.musicData.artUrl || ""
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                }

                                ColumnLayout {
                                    spacing: -2
                                    Layout.preferredWidth: 180

                                    Text {
                                        text: barWindow.musicData.title
                                        font.family: "CaskaydiaCoveNerdFont-Regular"
                                        font.weight: Font.Black
                                        font.pixelSize: 13
                                        color: theme.sapphire
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: barWindow.musicData.timeStr
                                        font.family: "CaskaydiaCoveNerdFont-Regular"
                                        font.weight: Font.Black
                                        font.pixelSize: 10
                                        color: theme.overlay1
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutExpo
                                    }

                                }

                            }

                        }

                        RowLayout {
                            spacing: 8

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒮"
                                    font.family: "CaskaydiaCoveNerdFont-Regular"
                                    font.pixelSize: 26
                                    color: prevMouse.containsMouse ? theme.text : theme.overlay2
                                    scale: prevMouse.containsMouse ? 1.1 : 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
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
                                    id: prevMouse

                                    hoverEnabled: true
                                    anchors.fill: parent
                                    onClicked: Quickshell.execDetached(["playerctl", "previous"])
                                }

                            }

                            Item {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28

                                Text {
                                    anchors.centerIn: parent
                                    text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"
                                    font.family: "CaskaydiaCoveNerdFont-Regular"
                                    font.pixelSize: 30
                                    color: playMouse.containsMouse ? theme.green : theme.text
                                    scale: playMouse.containsMouse ? 1.15 : 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
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
                                    id: playMouse

                                    hoverEnabled: true
                                    anchors.fill: parent
                                    onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
                                }

                            }

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒭"
                                    font.family: "CaskaydiaCoveNerdFont-Regular"
                                    font.pixelSize: 26
                                    color: nextMouse.containsMouse ? theme.text : theme.overlay2
                                    scale: nextMouse.containsMouse ? 1.1 : 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
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
                                    id: nextMouse

                                    hoverEnabled: true
                                    anchors.fill: parent
                                    onClicked: Quickshell.execDetached(["playerctl", "next"])
                                }

                            }

                        }

                    }

                }

                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }

                }

            }

            transform: Translate {
                x: leftLayout.showLayout ? 0 : -20

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }

            }

        }

        Rectangle {
            id: centerBox

            property bool isHovered: centerMouse.containsMouse
            property bool showLayout: false

            anchors.centerIn: parent
            color: isHovered ? theme.surface1 : theme.base
            radius: 14
            border.width: 1
            border.color: isHovered ? theme.overlay0 : theme.surface2
            height: 48
            width: centerLayout.implicitWidth + 48
            opacity: showLayout ? 1 : 0
            scale: isHovered ? 1.03 : 1

            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: centerBox.showLayout = true
            }

            MouseArea {
                id: centerMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: (mouse) => {
                    mouse.accepted = true;
                    Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle calendar"]);
                }
            }

            RowLayout {
                id: centerLayout

                anchors.centerIn: parent
                spacing: 24

                ColumnLayout {
                    spacing: -2

                    Text {
                        text: barWindow.timeStr
                        font.family: "CaskaydiaCoveNerdFont-Regular"
                        font.pixelSize: 16
                        font.weight: Font.Black
                        color: centerBox.isHovered ? theme.sky : theme.sapphire
                    }

                    Text {
                        text: barWindow.dateStr
                        font.family: "CaskaydiaCoveNerdFont-Regular"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: theme.subtext0
                    }

                }

                RowLayout {
                    spacing: 8

                    Text {
                        text: barWindow.weatherIcon
                        font.family: "CaskaydiaCoveNerdFont-Regular"
                        font.pixelSize: 24
                        color: barWindow.weatherHex
                    }

                    Text {
                        text: barWindow.weatherTemp
                        font.family: "CaskaydiaCoveNerdFont-Regular"
                        font.pixelSize: 17
                        font.weight: Font.Black
                        color: theme.peach
                    }

                }

            }

            Behavior on width {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutExpo
                }

            }

            transform: Translate {
                y: centerBox.showLayout ? 0 : -20

                Behavior on y {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutBack
                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutExpo
                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 250
                }

            }

        }

        RowLayout {
            id: rightLayout

            property bool showLayout: false

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            opacity: showLayout ? 1 : 0

            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: rightLayout.showLayout = true
            }

            Rectangle {
                property real targetWidth: trayRepeater.count > 0 ? trayLayout.implicitWidth + 24 : 0

                height: 48
                radius: 14
                color: theme.surface0
                border.color: theme.surface2
                border.width: 1
                Layout.preferredWidth: targetWidth
                visible: targetWidth > 0
                opacity: targetWidth > 0 ? 1 : 0

                RowLayout {
                    id: trayLayout

                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        id: trayRepeater

                        model: SystemTray.items

                        delegate: Image {
                            id: trayIcon

                            property bool isHovered: trayMouse.containsMouse
                            property bool initAnimTrigger: barWindow.startupCascadeFinished

                            source: modelData.icon || ""
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(18, 18)
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Layout.alignment: Qt.AlignVCenter
                            opacity: initAnimTrigger ? (isHovered ? 1 : 0.8) : 0
                            scale: initAnimTrigger ? (isHovered ? 1.15 : 1) : 0
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
                                onPressed: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (modelData.hasMenu && modelData.menu)
                                            menuAnchor.open();
                                        else if (typeof modelData.secondaryActivate === "function")
                                            modelData.secondaryActivate();
                                        else if (typeof modelData.contextMenu === "function")
                                            modelData.contextMenu(mouse.x, mouse.y);
                                        mouse.accepted = true;
                                    }
                                }
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (modelData.onlyMenu && modelData.hasMenu && modelData.menu)
                                            menuAnchor.open();
                                        else if (typeof modelData.activate === "function")
                                            modelData.activate();
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        if (typeof modelData.secondaryActivate === "function")
                                            modelData.secondaryActivate();

                                    }
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }

                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                }

                            }

                        }

                    }

                }

                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }

                }

            }

            Rectangle {
                property real targetWidth: sysLayout.implicitWidth + 20

                height: 48
                radius: 14
                color: theme.surface0
                border.color: theme.surface2
                border.width: 1
                Layout.preferredWidth: targetWidth

                RowLayout {
                    id: sysLayout

                    property int pillHeight: 34

                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        id: wifiPill

                        property bool isHovered: wifiMouse.containsMouse
                        property real targetWidth: wifiLayoutRow.implicitWidth + 24

                        radius: 10
                        Layout.preferredHeight: sysLayout.pillHeight
                        color: isHovered ? theme.surface2 : theme.surface1
                        Layout.preferredWidth: targetWidth
                        scale: isHovered ? 1.05 : 1

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: barWindow.isWifiOn ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 300
                                }

                            }

                            gradient: Gradient {
                                orientation: Gradient.Horizontal

                                GradientStop {
                                    position: 0
                                    color: theme.blue
                                }

                                GradientStop {
                                    position: 1
                                    color: theme.sapphire
                                }

                            }

                        }

                        RowLayout {
                            id: wifiLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: barWindow.wifiIcon
                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                font.pixelSize: 16
                                color: barWindow.isWifiOn ? theme.crust : theme.subtext0
                            }

                            Text {
                                text: {
                                    if (barWindow.wifiIcon === "󰤮")
                                        return "Wył.";

                                    if (barWindow.wifiIcon === "󰤯")
                                        return "Brak sieci";

                                    if (barWindow.wifiSsid !== "")
                                        return barWindow.wifiSsid;

                                    return "Połączone";
                                }
                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                font.pixelSize: 13
                                font.weight: Font.Black
                                color: barWindow.isWifiOn ? theme.crust : theme.text
                                Layout.maximumWidth: 100
                                elide: Text.ElideRight
                            }

                        }

                        MouseArea {
                            id: wifiMouse

                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            anchors.fill: parent
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                if (mouse.button === Qt.LeftButton)
                                    Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle network"]);
                                else if (mouse.button === Qt.RightButton)
                                    Quickshell.execDetached(["nm-connection-editor"]);
                            }
                        }

                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    Rectangle {
                        id: btPill

                        property bool isHovered: btMouse.containsMouse
                        property bool isRevealed: barWindow.isBtOn && barWindow.btDevice !== ""
                        property real targetWidth: btPill.isRevealed ? 160 : 40

                        radius: 10
                        Layout.preferredHeight: sysLayout.pillHeight
                        clip: true
                        color: isHovered ? theme.surface2 : theme.surface1
                        Layout.preferredWidth: targetWidth
                        scale: isHovered ? 1.05 : 1

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: barWindow.isBtOn ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 300
                                }

                            }

                            gradient: Gradient {
                                orientation: Gradient.Horizontal

                                GradientStop {
                                    position: 0
                                    color: theme.mauve
                                }

                                GradientStop {
                                    position: 1
                                    color: theme.pink
                                }

                            }

                        }

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
                                        color: btDisconnectMouse.containsMouse ? Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.3) : "transparent"

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

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }

                                        }

                                    }

                                }

                                Behavior on Layout.preferredWidth {
                                    NumberAnimation {
                                        duration: 350
                                        easing.type: Easing.OutExpo
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
                                mouse.accepted = true;
                                if (mouse.button === Qt.LeftButton)
                                    Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle network"]);
                                else if (mouse.button === Qt.RightButton)
                                    Quickshell.execDetached(["blueman-manager"]);
                            }
                        }

                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 350
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    Rectangle {
                        property bool isHovered: volMouse.containsMouse
                        property real targetWidth: volLayoutRow.implicitWidth + 24

                        color: barWindow.isMuted ? theme.surface1 : (isHovered ? theme.surface2 : theme.surface1)
                        radius: 10
                        Layout.preferredHeight: sysLayout.pillHeight
                        Layout.preferredWidth: targetWidth
                        scale: isHovered ? 1.05 : 1

                        RowLayout {
                            id: volLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: barWindow.isMuted ? "󰝟" : barWindow.volIcon
                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                font.pixelSize: 16
                                color: barWindow.isMuted ? theme.red : (volMouse.containsMouse ? theme.rosewater : theme.peach)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }

                                }

                            }

                            Text {
                                text: barWindow.volPercent
                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                font.pixelSize: 13
                                font.weight: Font.Black
                                color: barWindow.isMuted ? theme.subtext0 : theme.text
                                font.strikeout: barWindow.isMuted
                            }

                        }

                        MouseArea {
                            id: volMouse

                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            anchors.fill: parent
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                if (mouse.button === Qt.LeftButton)
                                    Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle mixer"]);
                                else if (mouse.button === Qt.RightButton)
                                    Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/scripts/sys_info.sh --toggle-mute"]);
                            }
                        }

                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    Rectangle {
                        property bool isHovered: batMouse.containsMouse
                        property real targetWidth: batLayoutRow.implicitWidth + 24

                        color: isHovered ? theme.surface2 : theme.surface1
                        radius: 10
                        Layout.preferredHeight: sysLayout.pillHeight
                        Layout.preferredWidth: targetWidth
                        scale: isHovered ? 1.05 : 1

                        RowLayout {
                            id: batLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "󰐥"
                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                font.pixelSize: 16
                                color: theme.green
                            }

                        }

                        MouseArea {
                            id: batMouse

                            hoverEnabled: true
                            anchors.fill: parent
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                Quickshell.execDetached(["bash", "-c", "~/.config/scripts/qs_manager.sh toggle dashboard"]);
                            }
                        }

                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                }

                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }

                }

            }

            transform: Translate {
                x: rightLayout.showLayout ? 0 : 20

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

}
