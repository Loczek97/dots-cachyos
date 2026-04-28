import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property QtObject theme: themeLoader.item ? themeLoader.item : dummyTheme
    
    // --- COLOR MAPPINGS ---
    readonly property color base: theme.base
    readonly property color mantle: theme.mantle
    readonly property color crust: theme.crust
    readonly property color text: theme.text
    readonly property color subtext1: theme.subtext1
    readonly property color subtext0: theme.subtext0
    readonly property color surface2: theme.surface2
    readonly property color surface1: theme.surface1
    readonly property color surface0: theme.surface0
    readonly property color mauve: theme.mauve
    readonly property color sapphire: theme.sapphire
    readonly property color blue: theme.blue
    readonly property color red: theme.red

    // --- ANIMATIONS ---
    property real introState: 0
    property real globalOrbitAngle: 0

    // --- SCALING HELPER ---
    function s(val) {
        return val * (Quickshell.screens[0].width / 1920);
    }

    // --- LOGIC ---
    property var mimeModel: []
    property string searchQuery: ""
    property bool appPopupVisible: false
    property bool addMimePopupVisible: false

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.appPopupVisible) {
                root.appPopupVisible = false;
            } else if (root.addMimePopupVisible) {
                root.addMimePopupVisible = false;
            } else {
                Qt.quit();
            }
        }
    }

    Component.onCompleted: {
        introState = 1;
        listMimesProc.running = true;
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
        property color mantle: "#181825"
        property color crust: "#11111b"
        property color text: "#cdd6f4"
        property color subtext1: "#bac2de"
        property color subtext0: "#a6adc8"
        property color surface2: "#585b70"
        property color surface1: "#45475a"
        property color surface0: "#313244"
        property color mauve: "#cba6f7"
        property color sapphire: "#74c7ec"
        property color blue: "#89b4fa"
        property color red: "#f38ba8"
    }

    Process {
        id: listMimesProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/mimemanager/mimemanager.sh", "list_mimes"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        root.mimeModel = JSON.parse(this.text);
                    } catch (e) {
                        console.error("JSON parse error:", e);
                    }
                }
            }
        }
    }

    Behavior on introState {
        NumberAnimation {
            duration: 1200
            easing.type: Easing.OutExpo
        }
    }

    NumberAnimation on globalOrbitAngle {
        from: 0
        to: Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }

    FloatingWindow {
        id: window
        title: "mimemanager_win"
        implicitWidth: 1050
        implicitHeight: 750
        visible: true
        color: "transparent"

        Item {
            anchors.fill: parent
            scale: 0.9 + (0.1 * root.introState)
            opacity: root.introState

            Rectangle {
                anchors.fill: parent
                color: root.base
                radius: 35
                border.color: root.surface0
                border.width: 1
                clip: true

                // --- BACKGROUND BLOBS ---
                Rectangle {
                    width: parent.width * 0.8
                    height: width
                    radius: width / 2
                    x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * root.s(150)
                    y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * root.s(100)
                    opacity: 0.08
                    color: root.mauve
                }

                Rectangle {
                    width: parent.width * 0.9
                    height: width
                    radius: width / 2
                    x: (parent.width / 2 - width / 2) + Math.sin(root.globalOrbitAngle * 1.5) * root.s(-150)
                    y: (parent.height / 2 - height / 2) + Math.cos(root.globalOrbitAngle * 1.5) * root.s(-100)
                    opacity: 0.06
                    color: Qt.lighter(root.mauve, 1.3)
                }

                // --- MAIN CONTENT ---
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40
                    spacing: 25

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Domyślne aplikacje"
                            font.pixelSize: 32
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            color: root.mauve
                        }
                        Item { Layout.fillWidth: true }
                    }

                    // --- SEARCH BAR ---
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 55
                        color: root.surface0
                        radius: 15
                        border.color: root.surface1
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 15

                            Text {
                                text: "󰍉"
                                font.family: "CaskaydiaCoveNerdFont-Regular"
                                font.pixelSize: 22
                                color: root.mauve
                            }

                            TextField {
                                id: searchInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: "Szukaj typów plików..."
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: root.text
                                placeholderTextColor: root.subtext0
                                onTextChanged: root.searchQuery = text.toLowerCase()
                                background: Item {}
                            }

                            // Add New Button
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 10
                                color: addMouse.containsMouse ? root.surface1 : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐕"
                                    font.family: "CaskaydiaCoveNerdFont-Regular"
                                    font.pixelSize: 24
                                    color: root.mauve
                                }
                                MouseArea {
                                    id: addMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.addMimePopupVisible = true
                                }
                            }
                        }
                    }

                    // --- LIST ---
                    ListView {
                        id: mimeList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.mimeModel.filter(item => item.mime.toLowerCase().includes(root.searchQuery))
                        spacing: 12
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 80
                            color: ma.containsMouse ? root.surface1 : root.surface0
                            radius: 15
                            border.color: ma.containsMouse ? root.surface2 : "transparent"
                            border.width: 1

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 25
                                anchors.rightMargin: 25
                                spacing: 20
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.mime
                                        color: root.text
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Domyślna: " + (modelData.default || "Brak")
                                        color: root.subtext1
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                Button {
                                    text: "Zmień"
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 30
                                    onClicked: appModal.openFor(modelData.mime)
                                    background: Rectangle {
                                        color: parent.hovered ? root.mauve : root.surface2
                                        radius: 10
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.hovered ? root.base : root.text
                                        font.pixelSize: 12
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- OVERLAY & MODALS ---
            Rectangle {
                id: overlay
                anchors.fill: parent
                visible: root.appPopupVisible || root.addMimePopupVisible
                opacity: visible ? 1 : 0
                color: "#90000000"
                radius: 35
                z: 100

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.appPopupVisible = false;
                        root.addMimePopupVisible = false;
                    }
                }

                // --- ADD MIME MODAL ---
                Rectangle {
                    id: addMimeModal
                    width: 550
                    height: 350
                    anchors.centerIn: parent
                    color: root.mantle
                    radius: 30
                    border.color: root.surface1
                    border.width: 2
                    scale: root.addMimePopupVisible ? 1 : 0.9
                    opacity: root.addMimePopupVisible ? 1 : 0
                    visible: opacity > 0

                    Behavior on scale {
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 35
                        spacing: 25

                        Text {
                            text: "Dodaj nowy wpis"
                            color: root.mauve
                            font.pixelSize: 24
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                        }

                        Text {
                            text: "Wprowadź typ MIME, dla którego chcesz ustawić domyślną aplikację."
                            color: root.subtext0
                            font.pixelSize: 14
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 55
                            color: root.surface0
                            radius: 14
                            border.color: root.surface2
                            border.width: 1

                            TextField {
                                id: newMimeInput
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                placeholderText: "np. text/html lub application/pdf"
                                color: root.text
                                font.pixelSize: 16
                                placeholderTextColor: root.subtext0
                                background: Item {}
                                focus: root.addMimePopupVisible
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 55
                            text: "Wybierz aplikację"
                            onClicked: {
                                if (newMimeInput.text.includes("/")) {
                                    let mime = newMimeInput.text.trim();
                                    root.addMimePopupVisible = false;
                                    appModal.openFor(mime);
                                    newMimeInput.text = "";
                                }
                            }
                            background: Rectangle {
                                color: parent.hovered ? root.mauve : "transparent"
                                radius: 14
                                border.color: root.mauve
                                border.width: 2
                            }
                            contentItem: Text {
                                text: parent.text
                                color: parent.hovered ? root.base : root.mauve
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // --- APP SELECTION MODAL ---
                Rectangle {
                    id: appModal
                    width: 550
                    height: 650
                    anchors.centerIn: parent
                    color: root.mantle
                    radius: 30
                    border.color: root.surface1
                    border.width: 2
                    scale: root.appPopupVisible ? 1 : 0.9
                    opacity: root.appPopupVisible ? 1 : 0
                    visible: opacity > 0

                    Behavior on scale {
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    property string currentMime: ""
                    property var apps: []
                    property string appSearchQuery: ""

                    function openFor(mime) {
                        currentMime = mime;
                        appSearchQuery = "";
                        appSearchInput.text = "";
                        apps = [];
                        listAppsProc.command = [Quickshell.env("HOME") + "/.config/quickshell/mimemanager/mimemanager.sh", "list_apps", mime];
                        listAppsProc.running = true;
                        root.appPopupVisible = true;
                    }

                    Process {
                        id: listAppsProc
                        stdout: StdioCollector {
                            onStreamFinished: {
                                if (this.text) {
                                    try {
                                        appModal.apps = JSON.parse(this.text);
                                    } catch (e) {
                                        console.error("Apps parse error:", e);
                                    }
                                }
                            }
                        }
                    }

                    Process {
                        id: setAppProc
                        onExited: listMimesProc.running = true
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 35
                        spacing: 20

                        ColumnLayout {
                            spacing: 5
                            Text {
                                text: "Wybierz aplikację dla:"
                                color: root.subtext1
                                font.pixelSize: 14
                            }
                            Text {
                                text: appModal.currentMime
                                color: root.mauve
                                font.pixelSize: 20
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        // App Search Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: root.surface0
                            radius: 12
                            border.color: root.surface1
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 15
                                anchors.rightMargin: 15
                                spacing: 10

                                Text {
                                    text: "󰍉"
                                    font.family: "CaskaydiaCoveNerdFont-Regular"
                                    font.pixelSize: 18
                                    color: root.mauve
                                }

                                TextField {
                                    id: appSearchInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    placeholderText: "Szukaj aplikacji..."
                                    color: root.text
                                    font.pixelSize: 14
                                    placeholderTextColor: root.subtext0
                                    background: Item {}
                                    onTextChanged: appModal.appSearchQuery = text.toLowerCase()
                                }
                            }
                        }

                        ListView {
                            id: appList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: appModal.apps.filter(app => 
                                app.name.toLowerCase().includes(appModal.appSearchQuery) || 
                                app.id.toLowerCase().includes(appModal.appSearchQuery)
                            )
                            clip: true
                            spacing: 8
                            
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 60
                                color: appMa.containsMouse ? root.surface1 : root.surface0
                                radius: 12
                                border.color: appMa.containsMouse ? root.mauve : "transparent"
                                border.width: 1
                                
                                MouseArea {
                                    id: appMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        setAppProc.command = [Quickshell.env("HOME") + "/.config/quickshell/mimemanager/mimemanager.sh", "set", appModal.currentMime, modelData.id];
                                        setAppProc.running = true;
                                        root.appPopupVisible = false;
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 15

                                    Image {
                                        source: modelData.icon ? "image://icon/" + modelData.icon : ""
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        fillMode: Image.PreserveAspectFit
                                        visible: source != ""
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.name
                                            color: root.text
                                            font.pixelSize: 15
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                        Text {
                                            text: modelData.id
                                            color: root.subtext0
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            text: "Resetuj do domyślnych"
                            onClicked: {
                                setAppProc.command = [Quickshell.env("HOME") + "/.config/quickshell/mimemanager/mimemanager.sh", "reset", appModal.currentMime];
                                setAppProc.running = true;
                                root.appPopupVisible = false;
                            }
                            background: Rectangle {
                                color: parent.hovered ? root.red : "transparent"
                                radius: 12
                                border.color: root.red
                                border.width: 2
                            }
                            contentItem: Text {
                                text: parent.text
                                color: parent.hovered ? root.base : root.red
                                font.pixelSize: 15
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
