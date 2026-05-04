import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtQuick.Window
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: window

    // -------------------------------------------------------------------------
    // WINDOW CONFIG
    // -------------------------------------------------------------------------
    title: "wallpaper-picker"
    width: 1920
    height: 400
    color: "transparent"

    // -------------------------------------------------------------------------
    // PROPERTIES
    // -------------------------------------------------------------------------
    readonly property string homePath: Quickshell.env("HOME")
    readonly property string homeDir: "file://" + homePath
    property int wallpaperIndex: 0
    readonly property string thumbDir: homeDir + "/.cache/wallpaper_picker/thumbs"
    readonly property string srcDir: homePath + "/.config/backgrounds"
    readonly property string backgroundsDir: "file://" + homePath + "/.cache/wallpaper_picker/thumbs"

    // Get WALLPAPER_INDEX using Process
    Process {
        id: wallpaperIndexProcess
        command: ["sh", "-c", "echo -n ${WALLPAPER_INDEX:-0}"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                window.wallpaperIndex = parseInt(this.text.trim() || "0")
            }
        }
    }

    property bool initialFocusSet: false
    property string currentFilter: "All"
    property var colorMap: ({})
    property int cacheVersion: 0

    readonly property int itemWidth: 300
    readonly property int itemHeight: 420
    readonly property int borderWidth: 3
    readonly property int spacing: 0 
    readonly property real skewFactor: -0.35

    // List of available awww transitions to randomize from
    readonly property var transitions: ["grow", "outer", "any", "wipe", "wave", "pixel", "center"]

    readonly property var filterData: [
        { name: "All", hex: "", label: "All" },
        { name: "Video", hex: "", label: "Vid" },
        { name: "Red", hex: "#FF4500", label: "" },
        { name: "Orange", hex: "#FFA500", label: "" },
        { name: "Yellow", hex: "#FFD700", label: "" },
        { name: "Green", hex: "#32CD32", label: "" },
        { name: "Blue", hex: "#1E90FF", label: "" },
        { name: "Purple", hex: "#8A2BE2", label: "" },
        { name: "Pink", hex: "#FF69B4", label: "" },
        { name: "Monochrome", hex: "#A9A9A9", label: "" }
    ]

    Loader {
        id: themeLoader
        source: homePath.length > 0 ? "file://" + homePath + "/.config/quickshell/MatugenTheme.qml" : ""
    }

    readonly property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    QtObject {
        id: dummyTheme
        property string base: "#1e1e2e"
        property string text: "#cdd6f4"
        property string surface0: "#313244"
        property string surface1: "#45475a"
        property string surface2: "#585b70"
        property string mantle: "#181825"
    }

    function getHexBucket(hexStr) {
        if (!hexStr) return "Monochrome";
        
        hexStr = String(hexStr).trim().replace(/#/g, '');
        if (hexStr.length > 6) hexStr = hexStr.substring(0, 6);
        if (hexStr.length !== 6) return "Monochrome";

        let r = parseInt(hexStr.substring(0,2), 16) / 255;
        let g = parseInt(hexStr.substring(2,4), 16) / 255;
        let b = parseInt(hexStr.substring(4,6), 16) / 255;

        if (isNaN(r) || isNaN(g) || isNaN(b)) return "Monochrome";

        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let d = max - min;
        
        let h = 0;
        let s = max === 0 ? 0 : d / max;
        let v = max;

        if (max !== min) {
            if (max === r) {
                h = (g - b) / d + (g < b ? 6 : 0);
            } else if (max === g) {
                h = (b - r) / d + 2;
            } else {
                h = (r - g) / d + 4;
            }
            h /= 6;
        }
        h = h * 360;

        if (s < 0.05 || v < 0.08) return "Monochrome";

        if (h >= 345 || h < 15) return "Red";
        if (h >= 15 && h < 45) return "Orange";
        if (h >= 45 && h < 75) return "Yellow";
        if (h >= 75 && h < 165) return "Green";
        if (h >= 165 && h < 260) return "Blue";
        if (h >= 260 && h < 315) return "Purple";
        if (h >= 315 && h < 345) return "Pink";

        return "Monochrome";
    }

    function checkItemMatchesFilter(fileName, isVid, cv, filter) {
        if (filter === "All") return true;
        if (filter === "Video") return isVid;
        
        let hexColor = colorMap[String(fileName)];
        if (!hexColor) return filter === "Monochrome";
        
        return getHexBucket(hexColor) === filter;
    }

    FolderListModel {
        id: markerModel
        folder: homePath.length > 0 ? "file://" + homePath + "/.cache/wallpaper_picker/colors_markers" : ""
        showDirs: false
        nameFilters: ["*_HEX_*"]
        
        onCountChanged: processMarkers()
        onStatusChanged: { if (status === FolderListModel.Ready) processMarkers() }
    }

    function processMarkers() {
        let newMap = {};
        for (let i = 0; i < markerModel.count; i++) {
            let markerName = markerModel.get(i, "fileName") || "";
            if (!markerName) continue;
            
            let splitIdx = markerName.lastIndexOf("_HEX_");
            if (splitIdx !== -1) {
                let fName = markerName.substring(0, splitIdx);
                let hexCode = markerName.substring(splitIdx + 5);
                newMap[fName] = "#" + hexCode;
            }
        }
        colorMap = newMap;
        cacheVersion++;
    }

    function stepToNextValidIndex(direction) {
        if (folderModel.count === 0) return;
        
        let start = view.currentIndex;
        let found = -1;

        for (let i = 1; i <= folderModel.count; i++) {
            let idx = (start + (i * direction) + folderModel.count) % folderModel.count;
            let fname = folderModel.get(idx, "fileName") || "";
            let isVid = fname.startsWith("000_");
            if (checkItemMatchesFilter(fname, isVid, cacheVersion, currentFilter)) {
                found = idx;
                break;
            }
        }

        if (found !== -1) {
            view.currentIndex = found;
        }
    }

    function applyFilters() {
        if (folderModel.count === 0) return;

        let foundIndex = -1;
        for (let i = 0; i < folderModel.count; i++) {
            let fname = folderModel.get(i, "fileName") || "";
            let isVid = fname.startsWith("000_");
            if (checkItemMatchesFilter(fname, isVid, cacheVersion, currentFilter)) {
                foundIndex = i;
                break;
            }
        }

        if (foundIndex !== -1) {
            view.currentIndex = foundIndex;
            view.positionViewAtIndex(foundIndex, ListView.Center);
        }
    }

    function cycleFilter(direction) {
        let currentIdx = -1;
        for (let i = 0; i < filterData.length; i++) {
            if (filterData[i].name === currentFilter) {
                currentIdx = i;
                break;
            }
        }
        
        if (currentIdx !== -1) {
            let nextIdx = (currentIdx + direction + filterData.length) % filterData.length;
            currentFilter = filterData[nextIdx].name;
        }
    }

    onCurrentFilterChanged: applyFilters()

    Shortcut { sequence: "Left"; onActivated: stepToNextValidIndex(-1) }
    Shortcut { sequence: "Right"; onActivated: stepToNextValidIndex(1) }
    Shortcut { sequence: "Tab"; onActivated: cycleFilter(1) }
    Shortcut { sequence: "Backtab"; onActivated: cycleFilter(-1) }
    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    Shortcut { 
        sequence: "Return"
        onActivated: {
            if (view.currentItem) view.currentItem.pickWallpaper()
        }
    }

    // -------------------------------------------------------------------------
    // FILTER BAR
    // -------------------------------------------------------------------------
    Rectangle {
        id: filterBarBackground
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        z: 20
        height: 56
        width: filterRow.width + 24
        radius: 14
        
        color: Qt.rgba(window.theme.mantle.r, window.theme.mantle.g, window.theme.mantle.b, 0.90)
        border.color: window.theme.surface2
        border.width: 1

        Row {
            id: filterRow
            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: window.filterData

                delegate: Item {
                    width: (modelData.name === "Video" || modelData.name === "All") ? 44 : (modelData.hex === "" ? filterText.contentWidth + 24 : 36)
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: modelData.hex === "" 
                                ? (window.currentFilter === modelData.name ? window.theme.surface2 : "transparent") 
                                : modelData.hex
                        
                        border.color: window.currentFilter === modelData.name ? window.theme.text : window.theme.surface1
                        border.width: window.currentFilter === modelData.name ? 2 : 1
                        scale: window.currentFilter === modelData.name ? 1.15 : (filterMouse.containsMouse ? 1.08 : 1.0)
                        
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        Text {
                            id: filterText
                            visible: modelData.hex === "" && modelData.name !== "Video" && modelData.name !== "All"
                            text: modelData.label
                            anchors.centerIn: parent
                            color: window.currentFilter === modelData.name ? window.theme.text : Qt.rgba(window.theme.text.r, window.theme.text.g, window.theme.text.b, 0.7)
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            font.bold: window.currentFilter === modelData.name
                            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }
                        }

                        Canvas {
                            visible: modelData.name === "Video"
                            width: 14; height: 16
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 2
                            property string activeColor: window.currentFilter === modelData.name ? window.theme.text : Qt.rgba(window.theme.text.r, window.theme.text.g, window.theme.text.b, 0.7)
                            onActiveColorChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = activeColor;
                                ctx.beginPath();
                                ctx.moveTo(0, 0);
                                ctx.lineTo(14, 8);
                                ctx.lineTo(0, 16);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }

                        Canvas {
                            visible: modelData.name === "All"
                            width: 14; height: 14
                            anchors.centerIn: parent
                            property string activeColor: window.currentFilter === modelData.name ? window.theme.text : Qt.rgba(window.theme.text.r, window.theme.text.g, window.theme.text.b, 0.7)
                            onActiveColorChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = activeColor;
                                ctx.fillRect(0, 0, 6, 6);
                                ctx.fillRect(8, 0, 6, 6);
                                ctx.fillRect(0, 8, 6, 6);
                                ctx.fillRect(8, 8, 6, 6);
                            }
                        }
                    }

                    MouseArea {
                        id: filterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: window.currentFilter = modelData.name
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // CONTENT
    // -------------------------------------------------------------------------
    ListView {
        id: view
        anchors.fill: parent
        anchors.margins: 0 
        
        spacing: window.spacing
        orientation: ListView.Horizontal
        
        clip: false 

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.5 + window.spacing) / 2)
        preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.5 + window.spacing) / 2)
        
        highlightMoveDuration: window.initialFocusSet ? 500 : 0

        focus: true

        onCountChanged: {
            if (!initialFocusSet && count > 0) {
                var idx = window.wallpaperIndex
                if (count > idx) {
                    currentIndex = idx
                    positionViewAtIndex(idx, ListView.Center)
                    initialFocusSet = true
                }
            }
        }

        add: Transition {
            enabled: window.initialFocusSet
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 400; easing.type: Easing.OutBack }
            }
        }

        addDisplaced: Transition {
            enabled: window.initialFocusSet
            NumberAnimation { property: "x"; duration: 400; easing.type: Easing.OutCubic }
        }

        header: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }
        footer: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }

        model: FolderListModel {
            id: folderModel
            folder: window.backgroundsDir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
            showDirs: false
            sortField: FolderListModel.Name
        }

        Keys.onReturnPressed: {
            if (currentItem) currentItem.pickWallpaper()
        }

        delegate: Item {
            id: delegateRoot
            
            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool matchesFilter: window.checkItemMatchesFilter(fileName, isVideo, window.cacheVersion, window.currentFilter)
            
            readonly property real targetWidth: isCurrent ? (window.itemWidth * 1.5) : (window.itemWidth * 0.5)
            readonly property real targetHeight: isCurrent ? (window.itemHeight + 30) : window.itemHeight
            
            width: matchesFilter ? (targetWidth + window.spacing) : 0
            visible: width > 0.1 || opacity > 0.01
            opacity: matchesFilter ? (isCurrent ? 1.0 : 0.6) : 0.0
            scale: matchesFilter ? 1.0 : 0.5
            height: matchesFilter ? targetHeight : 0

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 15

            readonly property bool isVideo: fileName.startsWith("000_")

            z: isCurrent ? 10 : 1

            Behavior on scale { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on width { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on height { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on opacity { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

            function pickWallpaper() {
                if (!matchesFilter) return;
                const originalFileName = isVideo ? fileName.substring(4) : fileName
                const originalFile = window.srcDir + "/" + originalFileName
                const randomTransition = window.transitions[Math.floor(Math.random() * window.transitions.length)]
                const applyWallScript = window.homePath + "/.config/quickshell/scripts/apply_wall.sh"
                
                console.log("Picking wallpaper: " + originalFile);
                Quickshell.execDetached(["bash", applyWallScript, originalFile, randomTransition])
                
                quitTimer.start()
            }

            Timer {
                id: quitTimer
                interval: 50
                onTriggered: Qt.quit()
            }

            // PARALLELOGRAM CONTAINER
            Item {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: ((window.itemHeight - height) / 2) * window.skewFactor
                
                width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + window.spacing)) : 0
                height: parent.height

                transform: Matrix4x4 {
                    property real s: window.skewFactor
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: delegateRoot.matchesFilter
                    onClicked: {
                        if (delegateRoot.isCurrent) {
                            delegateRoot.pickWallpaper()
                        } else {
                            view.currentIndex = index
                        }
                    }
                }

                // Obsługa zwykłych obrazów
                Image {
                    anchors.fill: parent
                    source: fileUrl
                    sourceSize: Qt.size(1, 1)
                    fillMode: Image.Stretch
                    visible: !fileName.toLowerCase().endsWith(".gif")
                }

                // Obsługa animowanych GIFów
                AnimatedImage {
                    anchors.fill: parent
                    source: fileUrl
                    playing: delegateRoot.isCurrent
                    fillMode: Image.Stretch
                    visible: fileName.toLowerCase().endsWith(".gif")
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: window.borderWidth 
                    
                    Rectangle { anchors.fill: parent; color: window.theme.base }
                    clip: true

                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -35 
                        
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + 30) * Math.abs(window.skewFactor)) + 50
                        height: window.itemHeight + 30
                        
                        fillMode: Image.PreserveAspectCrop
                        source: fileUrl
                        visible: !fileName.toLowerCase().endsWith(".gif")

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }

                    AnimatedImage {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -35 
                        
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + 30) * Math.abs(window.skewFactor)) + 50
                        height: window.itemHeight + 30
                        
                        fillMode: Image.PreserveAspectCrop
                        source: fileUrl
                        playing: delegateRoot.isCurrent
                        visible: fileName.toLowerCase().endsWith(".gif")

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    
                    Rectangle {
                        visible: delegateRoot.isVideo
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        
                        width: 32
                        height: 32
                        radius: 6
                        color: "#60000000"
                        
                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                        
                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 8 
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.fillStyle = "#EEFFFFFF"; 
                                ctx.beginPath();
                                ctx.moveTo(4, 0);
                                ctx.lineTo(14, 8);
                                ctx.lineTo(4, 16);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                    }
                }
            }
        }
    }
}
