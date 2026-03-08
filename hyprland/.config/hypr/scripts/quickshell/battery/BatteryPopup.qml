import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: window
    title: "battery-popup"
    width: 480
    height: 680
    color: "transparent"

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }

    // -------------------------------------------------------------------------
    // COLORS (Catppuccin Mocha)
    // -------------------------------------------------------------------------
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f5c2e7"
    readonly property color red: "#f38ba8"
    readonly property color maroon: "#eba0ac"
    readonly property color peach: "#fab387"
    readonly property color yellow: "#f9e2af"
    readonly property color green: "#a6e3a1"
    readonly property color teal: "#94e2d5"
    readonly property color sapphire: "#74c7ec"
    readonly property color blue: "#89b4fa"

    // -------------------------------------------------------------------------
    // STATE & POLLING
    // -------------------------------------------------------------------------
    property string powerProfile: "balanced"
    
    property int upHours: 0
    property int upMins: 0

    // POWER PROFILE COLORS
    readonly property color profileColorStart: {
        if (powerProfile === "performance") return window.red;
        if (powerProfile === "power-saver") return window.green;
        return window.blue;
    }

    readonly property color profileColorEnd: {
        if (powerProfile === "performance") return window.maroon;
        if (powerProfile === "power-saver") return window.teal;
        return window.sapphire;
    }

    // Ambient colors based on profile
    readonly property color ambientPrimary: window.profileColorStart
    readonly property color ambientSecondary: window.profileColorEnd

    // Animated segment position (0 = performance, 1 = balanced, 2 = power-saver)
    property real animatedSegment: 1.0
    
    Behavior on animatedSegment {
        NumberAnimation { duration: 600; easing.type: Easing.InOutCubic }
    }
    
    // Profile change trigger
    property bool profileChanging: false
    property real profilePulse: 0.0
    
    onPowerProfileChanged: {
        if (powerProfile === "performance") animatedSegment = 0.0;
        else if (powerProfile === "balanced") animatedSegment = 1.0;
        else if (powerProfile === "power-saver") animatedSegment = 2.0;
        
        profileChanging = true;
        profilePulse = 1.0;
        profilePulseAnim.start();
        setTimeout(function() { profileChanging = false; }, 600);
    }
    
    onAnimatedSegmentChanged: profileCanvas.requestPaint()
    onProfileColorStartChanged: profileCanvas.requestPaint()
    
    NumberAnimation {
        id: profilePulseAnim
        target: window
        property: "profilePulse"
        to: 0.0
        duration: 600
        easing.type: Easing.OutQuint
    }
    
    function setTimeout(callback, delay) {
        var timer = Qt.createQmlObject("import QtQuick; Timer {}", window);
        timer.interval = delay;
        timer.repeat = false;
        timer.triggered.connect(callback);
        timer.start();
    }

    Process {
        id: sysPoller
        command: ["sh", "-c", "powerprofilesctl get; awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                if (lines.length >= 2) {
                    window.powerProfile = lines[0]
                    
                    let upParts = lines[1].split("h ");
                    if (upParts.length === 2) {
                        window.upHours = parseInt(upParts[0]) || 0;
                        window.upMins = parseInt(upParts[1].replace("m", "")) || 0;
                    }
                }
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: sysPoller.running = true
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    property real introState: 0.0
    Component.onCompleted: introState = 1.0
    Behavior on introState { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introState)
        opacity: introState

        // Outer Border
        Rectangle {
            anchors.fill: parent
            radius: 30
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            // Rotating Background Blobs (Dual-Tone Integration)
            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
                opacity: 0.08 + (window.profilePulse * 0.04)
                color: window.ambientPrimary
                scale: 1.0 + (window.profilePulse * 0.1)
                Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } }
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
            }
            
            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
                opacity: 0.06 + (window.profilePulse * 0.03)
                color: window.ambientSecondary
                scale: 1.0 + (window.profilePulse * 0.08)
                Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } }
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
            }

            // Radar Rings (Maps to the secondary ambient/profile state)
            Item {
                id: radarItem
                anchors.fill: parent
                
                Repeater {
                    model: 3
                    Rectangle {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -30
                        width: 320 + (index * 170)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: window.ambientSecondary
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 1000 } }
                        opacity: 0.06 - (index * 0.02)
                    }
                }
            }

            // ==========================================
            // TOP: UPTIME COMPONENT
            // ==========================================
            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 25
                spacing: 6
                
                transform: Translate { y: -15 * (1.0 - introState) }
                opacity: introState
                
                // Hours Box (Maps to Battery State)
                Rectangle {
                    width: 44; height: 48; radius: 12
                    color: "#0dffffff"; border.color: "#1affffff"; border.width: 1
                    
                    Rectangle { anchors.fill: parent; radius: 12; color: window.ambientPrimary; opacity: 0.05; Behavior on color { ColorAnimation { duration: 1000 } } }
                    Column {
                        anchors.centerIn: parent
                        Text { 
                            text: window.upHours.toString().padStart(2, '0')
                            font.pixelSize: 18; font.family: "JetBrains Mono"; font.weight: Font.Black
                            color: window.ambientPrimary
                            Behavior on color { ColorAnimation { duration: 1000 } }
                            anchors.horizontalCenter: parent.horizontalCenter 
                        }
                        Text { 
                            text: "godz"; font.pixelSize: 8; font.family: "JetBrains Mono"; font.weight: Font.Bold
                            color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter 
                        }
                    }
                }

                // Pulsing Colon
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ":"
                    font.pixelSize: 22; font.family: "JetBrains Mono"; font.weight: Font.Black
                    color: window.ambientPrimary
                    Behavior on color { ColorAnimation { duration: 1000 } }
                    
                    opacity: uptimePulse
                    property real uptimePulse: 1.0
                    SequentialAnimation on uptimePulse {
                        loops: Animation.Infinite; running: true
                        NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                    }
                }

                // Mins Box (Maps to Profile State)
                Rectangle {
                    width: 44; height: 48; radius: 12
                    color: "#0dffffff"; border.color: "#1affffff"; border.width: 1
                    
                    Rectangle { anchors.fill: parent; radius: 12; color: window.ambientSecondary; opacity: 0.05; Behavior on color { ColorAnimation { duration: 1000 } } }
                    Column {
                        anchors.centerIn: parent
                        Text { 
                            text: window.upMins.toString().padStart(2, '0')
                            font.pixelSize: 18; font.family: "JetBrains Mono"; font.weight: Font.Black
                            color: window.ambientSecondary
                            Behavior on color { ColorAnimation { duration: 1000 } }
                            anchors.horizontalCenter: parent.horizontalCenter 
                        }
                        Text { 
                            text: "min"; font.pixelSize: 8; font.family: "JetBrains Mono"; font.weight: Font.Bold
                            color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter 
                        }
                    }
                }
            }

            // Simple top-right logout icon
            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.margins: 25
                width: 44; height: 44; radius: 22
                color: logoutMa.containsMouse ? "#1affffff" : "transparent"
                border.color: logoutMa.containsMouse ? "#33ffffff" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    font.family: "Iosevka Nerd Font"; font.pixelSize: 18
                    color: logoutMa.containsMouse ? window.red : window.overlay0
                    text: "󰍃"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: logoutMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { Quickshell.execDetached(["sh", "-c", "loginctl terminate-user $USER"]); Qt.quit(); }
                }
            }

            // ==========================================
            // CENTRAL CORE & BATTERY RING (REFINED)
            // ==========================================
            Item {
                anchors.fill: parent
                z: 1

                Rectangle {
                    id: centralCore
                    width: 260
                    height: width
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -30
                    radius: width / 2
                    
                    // Cinematic Breathing Animation
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation { 
                            to: heroMa.containsMouse ? 1.05 : 1.01
                            duration: heroMa.containsMouse ? 1200 : 2500
                            easing.type: Easing.InOutSine 
                        }
                        NumberAnimation { 
                            to: 1.0
                            duration: heroMa.containsMouse ? 1200 : 2500
                            easing.type: Easing.InOutSine 
                        }
                    }

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: window.surface0 }
                        GradientStop { position: 1.0; color: window.base }
                    }

                    border.color: window.ambientPrimary
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 1000 } }

                    // Soft rotating liquid glow inside the orb
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: width / 2
                        opacity: heroMa.containsMouse ? 0.3 : 0.15
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                        
                        RotationAnimation on rotation {
                            from: 0; to: 360; duration: 15000; loops: Animation.Infinite; running: true
                        }
                        
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: window.profileColorStart; Behavior on color { ColorAnimation { duration: 800 } } }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Power Profile Canvas Layer
                    Item {
                        anchors.fill: parent
                        
                        property real textPulse: 0.0
                        SequentialAnimation on textPulse {
                            loops: Animation.Infinite; running: true
                            NumberAnimation { from: 0.0; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0; to: 0.0; duration: 1200; easing.type: Easing.InOutSine }
                        }
                        
                        Canvas {
                            id: profileCanvas
                            anchors.fill: parent
                            rotation: -90  // Start from top
                            
                            // Animated scale pulse on profile change
                            scale: 1.0 + (window.profilePulse * 0.08)
                            Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutElastic; easing.amplitude: 1.2 } }
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                
                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = (width / 2) - 18;
                                var segmentSize = (2 * Math.PI) / 3;
                                
                                ctx.lineCap = "round";
                                
                                // Base track - three segments
                                ctx.lineWidth = 8;
                                ctx.strokeStyle = "#0dffffff";
                                
                                for (var i = 0; i < 3; i++) {
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, i * segmentSize, (i + 1) * segmentSize);
                                    ctx.stroke();
                                }
                                
                                // Determine active segment(s) and transition
                                var rawSegment = window.animatedSegment;
                                var currentSegment = Math.floor(rawSegment);
                                var nextSegment = Math.ceil(rawSegment);
                                var transition = rawSegment - currentSegment;
                                
                                var colors = [
                                    { start: window.red, end: window.maroon },       // performance (0)
                                    { start: window.blue, end: window.sapphire },    // balanced (1)
                                    { start: window.green, end: window.teal }        // power-saver (2)
                                ];
                                
                                // If we're in transition between segments
                                if (currentSegment !== nextSegment) {
                                    // Draw fading out segment
                                    var currentColors = colors[currentSegment];
                                    var currentStart = currentSegment * segmentSize;
                                    var currentEnd = currentStart + segmentSize;
                                    
                                    var grad1 = ctx.createLinearGradient(0, height, width, 0);
                                    grad1.addColorStop(0, currentColors.start.toString());
                                    grad1.addColorStop(1, currentColors.end.toString());
                                    
                                    ctx.globalAlpha = 1.0 - transition;
                                    ctx.lineWidth = 14;
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, currentStart, currentEnd);
                                    ctx.strokeStyle = grad1;
                                    ctx.stroke();
                                    
                                    // Draw fading in segment
                                    var nextColors = colors[nextSegment];
                                    var nextStart = nextSegment * segmentSize;
                                    var nextEnd = nextStart + segmentSize;
                                    
                                    var grad2 = ctx.createLinearGradient(0, height, width, 0);
                                    grad2.addColorStop(0, nextColors.start.toString());
                                    grad2.addColorStop(1, nextColors.end.toString());
                                    
                                    ctx.globalAlpha = transition;
                                    ctx.lineWidth = 14;
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, nextStart, nextEnd);
                                    ctx.strokeStyle = grad2;
                                    ctx.stroke();
                                } else {
                                    // Draw static active segment
                                    var activeColors = colors[currentSegment % 3];
                                    var startAngle = currentSegment * segmentSize;
                                    var endAngle = startAngle + segmentSize;
                                    
                                    var fillGrad = ctx.createLinearGradient(0, height, width, 0);
                                    fillGrad.addColorStop(0, activeColors.start.toString());
                                    fillGrad.addColorStop(1, activeColors.end.toString());
                                    
                                    ctx.globalAlpha = 1.0;
                                    ctx.lineWidth = 14;
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                                    ctx.strokeStyle = fillGrad;
                                    ctx.stroke();
                                }
                                
                                // Enhanced glow effect on hover + profile change
                                var glowIntensity = heroMa.containsMouse ? 0.3 : 0.0;
                                glowIntensity += window.profilePulse * 0.4;
                                
                                if (glowIntensity > 0.05) {
                                    var activeIdx = Math.round(rawSegment) % 3;
                                    var glowColors = colors[activeIdx];
                                    var glowStart = activeIdx * segmentSize;
                                    var glowEnd = glowStart + segmentSize;
                                    
                                    var glowGrad = ctx.createLinearGradient(0, height, width, 0);
                                    glowGrad.addColorStop(0, glowColors.start.toString());
                                    glowGrad.addColorStop(1, glowColors.end.toString());
                                    
                                    ctx.lineWidth = 18 + (window.profilePulse * 6);
                                    ctx.globalAlpha = glowIntensity;
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, glowStart, glowEnd);
                                    ctx.strokeStyle = glowGrad;
                                    ctx.stroke();
                                }
                            }
                        }

                        // Text Content
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 48
                                color: window.profileColorStart
                                text: {
                                    if (window.powerProfile === "performance") return "󰓅";
                                    if (window.powerProfile === "power-saver") return "󰌪";
                                    return "󰗑";
                                }
                                
                                // Animated scale on profile change
                                scale: 1.0 + (window.profilePulse * 0.15)
                                opacity: 1.0 - (window.profilePulse * 0.3)
                                
                                Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                                Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutElastic; easing.amplitude: 1.3 } }
                                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: 16
                                color: window.text
                                text: {
                                    if (window.powerProfile === "performance") return "WYDAJNY";
                                    if (window.powerProfile === "power-saver") return "OSZCZĘDNY";
                                    return "ZBALANSOWANY";
                                }
                                
                                // Slide animation on text change
                                opacity: 1.0 - (window.profilePulse * 0.5)
                                
                                Behavior on color { ColorAnimation { duration: 300 } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11
                                color: window.subtext0
                                text: "Profil wydajności"
                            }
                        }
                    }

                    MouseArea {
                        id: heroMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: batCanvas.requestPaint()
                        onExited: batCanvas.requestPaint()
                    }
                }
            }

            // ==========================================
            // BOTTOM DOCKS
            // ==========================================
            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 25
                spacing: 15
                transform: Translate { y: 20 * (1.0 - introState) }
                opacity: introState

                // 1. SYSTEM ACTIONS DOCK (Vertical Hold-to-Execute)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    spacing: 12
                    
                    Repeater {
                        model: ListModel {
                            ListElement { lbl: "Zablokuj"; cmd: "hyprlock"; icon: "󰌾"; c1: "#cba6f7"; c2: "#f5c2e7" }
                            ListElement { lbl: "Uśpij"; cmd: "hyprlock & systemctl suspend"; icon: "ᶻ 𝗓 𐰁"; c1: "#89b4fa"; c2: "#74c7ec" }
                            ListElement { lbl: "Restart"; cmd: "systemctl reboot"; icon: "󰑓"; c1: "#f9e2af"; c2: "#fab387" }
                            ListElement { lbl: "Wyłącz"; cmd: "systemctl poweroff"; icon: "󰐥"; c1: "#f38ba8"; c2: "#eba0ac" }
                        }
                        
                        delegate: Rectangle {
                            id: actionCapsule
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 18
                            color: actionMa.containsMouse ? "#1affffff" : "#0dffffff"
                            border.color: actionMa.containsMouse ? c1 : "#1affffff"
                            border.width: actionMa.containsMouse ? 2 : 1
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                            
                            // Bouncy Hover scaling
                            scale: actionMa.pressed ? 0.96 : (actionMa.containsMouse ? 1.08 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                            property real fillLevel: 0.0
                            property bool triggered: false
                            property real flashOpacity: 0.0
                            
                            // Wave Fill (Vertical)
                            Canvas {
                                id: waveCanvas
                                anchors.fill: parent
                                
                                property real wavePhase: 0.0
                                NumberAnimation on wavePhase {
                                    running: actionCapsule.fillLevel > 0.0 && actionCapsule.fillLevel < 1.0
                                    loops: Animation.Infinite
                                    from: 0; to: Math.PI * 2; duration: 800
                                }
                                onWavePhaseChanged: requestPaint()
                                Connections { target: actionCapsule; function onFillLevelChanged() { waveCanvas.requestPaint() } }
                                
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    if (actionCapsule.fillLevel <= 0.001) return;
                                    
                                    var r = 18; 
                                    var fillY = height * (1.0 - actionCapsule.fillLevel);
                                    ctx.save();
                                    ctx.beginPath();
                                    ctx.moveTo(r, 0);
                                    ctx.lineTo(width - r, 0);
                                    ctx.arcTo(width, 0, width, r, r);
                                    ctx.lineTo(width, height - r);
                                    ctx.arcTo(width, height, width - r, height, r);
                                    ctx.lineTo(r, height);
                                    ctx.arcTo(0, height, 0, height - r, r);
                                    ctx.lineTo(0, r);
                                    ctx.arcTo(0, 0, r, 0, r);
                                    ctx.closePath();
                                    ctx.clip(); 
                                    
                                    ctx.beginPath();
                                    ctx.moveTo(0, fillY);
                                    if (actionCapsule.fillLevel < 0.99) {
                                        var waveAmp = 10 * Math.sin(actionCapsule.fillLevel * Math.PI); 
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
                                    grad.addColorStop(0, c1);
                                    grad.addColorStop(1, c2);
                                    ctx.fillStyle = grad;
                                    ctx.fill();
                                    ctx.restore();
                                }
                            }

                            // Flash on trigger
                            Rectangle {
                                anchors.fill: parent; radius: 18; color: "#ffffff"
                                opacity: actionCapsule.flashOpacity
                                PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                            }

                            // Base Text (Unfilled)
                            ColumnLayout {
                                id: baseTextCol
                                anchors.centerIn: parent
                                spacing: 4
                                Text { 
                                    Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: 22
                                    color: actionMa.containsMouse ? window.text : window.subtext0; text: icon
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text { 
                                    Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 11
                                    color: actionMa.containsMouse ? window.text : window.subtext0; text: actionCapsule.fillLevel > 0.1 ? "Trzymaj" : lbl
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            // Overlay Text (Filled - Dark color for contrast)
                            Item {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                height: actionCapsule.height * actionCapsule.fillLevel
                                clip: true
                                
                                ColumnLayout {
                                    x: baseTextCol.x; y: baseTextCol.y - (actionCapsule.height - parent.height)
                                    width: baseTextCol.width; height: baseTextCol.height
                                    spacing: 4
                                    Text { Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: 22; color: window.crust; text: icon }
                                    Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 11; color: window.crust; text: actionCapsule.fillLevel > 0.1 ? "Trzymaj" : lbl }
                                }
                            }

                            MouseArea {
                                id: actionMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: actionCapsule.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor
                                
                                onPressed: { 
                                    if (!actionCapsule.triggered && actionCapsule.fillLevel === 0.0) { drainAnim.stop(); fillAnim.start(); }
                                }
                                onReleased: {
                                    if (!actionCapsule.triggered && actionCapsule.fillLevel < 1.0) { fillAnim.stop(); drainAnim.start(); }
                                }
                            }

                            NumberAnimation {
                                id: fillAnim; target: actionCapsule; property: "fillLevel"; to: 1.0
                                duration: 600 * (1.0 - actionCapsule.fillLevel); easing.type: Easing.InSine
                                onFinished: {
                                    actionCapsule.triggered = true; actionCapsule.flashOpacity = 0.6; cardFlashAnim.start();
                                    window.introState = 0.0; exitTimer.start();
                                }
                            }
                            
                            NumberAnimation {
                                id: drainAnim; target: actionCapsule; property: "fillLevel"; to: 0.0
                                duration: 1500 * actionCapsule.fillLevel; easing.type: Easing.OutQuad
                            }

                            Timer {
                                id: exitTimer; interval: 500 
                                onTriggered: { Quickshell.execDetached(["sh", "-c", cmd]); Qt.quit(); }
                            }
                        }
                    }
                }

                // 2. POWER PROFILES DOCK (SLIDER REDESIGN)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    radius: 27
                    color: "#0dffffff" 
                    border.color: "#1affffff"
                    border.width: 1
                    
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
                        
                        // Elegant overshoot bounce with elastic effect
                        Behavior on x { 
                            NumberAnimation { 
                                duration: 500; 
                                easing.type: Easing.OutElastic
                                easing.amplitude: 1.0
                                easing.period: 0.5
                            } 
                        }
                        
                        // Animated scale pulse on profile change
                        scale: 1.0 + (window.profilePulse * 0.06)
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutQuad } }
                        
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: window.profileColorStart; Behavior on color { ColorAnimation{duration:500; easing.type: Easing.InOutQuad} } }
                            GradientStop { position: 1.0; color: window.profileColorEnd; Behavior on color { ColorAnimation{duration:500; easing.type: Easing.InOutQuad} } }
                        }
                        
                        // Glow effect on profile change
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: parent.radius + 2
                            color: "transparent"
                            border.color: window.profileColorStart
                            border.width: 2
                            opacity: window.profilePulse * 0.6
                            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
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
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                // Scale effect on hover
                                scale: profileMa.containsMouse ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: 18
                                        color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                        text: icon
                                        
                                        // Bounce on selection
                                        scale: (window.powerProfile === name && window.profileChanging) ? 1.15 : 1.0
                                        
                                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                                    }
                                    Text {
                                        font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 13
                                        color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                        text: label
                                        
                                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                                    }
                                }
                                
                                MouseArea {
                                    id: profileMa
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", name]); sysPoller.running = true; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
