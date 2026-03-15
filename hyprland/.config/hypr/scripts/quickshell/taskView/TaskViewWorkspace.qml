import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import "." as Local

Local.WMouseAreaButton {
    id: root

    required property int workspace
    property var hyprlandClients: []

    readonly property bool isActiveWorkspace: Local.HyprlandData.activeWorkspace?.id === root.workspace

    // Filter clients for this workspace
    readonly property var workspaceClients: {
        const result = [];
        for (let i = 0; i < root.hyprlandClients.length; i++) {
            const c = root.hyprlandClients[i];
            if (c?.workspace?.id === root.workspace) {
                result.push(c);
            }
        }
        if (result.length > 0 || root.workspace <= 2) {
            console.log(`WS${root.workspace}: ${result.length} clients (total ${root.hyprlandClients.length})`);
        }
        return result;
    }
    
    // Map from client address to Hyprland.toplevel (for screencopy source)
    readonly property var addressToToplevel: {
        const map = {};
        const tl = Hyprland.toplevels;
        if (tl) {
            for (let i = 0; i < tl.length; i++) {
                const t = tl[i];
                if (t?.address) {
                    map[t.address] = t;
                }
            }
        }
        return map;
    }

    // Detect topbar height by finding minimum Y position of all windows on this monitor
    readonly property real topbarHeight: {
        let minY = 0;
        const monX = Hyprland.focusedMonitor?.x ?? 0;
        for (let i = 0; i < root.workspaceClients.length; i++) {
            const c = root.workspaceClients[i];
            const cMonX = c.monitor?.x ?? 0;
            // Only consider windows on the same monitor
            if (Math.abs(cMonX - monX) < 1) {
                const winY = c.at?.[1] ?? 0;
                if (winY > 0 && (minY === 0 || winY < minY)) {
                    minY = winY;
                }
            }
        }
        // If any window Y > 0, assume that's where topbar ends
        return minY > 0 ? Math.max(0, minY - 1) : 0;
    }

    readonly property int clientCount: workspaceClients.length

    // Monitor dimensions for scaling
    readonly property real screenW: Hyprland.focusedMonitor?.width ?? 1920
    readonly property real screenH: Hyprland.focusedMonitor?.height ?? 1080
    readonly property real previewScale: (width - 8) / screenW

    colBackground: isActiveWorkspace
        ? Local.ColorUtils.transparentize(Local.Looks.colors.bg2, 0.95)
        : Local.ColorUtils.transparentize(Local.Looks.colors.bg1, 0.88)
    borderColor: Local.ColorUtils.transparentize(Local.Looks.colors.bg2Border, 0.5)
    radius: Local.Looks.radius.large

    scale: containsPress ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }

    // Active workspace accent border
    Rectangle {
        z: 3
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Local.Looks.colors.accent
        border.width: 2
        visible: root.isActiveWorkspace
        opacity: 0.85
    }

    // Hover glow
    Rectangle {
        z: 1
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius - 1
        color: "white"
        opacity: root.containsMouse && !root.containsPress ? 0.04 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // --- Miniaturised desktop preview ---
    Item {
        z: 2
        anchors { fill: parent; margins: 4 }
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Local.Looks.colors.bg1
            radius: Local.Looks.radius.medium - 2
        }

        Item {
            id: scaledDesktop
            // Scale the content EXCLUDING topbar height
            width: root.screenW * root.previewScale
            height: (root.screenH - root.topbarHeight) * root.previewScale
            anchors.centerIn: parent

            Repeater {
                model: root.workspaceClients

                delegate: Item {
                    id: winDelegate
                    required property var modelData
                    required property int index

                    readonly property real monX: modelData.monitor?.x ?? 0
                    readonly property real monY: modelData.monitor?.y ?? 0
                    readonly property var tlData: root.addressToToplevel[modelData.address]
                    readonly property string previewIconName: Local.AppSearch.guessIcon(modelData.class ?? "application-x-executable")
                    readonly property bool isCodeOrDiscord: modelData.class === "code" || modelData.class === "discord"

                    Component.onCompleted: {
                        if (modelData.class === "code" || modelData.class === "discord") {
                            console.log(`[TaskViewWorkspace] class=${modelData.class} workspace=${root.workspace} icon=${previewIconName} hasToplevel=${!!tlData}`);
                        }
                    }

                    // Subtract both monitor offset AND topbar height from Y
                    x: ((modelData.at?.[0] ?? 0) - monX) * root.previewScale
                    y: ((modelData.at?.[1] ?? 0) - monY - root.topbarHeight) * root.previewScale
                    width: Math.max((modelData.size?.[0] ?? 400) * root.previewScale, 4)
                    height: Math.max((modelData.size?.[1] ?? 300) * root.previewScale, 4)
                    clip: true

                    // Window border/bg
                    Rectangle {
                        anchors.fill: parent
                        color: Local.Looks.colors.bg2
                        border.color: Local.Looks.colors.bg2Border
                        border.width: 1
                        radius: 2
                    }

                    // Real screencopy thumbnail - use toplevel.wayland as source
                    // For VSCode/Discord pokażemy zamiast tego duży kafel z ikoną.
                    Local.ScreencopyView {
                        id: scv
                        anchors.fill: parent
                        captureSource: winDelegate.tlData?.wayland
                        live: true
                        constraintSize: Qt.size(winDelegate.width, winDelegate.height)
                        visible: !winDelegate.isCodeOrDiscord
                    }

                    Rectangle {
                        z: 3
                        width: Math.min(Math.max(winDelegate.width * 0.25, 18), 32)
                        height: width
                        radius: width / 2
                        anchors {
                            left: parent.left
                            top: parent.top
                            margins: 4
                        }
                        color: Qt.rgba(0.15, 0.20, 0.16, 0.96)
                        border.color: Local.ColorUtils.transparentize(Local.Looks.colors.bg2Border, 0.25)
                        border.width: 1

                        Local.WAppIcon {
                            anchors.centerIn: parent
                            width: Math.max(parent.width - 6, 16)
                            height: width
                            iconName: winDelegate.previewIconName
                        }
                    }

                    // Dla VSCode/Discord: wyłącz screencopy i pokaż duży kafel z ikoną.
                    Rectangle {
                        anchors.fill: parent
                        z: 3
                        visible: winDelegate.isCodeOrDiscord
                        color: Local.ColorUtils.transparentize(Local.Looks.colors.bg1, 0.4)

                        Local.WAppIcon {
                            anchors.centerIn: parent
                            width: Math.min(winDelegate.width * 0.8, 96)
                            height: width
                            iconName: winDelegate.previewIconName
                        }
                    }

                    // Ogólny fallback ikony, gdy nie ma screencopy (inne aplikacje)
                    Local.WAppIcon {
                        anchors.centerIn: parent
                        z: 3
                        width: Math.min(winDelegate.width * 0.6, 60)
                        height: width
                        iconName: winDelegate.previewIconName
                        visible: !scv.hasContent && !winDelegate.isCodeOrDiscord
                    }
                }
            }
        }
    }

    // Workspace number — centered when empty, bottom-left when has windows
    Text {
        z: 4
        anchors.centerIn: parent
        visible: root.clientCount === 0
        text: root.workspace
        font.pixelSize: Math.min(parent.height * 0.45, 40)
        color: Local.Looks.colors.text
        opacity: 0.20
    }
    Text {
        z: 4
        anchors { left: parent.left; bottom: parent.bottom; margins: 5 }
        visible: root.clientCount > 0
        text: root.workspace
        font.pixelSize: 10
        color: Local.Looks.colors.text
        opacity: 0.50
    }
}
