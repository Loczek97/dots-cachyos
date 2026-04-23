import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

ListView {
    id: chatList
    spacing: 10
    clip: true
    model: ListModel { id: chatModel }
    
    delegate: MessageBubble {
        text: model.text
        isUser: model.isUser
        command: model.command || ""
        width: chatList.width
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    function sendMessage(msg) {
        chatModel.append({ text: msg, isUser: true, command: "" });
        chatList.positionViewAtEnd();
        
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:1337/chat");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    const res = JSON.parse(xhr.responseText);
                    chatModel.append({ text: res.text, isUser: false, command: res.command || "" });
                    chatList.positionViewAtEnd();
                } catch(e) {
                    appendSystemMessage("Błąd połączenia z backendem.");
                }
            }
        };
        xhr.send(JSON.stringify({ message: msg }));
    }

    function appendSystemMessage(msg) {
        chatModel.append({ text: msg, isUser: false, command: "" });
        chatList.positionViewAtEnd();
    }

    function clearChat() {
        chatModel.clear();
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:1337/reset");
        xhr.send();
    }
}
