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
    property string homeDir: ""
    property string homePath: ""
    property int wallpaperIndex: 0
    readonly property string thumbDir: homeDir + "/.cache/wallpaper_picker/thumbs"
    property string srcDir: homePath.length > 0 ? homePath + "/.config/backgrounds" : ""
    property string backgroundsDir: homePath.length > 0 ? "file://" + homePath + "/.cache/wallpaper_picker/thumbs" : ""

    // Get HOME directory using Process
    Process {
        id: homeDirProcess
        command: ["sh", "-c", "echo -n $HOME"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var path = this.text.trim()
                window.homePath = path
                window.homeDir = "file://" + path
            }
        }
    }
    
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

    // AWWW Command Template
    readonly property string awwwCommand: "awww img '%1' --transition-type %2 --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1"
    
    // Symlink command to save current wallpaper
    readonly property string symlinkCommand: "ln -sf '%1' ~/.config/current_bg"
    
    // MPVPAPER Command Template (OPTIMIZED)
    // -l auto: Fixes layer issues
    // --hwdec=auto: Forces GPU usage (Fixes lag)
    // --no-audio: Prevents audio processing (Saves CPU)
    property string mpvCommand: ""
    
    onHomePathChanged: {
        mpvCommand = "pkill mpvpaper; mpvpaper -o 'loop --hwdec=auto --no-audio' '*' '%1'"
    }
    
    // List of available awww transitions to randomize from
    readonly property var transitions: ["grow", "outer", "any", "wipe", "wave", "pixel", "center"]

    readonly property int itemWidth: 300
    readonly property int itemHeight: 420
    readonly property int borderWidth: 3
    readonly property int spacing: 0 
    readonly property real skewFactor: -0.35

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }

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
        preferredHighlightBegin: (width / 2) - (window.itemWidth / 2)
        preferredHighlightEnd: (width / 2) + (window.itemWidth / 2)
        
        // --- SPEED SETTINGS ---
        highlightMoveDuration: 300

        focus: true

        // --- NEW: Snap to active wallpaper on load ---
        property bool initialFocusSet: false
        onCountChanged: {
            if (!initialFocusSet && count > 0) {
                var idx = window.wallpaperIndex
                // Only jump if the index exists in the current count
                if (count > idx) {
                    currentIndex = idx
                    positionViewAtIndex(idx, ListView.Center)
                    initialFocusSet = true
                }
            }
        }

        model: FolderListModel {
            id: folderModel
            folder: window.backgroundsDir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
            showDirs: false
            sortField: FolderListModel.Name
            
            // Debug: log when folder changes
            Component.onCompleted: console.log("FolderListModel folder:", folder)
            onFolderChanged: console.log("Folder changed to:", folder)
        }

        Keys.onReturnPressed: {
            if (currentItem) currentItem.pickWallpaper()
        }

        delegate: Item {
            id: delegateRoot
            width: window.itemWidth
            height: window.itemHeight
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool isVideo: fileName.startsWith("000_")

            z: isCurrent ? 10 : 1

            function pickWallpaper() {
                const originalFileName = fileName.startsWith("000_") ? fileName.substring(4).replace(/\.[^/.]+$/, "") : fileName
                const originalFile = window.srcDir + "/" + originalFileName
                
                // Create symlink to current wallpaper
                const symlinkCmd = window.symlinkCommand.arg(originalFile)
                Quickshell.execDetached(["bash", "-c", symlinkCmd])
                
                if (isVideo) {
                     const finalCmd = window.mpvCommand.arg(originalFile)
                     Quickshell.execDetached(["bash", "-c", finalCmd])
                } else {
                     // Generate color palette with matugen for images
                     
                     const randomTransition = window.transitions[Math.floor(Math.random() * window.transitions.length)]
                     const finalCmd = window.awwwCommand.arg(originalFile).arg(randomTransition)
                     Quickshell.execDetached(["bash", "-c", "pkill mpvpaper; " + finalCmd])

                     const matugenCmd = ["matugen", "image", originalFile, "--mode", "dark", "--source-color-index", "0"]
                     Quickshell.execDetached(["bash", "-c", matugenCmd.join(" ")]);
                }
                
                Qt.quit()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    view.currentIndex = index
                    delegateRoot.pickWallpaper()
                }
            }

            // PARALLELOGRAM CONTAINER
            Item {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height

                scale: delegateRoot.isCurrent ? 1.15 : 0.95
                opacity: delegateRoot.isCurrent ? 1.0 : 0.6

                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 500 } }

                transform: Matrix4x4 {
                    property real s: window.skewFactor
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                // 1. DYNAMIC BORDER (Background Layer)
                Image {
                    anchors.fill: parent
                    source: fileUrl
                    sourceSize: Qt.size(1, 1)
                    fillMode: Image.Stretch
                    visible: true 
                }

                // 2. THE IMAGE (Inset Layer)
                Item {
                    anchors.fill: parent
                    anchors.margins: window.borderWidth 
                    
                    Rectangle { anchors.fill: parent; color: "black" }
                    clip: true

                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -35 
                        
                        width: parent.width + (parent.height * Math.abs(window.skewFactor)) + 50
                        height: parent.height
                        
                        fillMode: Image.PreserveAspectCrop
                        source: fileUrl

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    
                    // 3. VIDEO INDICATOR (Top Right, Subtle)
                    Rectangle {
                        visible: delegateRoot.isVideo
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        
                        width: 32
                        height: 32
                        radius: 6
                        color: "#60000000" // Subtle semi-transparent black
                        
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
