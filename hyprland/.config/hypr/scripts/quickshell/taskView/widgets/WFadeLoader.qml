import QtQuick

Loader {
    property bool shown: false
    active: shown
    opacity: shown ? 1 : 0
    
    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}
