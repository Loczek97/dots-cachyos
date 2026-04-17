//@ pragma UseQApplication
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

PanelWindow {
    id: popupWindow

    property var popupModel
    property real uiScale: 1.0

    property var layoutConfig: {
        "marginTop": 10,
        "marginRight": 10,
        "w": 380,
        "spacing": 10,
        "radius": 16,
        "padding": 16
    }

    WlrLayershell.namespace: "qs-popups"
    WlrLayershell.layer: WlrLayer.Overlay
    
    anchors { top: true; right: true }
    margins { top: 10; right: 10 }

    exclusionMode: ExclusionMode.Ignore
    focusable: false 
    color: "transparent"

    implicitWidth: popupWindow.layoutConfig.w
    implicitHeight: Math.min(popupList.contentHeight, Screen.height * 0.8)

    Behavior on implicitHeight {
        NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
    }

    MatugenTheme { id: _theme }

    ListView {
        id: popupList
        anchors.fill: parent
        model: popupWindow.popupModel
        spacing: popupWindow.layoutConfig.spacing
        interactive: false 
        clip: false 

        delegate: Item {
            id: delegateRoot
            width: ListView.view.width
            height: mainRow.height + (popupWindow.layoutConfig.padding * 2)

            property bool isCritical: model && model.urgency === 2
            
            property color colorPrimary: _theme.primary || "#3498db"
            property color colorRed: _theme.red || "#e74c3c"
            property color colorText: _theme.text || "#ffffff"
            property color colorBase: _theme.base || "#1e1e1e"

            Rectangle {
                id: popupCard
                anchors.fill: parent
                radius: popupWindow.layoutConfig.radius
                color: colorBase
                border.color: isCritical ? colorRed : colorPrimary
                border.width: isCritical ? 2 : 1
                clip: true 

                Timer {
                    interval: isCritical ? 10000 : 6000
                    running: true
                    onTriggered: barWindow.removePopup(model.uid)
                }

                // GŁÓWNA MYSZKA (KLIKNIĘCIE = OTWARCIE APKI)
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (model.notif && typeof model.notif.invokeAction === "function") {
                            model.notif.invokeAction("default")
                        }
                        barWindow.removePopup(model.uid)
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: isCritical ? "white" : _theme.surface0
                        opacity: parent.containsMouse ? 0.15 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                // PRZYCISK ZAMKNIĘCIA
                Rectangle {
                    id: closeButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    width: 24
                    height: 24
                    radius: 12
                    // Subtelny kolor surface1 zamiast jaskrawego czerwonego
                    color: closeMouse.containsMouse ? _theme.surface2 : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    z: 10 

                    Text {
                        anchors.fill: parent
                        text: "󰅖"
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        // Kolor ikony X również bardziej stonowany
                        color: isCritical ? "white" : (closeMouse.containsMouse ? _theme.text : colorText)
                        opacity: closeMouse.containsMouse ? 1.0 : 0.4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            barWindow.removePopup(model.uid)
                        }
                    }
                }

                RowLayout {
                    id: mainRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: popupWindow.layoutConfig.padding
                    anchors.rightMargin: 40 // Miejsce na przycisk zamknięcia
                    spacing: 16

                    // IKONA
                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 12
                        color: _theme.surface0
                        clip: true
                        visible: model.iconPath && model.iconPath !== ""

                        Image {
                            id: iconImage
                            anchors.fill: parent
                            anchors.margins: 6
                            
                            function resolveSource(path, retry) {
                                if (!path) return "";
                                if (path.startsWith("/") || path.startsWith("file://")) return path.startsWith("/") ? "file://" + path : path;
                                let name = path.replace("image://icon/", "").replace("image://desktop-icon/", "");
                                if (retry === 1 && name.includes("battery")) name = "battery-000";
                                return "image://icon/" + name;
                            }

                            source: resolveSource(model.iconPath, 0)
                            sourceSize: Qt.size(64, 64)
                            fillMode: Image.PreserveAspectFit
                            smooth: true

                            onStatusChanged: {
                                if (status === Image.Error && model.iconPath.includes("battery")) {
                                    source = resolveSource(model.iconPath, 1);
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: (model.appName || "?").substring(0, 1).toUpperCase()
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: 20
                            color: isCritical ? colorRed : colorPrimary
                            visible: iconImage.status !== Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: model.appName || "System"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: colorText
                            opacity: 0.6
                        }

                        Text {
                            text: model.summary || ""
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: 15
                            color: isCritical ? colorRed : colorPrimary
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.body || ""
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            color: colorText
                            opacity: 0.85
                            wrapMode: Text.Wrap
                            visible: text !== ""
                            Layout.fillWidth: true
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
