import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.Icon {
    property string icon: ""
    
    source: {
        const iconMap = {
            "add": "list-add",
            "remove": "list-remove",
            "checkmark": "emblem-checked",
            "empty": ""
        };
        return iconMap[icon] || icon;
    }
    
    width: 24
    height: 24
}
