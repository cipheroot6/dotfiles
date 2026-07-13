import QtQuick
import QtQuick.Controls

Item {
    id: aiPromptLayer

    signal closeRequested()

    onVisibleChanged: {
        if (visible) {
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 300
        repeat: false
        onTriggered: {
            aiInput.forceActiveFocus();
        }
    }

    function forceInputFocus() {
        focusTimer.restart();
    }

    property string welcomeMessage: ""

    Component.onCompleted: {
        var messages = [
            "READY TO BUILD? 🚀",
            "WHAT'S ON YOUR MIND? 💭",
            "LET'S CREATE SOMETHING. ✨",
            "HOW CAN I HELP? 🤖",
            "WHAT ARE WE CODING TODAY? 💻",
            "UNLEASH YOUR IDEAS. 💡"
        ];
        welcomeMessage = messages[Math.floor(Math.random() * messages.length)];
    }

    property string ollamaEndpoint: "http://localhost:11434/api/generate"
    property string ollamaModel: "gemma-31b"
    property string ollamaApiKey: ""
    property string textFontFamily: ""
    property color backgroundColor: "#1e1e2e"
    property color textColor: "#cdd6f4"
    property color accentColor: "#89b4fa"
    
    property var chatHistory: []

    anchors.fill: parent
    anchors.margins: 12

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: 20

        ListModel {
            id: chatModel
        }

        FontLoader {
            id: stylishFont
            source: "fonts/Pacifico.ttf"
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            width: parent.width * 0.9
            text: aiPromptLayer.welcomeMessage
            font.family: stylishFont.name
            font.pixelSize: 42
            font.weight: Font.Normal
            color: "#ffffff"
            visible: chatModel.count === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        MouseArea {
            id: chatViewScrollInterceptor
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: inputContainer.top
            anchors.margins: 16
            onWheel: (wheel) => { wheel.accepted = true; }

            ListView {
                id: chatView
                anchors.fill: parent
                clip: true
                model: chatModel
                spacing: 12
                
                delegate: Item {
                    width: ListView.view.width
                    height: bubble.height
                    
                    Rectangle {
                        id: bubble
                        width: Math.min(messageText.implicitWidth + 24, parent.width * 0.9)
                        height: messageText.implicitHeight + 16
                        radius: 12
                        color: model.role === "user" ? accentColor : "transparent"
                        border.color: model.role === "user" ? "transparent" : Qt.rgba(255, 255, 255, 0.1)
                        border.width: 1
                        anchors.right: model.role === "user" ? parent.right : undefined
                        anchors.left: model.role === "user" ? undefined : parent.left
                        
                        TextArea {
                            id: messageText
                            anchors.fill: parent
                            anchors.margins: 12
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            text: model.content
                            color: model.role === "user" ? "#1e1e2e" : textColor
                            font.family: textFontFamily
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                            textFormat: Text.MarkdownText
                            readOnly: true
                            selectByMouse: true
                            background: null
                        }
                    }
                }
                
                onCountChanged: {
                    Qt.callLater(function() {
                        chatView.positionViewAtEnd();
                    });
                }
            }
        }

        // Input Area
        Rectangle {
            id: inputContainer
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            height: 40
            radius: 12
            color: Qt.darker(backgroundColor, 1.2)
            border.color: aiInput.activeFocus ? accentColor : "transparent"
            border.width: 1

            TextInput {
                id: aiInput
                anchors.fill: parent
                anchors.margins: 10
                color: textColor
                font.family: textFontFamily
                font.pixelSize: 14
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                Keys.onEscapePressed: {
                    aiPromptLayer.closeRequested();
                }
                Keys.onReturnPressed: {
                    if (text.trim() !== "") {
                        sendPrompt(text.trim());
                        text = "";
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        console.log("AiPromptLayer: MouseArea clicked, forcing focus");
                        aiInput.forceActiveFocus();
                    }
                }
                
                onActiveFocusChanged: {
                    console.log("AiPromptLayer: aiInput activeFocus =", activeFocus);
                }
                
                
                Text {
                    text: "Ask AI..."
                    color: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.5)
                    visible: !parent.text && !parent.activeFocus
                    font: parent.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    function sendPrompt(prompt) {
        var userMsg = { "role": "user", "content": prompt };
        var newHistory = chatHistory.slice();
        newHistory.push(userMsg);
        chatHistory = newHistory;

        chatModel.append({ "role": "user", "content": prompt });
        chatModel.append({ "role": "assistant", "content": "Thinking..." });
        var thinkingIndex = chatModel.count - 1;

        var xhr = new XMLHttpRequest();
        xhr.open("POST", ollamaEndpoint);
        xhr.setRequestHeader("Content-Type", "application/json");
        if (ollamaApiKey !== "") {
            xhr.setRequestHeader("Authorization", "Bearer " + ollamaApiKey);
        }

        var payload = {
            "model": ollamaModel,
            "messages": chatHistory,
            "stream": false
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var aiMsg = response.message;

                        var updatedHistory = chatHistory.slice();
                        updatedHistory.push(aiMsg);
                        chatHistory = updatedHistory;

                        chatModel.setProperty(thinkingIndex, "content", aiMsg.content);
                    } catch (e) {
                        chatModel.setProperty(thinkingIndex, "content", "Error parsing response.");
                    }
                } else {
                    chatModel.setProperty(thinkingIndex, "content", "Error: " + xhr.status + " " + xhr.statusText);
                }
            }
        };

        xhr.send(JSON.stringify(payload));
    }
}
