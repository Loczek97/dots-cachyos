import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    
    // --- COLOR MAPPINGS ---
    readonly property color base: theme.base
    readonly property color text: theme.text
    readonly property color subtext1: theme.subtext1
    readonly property color surface2: theme.surface2
    readonly property color surface1: theme.surface1
    readonly property color surface0: theme.surface0
    readonly property color mauve: theme.mauve
    readonly property color primary: theme.primary

    // --- LOGIC ---
    property var allApps: []
    property var filteredResults: []
    property string searchQuery: ""
    property int currentIndex: 0
    property bool isSearching: false

    function runSelected() {
        if (filteredResults.length > 0 && currentIndex >= 0) {
            let item = filteredResults[currentIndex];
            if (item.type === "app") {
                Quickshell.execDetached(["bash", "-c", item.exec]);
            } else if (item.type === "web") {
                Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(searchQuery)]);
            } else if (item.type === "term") {
                Quickshell.execDetached(["kitty", "--hold", "bash", "-c", searchQuery]);
            }
            Qt.quit();
        }
    }

    function filterResults() {
        if (!searchQuery) {
            isSearching = false;
            filteredResults = [];
            currentIndex = 0;
            return;
        }
        
        isSearching = true;

        let results = [];
        let q = searchQuery.toLowerCase();

        let appMatches = allApps.filter(app => 
            app.name.toLowerCase().includes(q)
        ).slice(0, 5).map(app => ({
            "name": app.name,
            "desc": app.exec,
            "icon": app.icon,
            "type": "app",
            "exec": app.exec
        }));
        results = results.concat(appMatches);

        results.push({
            "name": "SZUKAJ W SIECI: " + searchQuery,
            "desc": "Otwórz w przeglądarce",
            "icon": "󰖟",
            "type": "web"
        });

        results.push({
            "name": "URUCHOM KOMENDĘ: " + searchQuery,
            "desc": "Wykonaj w terminalu kitty",
            "icon": "󰆍",
            "type": "term"
        });

        filteredResults = results;
        currentIndex = 0;
    }

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
        property color base: "#1e1e2e"
        property color text: "#cdd6f4"
        property color subtext1: "#bac2de"
        property color surface2: "#585b70"
        property color surface1: "#45475a"
        property color surface0: "#313244"
        property color mauve: "#cba6f7"
        property color primary: "#cba6f7"
    }

    Process {
        id: getAppsProc
        running: true
        command: [Quickshell.env("HOME") + "/.config/quickshell/launcher/get_apps.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        allApps = JSON.parse(this.text);
                        searchInput.forceActiveFocus();
                    } catch (e) {
                        console.error("Apps parse error:", e);
                    }
                }
            }
        }
    }

    PanelWindow {
        id: window
        implicitWidth: 500
        implicitHeight: 488
        visible: true
        color: "transparent"
        focusable: true


        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "launcher"
        
        anchors.top: true
        anchors.left: true
        margins.top: 150
        margins.left: (Screen.width - implicitWidth) / 2
        
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            width: parent.width
            height: mainColumn.height + 24
            color: base
            radius: 20
            border.color: mauve
            border.width: 2
            clip: true
            
            opacity: window.visible ? 1 : 0
            scale: window.visible ? 1 : 0.95

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

            Column {
                id: mainColumn
                width: parent.width - 24
                x: 12
                y: 12
                spacing: 8

                // --- SEARCH BAR ---
                Item {
                    width: parent.width
                    height: 50

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        spacing: 12
                        
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 24
                            color: primary
                        }

                        TextInput {
                            id: searchInput
                            width: parent.width - 60
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            color: "#ffffff"
                            
                            cursorDelegate: Rectangle {
                                width: 1
                                color: "#ffffff"
                            }

                            focus: true
                            selectByMouse: true
                            
                            onTextChanged: {
                                searchQuery = text;
                                filterResults();
                            }

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Down) {
                                    currentIndex = Math.min(currentIndex + 1, filteredResults.length - 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    currentIndex = Math.max(currentIndex - 1, 0);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    runSelected();
                                    event.accepted = true;
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Szukaj..."
                                color: "#bbbbbb"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }
                }

                // --- RESULTS ---
                Item {
                    id: listContainer
                    width: parent.width
                    height: isSearching && filteredResults.length > 0 ? resultsList.contentHeight + 8 : 0
                    clip: true
                    
                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    ListView {
                        id: resultsList
                        width: parent.width
                        height: contentHeight
                        anchors.top: parent.top
                        leftMargin: 4
                        rightMargin: 4
                        bottomMargin: 4

                        model: filteredResults

                        spacing: 4
                        currentIndex: root.currentIndex
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 54
                            radius: 12
                            color: index === root.currentIndex ? surface1 : "transparent"
                            border.color: index === root.currentIndex ? mauve : "transparent"
                            border.width: 1
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                spacing: 15

                                Item {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    Layout.alignment: Qt.AlignVCenter

                                    Image {
                                        anchors.fill: parent
                                        visible: modelData.type === "app"
                                        source: modelData.type === "app" ? "image://icon/" + modelData.icon : ""
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: modelData.type !== "app"
                                        text: modelData.icon
                                        color: index === root.currentIndex ? primary : mauve
                                        font.pixelSize: 22
                                    }
                                }

                                ColumnLayout {
                                    spacing: 1
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.name
                                        color: index === root.currentIndex ? primary : "#ffffff"
                                        font.pixelSize: 15
                                        font.weight: index === root.currentIndex ? Font.Bold : Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.desc
                                        color: index === root.currentIndex ? primary : "#ffffff"
                                        font.pixelSize: 11
                                        font.weight: index === root.currentIndex ? Font.Medium : Font.Normal
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        opacity: index === root.currentIndex ? 1.0 : 0.7
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.currentIndex = index;
                                    runSelected();
                                }
                                hoverEnabled: true
                                onEntered: root.currentIndex = index
                            }
                        }
                    }
                }
            }
        }
    }
}
