import "../"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: popupWindow

    property var popupModel
    property real uiScale: 1
    property var layoutConfig: {
        "marginTop": 10,
        "marginRight": 10,
        "w": 350,
        "spacing": 10,
        "radius": 12,
        "padding": 15
    }
    property bool dndEnabled: false

    WlrLayershell.namespace: "qs-popups"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"
    width: popupWindow.layoutConfig.w
    height: Math.min(popupList.contentHeight, Screen.height * 0.8)

    anchors {
        top: true
        right: true
    }

    margins {
        top: popupWindow.layoutConfig.marginTop
        right: popupWindow.layoutConfig.marginRight
    }

    Item {
        id: contentWrapper

        anchors.fill: parent
        opacity: popupWindow.dndEnabled ? 0 : 1
        visible: opacity > 0.01

        MatugenTheme {
            id: _theme
        }

        ListView {
            id: popupList

            anchors.fill: parent
            model: popupWindow.popupModel
            spacing: popupWindow.layoutConfig.spacing
            interactive: false
            clip: false

            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 400
                        easing.type: Easing.OutQuint
                    }

                    NumberAnimation {
                        property: "x"
                        from: popupWindow.width * 0.4
                        to: 0
                        duration: 500
                        easing.type: Easing.OutQuint
                    }

                    NumberAnimation {
                        property: "scale"
                        from: 0.9
                        to: 1
                        duration: 500
                        easing.type: Easing.OutQuint
                    }

                }

            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: 350
                        easing.type: Easing.OutQuint
                    }

                    NumberAnimation {
                        property: "x"
                        to: popupWindow.width * 0.4
                        duration: 400
                        easing.type: Easing.OutQuint
                    }

                    NumberAnimation {
                        property: "scale"
                        to: 0.9
                        duration: 400
                        easing.type: Easing.OutQuint
                    }

                }

            }

            delegate: Item {
                id: delegateRoot

                width: ListView.view.width
                height: contentCol.height + (popupWindow.layoutConfig.padding * 2)

                Rectangle {
                    id: popupCard

                    anchors.fill: parent
                    radius: popupWindow.layoutConfig.radius
                    color: _theme.base
                    border.color: _theme.surface1
                    border.width: 1
                    clip: true

                    Timer {
                        interval: 5000
                        running: true
                        onTriggered: {
                            if (typeof popupWindow.parent.removePopup === "function")
                                popupWindow.parent.removePopup(model.uid);

                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.notif && typeof model.notif.invokeAction === "function")
                                model.notif.invokeAction("default");

                            if (model.notif && typeof model.notif.close === "function")
                                model.notif.close();

                            if (typeof popupWindow.parent.removePopup === "function")
                                popupWindow.parent.removePopup(model.uid);

                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: _theme.surface0
                            opacity: parent.containsMouse ? 0.3 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 250
                                }

                            }

                        }

                    }

                    ColumnLayout {
                        id: contentCol

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: popupWindow.layoutConfig.padding
                        spacing: 6 * popupWindow.uiScale

                        Text {
                            text: model.appName || "System"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            font.pixelSize: 12 * popupWindow.uiScale
                            color: _theme.overlay1
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.summary || ""
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 15 * popupWindow.uiScale
                            color: _theme.text
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.body || ""
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            font.pixelSize: 13 * popupWindow.uiScale
                            color: _theme.subtext0
                            wrapMode: Text.Wrap
                            visible: text !== ""
                            Layout.fillWidth: true
                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }

        }

    }

    Behavior on height {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuint
        }

    }

}
