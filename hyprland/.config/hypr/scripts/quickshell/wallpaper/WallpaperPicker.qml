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
    readonly property string srcDir: homePath + "/.config/backgrounds"
    readonly property string backgroundsDir: homeDir + "/.config/backgrounds"

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
    
    // Generate thumbnails on startup (only missing ones)
    Process {
        id: thumbGenerator
        running: window.homePath !== ""
        command: ["bash", "-c", 
            "HOMEPATH='" + window.homePath + "'; " +
            "THUMBDIR=\"$HOMEPATH/.cache/wallpaper_picker/thumbs\"; " +
            "BGDIR=\"$HOMEPATH/.config/backgrounds\"; " +
            "mkdir -p \"$THUMBDIR\"; " +
            "cd \"$BGDIR\" 2>/dev/null || exit 0; " +
            "for file in *.jpg *.jpeg *.png *.webp *.gif *.mp4 *.mkv *.mov *.webm; do " +
            "  [ -f \"$file\" ] || continue; " +
            "  thumb=\"$THUMBDIR/${file}.jpg\"; " +
            "  [ -f \"$thumb\" ] && continue; " +
            "  case \"$file\" in " +
            "    *.mp4|*.mkv|*.mov|*.webm) " +
            "      ffmpeg -ss 00:00:01 -i \"$file\" -vf 'scale=200:-1' -q:v 5 \"$thumb\" 2>/dev/null & " +
            "      ;; " +
            "    *) " +
            "      magick \"$file\" -resize 200x -quality 70 \"$thumb\" 2>/dev/null & " +
            "      ;; " +
            "  esac; " +
            "done; " +
            "wait"
        ]
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
        mpvCommand = "pkill mpvpaper; mpvpaper -o 'loop --hwdec=auto --no-audio' '*' '%1' & sleep 0.5; " + homePath + "/.config/eww/bar/launch_bar.sh --force-open"
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
            readonly property bool isVideo: {
                var ext = fileName.toLowerCase()
                return ext.endsWith(".mp4") || ext.endsWith(".mkv") || 
                       ext.endsWith(".mov") || ext.endsWith(".webm")
            }
            readonly property string thumbUrl: window.thumbDir + "/" + fileName + ".jpg"

            z: isCurrent ? 10 : 1

            function pickWallpaper() {
                const originalFile = window.srcDir + "/" + fileName
                
                // Create symlink to current wallpaper
                const symlinkCmd = window.symlinkCommand.arg(originalFile)
                Quickshell.execDetached(["bash", "-c", symlinkCmd])
                
                if (isVideo) {
                     const finalCmd = window.mpvCommand.arg(originalFile)
                     Quickshell.execDetached(["bash", "-c", finalCmd])
                } else {
                     // Generate color palette with matugen for images
                     const matugenCmd = "matugen image '" + originalFile + "' --mode dark"
                     Quickshell.execDetached(["bash", "-c", matugenCmd])
                     
                     const randomTransition = window.transitions[Math.floor(Math.random() * window.transitions.length)]
                     const finalCmd = window.awwwCommand.arg(originalFile).arg(randomTransition)
                     Quickshell.execDetached(["bash", "-c", "pkill mpvpaper; " + finalCmd])
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
                    source: delegateRoot.thumbUrl
                    asynchronous: true
                    sourceSize: Qt.size(200, 200)
                    fillMode: Image.Stretch
                    cache: true
                    smooth: false
                    
                    // Fallback to original if thumb doesn't exist
                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = fileUrl
                            sourceSize = Qt.size(300, 300)
                        }
                    }
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
                        source: delegateRoot.thumbUrl
                        asynchronous: true
                        sourceSize: Qt.size(200, 200)
                        cache: true
                        smooth: false
                        
                        // Fallback to original if thumb doesn't exist
                        onStatusChanged: {
                            if (status === Image.Error) {
                                source = fileUrl
                                sourceSize = Qt.size(300, 300)
                            }
                        }

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
