import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    property alias color: background.color
    property alias borderColor: background.border.color
    property alias radius: background.radius
    property alias colBackground: background.color
    property bool containsMouse: mouseArea.containsMouse
    property bool containsPress: mouseArea.pressed
    property var drag: Item {}
    property var pressedButtons: mouseArea.pressedButtons
    property int acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    
    // Eksponuj mouseX/mouseY z MouseArea
    property alias mouseX: mouseArea.mouseX
    property alias mouseY: mouseArea.mouseY
    
    signal clicked(var event)
    
    Rectangle {
        id: background
        anchors.fill: parent
        border.width: 1
        border.color: "transparent"
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: root.acceptedButtons
        hoverEnabled: true
        
        onClicked: mouse => {
            root.clicked(mouse);
        }
    }
}
