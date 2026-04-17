import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

PanelWindow {
    id: centerWindow

    property var notifModel
    property bool isVisible: false

    // Szerokość panelu
    property int panelWidth: 400

    WlrLayershell.namespace: "qs-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    
    // Zmienione na LEWĄ stronę
    anchors {
        top: true
        bottom: true
        left: true
    }
    
    width: panelWidth + 20
    color: "transparent"

    // Ukrywamy okno, gdy kontener jest poza lewą krawędzią
    visible: mainContainer.x + mainContainer.width > 0
    
    MatugenTheme { id: _theme }

    Rectangle {
        id: mainContainer
        width: panelWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 10
        anchors.leftMargin: 10 // Margines od lewej krawędzi
        radius: 20
        color: _theme.base
        border.color: _theme.surface1
        border.width: 1

        // Logika wysuwania z LEWEJ strony
        x: isVisible ? 10 : -panelWidth - 20 
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // NAGŁÓWEK
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Powiadomienia"
                    font.family: "JetBrains Mono"
                    font.weight: Font.Black
                    font.pixelSize: 22
                    color: _theme.primary
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 80
                    height: 30
                    radius: 8
                    color: clearMouse.containsMouse ? _theme.surface2 : _theme.surface1
                    visible: centerWindow.notifModel.count > 0

                    Text {
                        anchors.centerIn: parent
                        text: "Wyczyść"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        color: _theme.text
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: centerWindow.notifModel.clear()
                    }
                }
            }

            // LISTA POWIADOMIEŃ
            ListView {
                id: notifList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: centerWindow.notifModel
                spacing: 10
                clip: true
                
                Text {
                    anchors.centerIn: parent
                    text: "Brak nowych powiadomień"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: _theme.overlay1
                    visible: notifList.count === 0
                }

                delegate: Item {
                    width: notifList.width
                    height: delegateCard.height

                    property bool isCritical: model.urgency === 2

                    Rectangle {
                        id: delegateCard
                        width: parent.width
                        height: innerRow.height + 24
                        radius: 12
                        color: _theme.surface0
                        border.color: isCritical ? _theme.red : _theme.surface1
                        border.width: isCritical ? 1 : 0

                        RowLayout {
                            id: innerRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 8
                                color: _theme.base
                                
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    source: {
                                        let p = model.iconPath || "";
                                        if (p === "") return "";
                                        if (p.startsWith("image://") || p.startsWith("file://") || p.startsWith("/")) return p;
                                        return "image://icon/" + p;
                                    }
                                    fillMode: Image.PreserveAspectFit
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                
                                Text {
                                    text: model.summary || ""
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 14
                                    color: isCritical ? _theme.red : _theme.primary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    text: model.body || ""
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 12
                                    color: _theme.subtext1
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                hoverEnabled: true
                                onClicked: centerWindow.notifModel.remove(index)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: "CaskaydiaCove Nerd Font"
                                    font.pixelSize: 14
                                    color: parent.containsMouse ? _theme.red : _theme.overlay1
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 30
                            onClicked: {
                                if (model.notif && typeof model.notif.invokeAction === "function") {
                                    model.notif.invokeAction("default")
                                }
                                centerWindow.notifModel.remove(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
