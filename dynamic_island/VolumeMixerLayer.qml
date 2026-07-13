import QtQuick
import QtQuick.Controls
import Quickshell.Io

Item {
    id: volumeMixerLayer

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
            mixerPoller.restart();
            mixerFetcher.exec(["python3", "/home/cipheroot/.config/quickshell/dynamic_island/bin/get_volume_mixer.py"]);
        } else {
            mixerPoller.stop();
        }
    }

    Timer {
        id: mixerPoller
        interval: 2000
        repeat: true
        onTriggered: {
            if (!mixerFetcher.running) {
                mixerFetcher.exec(["python3", "/home/cipheroot/.config/quickshell/dynamic_island/bin/get_volume_mixer.py"]);
            }
        }
    }

    Process {
        id: mixerFetcher
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    if (text.trim() === "") return;
                    var apps = JSON.parse(text);
                    
                    // Simple sync (clear and add for now, to avoid complex diffing)
                    // If a user is dragging a slider, we shouldn't update its value and ruin their drag.
                    // For simplicity, we just rebuild the model if lengths differ or IDs mismatch.
                    // A proper implementation would update existing items, but this works for a quick mixer.
                    var rebuild = apps.length !== mixerModel.count;
                    if (!rebuild) {
                        for (var i = 0; i < apps.length; i++) {
                            if (mixerModel.get(i).id !== apps[i].id) {
                                rebuild = true;
                                break;
                            }
                        }
                    }
                    
                    if (rebuild) {
                        mixerModel.clear();
                        for (var j = 0; j < apps.length; j++) {
                            mixerModel.append(apps[j]);
                        }
                    } else {
                        // Just update volumes if not dragging
                        for (var k = 0; k < apps.length; k++) {
                            if (Math.abs(mixerModel.get(k).volume - apps[k].volume) > 2) {
                                mixerModel.setProperty(k, "volume", apps[k].volume);
                            }
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: volumeSetter
    }

    ListModel {
        id: mixerModel
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
            text: "Volume Mixer"
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
                model: mixerModel
                spacing: 12

                delegate: Item {
                    width: listView.width
                    height: 50

                    Text {
                        id: appNameText
                        anchors.top: parent.top
                        anchors.left: parent.left
                        text: model.name
                        color: textColor
                        font.family: textFontFamily
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        text: Math.round(model.volume) + "%"
                        color: textColor
                        font.family: textFontFamily
                        font.pixelSize: 12
                        opacity: 0.7
                    }

                    Slider {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 20
                        from: 0
                        to: 100
                        value: model.volume
                        
                        onValueChanged: {
                            if (pressed) {
                                mixerModel.setProperty(index, "volume", value);
                                if (!volumeSetter.running) {
                                    volumeSetter.exec(["pactl", "set-sink-input-volume", model.id, Math.round(value) + "%"]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
