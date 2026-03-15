import QtQuick
import Quickshell.Wayland as QsWayland

Item {
    id: root

    property var captureSource: null
    property bool live: false
    property size constraintSize: Qt.size(0, 0)
    readonly property bool hasContent: _sv.hasContent

    QsWayland.ScreencopyView {
        id: _sv
        anchors.fill: parent
        captureSource: root.captureSource ?? null
        live: root.live
        constraintSize: root.constraintSize
    }
}
