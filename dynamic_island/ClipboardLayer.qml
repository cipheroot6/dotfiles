import QtQuick
import QtQuick.Controls
import Quickshell.Io

Item {
    id: clipboardLayer

    property bool showCondition: false
    property string textFontFamily: ""
    property color backgroundColor: "#1e1e2e"
    property color textColor: "#cdd6f4"
    property color accentColor: "#89b4fa"

    anchors.fill: parent
    anchors.margins: 12
    opacity: showCondition ? 1 : 0
    visible: opacity > 0
    scale: showCondition ? 1 : 0.95

    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
    }

    onShowConditionChanged: {
        if (showCondition) {
            clipboardReader.exec(["cat", "/home/cipheroot/.local/share/quickshell_clipboard.json"]);
        }
    }

    Process {
        id: clipboardReader
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    clipboardModel.clear();
                    if (text.trim() === "") return;
                    var items = JSON.parse(text);
                    for (var i = 0; i < items.length; i++) {
                        clipboardModel.append({ "content": items[i] });
                    }
                } catch(e) {}
            }
        }
    }
    
    Process {
        id: clipboardWriter
    }

    ListModel {
        id: clipboardModel
    }

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: 20

        Text {
            id: titleText
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 16
            text: "Clipboard History"
            color: textColor
            font.family: textFontFamily
            font.pixelSize: 16
            font.bold: true
        }

        MouseArea {
            id: listViewScrollInterceptor
            anchors.top: titleText.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            onWheel: (wheel) => { wheel.accepted = true; }

            ListView {
                id: listView
                anchors.fill: parent
                clip: true
                model: clipboardModel
                spacing: 8

                delegate: Rectangle {
                    width: listView.width
                    height: 40
                    color: mouseArea.containsMouse ? Qt.darker(accentColor, 1.5) : Qt.darker(backgroundColor, 1.2)
                    radius: 8
                    border.color: mouseArea.containsMouse ? accentColor : "transparent"
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: model.content.replace(/\n/g, " ")
                        color: textColor
                        font.family: textFontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            clipboardWriter.exec(["wl-copy", model.content]);
                            // Try to find the root dynamic island window and close the layer
                            var p = clipboardLayer;
                            while(p && p.objectName !== "islandContainer") {
                                if (p.parent) p = p.parent;
                                else break;
                            }
                            if (p && p.handleConfiguredClickAction) {
                                p.handleConfiguredClickAction("closeClipboard");
                            }
                        }
                    }
                }
            }
        }
    }
}
