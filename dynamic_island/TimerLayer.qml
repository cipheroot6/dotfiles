import QtQuick
import Quickshell.Io

Item {
    id: tl
    anchors.fill: parent

    property string textFontFamily: "JetBrainsMono Nerd Font"
    property string heroFontFamily: "JetBrainsMono Nerd Font"
    property bool   showCondition: false

    // expose for persistent ring
    property bool   running:       false
    property bool   finished:      false
    property bool   timerFinished: finished
    property real   ringProgress:  durationMs > 0 ? Math.max(0, remainingMs / durationMs) : 0
    property string timeString:    fmt(remainingMs)
    property int    durationMs:    0
    property int    remainingMs:   0
    property bool   inputMode:     true

    // digit accumulator for on-screen numpad
    property string digits: ""  // up to 6 digits e.g. "500" = 5:00

    readonly property color cMauve:   "#cba6f7"
    readonly property color cRed:     "#f38ba8"
    readonly property color cRingBg:  "#242437"
    readonly property color cSurface: "#1e1e2e"
    readonly property color cText:    "#cdd6f4"
    readonly property color cSub:     "#a6adc8"
    readonly property color cOverlay: "#585b70"
    readonly property color cActive:  finished ? cRed : cMauve

    function fmt(ms) {
        const h = Math.floor(ms/3600000), m = Math.floor((ms%3600000)/60000), s = Math.floor((ms%60000)/1000)
        const mm = (m<10?"0":"")+m, ss = (s<10?"0":"")+s
        return h > 0 ? h+":"+mm+":"+ss : mm+":"+ss
    }

    function digitsToMs(d) {
        const p = d.padStart(6,"0")
        return (parseInt(p.slice(0,2))*3600 + parseInt(p.slice(2,4))*60 + parseInt(p.slice(4,6)))*1000
    }

    function digitsPreviewRich(d) {
        const p = d.padStart(6,"0")
        const h = p.slice(0,2)
        const m = p.slice(2,4)
        const s = p.slice(4,6)

        const colorMuted = "#45475a"
        const colorActive = tl.cMauve

        let firstActiveIndex = 6 - d.length
        if (d.length === 0) firstActiveIndex = 6

        function formatPart(val, startIdx) {
            let result = ""
            for (let i = 0; i < val.length; i++) {
                let globalIdx = startIdx + i
                let color = globalIdx >= firstActiveIndex ? colorActive : colorMuted
                result += "<font color='" + color + "'>" + val[i] + "</font>"
            }
            return result
        }

        let hStr = formatPart(h, 0)
        let mStr = formatPart(m, 2)
        let sStr = formatPart(s, 4)

        let sepMuted = "<font color='" + colorMuted + "'>:</font>"
        let sepActive = "<font color='" + colorActive + "'>:</font>"

        let sep1 = firstActiveIndex <= 2 ? sepActive : sepMuted
        let sep2 = firstActiveIndex <= 4 ? sepActive : sepMuted

        return hStr + sep1 + mStr + sep2 + sStr
    }

    function pushDigit(n) {
        if (digits.length >= 6) return
        digits = digits + n
    }

    function popDigit() {
        if (digits.length > 0) digits = digits.slice(0,-1)
    }

    // Start timer and return remaining time
    function startTimer() {
        const ms = digitsToMs(digits)
        if (ms <= 0) return
        durationMs = ms; remainingMs = ms; inputMode = false; running = true; digits = ""
    }

    Process { id: notifier }
    Process { id: soundPlayer }
    Timer {
        interval: 100; repeat: true; running: tl.running && tl.remainingMs > 0
        onTriggered: {
            tl.remainingMs = Math.max(0, tl.remainingMs - interval)
            if (tl.remainingMs <= 0) {
                tl.running = false; tl.finished = true
                finishPulse.start(); finishReset.start()
                notifier.exec(["notify-send", "-u", "critical", "-t", "0", "Timer", "Time's up! ⏰"])
                soundPlayer.exec(["sh", "-c", "pw-play /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga || paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga || canberra-gtk-play -i alarm-clock-elapsed"])
                islandContainer.showTimer()
            }
        }
    }
    Timer { id: finishReset; interval: 15000; onTriggered: tl.finished = false }

    property real pulseOp: 0
    SequentialAnimation {
        id: finishPulse; loops: 3
        NumberAnimation { target: tl; property: "pulseOp"; to: 1.0; duration: 180 }
        NumberAnimation { target: tl; property: "pulseOp"; to: 0.0; duration: 180 }
    }
    Rectangle { anchors.fill: parent; color: tl.cRed; opacity: tl.pulseOp * 0.18; radius: parent.height/2 }

    opacity: showCondition ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

    // ── INPUT MODE ────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors { leftMargin: 16; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
        visible: tl.inputMode

        // LEFT: preview + hint + presets
        Item {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width - numpadArea.width - 16

            // time preview
            Row {
                id: previewRow
                anchors { top: parent.top; topMargin: 10; left: parent.left }
                spacing: 2

                Text {
                    id: previewText
                    text: tl.digitsPreviewRich(tl.digits)
                    color: tl.cText
                    textFormat: Text.RichText
                    font.pixelSize: 34; font.family: tl.textFontFamily; font.weight: Font.Bold; font.letterSpacing: -0.5
                }

                // blinking cursor
                Rectangle {
                    width: 2; height: 26; radius: 1
                    anchors.verticalCenter: previewText.verticalCenter
                    color: tl.cMauve
                    visible: tl.digits.length > 0 && tl.digits.length < 6
                    SequentialAnimation on opacity {
                        running: tl.digits.length > 0 && tl.digits.length < 6
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.0; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 100 }
                        PauseAnimation  { duration: 400 }
                    }
                }
            }

            Text {
                anchors { top: previewRow.bottom; topMargin: 4; left: parent.left }
                text: tl.digits.length > 0 ? "HH:MM:SS FORMAT" : "TAP NUMBERS →"
                color: tl.cOverlay; font.pixelSize: 9; font.family: tl.textFontFamily; font.weight: Font.Bold; font.letterSpacing: 0.5
            }

            // preset chips
            Row {
                anchors { bottom: parent.bottom; bottomMargin: 4; left: parent.left }
                spacing: 6

                Repeater {
                    model: [["5m", 300000], ["25m", 1500000], ["1h", 3600000]]
                    delegate: Rectangle {
                        required property var modelData
                        width: presetLabel.width + 16; height: 24; radius: 12
                        color: presetHover.hovered
                            ? Qt.rgba(203/255,166/255,247/255, 0.22)
                            : Qt.rgba(255,255,255,0.04)
                        border.color: presetHover.hovered ? tl.cMauve : Qt.rgba(255,255,255,0.06)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        scale: presetTA.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 70 } }

                        Text {
                            id: presetLabel
                            anchors.centerIn: parent; text: modelData[0]
                            color: presetHover.hovered ? tl.cMauve : tl.cSub
                            font.pixelSize: 10; font.family: tl.textFontFamily; font.weight: Font.Bold
                        }
                        HoverHandler { id: presetHover }
                        TapHandler  {
                            id: presetTA
                            onTapped: {
                                tl.durationMs  = modelData[1]
                                tl.remainingMs = modelData[1]
                                tl.inputMode   = false
                                tl.running     = true
                                tl.digits      = ""
                            }
                        }
                    }
                }
            }
        }

        // RIGHT: numpad
        Item {
            id: numpadArea
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 122

            Grid {
                anchors.centerIn: parent
                columns: 3; rowSpacing: 5; columnSpacing: 5

                Repeater {
                    model: ["1","2","3","4","5","6","7","8","9","󰁮","0",""]
                    delegate: Rectangle {
                        required property string modelData
                        required property int    index

                        readonly property bool isStart: modelData === ""
                        readonly property bool isBack:  modelData === "󰁮"
                        readonly property bool isDigit: !isStart && !isBack

                        readonly property bool canStart: isStart && tl.digits.length > 0 && tl.digitsToMs(tl.digits) > 0

                        width: 36; height: 26; radius: 9

                        color: {
                            if (isStart) return canStart
                                ? (numH.hovered ? Qt.rgba(203/255,166/255,247/255,0.40) : Qt.rgba(203/255,166/255,247/255,0.24))
                                : Qt.rgba(255,255,255,0.02)
                            return numH.hovered
                                ? Qt.rgba(255,255,255,0.08)
                                : Qt.rgba(255,255,255,0.03)
                        }
                        border.color: isStart
                            ? (canStart ? tl.cMauve : "transparent")
                            : (numH.hovered ? Qt.rgba(203/255,166/255,247/255,0.3) : Qt.rgba(255,255,255,0.06))
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        scale: numTA.pressed ? 0.88 : 1.0
                        Behavior on scale { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: {
                                if (parent.isStart) return parent.canStart ? tl.cMauve : tl.cOverlay
                                if (parent.isBack)  return tl.cSub
                                return numH.hovered ? tl.cMauve : tl.cText
                            }
                            font.pixelSize: parent.isStart ? 14 : 12
                            font.family: tl.textFontFamily; font.weight: Font.Bold
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        HoverHandler { id: numH }
                        TapHandler  {
                            id: numTA
                            onTapped: {
                                if (parent.isStart) { tl.startTimer(); return }
                                if (parent.isBack)  { tl.popDigit();  return }
                                tl.pushDigit(parent.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── RUNNING MODE ──────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors { leftMargin: 16; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
        visible: !tl.inputMode

        // LEFT: ring
        Item {
            id: ringPanel
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 90

            // glow when active
            Rectangle {
                anchors.centerIn: parent
                width: 86; height: 86; radius: 43
                color: tl.cActive
                opacity: tl.running ? 0.08 : (tl.finished ? 0.15 : 0.0)
                Behavior on opacity { NumberAnimation { duration: 350 } }
                Behavior on color   { ColorAnimation  { duration: 300 } }
            }

            Canvas {
                id: tmBg; anchors.centerIn: parent; width: 84; height: 84; antialiasing: true
                Component.onCompleted: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"), cx = width/2, cy = height/2, r = cx-5
                    ctx.clearRect(0, 0, width, height); ctx.lineWidth = 4; ctx.strokeStyle = tl.cRingBg
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke()
                }
            }
            Canvas {
                anchors.centerIn: parent; width: 84; height: 84; antialiasing: true
                property real  p: tl.ringProgress
                property color c: tl.cActive
                onPChanged: requestPaint(); onCChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"), cx = width/2, cy = height/2, r = cx-5
                    const s = -Math.PI/2, e = s + Math.PI*2 * Math.max(0, Math.min(1, p))
                    ctx.clearRect(0, 0, width, height); if (p <= 0) return
                    ctx.lineWidth = 4; ctx.lineCap = "round"; ctx.strokeStyle = c
                    ctx.beginPath(); ctx.arc(cx, cy, r, s, e, false); ctx.stroke()
                }
            }

            HoverHandler {
                id: runRingHover
            }

            Text {
                id: runRingTime
                anchors.centerIn: parent
                text: tl.timeString; color: tl.cActive
                font.pixelSize: 11; font.family: tl.heroFontFamily; font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                opacity: runRingHover.hovered ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Text {
                id: runRingIcon
                anchors.centerIn: parent
                text: tl.running ? "" : ""
                color: tl.cActive
                font.pixelSize: 14; font.family: tl.textFontFamily
                opacity: runRingHover.hovered ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Rectangle {
                width: 6; height: 6; radius: 3; color: tl.cActive
                anchors { bottom: tmBg.bottom; right: tmBg.right; bottomMargin: 4; rightMargin: 4 }
                visible: tl.running
                SequentialAnimation on opacity {
                    running: tl.running; loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                }
            }
            TapHandler {
                onTapped: {
                    if (tl.finished) { tl.finished = false; tl.remainingMs = tl.durationMs; return }
                    tl.running = !tl.running
                }
            }
            TapHandler {
                longPressThreshold: 0.5
                onLongPressed: { tl.running = false; tl.finished = false; tl.inputMode = true; tl.durationMs = 0 }
            }
        }

        // soft divider
        Rectangle {
            anchors { left: ringPanel.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
            width: 1; height: parent.height * 0.6
            color: tl.cRingBg; opacity: 0.6
        }

        // RIGHT
        Item {
            anchors { left: ringPanel.right; leftMargin: 24; right: parent.right; top: parent.top; bottom: parent.bottom }

            Text {
                id: runTime
                anchors { top: parent.top; topMargin: 0; left: parent.left }
                text: tl.timeString
                color: tl.finished ? tl.cRed : tl.cText
                font.pixelSize: 34; font.family: tl.heroFontFamily; font.weight: Font.Bold; font.letterSpacing: -0.5
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // status row
            Row {
                anchors { top: runTime.bottom; topMargin: 2; left: parent.left }
                spacing: 6

                Rectangle {
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: tl.finished ? tl.cRed : (tl.running ? tl.cMauve : "#45475a")
                    Behavior on color { ColorAnimation { duration: 200 } }
                    SequentialAnimation on opacity {
                        running: tl.running && !tl.finished; loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 600; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    text: tl.finished ? "TIME'S UP!" : (tl.running ? "RUNNING" : "PAUSED")
                    color: tl.finished ? tl.cRed : (tl.running ? tl.cMauve : tl.cOverlay)
                    font.pixelSize: 9; font.family: tl.textFontFamily; font.weight: Font.Bold; font.letterSpacing: 0.5
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // buttons row
            Row {
                anchors { bottom: parent.bottom; bottomMargin: 2; right: parent.right }
                spacing: 8

                // +1m quick-add
                Rectangle {
                    id: addMinBtn
                    visible: !tl.finished
                    width: 48; height: 26; radius: 13
                    color: addHover.hovered ? Qt.rgba(166/255,227/255,161/255,0.22) : Qt.rgba(255,255,255,0.04)
                    border.color: addHover.hovered ? "#a6e3a1" : Qt.rgba(255,255,255,0.06)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    scale: addTA.pressed ? 0.91 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent; text: "+1M"
                        color: addHover.hovered ? "#a6e3a1" : tl.cSub
                        font.pixelSize: 9; font.family: tl.textFontFamily; font.weight: Font.Bold; font.letterSpacing: 0.5
                    }
                    HoverHandler { id: addHover }
                    TapHandler  { id: addTA; onTapped: tl.remainingMs = Math.min(tl.remainingMs + 60000, 5999000) }
                }

                // RESET button
                Rectangle {
                    id: runResetBtn
                    width: 68; height: 26; radius: 13
                    color: runResetHover.hovered ? Qt.rgba(255,255,255,0.12) : Qt.rgba(255,255,255,0.06)
                    border.color: runResetHover.hovered ? tl.cSub : Qt.rgba(255,255,255,0.1)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    scale: runResetTA.pressed ? 0.91 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent; text: "󰑓 RESET"
                        color: tl.cSub; font.pixelSize: 9; font.family: tl.textFontFamily; font.weight: Font.Bold; font.letterSpacing: 0.5
                    }
                    HoverHandler { id: runResetHover }
                    TapHandler  {
                        id: runResetTA
                        onTapped: { tl.running = false; tl.finished = false; tl.inputMode = true; tl.durationMs = 0 }
                    }
                }
            }
        }
    }
}
