import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    readonly property int containerRadius: 30
    readonly property int itemRadius: 12
    
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
        property color base: "#1e1e2e"
        property color text: "#cdd6f4"
        property color subtext0: "#a6adc8"
        property color surface0: "#313244"
        property color primary: "#cba6f7"
        property color peach: "#fab387"
    }

    // --- Wayland Layer Shell Config ---
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher"
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

    color: "#80000000" // Dimmed background overlay

    // --- Logic & State ---
    property string searchQuery: ""
    property var results: []
    property int currentIndex: 0
    property bool showPreview: false

    function close() { Qt.quit(); }
    
    function runSelected(asSudo = false) {
        if (results.length > 0 && currentIndex < results.length) {
            let item = results[currentIndex];
            if (item.path) {
                if (item.type === "app") {
                    let cmd = "grep '^Exec=' '" + item.path + "' | head -1 | cut -d'=' -f2- | sed 's/%[fFuUnNdDeEiIkKmM]//g'";
                    if (asSudo) {
                        Quickshell.execDetached(["kitty", "sudo", "bash", "-c", "$(" + cmd + ")"]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", cmd + " | bash &"]);
                    }
                } else if (item.type === "web") {
                    Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(item.path)]);
                } else if (item.type === "url") {
                    Quickshell.execDetached(["xdg-open", item.path]);
                } else if (item.type === "term") {
                    let cmd = item.path;
                    if (asSudo) cmd = "sudo " + cmd;
                    Quickshell.execDetached(["kitty", "--hold", "sh", "-c", cmd]);
                } else if (item.type === "emoji" || item.type === "calc") {
                    Quickshell.execDetached(["bash", "-c", "echo -n '" + item.path + "' | wl-copy"]);
                } else {
                    if (asSudo) {
                        Quickshell.execDetached(["kitty", "sudo", "xdg-open", item.path]);
                    } else {
                        Quickshell.execDetached(["xdg-open", item.path]);
                    }
                }
                close();
            }
        }
    }

    function copyPath() {
        if (results.length > 0 && currentIndex < results.length) {
            Quickshell.execDetached(["bash", "-c", "echo -n '" + results[currentIndex].path + "' | wl-copy"]);
        }
    }

    function openTerminal() {
        if (results.length > 0 && currentIndex < results.length) {
            let item = results[currentIndex];
            let dir = item.path;
            if (item.type !== "dir") {
                dir = dir.substring(0, dir.lastIndexOf('/'));
            }
            Quickshell.execDetached(["kitty", "--directory", dir]);
            close();
        }
    }

    // --- Search Process ---
    Process {
        id: searchProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/launcher/search.sh", searchQuery]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        results = JSON.parse(this.text);
                        currentIndex = 0;
                    } catch (e) { results = []; }
                } else {
                    results = [];
                }
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: 150
        onTriggered: searchProc.running = true
    }

    onSearchQueryChanged: {
        searchProc.running = false;
        debounceTimer.restart();
    }

    // --- UI Layout ---
    Rectangle {
        id: mainContainer
        width: 700
        
        height: {
            if (results.length === 0) return 80;
            let targetHeight = 80 + (results.length * 50) + 20;
            return Math.min(targetHeight, 550);
        }
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height / 5
        
        radius: containerRadius
        color: root.theme.base
        border.color: root.theme.surface0
        border.width: 1
        clip: true

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }

        Item {
            anchors.fill: parent
            anchors.margins: 10

            RowLayout {
                id: searchBarRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 60
                spacing: 15

                Text {
                    text: ""
                    font.pixelSize: 24
                    color: root.theme.primary
                    leftPadding: 10
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.pixelSize: 22
                    font.family: "CaskaydiaCoveNerdFont-Regular"
                    font.weight: Font.Medium
                    color: root.theme.text
                    focus: true
                    verticalAlignment: TextInput.AlignVCenter
                    
                    onTextChanged: root.searchQuery = text

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) root.close();
                        if (event.key === Qt.Key_Down) root.currentIndex = Math.min(root.results.length - 1, root.currentIndex + 1);
                        if (event.key === Qt.Key_Up) root.currentIndex = Math.max(0, root.currentIndex - 1);
                        
                        if (event.key === Qt.Key_Return) {
                            if (event.modifiers & Qt.ControlModifier && event.modifiers & Qt.ShiftModifier) {
                                root.runSelected(true);
                            } else if (event.modifiers & Qt.ControlModifier) {
                                root.openTerminal();
                            } else {
                                root.runSelected(false);
                            }
                        }
                        
                        if (event.key === Qt.Key_Space && event.modifiers === Qt.NoModifier) root.showPreview = !root.showPreview;
                        if (event.key === Qt.Key_C && event.modifiers & Qt.ControlModifier) root.copyPath();
                    }
                }
            }

            RowLayout {
                id: resultsArea
                anchors.top: searchBarRow.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 10
                visible: results.length > 0
                spacing: 15

                ListView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: results
                    clip: true
                    currentIndex: root.currentIndex

                    delegate: Rectangle {
                        width: resultsList.width
                        height: 50
                        radius: itemRadius
                        color: index === root.currentIndex ? root.theme.surface0 : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 15

                            Loader {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                sourceComponent: {
                                    if (modelData.type === "emoji") return emojiIcon;
                                    if (modelData.icon && (modelData.type === "app" || modelData.type === "web" || modelData.type === "term" || modelData.type === "calc")) return appIcon;
                                    return fontIcon;
                                }

                                Component {
                                    id: emojiIcon
                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 24
                                        anchors.centerIn: parent
                                    }
                                }

                                Component {
                                    id: appIcon
                                    Image {
                                        source: modelData.icon.startsWith("/") ? "file://" + modelData.icon : "image://icon/" + modelData.icon
                                        width: 32
                                        height: 32
                                        fillMode: Image.PreserveAspectFit
                                    }
                                }

                                Component {
                                    id: fontIcon
                                    Text {
                                        text: {
                                            if (modelData.type === "content") return "󰈙";
                                            if (modelData.mime && modelData.mime.startsWith("image/")) return "󰋩";
                                            if (modelData.mime && modelData.mime.startsWith("video/")) return "󰈫";
                                            return "󰈔";
                                        }
                                        color: index === root.currentIndex ? root.theme.primary : root.theme.subtext0
                                        font.pixelSize: 22
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Text { 
                                    text: modelData.name; 
                                    color: root.theme.text; 
                                    font.pixelSize: 16; 
                                    elide: Text.ElideRight 
                                }
                                Text { 
                                    text: modelData.path; 
                                    color: root.theme.subtext0; 
                                    font.pixelSize: 10; 
                                    elide: Text.ElideRight;
                                    visible: index === root.currentIndex
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: searchInput.forceActiveFocus()
}
