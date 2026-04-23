import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: inputRoot
    height: 50
    radius: 14
    color: theme.surface0
    border.width: 1
    border.color: inputField.activeFocus ? theme.primary : theme.surface2
    
    signal messageSent(string msg)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8

        TextField {
            id: inputField
            Layout.fillWidth: true
            placeholderText: "Zadaj pytanie..."
            font.family: "CaskaydiaCoveNerdFont-Regular"
            color: theme.text
            font.pixelSize: 13
            background: null
            verticalAlignment: TextInput.AlignVCenter
            
            onAccepted: {
                if (text.trim() !== "") {
                    inputRoot.messageSent(text);
                    text = "";
                }
            }
        }

        Rectangle {
            width: 34; height: 34; radius: 10
            color: inputField.text !== "" ? theme.primary : theme.surface1
            Behavior on color { ColorAnimation { duration: 200 } }
            
            Text { 
                anchors.centerIn: parent
                text: "󰭹"
                font.family: "CaskaydiaCoveNerdFont-Regular"
                font.pixelSize: 18
                color: inputField.text !== "" ? theme.base : theme.subtext1
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: inputField.accepted()
            }
        }
    }
}
