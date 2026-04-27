import QtCharts
//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    // --- CUSTOM COMPONENTS ---

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
    property var stats: ({
        "cpu": 0,
        "ram": 0,
        "down": 0,
        "up": 0,
        "gpu": 0,
        "gpu_mem": 0,
        "cpu_temp": 0,
        "gpu_temp": 0,
        "processes": [],
        "cpu_cores": []
    })
    property int currentTab: 0
    readonly property color tabColor: {
        if (currentTab === 0)
            return root.mauve;

        if (currentTab === 1)
            return root.sapphire;

        if (currentTab === 2)
            return root.blue;

        return root.green;
    }
    property string sortKey: "cpu"
    property bool sortDesc: true
    property string filterText: ""
    property int tick: 0
    readonly property int maxPoints: 60
    // --- ANIMATIONS ---
    property real introState: 0
    property real globalOrbitAngle: 0

    // --- SCALING HELPER ---
    function s(val) {
        return val * (Quickshell.screens[0].width / 1920);
    }

    function getPath(filename) {
        var path = Qt.resolvedUrl(filename).toString();
        return path.replace(/^(file:\/{2,3})/, "/");
    }

    function formatSpeed(bytes) {
        let b = parseFloat(bytes);
        if (b < 1024)
            return b.toFixed(0) + " B/s";

        let kb = b / 1024;
        if (kb < 1024)
            return kb.toFixed(1) + " KB/s";

        let mb = kb / 1024;
        if (mb < 1024)
            return mb.toFixed(1) + " MB/s";

        return (mb / 1024).toFixed(2) + " GB/s";
    }

    function formatMem(mb) {
        let val = parseFloat(mb);
        if (val < 1024)
            return val.toFixed(0) + " MB";

        return (val / 1024).toFixed(2) + " GB";
    }

    function toggleSort(key) {
        if (root.sortKey === key) {
            root.sortDesc = !root.sortDesc;
        } else {
            root.sortKey = key;
            root.sortDesc = true;
        }
        applySort();
    }

    function applySort() {
        if (!root.stats.processes)
            return ;

        let p = root.stats.processes;
        p.sort((a, b) => {
            let valA = a[root.sortKey];
            let valB = b[root.sortKey];
            if (typeof valA === "string") {
                valA = valA.toLowerCase();
                valB = valB.toLowerCase();
            }
            if (valA < valB)
                return root.sortDesc ? 1 : -1;

            if (valA > valB)
                return root.sortDesc ? -1 : 1;

            return 0;
        });
        root.stats.processes = p;
    }

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

    Process {
        id: statsProc

        command: ["bash", getPath("./get_stats.sh")]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        if (data.processes)
                            data.processes.sort((a, b) => {
                            let valA = a[root.sortKey];
                            let valB = b[root.sortKey];
                            if (typeof valA === "string") {
                                valA = valA.toLowerCase();
                                valB = valB.toLowerCase();
                            }
                            if (valA < valB)
                                return root.sortDesc ? 1 : -1;

                            if (valA > valB)
                                return root.sortDesc ? -1 : 1;

                            return 0;
                        });

                        let oldY = (typeof processList !== "undefined") ? processList.contentY : 0;
                        root.stats = data;
                        if (typeof processList !== "undefined")
                            processList.contentY = oldY;

                        root.tick++;
                        if (cpuChart)
                            cpuChart.addData(root.tick, data.cpu);

                        if (ramChart)
                            ramChart.addData(root.tick, data.ram);

                        if (downChart)
                            downChart.addData(root.tick, data.down / (1024 * 1024), true);

                        if (upChart)
                            upChart.addData(root.tick, data.up / (1024 * 1024), true);

                        if (gpuChart)
                            gpuChart.addData(root.tick, data.gpu);

                        if (gpuMemChart)
                            gpuMemChart.addData(root.tick, data.gpu_mem);

                    } catch (e) {
                    }
                }
            }
        }

    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsProc.running)
                statsProc.running = true;

        }
    }

    FloatingWindow {
        id: window

        title: "taskmanager_win"
        implicitWidth: 1050
        implicitHeight: 750
        visible: true
        color: "transparent"

        Item {
            anchors.fill: parent
            scale: 0.9 + (0.1 * root.introState)
            opacity: root.introState

            Rectangle {
                anchors.fill: parent
                color: root.base
                radius: 35
                border.color: root.surface0
                border.width: 1
                clip: true

                // --- BACKGROUND BLOBS (IDENTICAL TO MIXER) ---
                Rectangle {
                    width: parent.width * 0.8
                    height: width
                    radius: width / 2
                    x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * root.s(150)
                    y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * root.s(100)
                    opacity: 0.08
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
                    opacity: 0.06
                    color: Qt.lighter(root.tabColor, 1.3)

                    Behavior on color {
                        ColorAnimation {
                            duration: 800
                        }

                    }

                }

                // --- ROTATING ORBITS ---
                Repeater {
                    model: 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: 600 + index * 400
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: root.tabColor
                        border.width: 1
                        opacity: 0.03

                        Canvas {
                            id: orbitCanvas

                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.beginPath();
                                ctx.arc(width / 2, height / 2, width / 2 - 1, 0, Math.PI * 2);
                                ctx.strokeStyle = root.tabColor;
                                ctx.lineWidth = 4;
                                ctx.setLineDash([20, 60]);
                                ctx.stroke();
                            }

                            Connections {
                                function onTabColorChanged() {
                                    orbitCanvas.requestPaint();
                                }

                                target: root
                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 800
                            }

                        }

                        transform: Rotation {
                            origin.x: width / 2
                            origin.y: height / 2
                            angle: root.globalOrbitAngle * (180 / Math.PI) * (index === 0 ? 0.5 : -0.3)
                        }

                    }

                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // --- SIDEBAR ---
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 80
                        color: "#05ffffff"
                        border.color: "#1affffff"
                        border.width: 1

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 40
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 15

                            Repeater {
                                model: [{
                                    "icon": "󰆼",
                                    "name": "Procesy"
                                }, {
                                    "icon": "󰓅",
                                    "name": "Wydajność"
                                }, {
                                    "icon": "󰀂",
                                    "name": "Sieć"
                                }, {
                                    "icon": "󰢮",
                                    "name": "GPU"
                                }]

                                delegate: Rectangle {
                                    width: 56
                                    height: 56
                                    radius: 18
                                    color: root.currentTab === index ? root.mauve : (sideMa.containsMouse ? root.surface1 : "transparent")
                                    scale: sideMa.containsMouse ? 1.1 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 26
                                        color: root.currentTab === index ? root.base : (sideMa.containsMouse ? root.text : root.overlay2)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }

                                        }

                                    }

                                    MouseArea {
                                        id: sideMa

                                        anchors.fill: parent
                                        onClicked: root.currentTab = index
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
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

                            }

                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        // --- HEADER ---
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 90
                            color: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 40
                                anchors.rightMargin: 40

                                ColumnLayout {
                                    spacing: 2

                                    Text {
                                        text: ["PROCESY", "WYDAJNOŚĆ", "SIEĆ", "GPU"][root.currentTab]
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 24
                                        font.weight: Font.Black
                                        color: root.text
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 4
                                        radius: 2
                                        color: root.mauve
                                    }

                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Row {
                                    spacing: 15

                                    // CPU Capsule
                                    Rectangle {
                                        width: cpuRow.implicitWidth + 30
                                        height: 50
                                        radius: 15
                                        color: root.surface0
                                        border.color: root.surface1
                                        border.width: 1

                                        Row {
                                            id: cpuRow

                                            anchors.centerIn: parent
                                            spacing: 20

                                            StatPill {
                                                label: "CPU"
                                                value: root.stats.cpu.toFixed(0) + "%"
                                                col: root.mauve
                                            }

                                            StatPill {
                                                label: "TEMP"
                                                value: parseFloat(root.stats.cpu_temp).toFixed(0) + "°C"
                                                col: root.peach
                                            }

                                        }

                                    }

                                    // RAM Capsule
                                    Rectangle {
                                        width: ramRow.implicitWidth + 30
                                        height: 50
                                        radius: 15
                                        color: root.surface0
                                        border.color: root.surface1
                                        border.width: 1

                                        Row {
                                            id: ramRow

                                            anchors.centerIn: parent

                                            StatPill {
                                                label: "RAM"
                                                value: root.stats.ram.toFixed(0) + "%"
                                                col: root.sapphire
                                            }

                                        }

                                    }

                                    // GPU Capsule
                                    Rectangle {
                                        width: gpuRow.implicitWidth + 30
                                        height: 50
                                        radius: 15
                                        color: root.surface0
                                        border.color: root.surface1
                                        border.width: 1

                                        Row {
                                            id: gpuRow

                                            anchors.centerIn: parent
                                            spacing: 20

                                            StatPill {
                                                label: "GPU"
                                                value: root.stats.gpu + "%"
                                                col: root.green
                                            }

                                            StatPill {
                                                label: "TEMP"
                                                value: root.stats.gpu_temp + "°C"
                                                col: root.maroon
                                            }

                                        }

                                    }

                                }

                            }

                        }

                        // --- MAIN CONTENT ---
                        StackLayout {
                            currentIndex: root.currentTab
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            // Tab: Processes
                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 30
                                    spacing: 15

                                    // --- SEARCH BAR ---
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50
                                        color: root.surface0
                                        radius: 15
                                        border.color: root.surface1
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 20
                                            anchors.rightMargin: 20
                                            spacing: 12

                                            Text {
                                                text: "󰍉"
                                                font.family: "CaskaydiaCove Nerd Font"
                                                font.pixelSize: 20
                                                color: root.mauve
                                            }

                                            TextField {
                                                id: searchInput

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                placeholderText: "Szukaj procesu..."
                                                font.family: "CaskaydiaCove Nerd Font"
                                                font.pixelSize: 14
                                                font.weight: Font.Bold
                                                color: root.text
                                                placeholderTextColor: root.overlay0
                                                onTextChanged: root.filterText = text

                                                background: Item {
                                                }

                                            }

                                        }

                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50
                                        color: root.surface0
                                        radius: 15
                                        border.color: root.surface1
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 25
                                            anchors.rightMargin: 25
                                            spacing: 10

                                            HeaderBtn {
                                                label: "Nazwa"
                                                Layout.fillWidth: true
                                                key: "name"
                                            }

                                            HeaderBtn {
                                                label: "PID"
                                                Layout.preferredWidth: 80
                                                key: "pid"
                                            }

                                            HeaderBtn {
                                                label: "CPU %"
                                                Layout.preferredWidth: 100
                                                key: "cpu"
                                            }

                                            HeaderBtn {
                                                label: "RAM %"
                                                Layout.preferredWidth: 100
                                                key: "mem"
                                            }

                                            HeaderBtn {
                                                label: "Pamięć"
                                                Layout.preferredWidth: 100
                                                key: "mem_mb"
                                            }

                                            Item {
                                                Layout.preferredWidth: 40
                                            }

                                        }

                                    }

                                    ListView {
                                        id: processList

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: root.stats.processes ? root.stats.processes.filter((p) => {
                                            return p.name.toLowerCase().includes(root.filterText.toLowerCase());
                                        }) : []
                                        spacing: 6

                                        delegate: Rectangle {
                                            width: processList.width
                                            height: 48
                                            radius: 12
                                            color: "transparent"

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 12
                                                clip: true
                                                color: processMa.containsMouse ? root.surface1 : root.surface0
                                                border.color: processMa.containsMouse ? root.surface2 : "transparent"

                                                MouseArea {
                                                    id: processMa

                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    propagateComposedEvents: true
                                                }

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }

                                                }

                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 25
                                                anchors.rightMargin: 25
                                                spacing: 10

                                                Text {
                                                    text: modelData.name
                                                    Layout.fillWidth: true
                                                    color: root.text
                                                    font.family: "CaskaydiaCove Nerd Font"
                                                    font.weight: Font.Bold
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: modelData.pid
                                                    Layout.preferredWidth: 80
                                                    color: root.subtext0
                                                    font.family: "CaskaydiaCove Nerd Font"
                                                    font.pixelSize: 12
                                                }

                                                Text {
                                                    text: modelData.cpu.toFixed(1) + "%"
                                                    Layout.preferredWidth: 100
                                                    color: modelData.cpu > 20 ? root.red : root.mauve
                                                    font.family: "CaskaydiaCove Nerd Font"
                                                    font.weight: Font.Black
                                                    horizontalAlignment: Text.AlignLeft
                                                }

                                                Text {
                                                    text: modelData.mem.toFixed(1) + "%"
                                                    Layout.preferredWidth: 100
                                                    color: modelData.mem > 5 ? root.red : root.sapphire
                                                    font.family: "CaskaydiaCove Nerd Font"
                                                    font.weight: Font.Black
                                                    horizontalAlignment: Text.AlignLeft
                                                }

                                                Text {
                                                    text: root.formatMem(modelData.mem_mb)
                                                    Layout.preferredWidth: 100
                                                    color: root.subtext1
                                                    font.family: "CaskaydiaCove Nerd Font"
                                                    font.pixelSize: 12
                                                }

                                                Rectangle {
                                                    Layout.preferredWidth: 34
                                                    Layout.preferredHeight: 34
                                                    radius: 10
                                                    color: killMa.containsMouse ? root.red : "transparent"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰆴"
                                                        font.family: "CaskaydiaCove Nerd Font"
                                                        font.pixelSize: 20
                                                        color: killMa.containsMouse ? root.base : root.red
                                                    }

                                                    MouseArea {
                                                        id: killMa

                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: {
                                                            let pidStr = String(modelData.pid);
                                                            Quickshell.execDetached(["bash", "-c", "kill -9 " + pidStr]);
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }

                            // Tab: Performance
                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 35
                                    spacing: 30

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 25

                                        ChartWidget {
                                            id: cpuChart

                                            title: "UŻYCIE CPU"
                                            valueText: root.stats.cpu.toFixed(1) + "%"
                                            accentColor: root.mauve
                                            maxV: 100
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: "#08ffffff"
                                            radius: 25
                                            border.color: "#1affffff"
                                            border.width: 1

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 20
                                                spacing: 15

                                                Text {
                                                    text: "WĄTKI PROCESORA"
                                                    font.family: "CaskaydiaCove Nerd Font"
                                                    font.weight: Font.Black
                                                    font.pixelSize: 16
                                                    color: root.text
                                                }

                                                Flickable {
                                                    id: coreFlick

                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    clip: true
                                                    contentHeight: coreFlow.height

                                                    Flow {
                                                        id: coreFlow

                                                        width: coreFlick.width
                                                        spacing: 8

                                                        Repeater {
                                                            model: root.stats.cpu_cores

                                                            delegate: Rectangle {
                                                                width: (coreFlow.width - 8) / 2
                                                                height: 34
                                                                radius: 8
                                                                color: root.surface0
                                                                border.color: modelData > 80 ? root.red : (modelData > 50 ? root.yellow : root.surface1)

                                                                RowLayout {
                                                                    anchors.fill: parent
                                                                    anchors.leftMargin: 10
                                                                    anchors.rightMargin: 10
                                                                    spacing: 8

                                                                    Text {
                                                                        text: index
                                                                        font.family: "CaskaydiaCove Nerd Font"
                                                                        font.pixelSize: 10
                                                                        font.weight: Font.Black
                                                                        color: root.subtext0
                                                                        Layout.preferredWidth: 15
                                                                    }

                                                                    Rectangle {
                                                                        Layout.fillWidth: true
                                                                        height: 6
                                                                        radius: 3
                                                                        color: root.surface2

                                                                        Rectangle {
                                                                            width: parent.width * (modelData / 100)
                                                                            height: parent.height
                                                                            radius: 3
                                                                            color: modelData > 80 ? root.red : (modelData > 50 ? root.yellow : root.mauve)

                                                                            Behavior on width {
                                                                                NumberAnimation {
                                                                                    duration: 500
                                                                                    easing.type: Easing.OutCubic
                                                                                }

                                                                            }

                                                                        }

                                                                    }

                                                                    Text {
                                                                        text: modelData.toFixed(0) + "%"
                                                                        font.family: "CaskaydiaCove Nerd Font"
                                                                        font.pixelSize: 9
                                                                        font.weight: Font.Bold
                                                                        color: root.text
                                                                        Layout.preferredWidth: 25
                                                                        horizontalAlignment: Text.AlignRight
                                                                    }

                                                                }

                                                            }

                                                        }

                                                    }

                                                    ScrollBar.vertical: ScrollBar {
                                                        policy: ScrollBar.AsNeeded
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    ChartWidget {
                                        id: ramChart

                                        title: "UŻYCIE PAMIĘCI: " + root.formatMem(root.stats.ram_used || 0) + "/" + root.formatMem(root.stats.ram_total || 0) + " (" + (root.stats.ram || 0).toFixed(1) + "%)"
                                        valueText: ""
                                        accentColor: root.sapphire
                                        maxV: 100
                                    }

                                }

                            }

                            // Tab: Network
                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 35
                                    spacing: 30

                                    ChartWidget {
                                        id: downChart

                                        title: "POBIERANIE"
                                        valueText: root.formatSpeed(root.stats.down)
                                        accentColor: root.blue
                                        maxV: 10
                                        isDynamic: true
                                    }

                                    ChartWidget {
                                        id: upChart

                                        title: "WYSYŁANIE"
                                        valueText: root.formatSpeed(root.stats.up)
                                        accentColor: root.pink
                                        maxV: 2
                                        isDynamic: true
                                    }

                                }

                            }

                            // Tab: GPU
                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 35
                                    spacing: 30

                                    ChartWidget {
                                        id: gpuChart

                                        title: "PROCESOR GRAFICZNY:"
                                        valueText: (root.stats.gpu || 0) + "%"
                                        accentColor: root.green
                                        maxV: 100
                                    }

                                    ChartWidget {
                                        id: gpuMemChart

                                        title: "VRAM: " + ((root.stats.gpu_mem_used || 0) / 1024).toFixed(2) + "/" + ((root.stats.gpu_mem_total || 0) / 1024).toFixed(2) + " GB (" + (root.stats.gpu_mem || 0) + "%)"
                                        valueText: ""
                                        accentColor: root.peach
                                        maxV: 100
                                    }

                                }

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

    component StatPill: RowLayout {
        property string label: ""
        property string value: ""
        property color col: "white"

        spacing: 10

        Rectangle {
            width: 12
            height: 12
            radius: 6
            color: parent.col
        }

        Column {
            Text {
                text: parent.parent.label
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: root.overlay1
            }

            Text {
                text: parent.parent.value
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 16
                font.weight: Font.Black
                color: root.text
            }

        }

    }

    component HeaderBtn: MouseArea {
        property string label: ""
        property string key: ""

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleSort(key)

        RowLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                text: parent.parent.label
                font.weight: Font.Black
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 12
                color: root.sortKey === parent.parent.key ? root.mauve : root.subtext0
            }

            Text {
                visible: root.sortKey === parent.parent.key
                text: root.sortDesc ? "󰁅" : "󰁝"
                font.family: "CaskaydiaCove Nerd Font"
                color: root.mauve
            }

        }

    }

    component ChartWidget: Rectangle {
        id: chartWidgetRoot

        property string title: ""
        property string valueText: ""
        property color accentColor: "white"
        property real maxV: 100
        property bool isDynamic: false

        function addData(x, y, dynamic = false) {
            lineSeries.append(x, y);
            if (lineSeries.count > root.maxPoints)
                lineSeries.remove(0);

            if (chartWidgetRoot.isDynamic) {
                let maxVal = 1;
                for (let i = 0; i < lineSeries.count; i++) {
                    if (lineSeries.at(i).y > maxVal)
                        maxVal = lineSeries.at(i).y;

                }
                chartWidgetRoot.maxV = maxVal * 1.2;
            }
            axisX.min = lineSeries.at(0).x;
            axisX.max = Math.max(axisX.min + root.maxPoints, lineSeries.at(lineSeries.count - 1).x);
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "#08ffffff"
        radius: 25
        border.color: "#1affffff"
        border.width: 1

        ChartView {
            anchors.fill: parent
            anchors.margins: 15
            title: chartWidgetRoot.title + "   " + chartWidgetRoot.valueText
            titleColor: root.text
            titleFont.family: "JetBrains Mono"
            titleFont.weight: Font.Black
            titleFont.pixelSize: 16
            backgroundColor: "transparent"
            legend.visible: false
            antialiasing: true
            plotAreaColor: "transparent"

            ValueAxis {
                id: axisX

                min: 0
                max: root.maxPoints
                visible: false
            }

            ValueAxis {
                id: axisY

                min: 0
                max: chartWidgetRoot.maxV
                labelsColor: root.overlay2
                gridLineColor: "#1affffff"
                labelsFont.family: "JetBrains Mono"
                labelsFont.pixelSize: 10
                labelFormat: chartWidgetRoot.isDynamic ? "%.1f" : "%d"
                tickCount: 5
            }

            AreaSeries {
                axisX: axisX
                axisY: axisY
                color: Qt.rgba(chartWidgetRoot.accentColor.r, chartWidgetRoot.accentColor.g, chartWidgetRoot.accentColor.b, 0.15)
                borderColor: chartWidgetRoot.accentColor
                borderWidth: 3

                upperSeries: LineSeries {
                    id: lineSeries

                    capStyle: Qt.RoundCap
                }

            }

        }

    }

}
