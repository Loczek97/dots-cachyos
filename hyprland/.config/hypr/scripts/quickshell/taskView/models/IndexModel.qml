import QtQuick

ListModel {
    id: root
    property int count: 0
    
    onCountChanged: {
        clear();
        for (var i = 0; i < count; i++) {
            append({ index: i });
        }
    }
    
    Component.onCompleted: {
        if (count > 0) {
            for (var i = 0; i < count; i++) {
                append({ index: i });
            }
        }
    }
}
