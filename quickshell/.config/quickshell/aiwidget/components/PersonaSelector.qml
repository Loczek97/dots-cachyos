import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: personaRoot
    width: 160; height: 32; radius: 8
    color: theme.surface1
    border.width: 1; border.color: theme.surface2

    property var personas: []
    property int currentIndex: 0

    Text {
        anchors.centerIn: parent
        text: personas.length > 0 ? personas[currentIndex].icon + " " + personas[currentIndex].name : "Ładowanie..."
        font.family: "CaskaydiaCoveNerdFont-Regular"
        font.pixelSize: 12
        color: theme.text
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            personaRoot.currentIndex = (personaRoot.currentIndex + 1) % personaRoot.personas.length;
            setPersona(personaRoot.personas[personaRoot.currentIndex].id);
        }
    }

    function loadPersonas() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "http://localhost:1337/personas");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                personaRoot.personas = JSON.parse(xhr.responseText);
            }
        };
        xhr.send();
    }

    function setPersona(id) {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:1337/set_persona");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ id: id }));
        chatArea.clearChat();
        chatArea.appendSystemMessage("Zmieniono osobowość na: " + personaRoot.personas[currentIndex].name);
    }

    Component.onCompleted: loadPersonas()
}
