import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: centerWindow

    property var notifModel
    property bool isVisible: false
    property int panelWidth: 400
    property QtObject _theme: themeLoader.item ? themeLoader.item : dummyTheme

    WlrLayershell.namespace: "qs-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    width: panelWidth + 20
    color: "transparent"
    visible: mainContainer.x + mainContainer.width > 0

    anchors {
        top: true
        bottom: true
        left: true
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

        property color base: "#000000"
        property color mantle: "#000000"
        property color crust: "#000000"
        property color surface0: "#000000"
        property color surface1: "#000000"
        property color surface2: "#000000"
        property color overlay0: "#000000"
        property color overlay1: "#000000"
        property color overlay2: "#000000"
        property color text: "#000000"
        property color subtext1: "#000000"
        property color subtext0: "#000000"
        property color primary: "#000000"
        property color secondary: "#000000"
        property color tertiary: "#000000"
        property color mauve: "#000000"
        property color pink: "#000000"
        property color blue: "#000000"
        property color sapphire: "#000000"
        property color peach: "#000000"
        property color yellow: "#000000"
        property color teal: "#000000"
        property color green: "#000000"
        property color red: "#000000"
        property color maroon: "#000000"
    }

    Rectangle {
        id: mainContainer

        width: panelWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 10
        anchors.leftMargin: 10
        radius: 20
        color: _theme.base
        border.color: _theme.surface1
        border.width: 1
        x: isVisible ? 10 : -panelWidth - 20

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

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
                    property bool isCritical: model.urgency === 2

                    width: notifList.width
                    height: delegateCard.height

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
                                        if (p === "")
                                            return "";

                                        if (p.startsWith("image://") || p.startsWith("file://") || p.startsWith("/"))
                                            return p;

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
                                if (model.notif && typeof model.notif.invokeAction === "function")
                                    model.notif.invokeAction("default");

                                centerWindow.notifModel.remove(index);
                            }
                        }

                    }

                }

            }

        }

        Behavior on x {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuint
            }

        }

    }

}
