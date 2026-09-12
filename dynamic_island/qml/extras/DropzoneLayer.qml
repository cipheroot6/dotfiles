import QtQuick
import IslandBackend
import QtQuick.Controls
import IslandBackend
import QtQuick.Layouts
import IslandBackend
import Quickshell.Io
import "../core"
import "../island"
import "../controlcenter"
import "../productivity"
import "../workspace"


Item {
    id: dropzoneLayer

    property bool showCondition: false
    property string textFontFamily: ""
    property string iconFontFamily: ""

    anchors.fill: parent
    anchors.margins: 16
    opacity: showCondition ? 1 : 0
    visible: opacity > 0
    scale: showCondition ? 1 : 0.95

    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    Process {
        id: copyProcess
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        radius: 20
        border.color: "#313244"
        border.width: 1

        Text {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: clearBtn.left
            anchors.topMargin: 16
            anchors.leftMargin: 20
            text: "Black Hole Shelf"
            color: "#cdd6f4"
            font.family: textFontFamily
            font.pixelSize: 16
            font.bold: true
        }

        MouseArea {
            id: clearBtn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 16
            anchors.topMargin: 16
            width: 80
            height: 24
            cursorShape: Qt.PointingHandCursor
            
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: clearBtn.containsMouse ? "#f38ba8" : "#45475a"
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: "#cdd6f4"
                    font.family: textFontFamily
                    font.pixelSize: 12
                }
            }
            
            onClicked: {
                UserConfig.dropzoneItems = [];
                dropzoneGrid.model = 0;
            }
        }

        GridView {
            id: dropzoneGrid
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 20
            anchors.topMargin: 16
            clip: true
            
            cellWidth: 80
            cellHeight: 90
            
            model: UserConfig.dropzoneItems

            delegate: Item {
                width: 70
                height: 80

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: itemMouseArea.containsMouse ? "#313244" : "transparent"
                    border.color: itemMouseArea.containsMouse ? "#89b4fa" : "transparent"
                    border.width: 1

                    // Safely handle modelData which might not be implicitly string
                    property string dataStr: typeof modelData !== "undefined" ? String(modelData) : ""
                    property bool isFile: dataStr.indexOf("file://") === 0
                    property string displayStr: isFile ? dataStr.substring(dataStr.lastIndexOf("/") + 1) : dataStr
                    property bool isImage: isFile && (displayStr.endsWith(".png") || displayStr.endsWith(".jpg") || displayStr.endsWith(".jpeg") || displayStr.endsWith(".gif"))

                    Image {
                        id: thumb
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32
                        height: 32
                        source: isImage ? dataStr : ""
                        sourceSize: Qt.size(64, 64)
                        fillMode: Image.PreserveAspectCrop
                        visible: isImage
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: isFile ? "󰈔" : "󰦨"
                        font.family: iconFontFamily
                        font.pixelSize: 32
                        color: "#89b4fa"
                        visible: !isImage
                    }

                    Text {
                        id: itemText
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        text: displayStr
                        font.family: textFontFamily
                        font.pixelSize: 10
                        color: "#a6adc8"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Item {
                        id: dragItem
                        Drag.active: itemMouseArea.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction
                        Drag.mimeData: {
                            let mime = {};
                            if (isFile) {
                                mime["text/uri-list"] = dataStr;
                            } else {
                                mime["text/plain"] = dataStr;
                            }
                            return mime;
                        }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        drag.target: dragItem

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                // Remove item
                                let newArr = [];
                                for (let i = 0; i < UserConfig.dropzoneItems.length; i++) {
                                    if (i !== index) newArr.push(UserConfig.dropzoneItems[i]);
                                }
                                UserConfig.dropzoneItems = newArr;
                            } else {
                                // Click to copy
                                let copyData = isFile ? dataStr.replace("file://", "") : dataStr;
                                copyProcess.exec(["wl-copy", copyData]);
                                
                                // Auto-remove on copy (as requested for 'tidy' but user said 'autoclean on restart')
                                // Wait, the user said "autoclean on system restart". That means they DON'T want auto-remove on copy.
                                // We will leave it in the list!
                                
                                // Show copied feedback (change text briefly)
                                let oldText = displayStr;
                                itemText.text = "Copied!";
                                itemText.color = "#a6e3a1";
                                
                                Qt.callLater(() => {
                                    setTimeout(() => {
                                        itemText.text = oldText;
                                        itemText.color = "#a6adc8";
                                    }, 1000);
                                });
                            }
                        }
                    }
                }
            }
        }
    }
    
    // JS setTimeout polyfill for QML
    Timer {
        id: delayTimer
        property var cb
        repeat: false
        onTriggered: { if (cb) cb(); }
    }
    function setTimeout(cb, delay) {
        delayTimer.cb = cb;
        delayTimer.interval = delay;
        delayTimer.start();
    }
}
