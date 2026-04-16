import QtQuick
import Quickshell
import Quickshell.Wayland 
import "."

PanelWindow {
    id: desktopClock
    WlrLayershell.layer: WlrLayer.Background 
    color: "transparent"
    
    // --- KOLOROWANIE MATUGEN ---
    MatugenTheme { id: theme }

    implicitWidth: contentItem.implicitWidth + 40
    implicitHeight: contentItem.implicitHeight + 40
    
    anchors {
        bottom: Config.isBottom
        top: !Config.isBottom
        right: Config.isRight
        left: !Config.isRight
    }
    
    margins.bottom: Config.isBottom ? Config.anchorBottom : 0
    Behavior on margins.bottom { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
    
    margins.top: !Config.isBottom ? Config.anchorTop : 0
    Behavior on margins.top { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
    
    margins.right: Config.isRight ? Config.anchorRight : 0
    Behavior on margins.right { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
    
    margins.left: !Config.isRight ? Config.anchorLeft : 0
    Behavior on margins.left { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }

    Item {
        id: contentItem
        anchors.centerIn: parent
        implicitWidth: mainLayout.implicitWidth
        implicitHeight: mainLayout.implicitHeight

        opacity: 0
        Component.onCompleted: fadeIn.start()
        
        NumberAnimation {
            id: fadeIn
            target: contentItem
            property: "opacity"
            from: 0
            to: 1
            duration: 1000
            easing.type: Easing.OutCubic
        }

        Rectangle {
            anchors.fill: mainLayout
            anchors.topMargin: -10
            anchors.bottomMargin: -20
            anchors.leftMargin: -25
            anchors.rightMargin: -25
            color: theme.crust
            opacity: 0.4
            radius: 25
            border.color: theme.surface0
            border.width: 1
        }

        Column {
            id: mainLayout
            spacing: -45

            Text {
                id: hoursText
                text: "00"
                color: theme.text
                font.pixelSize: 100
                font.weight: Font.Black
                font.letterSpacing: -6
                anchors.horizontalCenter: parent.horizontalCenter
                lineHeight: 0.8 
                topPadding: -15 

                style: Text.Outline
                styleColor: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.4)
            }

            Text {
                id: minutesText
                text: "00"
                color: theme.primary
                font.pixelSize: 100
                font.weight: Font.Black
                font.letterSpacing: -6
                anchors.horizontalCenter: parent.horizontalCenter
                
                style: Text.Outline
                styleColor: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.4)
            }

            Text {
                id: dateText
                text: ""
                color: theme.subtext1
                font.pixelSize: 15
                font.weight: Font.Bold
                font.capitalization: Font.Lowercase
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 30
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            hoursText.text = now.toLocaleTimeString(Qt.locale(), "HH")
            minutesText.text = now.toLocaleTimeString(Qt.locale(), "mm")
            dateText.text = now.toLocaleDateString(Qt.locale(), "dddd, d MMMM");
        }
    }
}
