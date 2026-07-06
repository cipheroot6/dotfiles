import QtQuick
import Quickshell.Io

Item {
    id: pm
    anchors.fill: parent

    property string textFontFamily: "JetBrainsMono Nerd Font"
    property string heroFontFamily: "JetBrainsMono Nerd Font"
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property bool   showCondition:  false

    readonly property color clrMauve:   "#cba6f7"
    readonly property color clrGreen:   "#a6e3a1"
    readonly property color clrRingBg:  "#313244"
    readonly property color clrText:    "#cdd6f4"
    readonly property color clrSub:     "#a6adc8"
    readonly property color clrOverlay: "#6c7086"

    readonly property int workMs:  25 * 60 * 1000
    readonly property int breakMs:  5 * 60 * 1000

    property bool active:       false
    property bool running:      false
    property bool onBreak:      false
    property int  sessionCount: 0
    property int  remainingMs:  workMs

    readonly property color accentColor: onBreak ? clrGreen : clrMauve
    readonly property string edgeIcon:   onBreak ? "󰖲" : ""
    readonly property real ringProgress: {
        const total = onBreak ? breakMs : workMs
        return total > 0 ? Math.max(0, remainingMs / total) : 0
    }
    readonly property string timeString: {
        const m = Math.floor(remainingMs / 60000)
        const s = Math.floor((remainingMs % 60000) / 1000)
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    Process { id: sessionNotifier }
    Process { id: soundPlayer }

    Timer {
        interval: 500; repeat: true; running: pm.running && pm.active
        onTriggered: {
            pm.remainingMs = Math.max(0, pm.remainingMs - interval)
            if (pm.remainingMs <= 0) pm.onSessionEnd()
        }
    }

    function onSessionEnd() {
        running = false
        sessionPulse.start()
        if (!onBreak) {
            sessionCount = Math.min(sessionCount + 1, 4)
            onBreak     = true
            remainingMs = breakMs
        } else {
            onBreak     = false
            remainingMs = workMs
            if (sessionCount >= 4) sessionCount = 0
        }
        running = true
        sessionNotifier.exec(["notify-send", "-u", "critical", "-t", "0", onBreak ? "Break time! 🍃" : "Focus time! 🍅",
            onBreak ? "5 minute break" : "25 minute session"])
        soundPlayer.exec(["sh", "-c", "pw-play /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga || paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga || canberra-gtk-play -i alarm-clock-elapsed"])
        islandContainer.showPomodoro()
    }

    function toggle() {
        if (!active) {
            active = true; running = true
            onBreak = false; remainingMs = workMs; sessionCount = 0
        } else {
            running = !running
        }
    }

    function stop() {
        active = false; running = false; onBreak = false
        remainingMs = workMs; sessionCount = 0
    }

    property real pulseOpacity: 0
    SequentialAnimation {
        id: sessionPulse; loops: 3
        NumberAnimation { target: pm; property: "pulseOpacity"; to: 1.0; duration: 180 }
        NumberAnimation { target: pm; property: "pulseOpacity"; to: 0.0; duration: 180 }
    }
    Rectangle {
        anchors.fill: parent; color: pm.accentColor; opacity: pm.pulseOpacity * 0.2
        radius: parent.height / 2
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    opacity: showCondition ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    // ── Full-width layout ─────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.leftMargin:   14
        anchors.rightMargin:  14
        anchors.topMargin:    8
        anchors.bottomMargin: 8

        // ring (left)
        Item {
            id: pmRingArea
            anchors.left: parent.left
            anchors.top:  parent.top
            anchors.bottom: parent.bottom
            width: 72

            Canvas {
                anchors.centerIn: parent; width:68; height:68; antialiasing:true
                Component.onCompleted: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    const cx = width/2, cy = height/2, r = cx - 5
                    ctx.clearRect(0,0,width,height)
                    ctx.lineWidth = 5; ctx.strokeStyle = pm.clrRingBg
                    ctx.beginPath(); ctx.arc(cx,cy,r,0,Math.PI*2); ctx.stroke()
                }
            }
            Canvas {
                anchors.centerIn: parent; width:68; height:68; antialiasing:true
                property real  prog: pm.ringProgress
                property color col:  pm.accentColor
                onProgChanged: requestPaint(); onColChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    const cx = width/2, cy = height/2, r = cx - 5
                    const s = -Math.PI/2, e = s + Math.PI*2*Math.max(0,Math.min(1,prog))
                    ctx.clearRect(0,0,width,height)
                    if (prog <= 0) return
                    ctx.lineWidth = 5; ctx.lineCap = "round"; ctx.strokeStyle = col
                    ctx.beginPath(); ctx.arc(cx,cy,r,s,e,false); ctx.stroke()
                }
            }
            Text {
                anchors.centerIn: parent
                text: pm.active ? pm.timeString : "25:00"
                color: pm.accentColor
                font.pixelSize: 11; font.family: pm.heroFontFamily; font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Rectangle {
                width: 7; height: 7; radius: 4; color: pm.accentColor
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.bottomMargin: 4; anchors.rightMargin: 4
                visible: pm.running
                Behavior on color { ColorAnimation { duration: 300 } }
                SequentialAnimation on opacity {
                    running: pm.running; loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                }
            }
            TapHandler { onTapped: pm.toggle() }
            TapHandler { longPressThreshold: 0.6; onLongPressed: pm.stop() }
        }

        // right side
        Item {
            anchors.left:   pmRingArea.right
            anchors.leftMargin: 12
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            // session label + time
            Text {
                id: pmBigTime
                anchors.top: parent.top; anchors.topMargin: 2
                text: pm.active ? pm.timeString : "25:00"
                color: pm.clrText
                font.pixelSize: 28; font.family: pm.heroFontFamily; font.weight: Font.Bold
                font.letterSpacing: -0.5
            }

            Row {
                anchors.top: pmBigTime.bottom; anchors.topMargin: 2
                spacing: 6

                Text {
                    text: pm.active ? (pm.onBreak ? "break" : "focus") : "pomodoro"
                    color: pm.active ? pm.accentColor : pm.clrOverlay
                    font.pixelSize: 10; font.family: pm.textFontFamily; font.weight: Font.Bold
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // session dots
                Row {
                    spacing: 4; visible: pm.active
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            width: 6; height: 6; radius: 3
                            color: index < pm.sessionCount ? pm.clrGreen : pm.clrRingBg
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                spacing: 8

                Rectangle {
                    width: 62; height: 22; radius: 11
                    color: Qt.rgba(1,1,1,0.07)
                    visible: pm.active
                    Text {
                        anchors.centerIn: parent; text: "STOP"
                        color: pm.clrSub
                        font.pixelSize: 10; font.family: pm.textFontFamily; font.weight: Font.Bold
                    }
                    TapHandler { onTapped: pm.stop() }
                }

                Rectangle {
                    width: 62; height: 22; radius: 11
                    color: !pm.active ? Qt.rgba(203/255,166/255,247/255,0.15) : Qt.rgba(1,1,1,0.07)
                    Text {
                        anchors.centerIn: parent
                        text: !pm.active ? "START" : (pm.running ? "PAUSE" : "RESUME")
                        color: !pm.active ? pm.clrMauve : pm.clrSub
                        font.pixelSize: 10; font.family: pm.textFontFamily; font.weight: Font.Bold
                    }
                    TapHandler { onTapped: pm.toggle() }
                }
            }
        }
    }
}
