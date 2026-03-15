import QtQuick
import QtQuick.Controls
import ".." as Local

Button {
    id: root
    
    flat: true
    
    contentItem: Text {
        text: "✕"
        color: root.hovered ? Local.Looks.colors.accent : Local.Looks.colors.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 16
        font.weight: Font.Bold
    }
    
    background: Rectangle {
        color: root.hovered ? Qt.rgba(1, 0, 0, 0.2) : "transparent"
        radius: Local.Looks.radius.medium
    }
}
