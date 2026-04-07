import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell

FloatingWindow {
    id: powermenuWindow
    title: "dashboard_win"
    
    color: "transparent"

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 15

        // ==========================================
        // KOLUMNA 1: PROFIL I CZAS
        // ==========================================
        ColumnLayout {
            spacing: 15
            Layout.alignment: Qt.AlignTop

            // Panel profilu
            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 270
                radius: 8
                color: "#16161e"
                border.color: "#292e42"
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    // Miejsce na render postaci
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 120
                        height: 140
                        color: "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "🗡️👱‍♂️" 
                            font.pixelSize: 50
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Nicolas"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#f7768e"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "@nico"
                        font.pixelSize: 14
                        color: "#7aa2f7"
                    }
                }
            }

            // Panel czasu / uptime
            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 80
                radius: 8
                color: "#16161e"
                border.color: "#292e42"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15

                    Text {
                        text: "🕒" 
                        font.pixelSize: 30
                        color: "#bb9af7"
                    }

                    ColumnLayout {
                        spacing: 2
                        Text { text: "2 Heures"; font.pixelSize: 16; font.bold: true; color: "#a9b1d6" }
                        Text { text: "28 Minutes"; font.pixelSize: 14; color: "#a9b1d6" }
                    }
                }
            }
        }

        // ==========================================
        // KOLUMNA 2: POGODA I MUZYKA
        // ==========================================
        ColumnLayout {
            spacing: 15
            Layout.alignment: Qt.AlignTop

            // Panel Pogody
            Rectangle {
                Layout.preferredWidth: 380
                Layout.preferredHeight: 170
                radius: 8
                color: "#16161e"
                border.color: "#292e42"
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 15

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20
                        Text { text: "☁️"; font.pixelSize: 40; color: "#565f89" }
                        Text { text: "11°C"; font.pixelSize: 36; font.bold: true; color: "#c0caf5" }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 5
                        Text { 
                            Layout.alignment: Qt.AlignHCenter
                            text: "Couvert"; font.pixelSize: 18; font.bold: true; color: "#f7768e" 
                        }
                        Text { 
                            Layout.alignment: Qt.AlignHCenter
                            text: "Ciel très nuageux, lumière tamisée.\nAmbiance idéale pour une lecture."; 
                            font.pixelSize: 12; color: "#565f89"; horizontalAlignment: Text.AlignHCenter 
                        }
                    }
                }
            }

            // Panel Muzyki
            Rectangle {
                Layout.preferredWidth: 380
                Layout.preferredHeight: 180
                radius: 8
                color: "#16161e"
                border.color: "#292e42"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    // Okładka płyty
                    Rectangle {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120
                        radius: 8
                        color: "#2ac3de"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "💿"
                            font.pixelSize: 60
                        }
                    }

                    // Kontrolki odtwarzacza
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text { Layout.alignment: Qt.AlignHCenter; text: "Offline"; font.pixelSize: 20; font.bold: true; color: "#7aa2f7" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Offline"; font.pixelSize: 12; color: "#e0af68" }

                        // Przyciski sterujące
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 15
                            Text { text: "⏮"; font.pixelSize: 20; color: "#e0af68" }
                            Text { text: "▶"; font.pixelSize: 20; color: "#9ece6a" }
                            Text { text: "⏭"; font.pixelSize: 20; color: "#e0af68" }
                        }

                        // Pasek postępu
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            radius: 2
                            color: "#292e42"
                        }
                        
                        Text { Layout.alignment: Qt.AlignHCenter; text: "0:00 / 0:00"; font.pixelSize: 10; color: "#565f89" }
                    }
                }
            }
        }

        // ==========================================
        // KOLUMNA 3: PRZYCISKI AKCJI
        // ==========================================
        ColumnLayout {
            spacing: 15
            Layout.alignment: Qt.AlignTop

            // Lista 4 przycisków
            Repeater {
                model: ListModel {
                    ListElement { iconChar: "🚪"; iconColor: "#e0af68"; action: "logout" }
                    ListElement { iconChar: "🔓"; iconColor: "#9ece6a"; action: "lock" }
                    ListElement { iconChar: "🔄"; iconColor: "#7aa2f7"; action: "reboot" }
                    ListElement { iconChar: "⏻"; iconColor: "#f7768e"; action: "poweroff" }
                }

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    radius: 8
                    color: btnHover.containsMouse ? "#1a1b26" : "#16161e"
                    border.color: btnHover.containsMouse ? model.iconColor : "#292e42"
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: model.iconChar
                        font.pixelSize: 28
                        color: model.iconColor
                    }

                    MouseArea {
                        id: btnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onClicked: {
                            console.log("Wykonano akcję: " + model.action)
                            // powermenuWindow.close() // Przykład zamykania okna po kliknięciu
                        }
                    }
                }
            }
        }
    }
}