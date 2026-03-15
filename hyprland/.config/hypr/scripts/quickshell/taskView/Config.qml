pragma Singleton
import QtQuick

QtObject {
    property QtObject options: QtObject {
        property QtObject background: QtObject {
            // Ścieżka do tapety - dopasuj do swojej konfiguracji
            readonly property string wallpaperPath: "/home/michal/.config/current_bg"
        }
    }
}
