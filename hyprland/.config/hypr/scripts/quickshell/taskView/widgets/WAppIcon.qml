import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    // Public API
    property string iconName: ""
    property int implicitSize: 24
    property bool tryCustomIcon: true

    // Treat any file:// URL (or absolute path) as a direct image
    readonly property bool isFileIcon: iconName.startsWith("file://") || iconName.startsWith("/")
    readonly property string resolvedFileIcon: iconName.startsWith("file://")
        ? iconName
        : (iconName.startsWith("/") ? "file://" + iconName : "")

    implicitWidth: implicitSize
    implicitHeight: implicitSize
    width: implicitSize
    height: implicitSize

    // Theme icon branch (for normal icon names)
    Kirigami.Icon {
        anchors.fill: parent
        visible: !root.isFileIcon
        source: root.isFileIcon ? "" : root.iconName
    }

    // File-based icon branch (for explicit PNG/SVG paths)
    Image {
        anchors.fill: parent
        visible: root.isFileIcon && root.resolvedFileIcon !== ""
        source: visible ? root.resolvedFileIcon : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
    }
}
