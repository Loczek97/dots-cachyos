pragma Singleton
import QtQuick

QtObject {
    id: root

    property ListModel history: ListModel {}
    property ListModel popups: ListModel {}

    property int _popupCounter: 0

    function removePopup(uid) {
        for (let i = 0; i < popups.count; i++) {
            if (popups.get(i).uid === uid) {
                popups.remove(i);
                break;
            }
        }
    }

    Component.onCompleted: console.log("NotificationService: Singleton initialized")
}
