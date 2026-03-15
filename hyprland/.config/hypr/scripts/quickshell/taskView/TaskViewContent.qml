import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "." as Local

Rectangle {
    id: root

    property var hyprlandClients: []

    onHyprlandClientsChanged: {
        console.log("TaskViewContent.hyprlandClients changed, length:", hyprlandClients.length);
    }

    color: Qt.rgba(0.05, 0.08, 0.06, 0.82 * openProgress)

    property real openProgress: 0
    signal closed

    Component.onCompleted: {
        openAnim.start();
    }
    function close() {
        closeAnim.start();
    }

    PropertyAnimation {
        id: openAnim
        target: root
        property: "openProgress"
        to: 1
        duration: 280
        easing.type: Easing.OutCubic
    }
    SequentialAnimation {
        id: closeAnim
        PropertyAnimation {
            target: root
            property: "openProgress"
            to: 0
            duration: 200
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: root.closed()
        }
    }

    MouseArea {
        z: 0
        anchors.fill: parent
        onClicked: root.close()
    }

    // --- Workspace count from client list ---
    readonly property int maxOccupiedWs: {
        let max = 1;
        for (let i = 0; i < root.hyprlandClients.length; i++) {
            const id = root.hyprlandClients[i]?.workspace?.id ?? 0;
            if (id > max) max = id;
        }
        return max;
    }
    readonly property int wsCount: Math.max(maxOccupiedWs, 8)
    readonly property int wsColumns: wsCount <= 5 ? wsCount : Math.ceil(wsCount / 2)

    // --- Workspace grid ---
    Item {
        id: gridContainer
        anchors {
            fill: parent
            margins: 52
        }
        opacity: root.openProgress
        scale: 0.92 + 0.08 * root.openProgress
        transformOrigin: Item.Center

        readonly property real tileWidth: (width - (root.wsColumns - 1) * 14) / root.wsColumns
        readonly property real tileHeight: tileWidth * 9.0 / 16.0

        Grid {
            anchors.centerIn: parent
            columns: root.wsColumns
            spacing: 8

            Repeater {
                model: root.wsCount
                delegate: TaskViewWorkspace {
                    id: workspaceItem
                    required property int index
                    workspace: index + 1
                    hyprlandClients: root.hyprlandClients
                    width: gridContainer.tileWidth
                    height: gridContainer.tileHeight

                    onClicked: {
                        Hyprland.dispatch(`workspace ${workspaceItem.workspace}`);
                        root.close();
                    }
                }
            }
        }
    }
}
