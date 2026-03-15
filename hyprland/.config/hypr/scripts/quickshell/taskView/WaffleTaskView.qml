pragma ComponentBehavior: Bound
import "." as Local
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope

    // Get live window list via hyprctl
    property var hyprlandClientList: []

    // Timer to restart the process automatically
    Timer {
        running: true
        repeat: true
        interval: 1000  // Refresh every 1 second
        onTriggered: {
            if (!hyprctlProcess.running) {
                hyprctlProcess.running = true;
            }
        }
    }

    Process {
        id: hyprctlProcess
        running: true  // Auto-start on creation
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text);
                    overviewScope.hyprlandClientList = parsed;
                    console.log("[TaskView] Loaded", parsed.length, "clients");
                } catch(e) {
                    console.log("[TaskView] JSON parse failed:", e);
                }
            }
        }
    }

    Variants {
        id: overviewVariants
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData

            screen: modelData

            WlrLayershell.namespace: "quickshell:wTaskView"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            TaskViewContent {
                id: taskViewContent
                anchors.fill: parent
                hyprlandClients: overviewScope.hyprlandClientList

                Component.onCompleted: {
                    taskViewContent.forceActiveFocus();
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        taskViewContent.close();
                    }
                }
                onClosed: Qt.quit()
            }
        }
    }
}
