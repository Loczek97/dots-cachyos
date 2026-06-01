import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: window

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    // -------------------------------------------------------------------------
    // COLOR MAPPINGS
    // -------------------------------------------------------------------------
    readonly property color base: theme.base
    readonly property color mantle: theme.mantle
    readonly property color crust: theme.crust
    readonly property color text: theme.text
    readonly property color subtext0: theme.subtext0
    readonly property color overlay0: theme.overlay0
    readonly property color overlay1: theme.overlay1
    readonly property color surface0: theme.surface0
    readonly property color surface1: theme.surface1
    readonly property color surface2: theme.surface2
    readonly property color mauve: theme.mauve
    readonly property color pink: theme.pink
    readonly property color red: theme.red
    readonly property color maroon: theme.maroon
    readonly property color peach: theme.peach
    readonly property color yellow: theme.yellow
    readonly property color green: theme.green
    readonly property color teal: theme.teal
    readonly property color sapphire: theme.sapphire
    readonly property color blue: theme.blue

    // -------------------------------------------------------------------------
    // STATE & POLLING
    // -------------------------------------------------------------------------
    property int batCapacity: 0
    property string batStatus: "Unknown"
    property string timeStr: "0h 0m"
    property string timeLabel: "POZOSTAŁO"
    
    // Power Profile Logic
    property string powerProfile: "balanced"
    property real animatedSegment: 1
    property bool profileChanging: false
    property real profilePulse: 0

    onPowerProfileChanged: {
        if (powerProfile === "performance") animatedSegment = 0;
        else if (powerProfile === "balanced") animatedSegment = 1;
        else if (powerProfile === "power-saver") animatedSegment = 2;
        profileChanging = true;
        profilePulse = 1;
        profilePulseAnim.start();
        setTimeout(function() { profileChanging = false; }, 600);
    }

    function setTimeout(callback, delay) {
        var timer = Qt.createQmlObject("import QtQuick; Timer {}", window);
        timer.interval = delay;
        timer.repeat = false;
        timer.triggered.connect(callback);
        timer.start();
    }

    NumberAnimation {
        id: profilePulseAnim
        target: window; property: "profilePulse"; to: 0; duration: 600; easing.type: Easing.OutQuint
    }

    readonly property bool isCharging: batStatus === "Charging" || batStatus === "Full"

    readonly property color batColorStart: {
        if (isCharging) return window.green;
        if (batCapacity >= 70) return window.blue;
        if (batCapacity >= 30) return window.yellow;
        return window.red;
    }
    
    readonly property color ambientPrimary: window.batColorStart
    readonly property color ambientSecondary: Qt.lighter(batColorStart, 1.2)
    
    property real globalOrbitAngle: 0
    property real introState: 0

    title: "battery-popup"
    width: 480
    height: 600
    color: "transparent"
    
    Component.onCompleted: introState = 1

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
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
        property color base: "#000000"; property color mantle: "#000000"; property color crust: "#000000"
        property color surface0: "#000000"; property color surface1: "#000000"; property color surface2: "#000000"
        property color overlay0: "#000000"; property color overlay1: "#000000"; property color overlay2: "#000000"
        property color text: "#000000"; property color subtext1: "#000000"; property color subtext0: "#000000"
        property color mauve: "#000000"; property color pink: "#000000"; property color blue: "#000000"
        property color sapphire: "#000000"; property color peach: "#000000"; property color yellow: "#000000"
        property color teal: "#000000"; property color green: "#000000"; property color red: "#000000"
        property color maroon: "#000000"
    }

    Process {
        id: batPoller
        command: ["bash", "-c", "LC_ALL=C upower -i $(upower -e | grep -m1 battery) | awk '/percentage:/ {p=$2} /state:/ {s=$2} /time to empty:/ {t=$4\"h \"$5} /time to full:/ {t=$4\"h \"$5} END {print p; print s; print (t?t:\"0h 0m\")}' ; powerprofilesctl get 2>/dev/null || echo 'balanced'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 4) {
                    window.batCapacity = parseInt(lines[0]) || 0;
                    window.batStatus = lines[1] || "Unknown";
                    window.timeStr = lines[2] || "0h 0m";
                    window.timeLabel = (window.batStatus === "charging" ? "DO PEŁNA" : "POZOSTAŁO");
                    window.powerProfile = lines[3] || "balanced";
                    batCanvas.requestPaint();
                }
            }
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: batPoller.running = true
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introState)
        opacity: introState

        Rectangle {
            anchors.fill: parent
            radius: 30
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            // Rotating Background Blobs
            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
                opacity: 0.1
                color: window.ambientPrimary
            }

            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
                opacity: 0.08
                color: window.ambientSecondary
            }

            // ==========================================
            // TOP: TIME REMAINING
            // ==========================================
            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 25
                spacing: 12
                
                Rectangle {
                    width: timeLayout.implicitWidth + 24
                    height: 48
                    radius: 12
                    color: window.surface0
                    border.color: window.surface1
                    border.width: 1

                    RowLayout {
                        id: timeLayout
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Text {
                            text: window.batStatus === "charging" ? "󱐋" : "󰔟"
                            font.pixelSize: 20
                            font.family: "Iosevka Nerd Font"
                            color: window.ambientPrimary
                        }
                        
                        Column {
                            Text {
                                text: window.timeStr
                                font.pixelSize: 16
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                color: window.text
                            }
                            Text {
                                text: window.timeLabel
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                color: window.subtext0
                            }
                        }
                    }
                }
            }

            // ==========================================
            // CENTRAL CORE: BATTERY %
            // ==========================================
            Item {
                anchors.fill: parent
                z: 1

                Rectangle {
                    id: centralCore
                    width: 280
                    height: width
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 20
                    radius: width / 2
                    color: window.surface0
                    border.color: window.surface1
                    border.width: 1

                    Canvas {
                        id: batCanvas
                        anchors.fill: parent
                        rotation: -90
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var centerX = width / 2;
                            var centerY = height / 2;
                            var radius = (width / 2) - 15;
                            
                            ctx.lineCap = "round";
                            ctx.lineWidth = 10;
                            ctx.strokeStyle = window.surface1;
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                            ctx.stroke();

                            var endAngle = (window.batCapacity / 100) * 2 * Math.PI;
                            ctx.lineWidth = 16;
                            var grad = ctx.createLinearGradient(0, height, width, 0);
                            grad.addColorStop(0, window.ambientPrimary.toString());
                            grad.addColorStop(1, window.ambientSecondary.toString());
                            ctx.strokeStyle = grad;
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, 0, endAngle);
                            ctx.stroke();
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: window.isCharging ? "󱐋" : "󰁹"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 42
                            color: window.ambientPrimary
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: window.batCapacity + "%"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: 64
                            color: window.text
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: window.batStatus.toUpperCase()
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            color: window.subtext0
                        }
                    }
                }
            }

            // ==========================================
            // BOTTOM: POWER PROFILES DOCK
            // ==========================================
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 25
                height: 54
                radius: 27
                color: window.surface0 
                border.color: window.surface1
                border.width: 1
                opacity: introState
                transform: Translate { y: 20 * (1 - introState) }

                Rectangle {
                    id: sliderPill
                    width: (parent.width - 2) / 3 
                    height: parent.height - 2
                    y: 1
                    radius: 26
                    x: {
                        if (window.powerProfile === "performance") return 1;
                        if (window.powerProfile === "balanced") return width + 1;
                        return (width * 2) + 1;
                    }
                    scale: 1 + (window.profilePulse * 0.06)

                    Behavior on x {
                        NumberAnimation { duration: 500; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.5 }
                    }

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { 
                            position: 0; color: window.powerProfile === "performance" ? window.red : (window.powerProfile === "balanced" ? window.blue : window.green)
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                        GradientStop { 
                            position: 1; color: Qt.lighter(parent.gradient.stops[0].color, 1.2)
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Repeater {
                        model: ListModel {
                            ListElement { name: "performance"; icon: "󰓅"; label: "Wydajny" } 
                            ListElement { name: "balanced"; icon: "󰗑"; label: "Zbalanso." }   
                            ListElement { name: "power-saver"; icon: "󰌪"; label: "Oszczęd." } 
                        }
                        delegate: Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: 18
                                    color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                    text: icon
                                }
                                Text {
                                    font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 13
                                    color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                    text: label
                                }
                            }
                            MouseArea {
                                id: profileMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", name]); batPoller.running = true; }
                            }
                        }
                    }
                }
            }
        }
    }

    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    Behavior on introState { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
}
