import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtCore
import Quickshell
import Quickshell.Io
import "MatugenTheme.qml"

FloatingWindow {
    id: window

    title: "network-popup"
    implicitWidth: 900
    implicitHeight: 700
    color: "transparent"

    // Dynamic Theme from Matugen
    MatugenTheme { id: theme }

    function closePopup() {
        Quickshell.execDetached(["bash", "-c", "pkill -f 'quickshell.*NetworkPopup.qml'; if [ -f ~/.cache/bt_scan_pid ]; then kill $(cat ~/.cache/bt_scan_pid) 2>/dev/null; rm ~/.cache/bt_scan_pid; fi; bluetoothctl scan off > /dev/null 2>&1"])
        Qt.quit()
    }

    Shortcut { sequence: "Escape"; onActivated: closePopup() }

    // -------------------------------------------------------------------------
    // PERSISTENT STORAGE
    // -------------------------------------------------------------------------
    Settings {
        id: cache
        property string lastWifiSsid: ""
    }

    // -------------------------------------------------------------------------
    // LIGHTWEIGHT SYSTEM AUDIO
    // -------------------------------------------------------------------------
    function playSfx(filename) {
        try {
            let rawUrl = Qt.resolvedUrl("sounds/" + filename).toString();
            let cleanPath = rawUrl;
            if (cleanPath.indexOf("file://") === 0) {
                cleanPath = cleanPath.substring(7); 
            }
            let cmd = "pw-play '" + cleanPath + "' 2>/dev/null || paplay '" + cleanPath + "' 2>/dev/null";
            Quickshell.execDetached(["sh", "-c", cmd]);
        } catch(e) {}
    }

    function shellQuote(value) {
        let s = value === undefined || value === null ? "" : String(value);
        return "'" + s.replace(/'/g, "'\"'\"'") + "'";
    }

    function openWifiPasswordPopup(ssid, security) {
        window.wifiPromptSsid = ssid || "";
        window.wifiPromptSecurity = security || "WPA2";
        window.wifiPromptPassword = "";
        window.wifiPromptError = "";
        window.wifiPasswordPopupVisible = true;
    }

    function submitWifiPassword() {
        if (!window.wifiPromptSsid) return;
        if (!window.wifiPromptPassword || window.wifiPromptPassword.length < 8) {
            window.wifiPromptError = "Hasło musi mieć co najmniej 8 znaków";
            return;
        }

        window.playSfx("switch.wav");
        window.wifiPromptError = "";
        window.busyTask = window.wifiPromptSsid;
        busyTimeout.start();

        wifiConnectProcess.pendingSsid = window.wifiPromptSsid;
        wifiConnectProcess.pendingPassword = window.wifiPromptPassword;
        wifiConnectProcess.running = true;
    }

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
    readonly property color sapphire: theme.sapphire
    readonly property color blue: theme.blue
    readonly property color red: theme.red
    readonly property color maroon: theme.maroon
    readonly property color peach: theme.peach

    readonly property string scriptsDir: "/home/michal/.config/quickshell/network"
    // -------------------------------------------------------------------------
    // VIEW MODE & CORE STATE
    // -------------------------------------------------------------------------
    property string activeMode: "wifi"  // Start in WiFi mode (Bluetooth not available on this system)
    readonly property color activeColor: activeMode === "wifi" ? window.sapphire : window.mauve
    readonly property color activeGradientSecondary: activeMode === "wifi" ? window.blue : window.pink

    property string busyTask: ""
    Timer { id: busyTimeout; interval: 15000; onTriggered: window.busyTask = "" }

    Timer { id: wifiPendingReset; interval: 8000; onTriggered: { window.wifiPowerPending = false; window.expectedWifiPower = ""; } }
    Timer { id: btPendingReset; interval: 8000; onTriggered: { window.btPowerPending = false; window.expectedBtPower = ""; } }

    property bool showInfoView: false

    property bool wifiPasswordPopupVisible: false
    property string wifiPromptSsid: ""
    property string wifiPromptSecurity: ""
    property string wifiPromptPassword: ""
    property string wifiPromptError: ""
    property bool wifiPasswordReveal: false

    onCurrentConnChanged: {
        // Don't auto-switch to info view, let user choose
        if (currentConn) updateInfoNodes();
    }

    onActiveModeChanged: {
        window.busyTask = "";
        // Don't auto-switch to info view, let user choose
        if (window.currentConn) window.updateInfoNodes();
    }

    // -------------------------------------------------------------------------
    // SMART DIFFING LIST MODELS
    // -------------------------------------------------------------------------
    ListModel { id: wifiListModel }
    ListModel { id: btListModel }
    ListModel { id: infoListModel }

    function syncModel(listModel, dataArray) {
        for (let i = listModel.count - 1; i >= 0; i--) {
            let id = listModel.get(i).id;
            let found = false;
            for (let j = 0; j < dataArray.length; j++) {
                if (id === dataArray[j].id) { found = true; break; }
            }
            if (!found) { listModel.remove(i); }
        }
        
        for (let i = 0; i < dataArray.length && i < 24; i++) {
            let d = dataArray[i];
            let foundIdx = -1;
            for (let j = i; j < listModel.count; j++) {
                if (listModel.get(j).id === d.id) { foundIdx = j; break; }
            }
            
            let obj = {
                id: d.id || "",
                ssid: d.ssid || "",
                mac: d.mac || "",
                name: d.name || d.ssid || "", 
                icon: d.icon || "",
                security: d.security || "",
                requiresPassword: d.requiresPassword !== undefined ? d.requiresPassword : false,
                action: d.action || "",
                isInfoNode: d.isInfoNode || false,
                isActionable: d.isActionable !== undefined ? d.isActionable : false,
                cmdStr: d.cmdStr || ""
            };

            if (foundIdx === -1) {
                listModel.insert(i, obj);
            } else {
                if (foundIdx !== i) { listModel.move(foundIdx, i, 1); }
                // SMART DIFFING: Only set the property if it actually changed to prevent UI redraw lag!
                for (let key in obj) { 
                    if (listModel.get(i)[key] !== obj[key]) {
                        listModel.setProperty(i, key, obj[key]); 
                    }
                }
            }
        }
    }

    property int hoveredCardCount: 0
    readonly property bool isListLocked: hoveredCardCount > 0
    property var nextWifiList: null
    property var nextBtList: null
    property var nextInfoList: null

    onIsListLockedChanged: {
        if (!isListLocked) {
            if (nextWifiList !== null) { window.syncModel(wifiListModel, nextWifiList); window.wifiList = nextWifiList; nextWifiList = null; }
            if (nextBtList !== null) { window.syncModel(btListModel, nextBtList); window.btList = nextBtList; nextBtList = null; }
            if (nextInfoList !== null) { window.syncModel(infoListModel, nextInfoList); nextInfoList = null; }
        }
    }

    // -------------------------------------------------------------------------
    // DATA POLLING & PENDING STATES
    // -------------------------------------------------------------------------
    property bool wifiPowerPending: false
    property string expectedWifiPower: ""
    property string wifiPower: ""  // Empty until first data received
    property var wifiConnected: null
    property var wifiList: []
    property string strongestWifiSsid: ""
    readonly property bool isWifiConn: !!window.wifiConnected && window.wifiConnected.ssid !== undefined

    readonly property string targetWifiSsid: {
        let found = false;
        if (cache.lastWifiSsid !== "") {
            for (let i = 0; i < wifiList.length; i++) {
                if (wifiList[i].id === cache.lastWifiSsid) { found = true; break; }
            }
        }
        return found ? cache.lastWifiSsid : strongestWifiSsid;
    }

    onWifiConnectedChanged: {
        if (window.wifiConnected && window.wifiConnected.ssid) { cache.lastWifiSsid = window.wifiConnected.ssid; }
        if (window.currentConn && window.activeMode === "wifi") updateInfoNodes();
    }

    property bool btPowerPending: false
    property string expectedBtPower: ""
    property string btPower: ""  // Empty until first data received
    property var btConnected: null
    property var btList: []
    readonly property bool isBtConn: !!window.btConnected && window.btConnected.mac !== undefined && window.btConnected.mac !== ""
    
    onBtConnectedChanged: { if (window.currentConn && window.activeMode === "bt") updateInfoNodes() }

    // If wifiPower is empty (no data yet) but we have connection, assume power is on
    readonly property bool currentPower: activeMode === "wifi" 
        ? (window.wifiPower === "on" || (window.wifiPower === "" && window.isWifiConn))
        : (window.btPower === "on" || (window.btPower === "" && window.isBtConn))
    readonly property bool currentPowerPending: activeMode === "wifi" ? window.wifiPowerPending : window.btPowerPending
    readonly property bool currentConn: activeMode === "wifi" ? window.isWifiConn : window.isBtConn
    readonly property var currentObj: activeMode === "wifi" ? window.wifiConnected : window.btConnected

    // Generates the flat Single-Orbit Info Constellation
    function updateInfoNodes() {
        let nodes = [];
        if (window.currentConn && window.currentObj) {
            if (window.activeMode === "wifi") {
                let sigValue = window.currentObj.signal !== undefined ? window.currentObj.signal + "%" : "Obliczanie...";
                nodes.push({ id: "sig", name: sigValue, icon: window.currentObj.icon || "󰤨", action: "Siła sygnału", isInfoNode: true, isActionable: false });
                nodes.push({ id: "sec", name: window.currentObj.security || "Otwarta", icon: "󰦝", action: "Zabezpieczenie", isInfoNode: true, isActionable: false });
                if (window.currentObj.ip) nodes.push({ id: "ip", name: window.currentObj.ip, icon: "󰩟", action: "Adres IP", isInfoNode: true, isActionable: false });
                if (window.currentObj.freq) nodes.push({ id: "freq", name: window.currentObj.freq, icon: "󰖧", action: "Pasmo", isInfoNode: true, isActionable: false });
            } else {
                nodes.push({ id: "bat", name: (window.currentObj.battery || "0") + "%", icon: "󰥉", action: "Bateria", isInfoNode: true, isActionable: false });
                if (window.currentObj.profile) {
                    nodes.push({ id: "prof", name: window.currentObj.profile, icon: (window.currentObj.profile === "Wysoka jakość (A2DP)" ? "󰓃" : "󰋎"), action: "Profil audio", isInfoNode: true, isActionable: false });
                }
                nodes.push({ id: "mac", name: window.currentObj.mac || "Nieznany", icon: "󰒋", action: "Adres MAC", isInfoNode: true, isActionable: false });
            }
            nodes.push({ id: "action_scan", name: "Wróć do listy", icon: "󰍉", action: "Przełącz widok", isInfoNode: true, isActionable: true, cmdStr: "TOGGLE_VIEW" });
        }
        
        if (window.isListLocked) window.nextInfoList = nodes;
        else { window.syncModel(infoListModel, nodes); window.nextInfoList = null; }
    }

    Process {
        id: wifiPoller
        command: ["bash", window.scriptsDir + "/wifi_panel_logic.sh"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    let textData = this.text.trim()
                    if (textData.length > 0) {
                        try {
                            let jsonData = JSON.parse(textData)
                            if (jsonData.power) window.wifiPower = jsonData.power
                            if (jsonData.connected !== undefined) window.wifiConnected = jsonData.connected
                            if (jsonData.networks) {
                                let nets = jsonData.networks
                                if (window.isWifiConn && window.activeMode === "wifi") {
                                    nets.push({ id: "action_settings", ssid: "Aktualne urządzenie", mac: "", name: "Aktualne urządzenie", icon: "󰒓", security: "", action: "Pokaż szczegóły", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW" })
                                }
                                window.syncModel(wifiListModel, nets)
                                window.wifiList = nets
                            }
                            if (window.activeMode === "wifi" && window.currentConn) window.updateInfoNodes()
                        } catch(e) { console.log("WiFi parse error:", e) }
                    }
                }
            }
        }
    }

    Process {
        id: wifiConnectProcess
        property string pendingSsid: ""
        property string pendingPassword: ""

        command: {
            let base = "LC_ALL=C nmcli device wifi connect " + window.shellQuote(pendingSsid);
            if (pendingPassword !== "") {
                base += " password " + window.shellQuote(pendingPassword);
            }
            return ["bash", "-lc", base + " 2>&1"];
        }
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let out = (this.text || "").trim();
                let lower = out.toLowerCase();

                window.busyTask = "";
                wifiConnectProcess.pendingPassword = "";

                let needsSecrets = lower.indexOf("secrets were required") !== -1 || lower.indexOf("no secrets") !== -1;
                let wrongPassword = lower.indexOf("wrong password") !== -1 || lower.indexOf("invalid") !== -1 || lower.indexOf("authentication") !== -1;
                let success = lower.indexOf("successfully activated") !== -1;

                if (success) {
                    window.wifiPasswordPopupVisible = false;
                    window.wifiPromptError = "";
                    window.playSfx("power_on.wav");
                } else if (needsSecrets || wrongPassword) {
                    window.wifiPasswordPopupVisible = true;
                    window.wifiPromptError = wrongPassword
                        ? "Nieprawidłowe hasło. Spróbuj ponownie."
                        : "Ta sieć wymaga hasła";
                } else if (out.length > 0) {
                    window.wifiPasswordPopupVisible = true;
                    window.wifiPromptError = "Nie udało się połączyć: " + out;
                } else {
                    window.wifiPasswordPopupVisible = true;
                    window.wifiPromptError = "Nie udało się połączyć z siecią";
                }

                wifiPoller.running = true;
            }
        }
    }

    Process {
        id: btPoller
        command: ["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--status"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    let textData = this.text.trim()
                    if (textData.length > 0) {
                        try {
                            let jsonData = JSON.parse(textData)
                            if (jsonData.power) window.btPower = jsonData.power
                            if (jsonData.connected !== undefined) window.btConnected = jsonData.connected
                            if (jsonData.devices) {
                                let devs = jsonData.devices
                                if (window.isBtConn && window.activeMode === "bt") {
                                    devs.unshift({
                                        id: window.btConnected.mac || "connected_bt",
                                        name: window.btConnected.name || "Aktualne urządzenie",
                                        mac: window.btConnected.mac || "",
                                        icon: window.btConnected.icon || "󰂯",
                                        action: "Pokaż szczegóły",
                                        isInfoNode: false,
                                        isActionable: true,
                                        cmdStr: "TOGGLE_VIEW"
                                    })
                                }
                                window.syncModel(btListModel, devs)
                                window.btList = devs
                            }
                            if (window.activeMode === "bt" && window.currentConn) window.updateInfoNodes()
                        } catch(e) { console.log("BT parse error:", e) }
                    }
                }
            }
        }
    }

    Timer {
        interval: window.busyTask !== "" ? 1000 : 3000
        running: true; repeat: true
        onTriggered: { wifiPoller.running = true; btPoller.running = true; }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    property real introState: 0.0
    Component.onCompleted: {
        introState = 1.0
        // Trigger initial poll
        wifiPoller.running = true
        btPoller.running = true
    }
    Behavior on introState { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

    component LoadingDots : Row {
        spacing: 5
        property color dotCol: window.text
        Repeater {
            model: 3
            Rectangle {
                width: 6; height: 6; radius: 3; color: dotCol
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 100 }
                    NumberAnimation { from: 0; to: -6; duration: 250; easing.type: Easing.OutSine }
                    NumberAnimation { from: -6; to: 0; duration: 250; easing.type: Easing.InSine }
                    PauseAnimation { duration: (2 - index) * 100 }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        scale: 0.8 + (0.2 * introState)
        opacity: introState

        Rectangle {
            anchors.fill: parent
            radius: 30
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
                opacity: window.currentPower ? 0.08 : 0.02
                color: window.currentConn ? window.activeColor : window.surface2
                Behavior on color { ColorAnimation { duration: 1000 } }
                Behavior on opacity { NumberAnimation { duration: 1000 } }
            }
            
            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
                opacity: window.currentPower ? 0.06 : 0.01
                color: window.currentConn ? window.activeGradientSecondary : window.surface1
                Behavior on color { ColorAnimation { duration: 1000 } }
                Behavior on opacity { NumberAnimation { duration: 1000 } }
            }

            Item {
                id: radarItem
                anchors.fill: parent
                anchors.bottomMargin: 80 
                opacity: window.currentPower ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                
                Repeater {
                    model: 3
                    Rectangle {
                        anchors.centerIn: parent
                        width: 280 + (index * 170)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        
                        border.color: coreMa.pressed && centralCore.disconnectFill > 0.05 ? "#9A1020" : window.activeColor
                        border.width: coreMa.pressed && centralCore.disconnectFill > 0.05 ? 2 : 1
                        
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        opacity: coreMa.pressed && centralCore.disconnectFill > 0.05 ? 0.2 : (window.currentConn ? 0.08 - (index * 0.02) : 0.03)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }

            Canvas {
                id: nodeLinesCanvas
                anchors.fill: parent
                anchors.bottomMargin: 80
                z: 0 
                opacity: (window.currentConn && window.showInfoView) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 500 } }
                
                Connections {
                    target: window
                    function onGlobalOrbitAngleChanged() { if (window.currentConn && window.showInfoView) nodeLinesCanvas.requestPaint() }
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (!window.currentConn || !window.showInfoView) return;
                    
                    ctx.lineWidth = 1.5;
                    ctx.strokeStyle = window.activeColor;
                    ctx.globalAlpha = 0.25;
                    
                    var centerX = width / 2;
                    var centerY = height / 2;
                    
                    for (var i = 0; i < orbitRepeater.count; i++) {
                        var item = orbitRepeater.itemAt(i);
                        if (item && item.isLoaded) {
                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.lineTo(item.x + item.width / 2, item.y + item.height / 2);
                            ctx.stroke();
                        }
                    }
                }
            }

            Item {
                id: orbitContainer
                anchors.fill: parent
                anchors.bottomMargin: 80 
                z: 1

                // --- THE CENTRAL CORE ---
                Rectangle {
                    id: centralCore
                    width: window.currentPower ? 200 : 160
                    height: width
                    anchors.centerIn: parent
                    radius: width / 2
                    
                    property real disconnectFill: 0.0
                    property bool disconnectTriggered: false
                    property real flashOpacity: 0.0
                    property real bumpScale: 1.0
                    property bool isDangerState: coreMa.containsMouse || disconnectFill > 0
                    
                    scale: bumpScale
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

                    SequentialAnimation on bumpScale {
                        id: coreBumpAnim
                        running: false
                        NumberAnimation { to: 1.15; duration: 150; easing.type: Easing.OutBack }
                        NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.OutQuint }
                    }

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: {
                                if (!window.currentPower) return window.mantle;
                                if (window.busyTask === "DISCONNECTING") return window.surface0; 
                                if (centralCore.isDangerState && window.currentConn) return window.peach;
                                return window.currentConn ? window.activeColor : window.surface0;
                            }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        GradientStop {
                            position: 1.0
                            color: {
                                if (!window.currentPower) return window.crust;
                                if (window.busyTask === "DISCONNECTING") return window.base; 
                                if (centralCore.isDangerState && window.currentConn) return window.maroon;
                                return window.currentConn ? window.activeGradientSecondary : window.base;
                            }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }

                    border.color: {
                        if (!window.currentPower) return window.crust;
                        if (window.busyTask === "DISCONNECTING") return window.surface0;
                        if (centralCore.isDangerState && window.currentConn) return window.red;
                        return window.currentConn ? window.activeColor : window.surface1;
                    }
                    Behavior on border.color { ColorAnimation { duration: 300 } }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#ffffff"
                        opacity: centralCore.flashOpacity
                        PropertyAnimation on opacity { id: coreFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                    }

                    Canvas {
                        id: coreWave
                        anchors.fill: parent
                        visible: centralCore.disconnectFill > 0
                        opacity: 0.95

                        property real wavePhase: 0.0
                        NumberAnimation on wavePhase {
                            running: centralCore.disconnectFill > 0.0 && centralCore.disconnectFill < 1.0
                            loops: Animation.Infinite
                            from: 0; to: Math.PI * 2; duration: 800
                        }
                        onWavePhaseChanged: requestPaint()
                        Connections {
                            target: centralCore
                            function onDisconnectFillChanged() { coreWave.requestPaint() }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            if (centralCore.disconnectFill <= 0.001) return;

                            var r = width / 2;
                            var fillY = height * (1.0 - centralCore.disconnectFill);

                            ctx.save();
                            ctx.beginPath();
                            ctx.arc(r, r, r, 0, 2 * Math.PI);
                            ctx.clip(); 

                            ctx.beginPath();
                            ctx.moveTo(0, fillY);
                            if (centralCore.disconnectFill < 0.99) {
                                var waveAmp = 10 * Math.sin(centralCore.disconnectFill * Math.PI);
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
                            grad.addColorStop(0, "#E61919"); 
                            grad.addColorStop(1, Qt.darker(window.red, 1.4).toString());
                            ctx.fillStyle = grad;
                            ctx.fill();
                            ctx.restore();
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 40
                        height: width
                        radius: width / 2
                        color: centralCore.isDangerState && window.currentConn ? window.red : window.activeColor
                        opacity: window.currentConn && window.busyTask !== "DISCONNECTING" ? (centralCore.isDangerState ? 0.3 : 0.15) : 0.0
                        z: -1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        
                        SequentialAnimation on scale {
                            loops: Animation.Infinite; running: window.currentConn
                            NumberAnimation { to: coreMa.containsMouse ? 1.15 : 1.1; duration: coreMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: coreMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
                        }
                    }

                    Item {
                        anchors.fill: parent

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            visible: !window.currentConn || !window.currentPower
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 48
                                color: window.currentPower ? window.overlay0 : window.surface2
                                text: window.activeMode === "wifi" ? "󰤮" : "󰂲"
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 14
                                color: window.overlay0
                                text: !window.currentPower ? "Wyłączone" : "Skanowanie..."
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            visible: window.currentConn && window.currentPower
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 48
                                color: window.busyTask === "DISCONNECTING" ? window.overlay1 : window.crust
                                text: window.busyTask === "DISCONNECTING" ? "" : (coreMa.containsMouse ? (window.activeMode === "wifi" ? "󰖪" : "󰂲") : (window.currentObj ? window.currentObj.icon : ""))
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            
                            LoadingDots { Layout.alignment: Qt.AlignHCenter; visible: window.busyTask === "DISCONNECTING"; dotCol: window.overlay1 }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 16
                                color: window.busyTask === "DISCONNECTING" ? window.overlay1 : window.crust
                                text: window.currentObj ? (window.activeMode === "wifi" ? window.currentObj.ssid : window.currentObj.name) : ""
                                width: 150; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 11
                                color: window.busyTask === "DISCONNECTING" ? window.overlay1 : (centralCore.disconnectFill > 0.1 ? window.crust : (coreMa.containsMouse ? window.crust : "#99000000"))
                                text: window.busyTask === "DISCONNECTING" ? "Rozłączanie..." : (centralCore.disconnectFill > 0.1 ? "Trzymaj..." : "Podłączono")
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            id: coreMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: window.currentConn && window.busyTask !== "DISCONNECTING" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            
                            onPressed: {
                                if (window.currentConn && window.busyTask === "" && !centralCore.disconnectTriggered) {
                                    coreDrainAnim.stop();
                                    coreFillAnim.start();
                                }
                            }
                            onReleased: {
                                if (!centralCore.disconnectTriggered && window.busyTask === "") {
                                    coreFillAnim.stop();
                                    coreDrainAnim.start();
                                }
                            }
                        }

                        NumberAnimation {
                            id: coreFillAnim
                            target: centralCore
                            property: "disconnectFill"
                            to: 1.0
                            duration: 700 * (1.0 - centralCore.disconnectFill) 
                            easing.type: Easing.InSine
                            onFinished: {
                                centralCore.disconnectTriggered = true;
                                centralCore.flashOpacity = 0.6;
                                coreFlashAnim.start();
                                coreBumpAnim.start();
                                
                                window.playSfx("disconnect.wav");
                                window.busyTask = "DISCONNECTING"
                                busyTimeout.start()
                                let cmd = window.activeMode === "wifi" 
                                    ? "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE d | grep wifi | cut -d: -f1 | head -n1)"
                                    : "bash " + window.scriptsDir + "/bluetooth_panel_logic.sh --disconnect " + window.currentObj.mac
                                Quickshell.execDetached(["sh", "-c", cmd])
                                
                                centralCore.disconnectFill = 0.0;
                                centralCore.disconnectTriggered = false;
                                
                                if (window.activeMode === "wifi") wifiPoller.running = true; else btPoller.running = true;
                            }
                        }
                        
                        NumberAnimation {
                            id: coreDrainAnim
                            target: centralCore
                            property: "disconnectFill"
                            to: 0.0
                            duration: 1000 * centralCore.disconnectFill 
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                // =========================================================
                // 2. THE SWARM (Single dynamic scaling orbit)
                // =========================================================
                Item {
                    anchors.fill: parent
                    opacity: window.currentPower ? 1.0 : 0.0
                    scale: window.currentPower ? 1.0 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                    Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

                    Repeater {
                        id: orbitRepeater
                        model: (window.currentConn && window.showInfoView) ? infoListModel : (window.activeMode === "wifi" ? wifiListModel : btListModel)
                        
                        delegate: Rectangle {
                            id: floatCard
                            width: 170; height: 60
                            radius: 16
                            
                            property string itemId: id
                            property string itemName: name
                            property bool isMyBusy: window.busyTask === itemId
                            property bool isPairedBT: window.activeMode === "bt" && action === "Połącz"
                            property bool isTargetWifi: window.activeMode === "wifi" && !window.isWifiConn && itemId === window.targetWifiSsid
                            property bool isSpecialAction: itemId === "action_scan" || itemId === "action_settings"
                            property bool isHighlighted: isPairedBT || isTargetWifi || isSpecialAction
                            
                            property bool isCurrentlyConnected: (window.activeMode === "wifi" ? (window.wifiConnected && window.wifiConnected.ssid === itemId) : (window.btConnected && window.btConnected.mac === itemId))
                            
                            property bool isInteractable: !isInfoNode || isActionable
                            property bool locksList: isInteractable && (floatMa.containsMouse || floatMa.pressed)
                            onLocksListChanged: { if (locksList) window.hoveredCardCount++; else window.hoveredCardCount--; }
                            Component.onDestruction: { if (locksList) window.hoveredCardCount--; }

                            property int activeCount: orbitRepeater.count
                            property real dynamicScale: activeCount > 10 ? Math.max(0.75, 12.0 / activeCount) : 1.0
                            
                            property real baseAngle: activeCount > 0 ? (index / activeCount) * Math.PI * 2 : 0
                            Behavior on baseAngle { NumberAnimation { duration: 1000; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                            property real liveAngle: window.globalOrbitAngle + baseAngle
                            
                            property real currentRadiusX: isInfoNode ? 300 : 290 + (Math.min(activeCount, 20) * 3)
                            property real currentRadiusY: isInfoNode ? 200 : 195 + (Math.min(activeCount, 20) * 2.5)

                            property bool isLoaded: false
                            property real animRadiusX: isLoaded ? currentRadiusX : 0
                            property real animRadiusY: isLoaded ? currentRadiusY : 0

                            Behavior on animRadiusX { NumberAnimation { duration: 1200; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                            Behavior on animRadiusY { NumberAnimation { duration: 1200; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                            property real targetX: (orbitContainer.width / 2 - width / 2) + Math.cos(liveAngle) * animRadiusX
                            property real targetY: (orbitContainer.height / 2 - height / 2) + Math.sin(liveAngle) * animRadiusY

                            property real bobOffset: 0
                            SequentialAnimation on bobOffset {
                                id: bobAnim
                                loops: Animation.Infinite; running: true
                                PauseAnimation { duration: (index % 5) * 200 }
                                NumberAnimation { from: 0; to: -15; duration: 2000; easing.type: Easing.InOutSine }
                                NumberAnimation { from: -15; to: 0; duration: 2000; easing.type: Easing.InOutSine }
                            }

                            x: targetX
                            y: targetY + bobOffset

                            Component.onCompleted: isLoaded = true
                            
                            opacity: isLoaded ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 500 } }
                            
                            property real bumpScale: 1.0
                            SequentialAnimation on bumpScale {
                                id: cardBumpAnim
                                running: false
                                NumberAnimation { to: 1.2; duration: 150; easing.type: Easing.OutBack }
                                NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.OutQuint }
                            }
                            scale: (!isLoaded ? 0.0 : (floatMa.pressed ? dynamicScale * 0.95 : (locksList ? dynamicScale * 1.08 : dynamicScale))) * bumpScale
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            
                            z: locksList ? 10 : index

                            property real nameImplicitWidth: baseNameText.implicitWidth
                            property real nameContainerWidth: nameContainerBase.width
                            property bool doMarquee: floatMa.containsMouse && nameImplicitWidth > nameContainerWidth
                            property real textOffset: 0

                            SequentialAnimation on textOffset {
                                running: floatCard.doMarquee
                                loops: Animation.Infinite
                                PauseAnimation { duration: 600 } 
                                NumberAnimation {
                                    from: 0
                                    to: -(floatCard.nameImplicitWidth + 30)
                                    duration: (floatCard.nameImplicitWidth + 30) * 35
                                }
                            }
                            onDoMarqueeChanged: if (!doMarquee) textOffset = 0;

                            // -------------------------------------------------------------------------
                            // HOLD TO EXECUTE STATE
                            // -------------------------------------------------------------------------
                            property real fillLevel: 0.0
                            property bool triggered: false
                            property real flashOpacity: 0.0
                            
                            property real renderFill: (isCurrentlyConnected) ? 1.0 : fillLevel
                            
                            onIsMyBusyChanged: {
                                if (!isMyBusy && triggered) {
                                    triggered = false;
                                    if (!floatCard.isCurrentlyConnected) drainAnim.start();
                                }
                            }
                            
                            onIsCurrentlyConnectedChanged: {
                                if (!isCurrentlyConnected && fillLevel > 0) drainAnim.start();
                            }

                            color: locksList ? "#1affffff" : "#0dffffff"
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: "transparent"
                                border.width: 1
                                border.color: window.surface2
                                visible: !isHighlighted && !locksList
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                opacity: locksList || isHighlighted ? 1.0 : 0.0
                                color: "transparent"
                                border.width: isHighlighted && !locksList ? 1 : 2
                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: isHighlighted && !locksList ? 1 : 2
                                    radius: 14
                                    color: window.base
                                    opacity: locksList ? 0.9 : 1.0
                                }
                                
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: window.activeColor }
                                    GradientStop { position: 1.0; color: window.activeGradientSecondary }
                                }
                                z: -1
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: "#ffffff"
                                opacity: floatCard.flashOpacity
                                PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                                z: 5
                            }

                            Canvas {
                                id: waveCanvas
                                anchors.fill: parent
                                
                                property real wavePhase: 0.0
                                
                                NumberAnimation on wavePhase {
                                    running: floatCard.renderFill > 0.0 && floatCard.renderFill < 1.0
                                    loops: Animation.Infinite
                                    from: 0; to: Math.PI * 2
                                    duration: 800
                                }

                                onWavePhaseChanged: requestPaint()
                                Connections { target: floatCard; function onRenderFillChanged() { waveCanvas.requestPaint() } }

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    if (floatCard.renderFill <= 0.001) return;

                                    var currentW = width * floatCard.renderFill;
                                    var r = 16; 

                                    ctx.save();
                                    ctx.beginPath();
                                    ctx.moveTo(0, 0);
                                    
                                    if (floatCard.renderFill < 0.99) {
                                        var waveAmp = 12 * Math.sin(floatCard.renderFill * Math.PI); 
                                        if (currentW - waveAmp < 0) waveAmp = currentW;
                                        var cp1x = currentW + Math.sin(wavePhase) * waveAmp;
                                        var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp;

                                        ctx.lineTo(currentW, 0);
                                        ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height);
                                        ctx.lineTo(0, height);
                                    } else {
                                        ctx.lineTo(width, 0);
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                    }
                                    ctx.closePath();
                                    ctx.clip(); 

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

                                    var grad = ctx.createLinearGradient(0, 0, currentW, 0);
                                    grad.addColorStop(0, window.activeColor);
                                    grad.addColorStop(1, window.activeGradientSecondary);
                                    ctx.fillStyle = grad;
                                    ctx.fill();

                                    ctx.restore();
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.color: window.activeColor
                                border.width: 2
                                visible: parent.isHighlighted && !parent.isMyBusy && !parent.isCurrentlyConnected
                                
                                SequentialAnimation on scale {
                                    loops: Animation.Infinite; running: parent.visible
                                    NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                                }
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite; running: parent.visible
                                    NumberAnimation { to: 0.0; duration: 1200; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
                                }
                            }

                            RowLayout {
                                id: baseTextRow
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10
                                
                                Text {
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 20
                                    color: floatCard.isMyBusy ? window.text : window.activeColor
                                    text: icon
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Item {
                                        id: nameContainerBase
                                        Layout.fillWidth: true
                                        height: 18
                                        clip: true

                                        Row {
                                            x: floatCard.textOffset
                                            spacing: 30
                                            Text {
                                                id: baseNameText
                                                text: floatCard.itemName
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: floatCard.isHighlighted ? window.activeColor : window.text
                                            }
                                            Text {
                                                visible: floatCard.doMarquee
                                                text: floatCard.itemName
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: floatCard.isHighlighted ? window.activeColor : window.text
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 10
                                        color: floatCard.isMyBusy ? window.activeColor : window.overlay0
                                        text: floatCard.isMyBusy ? "Łączenie..." : (floatCard.renderFill > 0.1 && floatCard.renderFill < 1.0 ? "Trzymaj..." : action)
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: floatCard.width * floatCard.renderFill
                                clip: true
                                
                                RowLayout {
                                    x: baseTextRow.x; y: baseTextRow.y
                                    width: baseTextRow.width; height: baseTextRow.height
                                    spacing: 10
                                    
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: window.crust; text: icon }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Item {
                                            Layout.fillWidth: true
                                            height: 18
                                            clip: true
                                            Row {
                                                x: floatCard.textOffset
                                                spacing: 30
                                                Text { text: floatCard.itemName; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 13; color: window.crust }
                                                Text { visible: floatCard.doMarquee; text: floatCard.itemName; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 13; color: window.crust }
                                            }
                                        }
                                        Text {
                                            font.family: "JetBrains Mono"; font.pixelSize: 10; color: window.crust
                                            text: floatCard.isMyBusy ? "Łączenie..." : (floatCard.renderFill > 0.1 && floatCard.renderFill < 1.0 ? "Trzymaj..." : action)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: floatMa
                                anchors.fill: parent
                                hoverEnabled: floatCard.isInteractable
                                cursorShape: (window.busyTask !== "" || floatCard.triggered || floatCard.isMyBusy || floatCard.renderFill === 1.0 || !floatCard.isInteractable) ? Qt.ArrowCursor : Qt.PointingHandCursor
                                
                                onPressed: { 
                                    if (floatCard.isInteractable && window.busyTask === "" && !floatCard.triggered && !floatCard.isMyBusy && floatCard.fillLevel === 0.0) {
                                        drainAnim.stop()
                                        fillAnim.start()
                                    }
                                }
                                onReleased: {
                                    if (floatCard.isInteractable && !floatCard.triggered && !floatCard.isMyBusy && floatCard.fillLevel < 1.0) {
                                        fillAnim.stop()
                                        drainAnim.start()
                                    }
                                }
                            }

                            NumberAnimation {
                                id: fillAnim
                                target: floatCard
                                property: "fillLevel"
                                to: 1.0
                                duration: 600 * (1.0 - floatCard.fillLevel) 
                                easing.type: Easing.InSine
                                onFinished: {
                                    floatCard.triggered = true;
                                    floatCard.flashOpacity = 0.6;
                                    cardFlashAnim.start();
                                    cardBumpAnim.start();
                                    
                                    if (cmdStr === "TOGGLE_VIEW") {
                                        window.playSfx("switch.wav");
                                        window.showInfoView = !window.showInfoView;
                                        floatCard.triggered = false;
                                        drainAnim.start();
                                    } else if (isInfoNode && cmdStr) {
                                        Quickshell.execDetached(["sh", "-c", cmdStr]);
                                        if (window.activeMode === "bt") btPoller.running = true;
                                        floatCard.triggered = false;
                                        drainAnim.start(); 
                                    } else {
                                        if (window.activeMode === "wifi") {
                                            let needsPassword = !!security && security !== "--" && security.toLowerCase() !== "none" && requiresPassword;
                                            if (needsPassword) {
                                                window.openWifiPasswordPopup(ssid, security);
                                                floatCard.triggered = false;
                                                drainAnim.start();
                                            } else {
                                                window.busyTask = floatCard.itemId;
                                                busyTimeout.start();
                                                wifiConnectProcess.pendingSsid = ssid;
                                                wifiConnectProcess.pendingPassword = "";
                                                wifiConnectProcess.running = true;
                                            }
                                        } else {
                                            window.busyTask = floatCard.itemId;
                                            busyTimeout.start();
                                            let cmd = "bash " + window.scriptsDir + "/bluetooth_panel_logic.sh --connect " + mac;
                                            Quickshell.execDetached(["sh", "-c", cmd]);
                                            btPoller.running = true;
                                        }
                                    }
                                }
                            }
                            
                            NumberAnimation {
                                id: drainAnim
                                target: floatCard
                                property: "fillLevel"
                                to: 0.0
                                duration: 1500 * floatCard.fillLevel 
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }

            // =========================================================
            // BOTTOM DOCK (Mode Switcher & Power)
            // =========================================================
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 25
                width: 360
                height: 54
                radius: 27
                color: "#1affffff" 
                border.color: "#1affffff"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    // Wi-Fi Mode Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 21
                        
                        color: window.activeMode === "wifi" ? "transparent" : (wifiTabMa.containsMouse ? window.surface1 : "transparent")
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 21
                            opacity: window.activeMode === "wifi" ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: window.sapphire }
                                GradientStop { position: 1.0; color: window.blue }
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: window.activeMode === "wifi" ? window.crust : window.text; text: "󰤨"; Behavior on color { ColorAnimation{duration:200} } }
                            Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 13; color: window.activeMode === "wifi" ? window.crust : window.text; text: "Wi-Fi"; Behavior on color { ColorAnimation{duration:200} } }
                        }
                        MouseArea {
                            id: wifiTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activeMode !== "wifi") window.playSfx("switch.wav");
                                window.activeMode = "wifi";
                            }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; Layout.margins: 5; color: "#33ffffff" }

                    // Bluetooth Mode Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 21
                        color: window.activeMode === "bt" ? "transparent" : (btTabMa.containsMouse ? window.surface1 : "transparent")
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 21
                            opacity: window.activeMode === "bt" ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: window.mauve }
                                GradientStop { position: 1.0; color: window.pink }
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: window.activeMode === "bt" ? window.crust : window.text; text: "󰂯"; Behavior on color { ColorAnimation{duration:200} } }
                            Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 13; color: window.activeMode === "bt" ? window.crust : window.text; text: "Bluetooth"; Behavior on color { ColorAnimation{duration:200} } }
                        }
                        MouseArea {
                            id: btTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activeMode !== "bt") window.playSfx("switch.wav");
                                window.activeMode = "bt";
                            }
                        }
                    }
                }
            }

            // Power Toggle 
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 30
                width: 48; height: 48; radius: 24
                
                color: "transparent"
                border.color: window.currentPowerPending ? window.activeColor : (window.currentPower ? "transparent" : window.surface2)
                border.width: 2
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    opacity: window.currentPower ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: window.activeColor; Behavior on color { ColorAnimation {duration: 300} } }
                        GradientStop { position: 1.0; color: window.activeGradientSecondary; Behavior on color { ColorAnimation {duration: 300} } }
                    }
                }
                
                scale: pwrMa.pressed ? 0.9 : (pwrMa.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                Text {
                    id: pwrIcon
                    anchors.centerIn: parent
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 22
                    color: window.currentPower ? window.crust : window.text
                    text: window.currentPowerPending ? "󰑮" : "" 
                    Behavior on color { ColorAnimation { duration: 300 } }

                    RotationAnimation {
                        target: pwrIcon
                        property: "rotation"
                        from: 0; to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: window.currentPowerPending
                        onRunningChanged: {
                            if (!running) pwrIcon.rotation = 0;
                        }
                    }
                }

                MouseArea {
                    id: pwrMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (window.activeMode === "wifi") {
                            if (window.wifiPowerPending) return;
                            window.expectedWifiPower = window.wifiPower === "on" ? "off" : "on";
                            window.wifiPowerPending = true;
                            
                            if (window.expectedWifiPower === "on") window.playSfx("power_on.wav"); else window.playSfx("power_off.wav");
                            
                            wifiPendingReset.start();
                            window.wifiPower = window.expectedWifiPower; // Optimistic
                            Quickshell.execDetached(["nmcli", "radio", "wifi", window.wifiPower]);
                            wifiPoller.running = true;
                        } else {
                            if (window.btPowerPending) return;
                            window.expectedBtPower = window.btPower === "on" ? "off" : "on";
                            window.btPowerPending = true;
                            
                            if (window.expectedBtPower === "on") window.playSfx("power_on.wav"); else window.playSfx("power_off.wav");
                            
                            btPendingReset.start();
                            window.btPower = window.expectedBtPower; // Optimistic
                            Quickshell.execDetached(["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--toggle"]);
                            btPoller.running = true;
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: window.wifiPasswordPopupVisible
                opacity: visible ? 1.0 : 0.0
                color: "#a0000000"
                z: 100
                Behavior on opacity { NumberAnimation { duration: 220 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.wifiPasswordPopupVisible = false;
                        window.wifiPromptError = "";
                        window.wifiPromptPassword = "";
                    }
                }

                Rectangle {
                    width: Math.min(parent.width - 80, 500)
                    height: 285
                    anchors.centerIn: parent
                    radius: 22
                    color: window.base
                    border.color: window.surface0
                    border.width: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: 0.18
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: window.activeColor }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: 18
                            color: window.text
                            text: "Podaj hasło Wi-Fi"
                        }

                        Text {
                            Layout.fillWidth: true
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            color: window.activeColor
                            text: window.wifiPromptSsid
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            color: window.text
                            text: "Zabezpieczenie: " + window.wifiPromptSecurity
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            height: 52
                            radius: 14
                            color: window.crust
                            border.color: passInput.activeFocus ? window.activeColor : window.surface2
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Text {
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 18
                                    color: window.activeColor
                                    text: "󰌾"
                                }

                                TextInput {
                                    id: passInput
                                    Layout.fillWidth: true
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 14
                                    color: window.text
                                    selectionColor: window.activeColor
                                    selectedTextColor: window.crust
                                    echoMode: window.wifiPasswordReveal ? TextInput.Normal : TextInput.Password
                                    text: window.wifiPromptPassword
                                    onTextChanged: window.wifiPromptPassword = text
                                    focus: window.wifiPasswordPopupVisible
                                    clip: true
                                    Keys.onReturnPressed: window.submitWifiPassword()
                                    Keys.onEnterPressed: window.submitWifiPassword()
                                }

                                Text {
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 18
                                    color: revealMa.containsMouse ? window.activeGradientSecondary : window.overlay0
                                    text: window.wifiPasswordReveal ? "󰈈" : "󰈉"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                id: revealMa
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 54
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.wifiPasswordReveal = !window.wifiPasswordReveal
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: window.wifiPromptError !== ""
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            color: window.red
                            text: window.wifiPromptError
                            wrapMode: Text.WordWrap
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: 10

                            Rectangle {
                                width: 110
                                height: 38
                                radius: 12
                                color: cancelMa.containsMouse ? window.surface1 : window.mantle
                                border.color: window.surface2
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 12
                                    color: window.text
                                    text: "Anuluj"
                                }

                                MouseArea {
                                    id: cancelMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        window.wifiPasswordPopupVisible = false;
                                        window.wifiPromptError = "";
                                        window.wifiPromptPassword = "";
                                    }
                                }
                            }

                            Rectangle {
                                width: 132
                                height: 38
                                radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: window.sapphire }
                                    GradientStop { position: 1.0; color: window.blue }
                                }
                                opacity: window.busyTask === window.wifiPromptSsid ? 0.75 : 1.0

                                Text {
                                    anchors.centerIn: parent
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: 12
                                    color: window.crust
                                    text: window.busyTask === window.wifiPromptSsid ? "Łączenie..." : "Połącz"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: window.busyTask !== window.wifiPromptSsid
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.submitWifiPassword()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
