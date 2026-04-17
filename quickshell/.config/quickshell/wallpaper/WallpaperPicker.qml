import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtCore
import Qt.labs.folderlistmodel
import QtMultimedia
import Quickshell
import "." 

ShellRoot {
    id: root

    MatugenTheme { id: theme }

    // --- COLOR MAPPINGS ---
    readonly property color base: theme.base
    readonly property color mantle: theme.mantle
    readonly property color crust: theme.crust
    readonly property color text: theme.text
    readonly property color surface2: theme.surface2
    readonly property color surface1: theme.surface1
    
    readonly property real scaleFactor: (Quickshell.screens.length > 0) ? Quickshell.screens[0].width / 1920.0 : 1.0

    // --- STATE ---
    property string currentSessionId: ""
    property bool hasSearched: false 
    property string currentFilter: "All"
    property bool isApplying: false 
    property var colorMap: ({})
    property int cacheVersion: 0 
    property bool isExtracting: false
    
    readonly property string homePath: Quickshell.env("HOME")
    readonly property string thumbDir: "file://" + homePath + "/.cache/wallpaper_picker/thumbs"
    readonly property string markerDir: "file://" + homePath + "/.cache/wallpaper_picker/colors_markers"
    readonly property string srcDir: homePath + "/.config/backgrounds"

    readonly property real itemWidth: 400 * scaleFactor
    readonly property real itemHeight: 420 * scaleFactor
    readonly property real spacing: 10 * scaleFactor
    readonly property real skewFactor: -0.35

    property string currentNotification: {
        if (isExtracting) return "Refining rainbow colors..."
        if (currentFilter === "Search") {
            if (hasSearched) {
                if (searchProxyModel.count === 0) return "Searching Wallhaven..."
                return "Found " + searchProxyModel.count + " results"
            }
            return "Type something to search..."
        }
        return ""
    }
    
    property bool isReady: (localProxyModel.count > 0)

    // --- ACTIONS ---
    function applyWallpaper(safeFileName, isVideo) {
        if (!safeFileName || root.isApplying) return
        root.isApplying = true 
        var scriptPath = homePath + "/.config/quickshell/wallpaper/apply_wall.sh"
        var isSearchStr = (currentFilter === "Search") ? "true" : "false"
        var isVideoStr = isVideo ? "true" : "false"
        Quickshell.execDetached(["bash", scriptPath, safeFileName, isVideoStr, "grow", isSearchStr])
        Qt.quit()
    }

    function triggerOnlineSearch() {
        var query = searchInput.text.trim()
        if (query === "") return
        root.currentSessionId = Date.now().toString()
        searchProxyModel.clear()
        root.hasSearched = true
        currentFilter = "Search"
        var scriptPath = homePath + "/.config/quickshell/wallpaper/ddg_search.sh"
        Quickshell.execDetached(["bash", scriptPath, query, root.currentSessionId])
        onlineSearchTimer.restart()
        searchInput.focus = false
        view.forceActiveFocus()
    }

    Timer {
        id: onlineSearchTimer
        interval: 1000
        onTriggered: searchFolderModel.folder = "file://" + homePath + "/.cache/wallpaper_picker/search_thumbs/" + root.currentSessionId
    }

    // --- COLOR LOGIC ---
    function getHue(hexStr) {
        if (!hexStr || hexStr === "" || hexStr === "undefined") return 999 
        var hex = String(hexStr).replace("#", "")
        if (hex.length !== 6) return 999
        var r = parseInt(hex.substring(0,2), 16) / 255, g = parseInt(hex.substring(2,4), 16) / 255, b = parseInt(hex.substring(4,6), 16) / 255
        var max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min, h = 0
        if (max === min) return 998
        if (max === r) h = (g - b) / d + (g < b ? 6 : 0)
        else if (max === g) h = (b - r) / d + 2
        else h = (r - g) / d + 4
        return h * 60
    }

    function getHexBucket(hexStr) {
        if (!hexStr || hexStr === "") return "Monochrome"
        var h = getHue(hexStr)
        if (h >= 998) return "Monochrome"
        if (h >= 345 || h < 15) return "Red"
        if (h >= 15 && h < 45) return "Orange"
        if (h >= 45 && h < 75) return "Yellow"
        if (h >= 75 && h < 165) return "Green"
        if (h >= 165 && h < 260) return "Blue"
        if (h >= 260 && h < 315) return "Purple"
        if (h >= 315 && h < 345) return "Pink"
        return "Monochrome"
    }

    function checkItemMatchesFilter(fileName, filter) {
        if (filter === "Search" || filter === "All") return true
        var fnStr = String(fileName)
        if (filter === "Video") return fnStr.startsWith("000_")
        var hexColor = root.colorMap[fnStr]
        return getHexBucket(hexColor) === filter
    }

    // --- MODELS & REBUILDING ---
    ListModel { id: localProxyModel }
    ListModel { id: searchProxyModel }

    FolderListModel {
        id: markerModel
        folder: root.markerDir
        nameFilters: ["*_HEX_*"]
        onStatusChanged: if (status === FolderListModel.Ready) processMarkers()
        onCountChanged: processMarkers()
    }

    function processMarkers() {
        var newMap = {}
        for (var i = 0; i < markerModel.count; i++) {
            var mName = String(markerModel.get(i, "fileName"))
            var splitIdx = mName.lastIndexOf("_HEX_")
            if (splitIdx !== -1) { newMap[mName.substring(0, splitIdx)] = "#" + mName.substring(splitIdx + 5) }
        }
        root.colorMap = newMap
        root.cacheVersion++
        syncLocalModel()
    }

    FolderListModel {
        id: localFolderModel
        folder: root.thumbDir
        nameFilters: ["*.jpg", "*.png", "*.webp", "*.jpeg", "*.gif"]
        onStatusChanged: if (status === FolderListModel.Ready) syncLocalModel()
        onCountChanged: syncLocalModel()
    }

    function syncLocalModel() {
        if (localFolderModel.status !== FolderListModel.Ready) return
        var items = []
        for (var i = 0; i < localFolderModel.count; i++) {
            var fn = String(localFolderModel.get(i, "fileName"))
            var fu = String(localFolderModel.get(i, "fileUrl"))
            var hex = root.colorMap[fn] || ""
            items.push({ "fileName": fn, "fileUrl": fu, "hex": hex, "hue": getHue(hex) })
        }
        // Rainbow Sort
        items.sort(function(a, b) { return a.hue - b.hue })
        localProxyModel.clear()
        for (var j = 0; j < items.length; j++) { localProxyModel.append(items[j]) }
    }

    FolderListModel {
        id: searchFolderModel
        folder: ""
        nameFilters: ["*.jpg", "*.png", "*.webp", "*.jpeg", "*.gif"]
        onStatusChanged: if (status === FolderListModel.Ready) syncSearchModel()
        onCountChanged: syncSearchModel()
    }

    function syncSearchModel() {
        if (searchFolderModel.status !== FolderListModel.Ready) return
        searchProxyModel.clear()
        for (var i = 0; i < searchFolderModel.count; i++) {
            searchProxyModel.append({ "fileName": String(searchFolderModel.get(i, "fileName")), "fileUrl": String(searchFolderModel.get(i, "fileUrl")), "hex": "", "hue": 999 })
        }
    }

    // --- UI ---
    FloatingWindow {
        id: pickerWindow
        title: "wallpaper-picker"
        implicitWidth: Screen.width
        implicitHeight: 550 * scaleFactor
        color: "transparent"
        visible: true

        Item {
            anchors.fill: parent
            
            ListView {
                id: view
                anchors.fill: parent
                opacity: root.isReady ? 1.0 : 0.0
                anchors.margins: root.isReady ? 0 : (40 * scaleFactor)
                spacing: 0
                orientation: ListView.Horizontal
                interactive: !root.isApplying
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width / 2) - ((root.itemWidth * 1.5 + root.spacing) / 2)
                preferredHighlightEnd: (width / 2) + ((root.itemWidth * 1.5 + root.spacing) / 2)
                highlightMoveDuration: 500
                focus: true
                model: (root.currentFilter === "Search") ? searchProxyModel : localProxyModel
                
                header: Item { width: (view.width / 2) - ((root.itemWidth * 1.5) / 2) }
                footer: Item { width: (view.width / 2) - ((root.itemWidth * 1.5) / 2) }

                delegate: Item {
                    id: delContainer
                    readonly property string safefn: fileName ? String(fileName) : ""
                    readonly property bool isCurrent: ListView.isCurrentItem
                    readonly property bool isMatching: root.checkItemMatchesFilter(safefn, root.currentFilter)
                    
                    width: isMatching ? (isCurrent ? root.itemWidth * 1.5 : root.itemWidth * 0.5) + root.spacing : 0
                    opacity: isMatching ? (isCurrent ? 1.0 : 0.6) : 0.0
                    height: isMatching ? (isCurrent ? root.itemHeight + (30 * scaleFactor) : root.itemHeight) : 0
                    visible: (width > 0.1)
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    anchors.verticalCenterOffset: 15 * scaleFactor
                    z: isCurrent ? 10 : 1
                    
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } } 
                    Behavior on opacity { NumberAnimation { duration: 400 } }

                    Item {
                        anchors.centerIn: parent
                        width: Math.max(0, delContainer.width - root.spacing)
                        height: parent ? parent.height : 0
                        transform: Matrix4x4 { 
                            property real skew: root.skewFactor
                            matrix: Qt.matrix4x4(1, skew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) 
                        }
                        
                        Item {
                            anchors.fill: parent
                            anchors.margins: 4 * scaleFactor
                            clip: true
                            Rectangle { anchors.fill: parent; color: root.crust }

                            Image {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: -50 * scaleFactor
                                width: (parent ? parent.width * 1.4 : 0) + (root.itemHeight * Math.abs(root.skewFactor))
                                height: parent ? parent.height + (10 * scaleFactor) : 0
                                fillMode: Image.PreserveAspectCrop
                                source: fileUrl ? String(fileUrl) : ""
                                asynchronous: true
                                transform: Matrix4x4 { 
                                    property real invSkew: -root.skewFactor
                                    matrix: Qt.matrix4x4(1, invSkew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) 
                                }
                            }

                            MediaPlayer {
                                id: previewPlayer
                                source: (delContainer.isMatching && delContainer.isCurrent && safefn.indexOf("000_") === 0) ? "file://" + root.srcDir + "/" + safefn.substring(4) : ""
                                audioOutput: AudioOutput { muted: true }
                                videoOutput: previewOutput
                                loops: MediaPlayer.Infinite
                            }
                            VideoOutput {
                                id: previewOutput
                                anchors.fill: parent
                                fillMode: VideoOutput.PreserveAspectCrop
                                visible: (previewPlayer.playbackState === MediaPlayer.PlayingState)
                                transform: Matrix4x4 { 
                                    property real invSkew: -root.skewFactor
                                    matrix: Qt.matrix4x4(1, invSkew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) 
                                }
                            }
                        }
                        MouseArea { anchors.fill: parent; enabled: (delContainer.isMatching && !root.isApplying); onClicked: { if (isCurrent) root.applyWallpaper(delContainer.safefn, delContainer.safefn.indexOf("000_") === 0); else view.currentIndex = index } }
                    }
                }
            }

            // Control Panel (Filters + Search)
            Rectangle {
                id: controlPanel
                anchors.top: parent.top
                anchors.topMargin: 30 * scaleFactor
                anchors.horizontalCenter: parent.horizontalCenter
                z: 20
                height: 56 * scaleFactor
                width: filterLayout.width + (24 * scaleFactor)
                radius: 14 * scaleFactor
                color: Qt.rgba(root.mantle.r, root.mantle.g, root.mantle.b, 0.90)
                border.color: Qt.rgba(root.surface2.r, root.surface2.g, root.surface2.b, 0.8)
                border.width: 1

                Row {
                    id: filterLayout
                    anchors.centerIn: parent
                    spacing: 12 * scaleFactor
                    
                    Rectangle {
                        id: notifDrawer
                        height: 44 * scaleFactor
                        width: (root.currentNotification !== "") ? Math.min(notifText.implicitWidth + (40 * scaleFactor), 300 * scaleFactor) : 0
                        radius: 10 * scaleFactor
                        color: Qt.rgba(root.surface2.r, root.surface2.g, root.surface2.b, 0.5)
                        clip: true
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
                        Text { id: notifText; anchors.centerIn: parent; text: root.currentNotification; color: root.text; font.family: "JetBrains Mono"; font.pixelSize: 14 * scaleFactor; font.bold: true }
                    }

                    Repeater {
                        model: [ { name: "All", hex: "" }, { name: "Video", hex: "" }, { name: "Red", hex: "#FF4500" }, { name: "Orange", hex: "#FFA500" }, { name: "Yellow", hex: "#FFD700" }, { name: "Green", hex: "#32CD32" }, { name: "Blue", hex: "#1E90FF" }, { name: "Purple", hex: "#8A2BE2" }, { name: "Pink", hex: "#FF69B4" }, { name: "Monochrome", hex: "#A9A9A9" } ]
                        delegate: Rectangle {
                            width: (modelData.name === "All" || modelData.name === "Video") ? 44 * scaleFactor : 36 * scaleFactor
                            height: 36 * scaleFactor; radius: 10 * scaleFactor; anchors.verticalCenter: parent.verticalCenter
                            color: modelData.hex ? modelData.hex : (root.currentFilter === modelData.name ? root.surface2 : "transparent")
                            border.color: root.currentFilter === modelData.name ? root.text : Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.4)
                            border.width: root.currentFilter === modelData.name ? 2 : 1
                            Text { visible: !modelData.hex; text: modelData.name === "All" ? "All" : (modelData.name === "Video" ? "Vid" : ""); anchors.centerIn: parent; color: root.text; font.pixelSize: 12 * scaleFactor; font.family: "JetBrains Mono" }
                            MouseArea { anchors.fill: parent; onClicked: { root.currentFilter = modelData.name; searchInput.focus = false } }
                        }
                    }

                    // Search Box
                    Rectangle {
                        id: searchBox
                        height: 44 * scaleFactor
                        width: (root.currentFilter === "Search") ? 300 * scaleFactor : 44 * scaleFactor
                        radius: 10 * scaleFactor
                        color: root.currentFilter === "Search" ? Qt.rgba(root.surface2.r, root.surface2.g, root.surface2.b, 0.8) : "transparent"
                        border.color: root.text
                        border.width: root.currentFilter === "Search" ? 2 : 1
                        clip: true
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
                        TextInput { 
                            id: searchInput; anchors.left: parent.left; anchors.leftMargin: 44 * scaleFactor; anchors.right: parent.right; 
                            anchors.verticalCenter: parent.verticalCenter; visible: (root.currentFilter === "Search"); 
                            color: root.text; font.family: "JetBrains Mono"; font.pixelSize: 16 * scaleFactor; 
                            onAccepted: root.triggerOnlineSearch() 
                        }
                        Text { 
                            anchors.centerIn: (root.currentFilter === "Search") ? undefined : parent; 
                            anchors.left: (root.currentFilter === "Search") ? parent.left : undefined; 
                            anchors.leftMargin: 12 * scaleFactor; text: "󰍉"; 
                            font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 20 * scaleFactor; color: root.text 
                        }
                        MouseArea { 
                            anchors.fill: parent; enabled: (root.currentFilter !== "Search"); 
                            onClicked: { root.currentFilter = "Search"; searchInput.forceActiveFocus() } 
                        }
                    }
                }
            }
            
            Shortcut { sequence: "Return"; enabled: (!searchInput.activeFocus); onActivated: { if (view.currentItem) root.applyWallpaper(view.model.get(view.currentIndex).fileName, String(view.model.get(view.currentIndex).fileName).startsWith("000_")) } }
            Shortcut { sequence: "Left"; onActivated: view.decrementCurrentIndex() }
            Shortcut { sequence: "Right"; onActivated: view.incrementCurrentIndex() }
            Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
        }
    }

    function triggerColorExtraction() {
        root.isExtracting = true
        var script = "
            COLOR_DIR=\"$HOME/.cache/wallpaper_picker/colors_markers\"
            THUMBS=\"$HOME/.cache/wallpaper_picker/thumbs\"
            mkdir -p \"$COLOR_DIR\"
            if command -v magick &> /dev/null; then CMD=\"magick\"; else CMD=\"convert\"; fi
            for file in \"$THUMBS\"/*; do
                if [ -f \"$file\" ]; then
                    filename=$(basename \"$file\")
                    if ! ls \"$COLOR_DIR/$filename\"_HEX_* &>/dev/null; then
                        hex=$($CMD \"$file\" -scale 1x1\\! -alpha off -format \"%[hex]\" info: 2>/dev/null | grep -oE '[0-9A-Fa-f]{6}' | head -n 1)
                        if [ -n \"$hex\" ]; then touch \"$COLOR_DIR/$filename\"_HEX_$hex; fi
                    fi
                fi
            done
        "
        Quickshell.execDetached(["bash", "-c", script])
        extractionDoneTimer.restart()
    }
    
    Timer { id: extractionDoneTimer; interval: 3500; onTriggered: { root.isExtracting = false; processMarkers() } }

    Component.onCompleted: {
        processMarkers()
        triggerColorExtraction()
    }
}
