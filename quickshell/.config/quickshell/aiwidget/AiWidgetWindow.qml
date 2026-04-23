import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "./components"
import "."

FloatingWindow {
    id: aiWindow
    title: "AiWidget"
    
    implicitWidth: screen.width
    implicitHeight: screen.height
    color: "transparent"

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    
    // Tło przyciemniające
    Rectangle {
        anchors.fill: parent
        color: "#d0000000"
        
        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
    }

    MatugenTheme { id: theme }

    Rectangle {
        id: mainContainer
        width: 450
        height: 600
        anchors.centerIn: parent
        
        color: theme.base
        radius: 14
        border.width: 1
        border.color: theme.surface2
        clip: true

        MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "AiWidget"
                    font.family: "CaskaydiaCoveNerdFont-Regular"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: theme.primary
                }
                Item { Layout.fillWidth: true }
                
                PersonaSelector { id: personaSelector }
                
                Rectangle {
                    width: 32; height: 32; radius: 8; color: theme.surface1
                    Text { 
                        anchors.centerIn: parent; text: "󰎖"; color: theme.red; 
                        font.family: "CaskaydiaCoveNerdFont-Regular"; font.pixelSize: 16 
                    }
                    MouseArea { 
                        anchors.fill: parent
                        onClicked: chatArea.clearChat()
                    }
                }
            }

            ChatArea {
                id: chatArea
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            InputBar {
                id: inputBar
                Layout.fillWidth: true
                onMessageSent: (msg) => chatArea.sendMessage(msg)
            }
        }
    }
}
