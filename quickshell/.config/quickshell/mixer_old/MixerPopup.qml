//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import "."

ShellRoot {
    id: root

    MatugenTheme { id: theme }

    // --- COLOR MAPPINGS ---
    readonly property color base: theme.base
    readonly property color mantle: theme.mantle
    readonly property color crust: theme.crust
    readonly property color text: theme.text
    readonly property color subtext1: theme.subtext1
    readonly property color subtext0: theme.subtext0
    readonly property color overlay2: theme.overlay2
    readonly property color overlay1: theme.overlay1
    readonly property color overlay0: theme.overlay0
    readonly property color surface2: theme.surface2
    readonly property color surface1: theme.surface1
    readonly property color surface0: theme.surface0
    
    readonly property color mauve: theme.mauve
    readonly property color pink: theme.pink
    readonly property color blue: theme.blue
    readonly property color sapphire: theme.sapphire
    readonly property color peach: theme.peach
    readonly property color yellow: theme.yellow
    readonly property color teal: theme.teal
    readonly property color green: theme.green
    readonly property color red: theme.red
    readonly property color maroon: theme.maroon

    property int currentTab: 0 
    property string filterText: ""
    
    // --- ANIMATIONS ---
    property real introState: 0.0
    Behavior on introState { NumberAnimation { duration: 1200; easing.type: Easing.OutExpo } }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    Component.onCompleted: introState = 1.0

    function isOutput(node) { return node.isSink && !node.isStream; }
    function isInput(node) { return !node.isSink && !node.isStream; }
    function isApp(node) { return node.isStream; }

    FloatingWindow {
        id: window
        title: "mixer_win"
        implicitWidth: 850
        implicitHeight: 700
        visible: true
        color: "transparent"

        Item {
            anchors.fill: parent
            scale: 0.90 + (0.10 * root.introState)
            opacity: root.introState

            Rectangle {
                anchors.fill: parent
                color: root.base
                radius: 35
                border.color: root.surface0
                border.width: 1
                clip: true

                // --- AMBIENT BACKGROUND BLOBS ---
                Item {
                    anchors.fill: parent
                    z: -1
                    
                    Rectangle {
                        width: 600; height: 600; radius: 300
                        color: root.mauve
                        opacity: 0.04
                        x: -150; y: -150
                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 15000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: -150; duration: 15000; easing.type: Easing.InOutSine }
                        }
                    }
                    Rectangle {
                        width: 500; height: 500; radius: 250
                        color: root.sapphire
                        opacity: 0.04
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -100
                        anchors.bottomMargin: -100
                        SequentialAnimation on anchors.bottomMargin {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 12000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: -100; duration: 12000; easing.type: Easing.InOutSine }
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent; spacing: 0

                    // --- SIDEBAR ---
                    Rectangle {
                        Layout.fillHeight: true; Layout.preferredWidth: 80; color: "#05ffffff"
                        border.color: "#1affffff"; border.width: 1
                        
                        Column {
                            anchors.top: parent.top; anchors.topMargin: 40; anchors.horizontalCenter: parent.horizontalCenter; spacing: 15
                            Repeater {
                                model: [
                                    { "icon": "󰓃", "name": "Wyjścia" },
                                    { "icon": "󰍬", "name": "Wejścia" },
                                    { "icon": "󰎆", "name": "Aplikacje" }
                                ]
                                delegate: Rectangle {
                                    width: 56; height: 56; radius: 18
                                    color: root.currentTab === index ? root.mauve : (sideMa.containsMouse ? root.surface1 : "transparent")
                                    
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    scale: sideMa.containsMouse ? 1.1 : 1.0

                                    Text { 
                                        anchors.centerIn: parent; text: modelData.icon
                                        font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 26
                                        color: root.currentTab === index ? root.base : (sideMa.containsMouse ? root.text : root.overlay2)
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    
                                    MouseArea { id: sideMa; anchors.fill: parent; onClicked: root.currentTab = index; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

                        // --- HEADER ---
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 90; color: "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 40; anchors.rightMargin: 40
                                ColumnLayout {
                                    spacing: 2
                                    Text { 
                                        text: ["WYJŚCIA", "WEJŚCIA", "APLIKACJE"][root.currentTab]
                                        font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 24; font.weight: Font.Black
                                        color: root.text 
                                    }
                                    Rectangle { width: 40; height: 4; radius: 2; color: root.mauve }
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Row {
                                    spacing: 15
                                    
                                    // Default Sink Capsule
                                    Rectangle {
                                        width: sinkRow.implicitWidth + 30; height: 50; radius: 15
                                        color: root.surface0; border.color: root.surface1; border.width: 1
                                        Row {
                                            id: sinkRow; anchors.centerIn: parent; spacing: 20
                                            StatPill { 
                                                label: "GŁOŚNOŚĆ"; 
                                                value: Math.floor((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"; 
                                                col: root.mauve 
                                            }
                                        }
                                    }

                                    // Default Source Capsule
                                    Rectangle {
                                        width: sourceRow.implicitWidth + 30; height: 50; radius: 15
                                        color: root.surface0; border.color: root.surface1; border.width: 1
                                        Row {
                                            id: sourceRow; anchors.centerIn: parent
                                            StatPill { 
                                                label: "MIKROFON"; 
                                                value: Math.floor((Pipewire.defaultAudioSource?.audio?.volume ?? 0) * 100) + "%"; 
                                                col: root.sapphire 
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- SEARCH BAR (Shared) ---
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 50; color: "transparent"
                            Layout.leftMargin: 40; Layout.rightMargin: 40; Layout.bottomMargin: 10
                            
                            Rectangle {
                                anchors.fill: parent
                                color: root.surface0; radius: 15; border.color: root.surface1; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 12
                                    Text { text: "󰍉"; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 20; color: root.mauve }
                                    TextField {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        placeholderText: "Szukaj urządzenia lub aplikacji..."
                                        font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 14; font.weight: Font.Bold
                                        color: root.text; placeholderTextColor: root.overlay0
                                        background: Item {}
                                        onTextChanged: root.filterText = text
                                    }
                                }
                            }
                        }

                        // --- MAIN CONTENT ---
                        StackLayout {
                            currentIndex: root.currentTab
                            Layout.fillWidth: true; Layout.fillHeight: true

                            // Tab: Outputs
                            MixerTab {
                                filterFunc: root.isOutput
                            }

                            // Tab: Inputs
                            MixerTab {
                                filterFunc: root.isInput
                            }

                            // Tab: Applications
                            MixerTab {
                                filterFunc: root.isApp
                            }
                        }
                    }
                }
            }
        }
    }

    // --- CUSTOM COMPONENTS ---

    component StatPill : RowLayout {
        property string label: ""; property string value: ""; property color col: "white"
        spacing: 10
        Rectangle { width: 12; height: 12; radius: 6; color: parent.col }
        Column {
            Text { text: parent.parent.label; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 10; font.weight: Font.Bold; color: root.overlay1 }
            Text { text: parent.parent.value; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 16; font.weight: Font.Black; color: root.text }
        }
    }

    component MixerTab : Item {
        property var filterFunc

        ListView {
            id: nodeList
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            anchors.bottomMargin: 20
            clip: true 
            spacing: 0 // Spacing handled inside delegate to prevent ghost gaps
            model: Pipewire.nodes
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                required property var modelData
                
                // Filtering Logic
                property bool isFiltered: filterFunc(modelData) && 
                                       (modelData.description.toLowerCase().includes(root.filterText.toLowerCase()) || 
                                        modelData.name.toLowerCase().includes(root.filterText.toLowerCase()))
                
                visible: isFiltered && modelData.audio !== null
                width: nodeList.width
                height: visible ? 93 : 0 // 85 (card) + 8 (spacing)
                
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // The visible card
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 85
                    radius: 15
                    color: nodeMa.containsMouse ? root.surface1 : "#05ffffff"
                    border.color: nodeMa.containsMouse ? root.surface2 : "transparent"
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    PwObjectTracker { objects: [modelData] }

                    MouseArea { id: nodeMa; anchors.fill: parent; hoverEnabled: true }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 15
                        
                        // Icon
                        Rectangle {
                            width: 50; height: 50; radius: 14; color: root.surface0
                            Text {
                                anchors.centerIn: parent
                                text: modelData.isSink ? "󰓃" : (!modelData.isStream ? "󰍬" : "󰎆")
                                font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 26
                                color: root.mauve
                            }
                        }

                        // Info & Slider
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            Text { 
                                text: modelData.description != "" ? modelData.description : modelData.name;
                                color: root.text; font.family: "CaskaydiaCove Nerd Font"; font.weight: Font.Black; font.pixelSize: 15; elide: Text.ElideRight 
                                Layout.fillWidth: true
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true; spacing: 12
                                Slider {
                                    id: volSlider
                                    Layout.fillWidth: true
                                    value: modelData.audio?.volume ?? 0
                                    onMoved: if (modelData.audio) modelData.audio.volume = value
                                    
                                    background: Rectangle {
                                        x: volSlider.leftPadding
                                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                                        implicitWidth: 200; implicitHeight: 8; width: volSlider.availableWidth; height: implicitHeight; radius: 4
                                        color: root.surface2
                                        Rectangle {
                                            width: volSlider.visualPosition * parent.width; height: parent.height; color: root.mauve; radius: 4
                                        }
                                    }
                                    handle: Rectangle {
                                        x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                                        implicitWidth: 18; implicitHeight: 18; radius: 9; color: root.text; border.color: root.mauve; border.width: 2
                                        
                                        scale: volSlider.pressed ? 0.9 : (volSlider.hovered ? 1.1 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                    }
                                }
                                Text { 
                                    text: Math.floor((modelData.audio?.volume ?? 0) * 100) + "%"
                                    color: root.subtext0; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 13; font.weight: Font.Bold; Layout.preferredWidth: 40
                                }
                            }
                        }

                        // Controls
                        RowLayout {
                            spacing: 10
                            
                            // Mute Toggle
                            Rectangle {
                                width: 44; height: 44; radius: 12
                                color: (modelData.audio?.muted ? root.red : (muteMa.containsMouse ? root.surface2 : "transparent"))
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                scale: muteMa.containsMouse ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150 } }

                                Text { 
                                    anchors.centerIn: parent; text: modelData.audio?.muted ? "󰝟" : "󰕾"
                                    font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 20; color: modelData.audio?.muted ? root.base : root.text 
                                }
                                MouseArea { 
                                    id: muteMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted 
                                }
                            }

                            // Default Sink/Source Star
                            Rectangle {
                                visible: !modelData.isStream
                                width: 44; height: 44; radius: 12
                                property bool isDefault: (modelData.isSink ? Pipewire.defaultAudioSink === modelData : Pipewire.defaultAudioSource === modelData)
                                color: isDefault ? root.yellow : (starMa.containsMouse ? root.surface2 : "transparent")
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                scale: starMa.containsMouse ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150 } }

                                Text { 
                                    anchors.centerIn: parent; text: "󰓎"
                                    font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 20; color: parent.isDefault ? root.base : root.overlay2 
                                }
                                MouseArea { 
                                    id: starMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.isSink) Pipewire.preferredDefaultAudioSink = modelData;
                                        else if (!modelData.isStream) Pipewire.preferredDefaultAudioSource = modelData;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
