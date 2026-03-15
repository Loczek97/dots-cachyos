pragma Singleton
import QtQuick
import Quickshell.Hyprland

QtObject {
    // Wrapper wykorzystujący Hyprland.clients zamiast ToplevelManagement
    property var toplevels: QtObject {
        property var values: {
            if (!Hyprland || !Hyprland.clients) return [];
            // Konwertuj do standardowej tablicy jeśli to QML lista
            var arr = [];
            for (var i = 0; i < Hyprland.clients.length; i++) {
                arr.push(Hyprland.clients[i]);
            }
            return arr;
        }
    }
}
