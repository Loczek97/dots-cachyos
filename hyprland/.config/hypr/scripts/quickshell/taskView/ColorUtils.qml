pragma Singleton
import QtQuick

QtObject {
    function transparentize(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }
}
