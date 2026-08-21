import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: powermenuWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    exclusionMode: ExclusionMode.Ignore
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    color: "transparent"

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    // -------------------------------------------------------------------------
    // COLOR MAPPINGS
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // PATHS & STATE
    // -------------------------------------------------------------------------
    property string scriptsDir: Quickshell.env("HOME") + "/.config/quickshell/dashboard_v2"
    property var statsData: null
    property var weatherData: null
    property int monthOffset: 0
    property string targetMonthName: ""

    // Helper functions for Polish calendar & uptime translation
    function getPolishMonthName(monthIndex) {
        const months = ["Styczeń", "Luty", "Marzec", "Kwiecień", "Maj", "Czerwiec", "Lipiec", "Sierpień", "Wrzesień", "Październik", "Listopad", "Grudzień"];
        return months[monthIndex];
    }

    function getDaysText(days) {
        if (days === 1) return "Dzień";
        return "Dni";
    }
    
    function getHoursText(hours) {
        if (hours === 1) return "godzina";
        let lastDigit = hours % 10;
        let lastTwo = hours % 100;
        if (lastDigit >= 2 && lastDigit <= 4 && (lastTwo < 10 || lastTwo > 20)) {
            return "godziny";
        }
        return "godzin";
    }

    function getMinsText(mins) {
        if (mins === 1) return "minuta";
        let lastDigit = mins % 10;
        let lastTwo = mins % 100;
        if (lastDigit >= 2 && lastDigit <= 4 && (lastTwo < 10 || lastTwo > 20)) {
            return "minuty";
        }
        return "minut";
    }

    function updateCalendarGrid() {
        let d = new Date();
        d.setDate(1);
        d.setMonth(d.getMonth() + powermenuWindow.monthOffset);
        let targetMonth = d.getMonth();
        let targetYear = d.getFullYear();
        let actualToday = new Date();
        let isRealCurrentMonth = (actualToday.getMonth() === targetMonth && actualToday.getFullYear() === targetYear);
        let todayDate = actualToday.getDate();
        powermenuWindow.targetMonthName = getPolishMonthName(targetMonth);
        let targetYearStr = targetYear.toString();
        
        let firstDay = new Date(targetYear, targetMonth, 1).getDay(); // Sunday=0
        let daysInMonth = new Date(targetYear, targetMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(targetYear, targetMonth, 0).getDate();
        
        calendarModel.clear();
        for (let i = firstDay - 1; i >= 0; i--) {
            calendarModel.append({
                "dayNum": (daysInPrevMonth - i).toString(),
                "isCurrentMonth": false,
                "isToday": false
            });
        }
        for (let i = 1; i <= daysInMonth; i++) {
            calendarModel.append({
                "dayNum": i.toString(),
                "isCurrentMonth": true,
                "isToday": (isRealCurrentMonth && i === todayDate)
            });
        }
        let remaining = 42 - calendarModel.count;
        for (let i = 1; i <= remaining; i++) {
            calendarModel.append({
                "dayNum": i.toString(),
                "isCurrentMonth": false,
                "isToday": false
            });
        }
    }

    function addNote(text) {
        notesAddProc.command = ["bash", powermenuWindow.scriptsDir + "/notes.sh", "add", text];
        notesAddProc.running = true;
    }

    function deleteNote(index) {
        notesDeleteProc.command = ["bash", powermenuWindow.scriptsDir + "/notes.sh", "delete", index.toString()];
        notesDeleteProc.running = true;
    }

    Loader {
        id: themeLoader
        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/MatugenTheme.qml"
    }

    QtObject {
        id: dummyTheme
        property color base: "#121318"
        property color mantle: "#121318"
        property color crust: "#0d0e13"
        property color surface0: "#1a1b21"
        property color surface1: "#1e1f25"
        property color surface2: "#45464f"
        property color overlay0: "#45464f"
        property color overlay1: "#45464f"
        property color overlay2: "#8f909a"
        property color text: "#e3e1e9"
        property color subtext0: "#8f909a"
        property color subtext1: "#c6c6d0"
        property color mauve: "#c1c5dd"
        property color pink: "#e2bbdb"
        property color blue: "#b5c4ff"
        property color sapphire: "#dbe1ff"
        property color peach: "#ffd7f7"
        property color yellow: "#dbe1ff"
        property color teal: "#ffd7f7"
        property color green: "#dde1f9"
        property color red: "#ffdad6"
    }

    // -------------------------------------------------------------------------
    // SYSTEM PROCESSES & TIMERS
    // -------------------------------------------------------------------------
    Process {
        id: statsPoller
        command: ["bash", powermenuWindow.scriptsDir + "/dashboard_stats.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        powermenuWindow.statsData = JSON.parse(txt);
                    } catch (e) {}
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statsPoller.running = true
    }

    Process {
        id: weatherPoller
        command: ["bash", powermenuWindow.scriptsDir + "/weather.sh", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        powermenuWindow.weatherData = JSON.parse(txt);
                    } catch (e) {}
                }
            }
        }
    }

    Timer {
        interval: 300000 // 5 minut
        running: true
        repeat: true
        onTriggered: weatherPoller.running = true
    }

    Process {
        id: notesPoller
        command: ["bash", powermenuWindow.scriptsDir + "/notes.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let parsed = JSON.parse(txt);
                        notesModel.clear();
                        for (let i = 0; i < parsed.length; i++) {
                            notesModel.append({ "noteText": parsed[i] });
                        }
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: notesAddProc
        onExited: notesPoller.running = true
    }

    Process {
        id: notesDeleteProc
        onExited: notesPoller.running = true
    }

    Component.onCompleted: {
        updateCalendarGrid();
    }

    // Close on escape
    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
    }

    // Full screen semi-transparent background
    Rectangle {
        anchors.fill: parent
        color: "#d0000000" // Dark overlay
    }

    // Inline component for the Circular Gauges
    component GaugeCard: Rectangle {
        id: card
        property string icon: ""
        property real value: 0
        property string hoverVal: ""
        property color gaugeColor: "blue"
        
        width: 110
        height: 115
        radius: 25
        color: powermenuWindow.surface0
        border.color: "#1affffff"
        border.width: 1
        
        Item {
            anchors.centerIn: parent
            width: 80
            height: 80
            
            Canvas {
                id: canvas
                anchors.fill: parent
                rotation: -90
                property real drawVal: card.value
                
                onDrawValChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var r = width / 2;
                    
                    // Track
                    ctx.beginPath();
                    ctx.arc(r, r, r - 5, 0, 2 * Math.PI);
                    ctx.strokeStyle = "#1affffff";
                    ctx.lineWidth = 3;
                    ctx.stroke();
                    
                    // Active Arc
                    if (drawVal > 0) {
                        ctx.beginPath();
                        ctx.arc(r, r, r - 5, 0, (Math.min(100, drawVal) / 100) * 2 * Math.PI);
                        ctx.strokeStyle = card.gaugeColor;
                        ctx.lineWidth = 5;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
                
                Behavior on drawVal {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.OutCubic
                    }
                }
            }
            
            HoverHandler {
                id: hh
            }
            
            Text {
                id: iconText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: hh.hovered ? -12 : 0
                
                text: card.icon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: hh.hovered ? 18 : 28
                color: card.gaugeColor
                
                Behavior on font.pixelSize { NumberAnimation { duration: 180 } }
                Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 180 } }
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: iconText.bottom
                anchors.topMargin: 2
                
                text: card.hoverVal
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                font.pixelSize: 11
                color: powermenuWindow.text
                opacity: hh.hovered ? 1 : 0
                
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }
    }

    // --- UI GRID LAYOUT ---
    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 20

        // SEKCOJA 1: 4 Okrągłe wskaźniki (Lewy panel)
        ColumnLayout {
            spacing: 20
            Layout.alignment: Qt.AlignTop

            GaugeCard {
                icon: "󰻠" // CPU
                value: powermenuWindow.statsData ? powermenuWindow.statsData.cpu_usage : 0
                hoverVal: powermenuWindow.statsData ? powermenuWindow.statsData.cpu_temp + "°C" : "--°C"
                gaugeColor: powermenuWindow.blue
            }

            GaugeCard {
                icon: "󰘚" // RAM
                value: powermenuWindow.statsData ? powermenuWindow.statsData.ram_usage : 0
                hoverVal: powermenuWindow.statsData ? powermenuWindow.statsData.ram_used : "--G"
                gaugeColor: powermenuWindow.mauve
            }

            GaugeCard {
                icon: "󰋊" // Disk
                value: powermenuWindow.statsData ? powermenuWindow.statsData.disk_usage : 0
                hoverVal: powermenuWindow.statsData ? powermenuWindow.statsData.disk_used : "--G"
                gaugeColor: powermenuWindow.green
            }

            GaugeCard {
                icon: "󰈸" // Temp (Flame)
                value: powermenuWindow.statsData ? powermenuWindow.statsData.cpu_temp : 0
                hoverVal: powermenuWindow.statsData ? (powermenuWindow.statsData.gpu_temp > 0 ? powermenuWindow.statsData.gpu_temp + "°C" : powermenuWindow.statsData.cpu_temp + "°C") : "--°C"
                gaugeColor: powermenuWindow.red
            }
        }

        // SEKCJA 2: Uptime + Pogoda (góra), Prognozy (dół)
        ColumnLayout {
            spacing: 20
            Layout.preferredWidth: 560
            Layout.preferredHeight: 520
            Layout.alignment: Qt.AlignTop

            RowLayout {
                spacing: 20
                Layout.fillWidth: true

                // UPTIME
                Rectangle {
                    id: uptimeCard
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 240
                    radius: 25
                    color: powermenuWindow.surface0
                    border.color: "#1affffff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            color: "#05ffffff"
                            radius: 18
                            border.color: "#0dffffff"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 15

                                Text {
                                    text: "" // Tux Penguin
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 42
                                    color: powermenuWindow.yellow
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: powermenuWindow.statsData ? powermenuWindow.statsData.uptime_days : "0"
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Black
                                        font.pixelSize: 28
                                        color: powermenuWindow.text
                                    }

                                    Text {
                                        text: powermenuWindow.getDaysText(powermenuWindow.statsData ? powermenuWindow.statsData.uptime_days : 0)
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 12
                                        color: powermenuWindow.subtext0
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#05ffffff"
                            radius: 18
                            border.color: "#0dffffff"
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: (powermenuWindow.statsData ? powermenuWindow.statsData.uptime_hours : "0") + " " + powermenuWindow.getHoursText(powermenuWindow.statsData ? powermenuWindow.statsData.uptime_hours : 0)
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 16
                                    color: powermenuWindow.blue
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    text: (powermenuWindow.statsData ? powermenuWindow.statsData.uptime_minutes : "0") + " " + powermenuWindow.getMinsText(powermenuWindow.statsData ? powermenuWindow.statsData.uptime_minutes : 0)
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 13
                                    color: powermenuWindow.subtext1
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }

                // AKTUALNA POGODA
                Rectangle {
                    id: weatherCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: 240
                    radius: 25
                    color: powermenuWindow.surface0
                    border.color: "#1affffff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            Text {
                                text: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast[0].icon : ""
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 76
                                color: powermenuWindow.pink
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast[0].max + "°C" : "--°C"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: 44
                                    color: powermenuWindow.green
                                }

                                Text {
                                    text: powermenuWindow.weatherData ? (powermenuWindow.weatherData.forecast[0].humidity + "% wilg. | " + powermenuWindow.weatherData.forecast[0].wind + " km/h") : "--% wilg. | -- km/h"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 13
                                    color: powermenuWindow.subtext0
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Łódź"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 13
                                color: powermenuWindow.subtext0
                            }

                            Text {
                                text: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast[0].desc : "Wczytywanie..."
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: 20
                                color: powermenuWindow.text
                            }
                        }
                    }
                }
            }

            // PROGNOZA POGODY (DÓŁ)
            Rectangle {
                id: forecastCard
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                radius: 25
                color: powermenuWindow.surface0
                border.color: "#1affffff"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    // Mini-paski prognozy
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast.slice(1, 5) : []

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 65
                                color: "#05ffffff"
                                radius: 15
                                border.color: "#0dffffff"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: modelData.icon
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 28
                                        color: powermenuWindow.teal
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        spacing: 0
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: modelData.max + "°C"
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            font.pixelSize: 13
                                            color: powermenuWindow.text
                                        }

                                        Text {
                                            text: modelData.desc
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 10
                                            color: powermenuWindow.subtext0
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Wykres słupkowy + Wschód/Zachód
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 15

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#05ffffff"
                            radius: 18
                            border.color: "#0dffffff"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "Prognoza pogody"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 11
                                    color: powermenuWindow.subtext0
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 12

                                    Repeater {
                                        model: powermenuWindow.weatherData ? powermenuWindow.weatherData.forecast.slice(1, 5) : []

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 4

                                            Text {
                                                text: modelData.max + "°"
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: 10
                                                color: powermenuWindow.text
                                                Layout.alignment: Qt.AlignHCenter
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.minimumHeight: 50

                                                Rectangle {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    anchors.bottom: parent.bottom
                                                    width: 10
                                                    height: Math.max(5, Math.min(parent.height, (parseFloat(modelData.max) / 40.0) * parent.height))
                                                    radius: 5
                                                    color: powermenuWindow.peach
                                                }
                                            }

                                            Text {
                                                text: modelData.day
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: 10
                                                color: powermenuWindow.subtext1
                                                Layout.alignment: Qt.AlignHCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 180
                            Layout.fillHeight: true
                            color: "#05ffffff"
                            radius: 18
                            border.color: "#0dffffff"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    text: "Wschód i zachód"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 11
                                    color: powermenuWindow.subtext0
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    RowLayout {
                                        spacing: 10
                                        Text {
                                            text: "󰖑"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 22
                                            color: powermenuWindow.yellow
                                        }
                                        ColumnLayout {
                                            spacing: 0
                                            Text {
                                                text: "Wschód"
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: 9
                                                color: powermenuWindow.subtext0
                                            }
                                            Text {
                                                text: powermenuWindow.weatherData ? new Date(powermenuWindow.weatherData.sunrise * 1000).toLocaleTimeString(Qt.locale("pl_PL"), "HH:mm") : "--:--"
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: powermenuWindow.text
                                            }
                                        }
                                    }

                                    RowLayout {
                                        spacing: 10
                                        Text {
                                            text: "󰖔"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 22
                                            color: powermenuWindow.mauve
                                        }
                                        ColumnLayout {
                                            spacing: 0
                                            Text {
                                                text: "Zachód"
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: 9
                                                color: powermenuWindow.subtext0
                                            }
                                            Text {
                                                text: powermenuWindow.weatherData ? new Date(powermenuWindow.weatherData.sunset * 1000).toLocaleTimeString(Qt.locale("pl_PL"), "HH:mm") : "--:--"
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: powermenuWindow.text
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // SEKCJA 3: Dzisiejsze notatki (góra), Kalendarz (dół)
        ColumnLayout {
            spacing: 20
            Layout.preferredWidth: 340
            Layout.preferredHeight: 520
            Layout.alignment: Qt.AlignTop

            // DZISIEJSZE NOTATKI
            Rectangle {
                id: notesCard
                Layout.preferredWidth: 340
                Layout.preferredHeight: 240
                radius: 25
                color: powermenuWindow.surface0
                border.color: "#1affffff"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "📝"
                            font.pixelSize: 16
                        }
                        Text {
                            text: "Dzisiejsze notatki"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 14
                            color: powermenuWindow.text
                        }
                    }

                    ListView {
                        id: notesListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: ListModel { id: notesModel }
                        spacing: 6

                        delegate: Item {
                            width: notesListView.width
                            height: 24

                            HoverHandler {
                                id: noteHover
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: "•"
                                    font.pixelSize: 14
                                    color: powermenuWindow.mauve
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: noteText
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 13
                                    color: powermenuWindow.text
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "󰆴" // Trash bin icon
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    color: trashMa.containsMouse ? powermenuWindow.red : powermenuWindow.subtext0
                                    opacity: noteHover.hovered ? 1.0 : 0.0
                                    Layout.alignment: Qt.AlignVCenter

                                    MouseArea {
                                        id: trashMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: noteHover.hovered
                                        onClicked: powermenuWindow.deleteNote(index)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: "#0dffffff"
                        radius: 8
                        border.color: noteInput.activeFocus ? powermenuWindow.mauve : "#0dffffff"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            TextInput {
                                id: noteInput
                                Layout.fillWidth: true
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                color: powermenuWindow.text
                                selectByMouse: true

                                Text {
                                    text: "Dodaj nową notatkę..."
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 12
                                    color: powermenuWindow.subtext0
                                    visible: noteInput.text.length === 0 && !noteInput.activeFocus
                                }

                                onAccepted: {
                                    let trimmed = noteInput.text.trim();
                                    if (trimmed !== "") {
                                        powermenuWindow.addNote(trimmed);
                                        noteInput.text = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // KALENDARZ
            Rectangle {
                id: calendarCard
                Layout.preferredWidth: 340
                Layout.preferredHeight: 260
                radius: 25
                color: powermenuWindow.surface0
                border.color: "#1affffff"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Sterowanie
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "<"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 15
                            color: prevMa.containsMouse ? powermenuWindow.mauve : powermenuWindow.subtext0
                            
                            MouseArea {
                                id: prevMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    powermenuWindow.monthOffset--;
                                    powermenuWindow.updateCalendarGrid();
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: powermenuWindow.targetMonthName
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: 15
                            color: powermenuWindow.text
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: ">"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 15
                            color: nextMa.containsMouse ? powermenuWindow.mauve : powermenuWindow.subtext0

                            MouseArea {
                                id: nextMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    powermenuWindow.monthOffset++;
                                    powermenuWindow.updateCalendarGrid();
                                }
                            }
                        }
                    }

                    // Siatka Dni Tygodnia (Niedziela start!)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: ["Nie", "Pon", "Wt", "Śr", "Czw", "Pią", "Sob"]

                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: 11
                                color: powermenuWindow.overlay2
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Siatka Dni Miesiąca (6 wierszy x 7 kolumn = 42 komórki)
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: ListModel { id: calendarModel }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: isToday ? powermenuWindow.green : (dayMa.containsMouse ? "#1affffff" : "transparent")
                                radius: 8
                                border.color: isToday ? "transparent" : (dayMa.containsMouse ? powermenuWindow.overlay0 : "transparent")
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: dayNum
                                    font.family: "JetBrains Mono"
                                    font.weight: isToday ? Font.Black : Font.Bold
                                    font.pixelSize: 12
                                    color: isToday ? powermenuWindow.base : (isCurrentMonth ? powermenuWindow.text : powermenuWindow.surface2)
                                }

                                MouseArea {
                                    id: dayMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
