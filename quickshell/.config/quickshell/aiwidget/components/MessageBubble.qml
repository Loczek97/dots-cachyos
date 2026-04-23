import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root
    property string text: ""
    property bool isUser: false
    property string command: ""
    
    height: bubbleRect.height
    
    Rectangle {
        id: bubbleRect
        anchors.right: isUser ? parent.right : undefined
        anchors.left: isUser ? undefined : parent.left
        
        width: Math.min(parent.width * 0.85, contentLayout.implicitWidth + 24)
        height: contentLayout.implicitHeight + 16

        radius: 12
        color: isUser ? theme.primaryContainer : theme.surface1
        border.width: 1
        border.color: isUser ? theme.primary : theme.surface2

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                id: messageText
                text: root.text
                color: isUser ? theme.base : theme.text
                font.family: "CaskaydiaCoveNerdFont-Regular"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Loader {
                active: root.command !== ""
                Layout.fillWidth: true
                sourceComponent: ActionConfirm {
                    commandText: root.command
                    onExecuted: (res) => chatList.appendSystemMessage(res)
                }
            }
        }
    }
}
