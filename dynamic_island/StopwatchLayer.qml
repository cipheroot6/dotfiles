import QtQuick

Item {
    id: sw
    anchors.fill: parent

    property string textFontFamily: "JetBrainsMono Nerd Font"
    property string heroFontFamily: "JetBrainsMono Nerd Font"
    property bool   showCondition: false

    // expose for persistent ring
    property bool   isRunning:    false
    property real   ringProgress: (elapsedMs % 60000) / 60000
    property string timeString:   fmt(elapsedMs)
    property int    elapsedMs:    0
    property int    lapCount:     0

    // lap times list (stores split times)
    property var lapTimes: []
    property int lastLapMs: 0

    readonly property color cMauve:   "#cba6f7"
    readonly property color cGreen:   "#a6e3a1"
    readonly property color cRingBg:  "#242437"
    readonly property color cText:    "#cdd6f4"
    readonly property color cSub:     "#a6adc8"
    readonly property color cOverlay: "#585b70"
    readonly property color cSurface: "#1e1e2e"
    readonly property color cBase:    "#181825"

    function fmt(ms) {
        const h  = Math.floor(ms / 3600000)
        const m  = Math.floor((ms % 3600000) / 60000)
        const s  = Math.floor((ms % 60000) / 1000)
        const mm = (m < 10 ? "0" : "") + m
        const ss = (s < 10 ? "0" : "") + s
        return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss
    }

    function fmtMs(ms) {
        if (ms < 10000) {
            const s  = Math.floor(ms / 1000)
            const ds = Math.floor((ms % 1000) / 100)
            return s + "." + ds + "s"
        }
        return fmt(ms)
    }

    function doLap() {
        if (!sw.isRunning) return
        const split = sw.elapsedMs - sw.lastLapMs
        sw.lastLapMs = sw.elapsedMs
        sw.lapCount++
        const times = sw.lapTimes.slice()
        times.unshift({ n: sw.lapCount, t: fmt(split) })
        if (times.length > 3) times.pop()
        sw.lapTimes = times
    }

    Timer {
        interval: 37
        repeat: true
        running: sw.isRunning
        onTriggered: sw.elapsedMs += interval
    }

    opacity: showCondition ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

    // Outer padding
    Item {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 10; bottomMargin: 10 }

        // ── LEFT: ring ────────────────────────────────────────────────────────
        Item {
            id: leftPanel
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 90

            // glow behind ring when running
            Rectangle {
                anchors.centerIn: parent
                width: 86; height: 86; radius: 43
                color: sw.cMauve
                opacity: sw.isRunning ? 0.08 : 0.0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            }

            // background ring
            Canvas {
                id: bgRing
                anchors.centerIn: parent; width: 84; height: 84; antialiasing: true
                Component.onCompleted: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"), cx = width/2, cy = height/2, r = cx - 5
                    ctx.clearRect(0, 0, width, height)
                    ctx.lineWidth = 4; ctx.strokeStyle = sw.cRingBg
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke()
                }
            }

            // progress ring
            Canvas {
                anchors.centerIn: parent; width: 84; height: 84; antialiasing: true
                property real  p: sw.ringProgress
                property color c: sw.isRunning ? sw.cMauve : "#45475a"
                onPChanged: requestPaint()
                onCChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"), cx = width/2, cy = height/2, r = cx - 5
                    const s = -Math.PI/2, e = s + Math.PI*2 * Math.max(0, Math.min(1, p))
                    ctx.clearRect(0, 0, width, height)
                    if (p <= 0) return
                    ctx.lineWidth = 4; ctx.lineCap = "round"
                    ctx.strokeStyle = c
                    ctx.beginPath(); ctx.arc(cx, cy, r, s, e, false); ctx.stroke()
                }
            }

            // Hover handler for interactive overlay
            HoverHandler {
                id: ringHover
            }

            // ring inner: show sub-second precision when small, else MM:SS
            Text {
                id: ringTime
                anchors.centerIn: parent
                text: sw.elapsedMs < 10000 && sw.elapsedMs > 0 ? sw.fmtMs(sw.elapsedMs) : sw.timeString
                color: sw.isRunning ? sw.cMauve : sw.cSub
                font.pixelSize: 11; font.family: sw.textFontFamily; font.weight: Font.Bold
                opacity: ringHover.hovered ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // ring inner hover icon
            Text {
                id: ringIcon
                anchors.centerIn: parent
                text: sw.isRunning ? "" : ""
                color: sw.cMauve
                font.pixelSize: 14; font.family: sw.textFontFamily
                opacity: ringHover.hovered ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // pulse dot
            Rectangle {
                width: 6; height: 6; radius: 3; color: sw.cMauve
                anchors { bottom: bgRing.bottom; right: bgRing.right; bottomMargin: 4; rightMargin: 4 }
                visible: sw.isRunning
                SequentialAnimation on opacity {
                    running: sw.isRunning; loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            // tap = start/stop, hold = reset
            TapHandler { onTapped: sw.isRunning = !sw.isRunning }
            TapHandler {
                longPressThreshold: 0.55
                onLongPressed: {
                    sw.isRunning = false
                    sw.elapsedMs = 0
                    sw.lapCount  = 0
                    sw.lastLapMs = 0
                    sw.lapTimes  = []
                }
            }
        }

        // soft divider
        Rectangle {
            anchors { left: leftPanel.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
            width: 1; height: parent.height * 0.6
            color: sw.cRingBg
            opacity: 0.6
        }

        // ── RIGHT: time + status + lap list + buttons ─────────────────────────
        Item {
            anchors { left: leftPanel.right; leftMargin: 24; right: parent.right; top: parent.top; bottom: parent.bottom }

            // big time display (monospace to prevent wiggling/jitter)
            Text {
                id: bigTime
                anchors { top: parent.top; topMargin: 0; left: parent.left }
                text: sw.timeString
                color: sw.cText
                font.pixelSize: 34; font.family: sw.textFontFamily; font.weight: Font.Bold; font.letterSpacing: -0.5
            }

            // status row
            Row {
                id: statusRow
                anchors { top: bigTime.bottom; topMargin: 2; left: parent.left }
                spacing: 6

                Rectangle {
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: sw.isRunning ? sw.cMauve : (sw.elapsedMs > 0 ? "#45475a" : sw.cOverlay)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    SequentialAnimation on opacity {
                        running: sw.isRunning; loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 600; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    text: sw.isRunning ? "RUNNING" : (sw.elapsedMs > 0 ? "PAUSED" : "READY")
                    color: sw.isRunning ? sw.cMauve : sw.cOverlay
                    font.pixelSize: 9; font.family: sw.textFontFamily; font.weight: Font.Bold; font.letterSpacing: 0.5
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // lap badge
                Rectangle {
                    visible: sw.lapCount > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: lapBadgeText.width + 10; height: 14; radius: 7
                    color: Qt.rgba(203/255, 166/255, 247/255, 0.12)
                    Text {
                        id: lapBadgeText
                        anchors.centerIn: parent
                        text: sw.lapCount + (sw.lapCount === 1 ? " LAP" : " LAPS")
                        color: sw.cMauve; font.pixelSize: 8; font.family: sw.textFontFamily; font.weight: Font.Bold
                    }
                }
            }

            // lap times mini-list (last 3, newest on top)
            Column {
                anchors { top: statusRow.bottom; topMargin: 6; left: parent.left }
                spacing: 3
                visible: sw.lapTimes.length > 0

                Repeater {
                    model: sw.lapTimes
                    delegate: Row {
                        spacing: 8
                        Rectangle {
                            width: 22; height: 13; radius: 4
                            color: Qt.rgba(203/255, 166/255, 247/255, 0.15)
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: "L" + modelData.n
                                color: sw.cMauve; font.pixelSize: 8; font.family: sw.textFontFamily; font.weight: Font.Bold
                            }
                        }
                        Text {
                            text: modelData.t
                            color: index === 0 ? sw.cText : sw.cOverlay
                            font.pixelSize: 10; font.family: sw.textFontFamily; font.weight: index === 0 ? Font.Bold : Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // buttons row
            Row {
                anchors { bottom: parent.bottom; bottomMargin: 2; right: parent.right }
                spacing: 8

                // LAP button
                Rectangle {
                    id: lapBtn
                    width: 58; height: 26; radius: 13
                    color: {
                        if (!sw.isRunning) return Qt.rgba(255,255,255,0.02)
                        return lapHover.hovered
                            ? Qt.rgba(203/255,166/255,247/255, 0.22)
                            : Qt.rgba(203/255,166/255,247/255, 0.12)
                    }
                    border.color: sw.isRunning ? (lapHover.hovered ? sw.cMauve : Qt.rgba(203/255,166/255,247/255,0.3)) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    scale: lapTA.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰝗 LAP"
                        color: sw.isRunning ? sw.cMauve : sw.cOverlay
                        font.pixelSize: 9; font.family: sw.textFontFamily; font.weight: Font.Bold; font.letterSpacing: 0.5
                    }
                    HoverHandler { id: lapHover; enabled: sw.isRunning }
                    TapHandler  { id: lapTA; enabled: sw.isRunning; onTapped: sw.doLap() }
                }

                // RESET button
                Rectangle {
                    id: resetBtn
                    width: 68; height: 26; radius: 13
                    color: {
                        if (sw.elapsedMs <= 0) return Qt.rgba(255,255,255,0.02)
                        return resetHover.hovered
                            ? Qt.rgba(255,255,255,0.12)
                            : Qt.rgba(255,255,255,0.06)
                    }
                    border.color: sw.elapsedMs > 0 ? (resetHover.hovered ? sw.cSub : Qt.rgba(255,255,255,0.1)) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    scale: resetTA.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑓 RESET"
                        color: sw.elapsedMs > 0 ? sw.cText : sw.cOverlay
                        font.pixelSize: 9; font.family: sw.textFontFamily; font.weight: Font.Bold; font.letterSpacing: 0.5
                    }
                    HoverHandler { id: resetHover; enabled: sw.elapsedMs > 0 }
                    TapHandler  {
                        id: resetTA; enabled: sw.elapsedMs > 0
                        onTapped: {
                            sw.isRunning = false
                            sw.elapsedMs = 0
                            sw.lapCount  = 0
                            sw.lastLapMs = 0
                            sw.lapTimes  = []
                        }
                    }
                }
            }
        }
    }
}
