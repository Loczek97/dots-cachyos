import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Rectangle {
    property string commandText: ""
    signal executed(string result)

    Layout.fillWidth: true
    implicitHeight: 60
    radius: 10
    color: theme.crust
    border.color: theme.yellow
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        Text {
            text: "󰆍"
            font.family: "CaskaydiaCoveNerdFont-Regular"
            font.pixelSize: 20
            color: theme.yellow
        }

        Text {
            text: commandText
            font.family: "CaskaydiaCoveNerdFont-Regular"
            font.pixelSize: 11
            color: theme.subtext0
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        
        Rectangle {
            width: 80; height: 32; radius: 8; color: theme.green
            Text { 
                anchors.centerIn: parent; 
                text: "Wykonaj"; 
                color: theme.base; 
                font.family: "CaskaydiaCoveNerdFont-Regular";
                font.bold: true; 
                font.pixelSize: 12 
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    const proc = Quickshell.exec(["bash", "-c", commandText]);
                    proc.finished.connect(() => {
                        executed(" Wynik komendy:\n" + proc.stdout.readAll());
                    });
                }
            }
        }
    }
}
