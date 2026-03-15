import QtQuick

ListView {
    id: root
    
    // Aliasy dla kompatybilności
    property real topMargin: 0
    property real bottomMargin: 0
    
    header: Item { 
        height: root.topMargin 
        // Usunięto width aby uniknąć binding loop
    }
    footer: Item { 
        height: root.bottomMargin 
        // Usunięto width aby uniknąć binding loop
    }
}
