import "."
import QtCore
//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    // --- COLOR MAPPINGS ---
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
    readonly property color maroon: theme.maroon
    // --- STATE & CONFIG ---
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/quickshell/mixer"
    property string activeTab: "outputs" // outputs, inputs, apps
    readonly property color tabColor: {
        if (activeTab === "outputs")
            return root.blue;

        if (activeTab === "inputs")
            return root.mauve;

        return root.green;
    }
    property real globalOrbitAngle: 0
    // Top Orb Active State Links
    property string activeId: ""
    property string activeName: "No Device"
    property string activeDesc: ""
    property int activeVol: 0
    property bool activeMute: false
    property string activeIcon: "󰓃"
    property var draggingNodes: ({
    })
    property bool draggingMaster: false
    // --- ANIMATIONS ---
    property real introMain: 0
    property real introHeader: 0
    property real introContent: 0

    // --- SCALING HELPER ---
    function s(val) {
        // Simple scaling based on a reference width of 1920
        return val * (Quickshell.screens[0].width / 1920);
    }

    function processAudioJson(textData) {
        if (!textData)
            return ;

        try {
            let data = JSON.parse(textData);
            syncModel(outputsModel, data.outputs || []);
            syncModel(inputsModel, data.inputs || []);
            syncModel(appsModel, data.apps || []);
            updateHeroData();
        } catch (e) {
        }
    }

    function updateHeroData() {
        let targetModel = (root.activeTab === "inputs") ? inputsModel : outputsModel;
        let foundDefault = false;
        for (let i = 0; i < targetModel.count; i++) {
            let d = targetModel.get(i);
            if (d.is_default) {
                root.activeId = d.id;
                root.activeName = d.description;
                root.activeDesc = d.name;
                root.activeIcon = d.icon;
                if (!root.draggingMaster) {
                    root.activeVol = d.volume;
                    root.activeMute = d.mute;
                }
                foundDefault = true;
                break;
            }
        }
        if (!foundDefault && targetModel.count > 0) {
            let d = targetModel.get(0);
            root.activeId = d.id;
            root.activeName = d.description;
            root.activeDesc = d.name;
            root.activeIcon = d.icon;
            if (!root.draggingMaster) {
                root.activeVol = d.volume;
                root.activeMute = d.mute;
            }
        }
    }

    function syncModel(listModel, dataArray) {
        for (let i = listModel.count - 1; i >= 0; i--) {
            let id = listModel.get(i).id;
            let found = false;
            for (let j = 0; j < dataArray.length; j++) {
                if (id === dataArray[j].id) {
                    found = true;
                    break;
                }
            }
            if (!found)
                listModel.remove(i);

        }
        for (let i = 0; i < dataArray.length; i++) {
            let d = dataArray[i];
            let foundIdx = -1;
            for (let j = i; j < listModel.count; j++) {
                if (listModel.get(j).id === d.id) {
                    foundIdx = j;
                    break;
                }
            }
            let obj = {
                "id": d.id,
                "name": d.name,
                "description": d.description,
                "volume": d.volume,
                "mute": d.mute,
                "is_default": d.is_default,
                "icon": d.icon
            };
            if (foundIdx === -1) {
                listModel.insert(i, obj);
            } else {
                if (foundIdx !== i)
                    listModel.move(foundIdx, i, 1);

                for (let key in obj) {
                    if (key === "volume" && root.draggingNodes[obj.id])
                        continue;

                    if (listModel.get(i)[key] !== obj[key])
                        listModel.setProperty(i, key, obj[key]);

                }
            }
        }
    }

    onActiveTabChanged: updateHeroData()

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

    // Models
    ListModel {
        id: outputsModel
    }

    ListModel {
        id: inputsModel
    }

    ListModel {
        id: appsModel
    }

    Timer {
        id: syncDelay

        interval: 600
        onTriggered: {
            root.draggingNodes = ({
            });
            root.draggingMaster = false;
        }
    }

    Process {
        id: audioPoller

        command: ["python3", root.scriptsDir + "/get_audio_state.py"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                processAudioJson(this.text.trim());
            }
        }

    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: audioPoller.running = true
    }

    ParallelAnimation {
        running: true

        NumberAnimation {
            target: root
            property: "introMain"
            from: 0
            to: 1
            duration: 800
            easing.type: Easing.OutExpo
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 100
            }

            NumberAnimation {
                target: root
                property: "introHeader"
                from: 0
                to: 1
                duration: 700
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 200
            }

            NumberAnimation {
                target: root
                property: "introContent"
                from: 0
                to: 1
                duration: 800
                easing.type: Easing.OutExpo
            }

        }

    }

    FloatingWindow {
        id: window

        title: "mixer_win"
        implicitWidth: root.s(850)
        implicitHeight: root.s(700)
        visible: true
        color: "transparent"

        Item {
            anchors.fill: parent
            scale: 0.95 + (0.05 * root.introMain)
            opacity: root.introMain

            Rectangle {
                anchors.fill: parent
                radius: root.s(35)
                color: root.base
                border.color: root.surface0
                border.width: 1
                clip: true

                // Rotating Background Blobs
                Rectangle {
                    width: parent.width * 0.8
                    height: width
                    radius: width / 2
                    x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * root.s(150)
                    y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * root.s(100)
                    opacity: 0.06
                    color: root.tabColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 800
                        }

                    }

                }

                Rectangle {
                    width: parent.width * 0.9
                    height: width
                    radius: width / 2
                    x: (parent.width / 2 - width / 2) + Math.sin(root.globalOrbitAngle * 1.5) * root.s(-150)
                    y: (parent.height / 2 - height / 2) + Math.cos(root.globalOrbitAngle * 1.5) * root.s(-100)
                    opacity: 0.04
                    color: Qt.lighter(root.tabColor, 1.3)

                    Behavior on color {
                        ColorAnimation {
                            duration: 800
                        }

                    }

                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.s(25)
                    spacing: root.s(20)

                    // HERO ORB & MASTER SLIDER
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(150)
                        opacity: root.introHeader

                        RowLayout {
                            anchors.fill: parent
                            spacing: root.s(25)

                            Item {
                                Layout.preferredWidth: root.s(130)
                                Layout.preferredHeight: root.s(130)
                                scale: masterOrbMa.pressed ? 0.95 : (masterOrbMa.containsMouse ? 1.05 : 1)

                                Rectangle {
                                    property real pulseOp: 0
                                    property real pulseSc: 1

                                    anchors.centerIn: parent
                                    width: parent.width + root.s(15)
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: root.activeMute ? root.red : root.tabColor
                                    border.width: root.s(3)
                                    z: -2
                                    opacity: root.activeMute ? 0 : pulseOp
                                    scale: pulseSc

                                    Timer {
                                        interval: 45
                                        running: parent.opacity > 0.01 || !root.activeMute
                                        repeat: true
                                        onTriggered: {
                                            var time = Date.now() / 1000;
                                            parent.pulseOp = 0.3 + Math.sin(time * 2.5) * 0.15;
                                            parent.pulseSc = 1.02 + Math.cos(time * 3) * 0.02;
                                        }
                                    }

                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width + root.s(40)
                                    height: width
                                    radius: width / 2
                                    color: root.activeMute ? root.red : root.tabColor
                                    opacity: root.activeMute ? 0.3 : 0.15
                                    z: -1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 300
                                        }

                                    }

                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite
                                        running: true

                                        NumberAnimation {
                                            to: masterOrbMa.containsMouse ? 1.15 : 1.1
                                            duration: masterOrbMa.containsMouse ? 800 : 2000
                                            easing.type: Easing.InOutSine
                                        }

                                        NumberAnimation {
                                            to: 1
                                            duration: masterOrbMa.containsMouse ? 800 : 2000
                                            easing.type: Easing.InOutSine
                                        }

                                    }

                                }

                                MultiEffect {
                                    source: centralCore
                                    anchors.fill: centralCore
                                    shadowEnabled: true
                                    shadowColor: "#000000"
                                    shadowOpacity: 0.5
                                    shadowBlur: 1.2
                                    shadowVerticalOffset: root.s(6)
                                    z: -1
                                }

                                Rectangle {
                                    id: centralCore

                                    anchors.fill: parent
                                    radius: width / 2
                                    color: root.base
                                    border.color: root.activeMute ? root.red : Qt.lighter(root.tabColor, 1.1)
                                    border.width: 2
                                    clip: true

                                    Canvas {
                                        id: orbWave

                                        property real wavePhase: 0

                                        anchors.fill: parent
                                        onWavePhaseChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);
                                            if (root.activeVol <= 0)
                                                return ;

                                            var fillRatio = root.activeVol / 100;
                                            var r = width / 2;
                                            var fillY = height * (1 - fillRatio);
                                            ctx.save();
                                            ctx.beginPath();
                                            ctx.arc(r, r, r, 0, 2 * Math.PI);
                                            ctx.clip();
                                            ctx.beginPath();
                                            ctx.moveTo(0, fillY);
                                            if (fillRatio < 0.99) {
                                                var waveAmp = root.s(8) * Math.sin(fillRatio * Math.PI);
                                                var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
                                                var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
                                                ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
                                                ctx.lineTo(width, height);
                                                ctx.lineTo(0, height);
                                            } else {
                                                ctx.lineTo(width, 0);
                                                ctx.lineTo(width, height);
                                                ctx.lineTo(0, height);
                                            }
                                            ctx.closePath();
                                            var grad = ctx.createLinearGradient(0, 0, 0, height);
                                            if (root.activeMute) {
                                                grad.addColorStop(0, Qt.lighter(root.red, 1.15).toString());
                                                grad.addColorStop(1, root.red.toString());
                                            } else {
                                                grad.addColorStop(0, Qt.lighter(root.tabColor, 1.15).toString());
                                                grad.addColorStop(1, root.tabColor.toString());
                                            }
                                            ctx.fillStyle = grad;
                                            ctx.globalAlpha = 1;
                                            ctx.fill();
                                            ctx.restore();
                                        }

                                        Connections {
                                            function onActiveVolChanged() {
                                                orbWave.requestPaint();
                                            }

                                            function onActiveMuteChanged() {
                                                orbWave.requestPaint();
                                            }

                                            function onTabColorChanged() {
                                                orbWave.requestPaint();
                                            }

                                            target: root
                                        }

                                        NumberAnimation on wavePhase {
                                            running: root.activeVol > 0 && root.activeVol < 100
                                            loops: Animation.Infinite
                                            from: 0
                                            to: Math.PI * 2
                                            duration: 1200
                                        }

                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Black
                                        font.pixelSize: root.s(32)
                                        color: root.activeMute ? root.red : root.text
                                        text: root.activeMute ? "󰝟" : root.activeVol + "%"

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }

                                        }

                                    }

                                    Item {
                                        id: waveClipItem

                                        property real fillRatio: root.activeVol / 100
                                        property real waveAmp: fillRatio < 0.99 ? root.s(8) * Math.sin(fillRatio * Math.PI) : 0
                                        property real waveCenterOffset: 0.375 * waveAmp * (Math.sin(orbWave.wavePhase) - Math.cos(orbWave.wavePhase))
                                        property real baseClipHeight: parent.height * fillRatio

                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: Math.min(parent.height, Math.max(0, baseClipHeight - waveCenterOffset))
                                        clip: true
                                        visible: root.activeVol > 0

                                        Text {
                                            x: waveClipItem.width / 2 - width / 2
                                            y: (centralCore.height / 2) - (height / 2) - (centralCore.height - waveClipItem.height)
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Black
                                            font.pixelSize: root.s(32)
                                            color: root.crust
                                            text: root.activeMute ? "󰝟" : root.activeVol + "%"
                                        }

                                    }

                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: 300
                                        }

                                    }

                                }

                                MouseArea {
                                    id: masterOrbMa

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let type = root.activeTab === "inputs" ? "source" : "sink";
                                        Quickshell.execDetached(["bash", root.scriptsDir + "/audio_control.sh", "toggle-mute", type, root.activeId]);
                                        audioPoller.running = true;
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 400
                                        easing.type: Easing.OutBack
                                    }

                                }

                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: root.s(10)

                                ColumnLayout {
                                    spacing: root.s(2)

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Black
                                        font.pixelSize: root.s(20)
                                        color: root.text
                                        text: root.activeName
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: root.s(13)
                                        color: root.subtext0
                                        text: root.activeTab === "apps" ? "Master Output Volume" : root.activeDesc
                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: root.s(15)

                                    Item {
                                        Layout.fillWidth: true
                                        height: root.s(24)

                                        Timer {
                                            id: masterCmdThrottle

                                            property int targetPct: -1

                                            interval: 50
                                            onTriggered: {
                                                if (targetPct >= 0) {
                                                    let type = root.activeTab === "inputs" ? "source" : "sink";
                                                    if (targetPct > 0 && root.activeMute)
                                                        Quickshell.execDetached(["bash", root.scriptsDir + "/audio_control.sh", "toggle-mute", type, root.activeId]);

                                                    Quickshell.execDetached(["bash", root.scriptsDir + "/audio_control.sh", "set-volume", type, root.activeId, targetPct]);
                                                    targetPct = -1;
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: root.s(12)
                                            color: "#0dffffff"
                                            border.color: "#1affffff"
                                            border.width: 1
                                            clip: true

                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * (Math.min(100, root.activeVol) / 100)
                                                radius: root.s(12)
                                                opacity: root.activeMute ? 0.3 : (masterSliderMa.containsMouse ? 1 : 0.85)

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 200
                                                    }

                                                }

                                                Behavior on width {
                                                    enabled: !root.draggingMaster

                                                    NumberAnimation {
                                                        duration: 300
                                                        easing.type: Easing.OutQuint
                                                    }

                                                }

                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal

                                                    GradientStop {
                                                        position: 0
                                                        color: root.activeMute ? root.surface2 : root.tabColor

                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: 300
                                                            }

                                                        }

                                                    }

                                                    GradientStop {
                                                        position: 1
                                                        color: root.activeMute ? Qt.lighter(root.surface2, 1.15) : Qt.lighter(root.tabColor, 1.25)

                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: 300
                                                            }

                                                        }

                                                    }

                                                }

                                            }

                                        }

                                        MouseArea {
                                            id: masterSliderMa

                                            function updateVol(mx) {
                                                let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                                root.activeVol = pct;
                                                masterCmdThrottle.targetPct = pct;
                                                if (!masterCmdThrottle.running)
                                                    masterCmdThrottle.start();

                                            }

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: (mouse) => {
                                                syncDelay.stop();
                                                root.draggingMaster = true;
                                                updateVol(mouse.x);
                                            }
                                            onPositionChanged: (mouse) => {
                                                if (pressed)
                                                    updateVol(mouse.x);

                                            }
                                            onReleased: {
                                                syncDelay.restart();
                                                audioPoller.running = true;
                                            }
                                        }

                                    }

                                }

                            }

                        }

                        transform: Translate {
                            y: root.s(30) * (1 - root.introHeader)
                        }

                    }

                    // TABS
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(54)
                        radius: root.s(14)
                        color: "#0dffffff"
                        border.color: "#1affffff"
                        border.width: 1
                        opacity: root.introHeader

                        Rectangle {
                            width: (parent.width - root.s(2)) / 3
                            height: parent.height - root.s(2)
                            y: root.s(1)
                            radius: root.s(10)
                            x: {
                                if (root.activeTab === "outputs")
                                    return root.s(1);

                                if (root.activeTab === "inputs")
                                    return width + root.s(1);

                                return (width * 2) + root.s(1);
                            }

                            Behavior on x {
                                NumberAnimation {
                                    duration: 500
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.1
                                }

                            }

                            gradient: Gradient {
                                orientation: Gradient.Horizontal

                                GradientStop {
                                    position: 0
                                    color: root.tabColor

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 400
                                        }

                                    }

                                }

                                GradientStop {
                                    position: 1
                                    color: Qt.lighter(root.tabColor, 1.15)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 400
                                        }

                                    }

                                }

                            }

                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Repeater {

                                model: ListModel {
                                    ListElement {
                                        tabId: "outputs"
                                        icon: "󰓃"
                                        label: "Wyjścia"
                                    }

                                    ListElement {
                                        tabId: "inputs"
                                        icon: "󰍬"
                                        label: "Wejścia"
                                    }

                                    ListElement {
                                        tabId: "apps"
                                        icon: "󰎆"
                                        label: "Aplikacje"
                                    }

                                }

                                delegate: Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: root.s(8)

                                        Text {
                                            font.family: "CaskaydiaCove Nerd Font"
                                            font.pixelSize: root.s(18)
                                            color: root.activeTab === tabId ? root.crust : (tabMa.containsMouse ? root.text : root.subtext0)
                                            text: icon

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }

                                            }

                                        }

                                        Text {
                                            font.family: "CaskaydiaCove Nerd Font"
                                            font.weight: Font.Black
                                            font.pixelSize: root.s(13)
                                            color: root.activeTab === tabId ? root.crust : (tabMa.containsMouse ? root.text : root.subtext0)
                                            text: label

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }

                                            }

                                        }

                                    }

                                    MouseArea {
                                        id: tabMa

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.activeTab = tabId;
                                        }
                                    }

                                }

                            }

                        }

                        transform: Translate {
                            y: root.s(20) * (1 - root.introHeader)
                        }

                    }

                    // LIST VIEW CONTENT
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: root.introContent

                        ListView {
                            id: contentList

                            anchors.fill: parent
                            spacing: root.s(12)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: {
                                if (root.activeTab === "outputs")
                                    return outputsModel;

                                if (root.activeTab === "inputs")
                                    return inputsModel;

                                return appsModel;
                            }

                            Item {
                                width: contentList.width
                                height: contentList.height
                                visible: contentList.count === 0

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: root.s(10)

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: root.s(32)
                                        color: root.surface2
                                        text: "󰖁"
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: root.s(14)
                                        color: root.overlay0
                                        text: "Brak aktywnych strumieni"
                                    }

                                }

                            }

                            add: Transition {
                                NumberAnimation {
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 400
                                    easing.type: Easing.OutQuint
                                }

                                NumberAnimation {
                                    property: "scale"
                                    from: 0.9
                                    to: 1
                                    duration: 400
                                    easing.type: Easing.OutBack
                                }

                            }

                            displaced: Transition {
                                SpringAnimation {
                                    property: "y"
                                    spring: 3
                                    damping: 0.2
                                    mass: 0.2
                                }

                            }

                            delegate: Rectangle {
                                id: delegateRoot

                                property bool isLoaded: false
                                property bool isActiveNode: model.is_default && root.activeTab !== "apps"
                                property bool isHovered: cardMa.containsMouse && !isActiveNode

                                width: contentList.width
                                opacity: isLoaded ? 1 : 0
                                height: isActiveNode ? root.s(60) : root.s(100)
                                radius: root.s(14)
                                color: isActiveNode ? root.tabColor : (isHovered ? "#0affffff" : "#05ffffff")
                                border.color: isActiveNode ? root.tabColor : "#1affffff"
                                border.width: isActiveNode ? 2 : 1

                                Timer {
                                    running: true
                                    interval: 40 + (index * 40)
                                    onTriggered: delegateRoot.isLoaded = true
                                }

                                MouseArea {
                                    id: cardMa

                                    anchors.fill: parent
                                    hoverEnabled: root.activeTab !== "apps"
                                    cursorShape: root.activeTab !== "apps" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (root.activeTab !== "apps" && !model.is_default) {
                                            let type = root.activeTab === "outputs" ? "sink" : "source";
                                            Quickshell.execDetached(["bash", root.scriptsDir + "/audio_control.sh", "set-default", type, model.name]);
                                            audioPoller.running = true;
                                        }
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.s(16)
                                    anchors.rightMargin: root.s(16)
                                    anchors.topMargin: root.s(12)
                                    anchors.bottomMargin: isActiveNode ? root.s(12) : root.s(16)
                                    spacing: root.s(12)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: root.s(12)

                                        Text {
                                            font.family: "CaskaydiaCove Nerd Font"
                                            font.pixelSize: root.s(22)
                                            color: isActiveNode ? root.crust : root.text
                                            text: {
                                                if (root.activeTab === "inputs")
                                                    return "󰍬";

                                                if (root.activeTab === "apps")
                                                    return "󰎆";

                                                if (model.description.toLowerCase().indexOf("headset") !== -1 || model.description.toLowerCase().indexOf("headphones") !== -1)
                                                    return "󰋎";

                                                return "󰓃";
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }

                                            }

                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: root.s(2)

                                            Text {
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                font.family: "CaskaydiaCove Nerd Font"
                                                font.weight: Font.Bold
                                                font.pixelSize: root.s(14)
                                                color: isActiveNode ? root.crust : root.text
                                                text: model.description
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                font.family: "CaskaydiaCove Nerd Font"
                                                font.pixelSize: root.s(11)
                                                color: isActiveNode ? Qt.darker(root.crust, 1.5) : root.subtext0
                                                text: isActiveNode ? "Domyślne urządzenie" : model.name
                                            }

                                        }

                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: root.s(15)
                                        visible: !isActiveNode
                                        opacity: isActiveNode ? 0 : 1

                                        Rectangle {
                                            Layout.preferredWidth: root.s(32)
                                            Layout.preferredHeight: root.s(32)
                                            radius: root.s(16)
                                            color: muteMa.containsMouse ? "#1affffff" : "transparent"
                                            border.color: muteMa.containsMouse ? (model.mute ? root.overlay0 : root.tabColor) : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: "CaskaydiaCove Nerd Font"
                                                font.pixelSize: root.s(18)
                                                color: model.mute ? root.overlay0 : root.subtext0
                                                text: model.mute || model.volume === 0 ? "󰖁" : (model.volume > 50 ? "󰕾" : "󰖀")

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 200
                                                    }

                                                }

                                            }

                                            MouseArea {
                                                id: muteMa

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let type = "sink";
                                                    if (root.activeTab === "inputs")
                                                        type = "source";

                                                    if (root.activeTab === "apps")
                                                        type = "sink-input";

                                                    Quickshell.execDetached(["bash", root.scriptsDir + "/audio_control.sh", "toggle-mute", type, model.id]);
                                                    audioPoller.running = true;
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }

                                            }

                                        }

                                        Item {
                                            Layout.fillWidth: true
                                            height: root.s(14)

                                            Timer {
                                                id: volCmdThrottle

                                                property int targetPct: -1

                                                interval: 50
                                                onTriggered: {
                                                    if (targetPct >= 0) {
                                                        let type = "sink";
                                                        if (root.activeTab === "inputs")
                                                            type = "source";

                                                        if (root.activeTab === "apps")
                                                            type = "sink-input";

                                                        if (targetPct > 0 && model.mute)
                                                            Quickshell.execDetached(["bash", root.scriptsDir + "/audio_control.sh", "toggle-mute", type, model.id]);

                                                        Quickshell.execDetached(["bash", root.scriptsDir + "/audio_control.sh", "set-volume", type, model.id, targetPct]);
                                                        targetPct = -1;
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: root.s(7)
                                                color: "#0dffffff"
                                                border.color: "#1affffff"
                                                border.width: 1
                                                clip: true

                                                Rectangle {
                                                    height: parent.height
                                                    width: parent.width * (Math.min(100, model.volume) / 100)
                                                    radius: root.s(7)
                                                    opacity: model.mute ? 0.3 : (volSliderMa.containsMouse ? 0.7 : 0.4)

                                                    Behavior on opacity {
                                                        NumberAnimation {
                                                            duration: 200
                                                        }

                                                    }

                                                    Behavior on width {
                                                        enabled: !root.draggingNodes[model.id]

                                                        NumberAnimation {
                                                            duration: 300
                                                            easing.type: Easing.OutQuint
                                                        }

                                                    }

                                                    gradient: Gradient {
                                                        orientation: Gradient.Horizontal

                                                        GradientStop {
                                                            position: 0
                                                            color: model.mute ? root.surface2 : root.tabColor

                                                            Behavior on color {
                                                                ColorAnimation {
                                                                    duration: 300
                                                                }

                                                            }

                                                        }

                                                        GradientStop {
                                                            position: 1
                                                            color: model.mute ? Qt.lighter(root.surface2, 1.15) : Qt.lighter(root.tabColor, 1.25)

                                                            Behavior on color {
                                                                ColorAnimation {
                                                                    duration: 300
                                                                }

                                                            }

                                                        }

                                                    }

                                                }

                                            }

                                            MouseArea {
                                                id: volSliderMa

                                                function updateVol(mx) {
                                                    let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                                    let targetList = root.activeTab === "outputs" ? outputsModel : (root.activeTab === "inputs" ? inputsModel : appsModel);
                                                    for (let i = 0; i < targetList.count; i++) {
                                                        if (targetList.get(i).id === model.id) {
                                                            targetList.setProperty(i, "volume", pct);
                                                            break;
                                                        }
                                                    }
                                                    volCmdThrottle.targetPct = pct;
                                                    if (!volCmdThrottle.running)
                                                        volCmdThrottle.start();

                                                }

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onPressed: (mouse) => {
                                                    syncDelay.stop();
                                                    root.draggingNodes[model.id] = true;
                                                    updateVol(mouse.x);
                                                }
                                                onPositionChanged: (mouse) => {
                                                    if (pressed)
                                                        updateVol(mouse.x);

                                                }
                                                onReleased: {
                                                    syncDelay.restart();
                                                    audioPoller.running = true;
                                                }
                                            }

                                        }

                                        Text {
                                            Layout.preferredWidth: root.s(35)
                                            font.family: "CaskaydiaCove Nerd Font"
                                            font.weight: Font.Bold
                                            font.pixelSize: root.s(12)
                                            color: root.subtext0
                                            text: model.volume + "%"
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }

                                        }

                                    }

                                }

                                transform: Translate {
                                    y: isLoaded ? 0 : root.s(15)
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutQuint
                                    }

                                }

                                Behavior on transform {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutQuint
                                    }

                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 400
                                        easing.type: Easing.OutQuint
                                    }

                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                            }

                        }

                        transform: Translate {
                            y: root.s(20) * (1 - root.introContent)
                        }

                    }

                }

            }

            transform: Translate {
                y: root.s(20) * (1 - root.introMain)
            }

        }

    }

    NumberAnimation on globalOrbitAngle {
        from: 0
        to: Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }

}
