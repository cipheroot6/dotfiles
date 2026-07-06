import QtQuick

Item {
    id: clockLayer

    UserConfig { id: userConfig }

    property string currentTime:      "00:00"
    property string heroFontFamily:   userConfig.heroFontFamily
    property bool   showCondition:    false
    property real   contentOffsetX:   0
    property int    textPixelSize:    18

    // persistent indicator props
    property bool   stopwatchRunning:      false
    property string stopwatchTime:         ""
    property real   stopwatchRingProgress: 0.0
    property bool   timerRunning:          false
    property bool   timerFinished:         false
    property string timerTime:             ""
    property real   timerProgress:         1.0

    readonly property color clrMauve:  "#cba6f7"
    readonly property color clrRed:    "#f38ba8"
    readonly property color clrRingBg: "#313244"
    readonly property bool  showRing:  stopwatchRunning || timerRunning || timerFinished
    readonly property bool  isTimer:   timerRunning || timerFinished
    readonly property color ringColor: timerFinished ? clrRed : clrMauve
    readonly property real  ringProg:  isTimer ? timerProgress : stopwatchRingProgress
    readonly property string ringTime: isTimer ? timerTime : stopwatchTime
    readonly property real preferredWidth: showRing ? 210 : 140

    anchors.fill: parent
    opacity: showCondition ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: showCondition ? 300 : 200; easing.type: Easing.InOutQuad }
    }

    Item {
        anchors.fill: parent
        x: contentOffsetX
        clip: true

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: clockLayer.currentTime
                color: "white"
                font.pixelSize: clockLayer.textPixelSize
                font.family:    clockLayer.heroFontFamily
                font.weight:    Font.Bold
                font.letterSpacing: -0.35
                wrapMode: Text.NoWrap
            }

            Item {
                width:  38
                height: 38
                anchors.verticalCenter: parent.verticalCenter
                opacity: clockLayer.showRing ? 1.0 : 0.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 280 } }

                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        const cx = width/2, cy = height/2, r = cx - 3;
                        ctx.clearRect(0, 0, width, height);
                        ctx.lineWidth = 3;
                        ctx.strokeStyle = clockLayer.clrRingBg;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI*2);
                        ctx.stroke();
                    }
                }

                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    property real  prog: clockLayer.ringProg
                    property color col:  clockLayer.ringColor
                    onProgChanged: requestPaint()
                    onColChanged:  requestPaint()
                    onPaint: {
                        const ctx   = getContext("2d");
                        const cx    = width/2, cy = height/2, r = cx - 3;
                        const start = -Math.PI/2;
                        const end   = start + Math.PI*2 * Math.max(0, Math.min(1, prog));
                        ctx.clearRect(0, 0, width, height);
                        if (prog <= 0) return;
                        ctx.lineWidth   = 3;
                        ctx.lineCap     = "round";
                        ctx.strokeStyle = col;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, end, false);
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text:           clockLayer.ringTime
                    color:          clockLayer.ringColor
                    font.pixelSize: 9
                    font.family:    clockLayer.heroFontFamily
                    font.weight:    Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Rectangle {
                    width: 5; height: 5; radius: 3
                    color: clockLayer.ringColor
                    anchors.bottom: parent.bottom
                    anchors.right:  parent.right
                    anchors.margins: 1
                    visible: clockLayer.stopwatchRunning || clockLayer.timerRunning
                    SequentialAnimation on opacity {
                        running: clockLayer.stopwatchRunning || clockLayer.timerRunning
                        loops:   Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }
}
