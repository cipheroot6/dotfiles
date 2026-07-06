import QtQuick

Item {
    id: petCat

    property bool musicPlaying: false
    property real cpuUsage: 0
    property bool notificationIn: false
    property bool pomodoroBreak: false
    property bool timerFinished: false
    readonly property string catState: {
        if (timerFinished)
            return "timerfinished";

        if (notificationIn)
            return "notification";

        if (cpuUsage > 80)
            return "highcpu";

        if (pomodoroBreak)
            return "pomodoro";

        if (musicPlaying)
            return "music";

        return "idle";
    }
    property real bobY: 0
    property real bodyTilt: 0
    property real jumpY: 0
    property real tailWag: 0
    property real spinAngle: 0
    property real glowOpacity: 0
    property real blushOp: 0
    property bool eyesClosed: false
    property bool eyesWide: false
    readonly property color accentColor: {
        switch (catState) {
        case "music":
            return "#cba6f7";
        case "highcpu":
            return "#f38ba8";
        case "pomodoro":
            return "#a6e3a1";
        case "timerfinished":
            return "#fab387";
        default:
            return "#89b4fa";
        }
    }

    width: 38
    height: 56

    // IDLE - Soft breathing and gentle wagging
    SequentialAnimation {
        running: petCat.catState === "idle"
        loops: Animation.Infinite
        onStopped: petCat.bobY = 0

        NumberAnimation {
            target: petCat
            property: "bobY"
            to: 0.8
            duration: 1300
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: petCat
            property: "bobY"
            to: -0.4
            duration: 1300
            easing.type: Easing.InOutSine
        }

    }

    SequentialAnimation {
        running: petCat.catState === "idle"
        loops: Animation.Infinite
        onStopped: petCat.tailWag = 0

        NumberAnimation {
            target: petCat
            property: "tailWag"
            to: 10
            duration: 1000
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: petCat
            property: "tailWag"
            to: -10
            duration: 1000
            easing.type: Easing.InOutSine
        }

    }

    SequentialAnimation {
        running: petCat.catState === "idle" || petCat.catState === "music"
        loops: Animation.Infinite
        onStopped: petCat.eyesClosed = false

        PauseAnimation {
            duration: 3400
        }

        PropertyAction {
            target: petCat
            property: "eyesClosed"
            value: true
        }

        PauseAnimation {
            duration: 150
        }

        PropertyAction {
            target: petCat
            property: "eyesClosed"
            value: false
        }

    }

    // MUSIC - Faster dance and side tilt
    SequentialAnimation {
        running: petCat.catState === "music"
        loops: Animation.Infinite
        onStopped: petCat.bobY = 0

        NumberAnimation {
            target: petCat
            property: "bobY"
            to: 2.5
            duration: 260
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: petCat
            property: "bobY"
            to: -0.6
            duration: 260
            easing.type: Easing.InOutQuad
        }

    }

    SequentialAnimation {
        running: petCat.catState === "music"
        loops: Animation.Infinite
        onStopped: petCat.bodyTilt = 0

        NumberAnimation {
            target: petCat
            property: "bodyTilt"
            to: 6
            duration: 310
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: petCat
            property: "bodyTilt"
            to: -6
            duration: 310
            easing.type: Easing.InOutSine
        }

    }

    SequentialAnimation {
        running: petCat.catState === "music"
        loops: Animation.Infinite
        onStopped: petCat.tailWag = 0

        NumberAnimation {
            target: petCat
            property: "tailWag"
            to: 18
            duration: 240
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: petCat
            property: "tailWag"
            to: -18
            duration: 240
            easing.type: Easing.InOutQuad
        }

    }

    SequentialAnimation {
        running: petCat.catState === "music"
        loops: Animation.Infinite
        onStopped: petCat.glowOpacity = 0

        NumberAnimation {
            target: petCat
            property: "glowOpacity"
            to: 0.4
            duration: 420
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: petCat
            property: "glowOpacity"
            to: 0.08
            duration: 420
            easing.type: Easing.InOutSine
        }

    }

    NumberAnimation {
        running: petCat.catState === "music"
        target: petCat
        property: "blushOp"
        to: 0.75
        duration: 500
    }

    NumberAnimation {
        running: petCat.catState !== "music"
        target: petCat
        property: "blushOp"
        to: 0
        duration: 400
    }

    // HIGH CPU - Shaking and sweating
    SequentialAnimation {
        running: petCat.catState === "highcpu"
        loops: Animation.Infinite
        onStopped: petCat.bodyTilt = 0

        NumberAnimation {
            target: petCat
            property: "bodyTilt"
            to: 2.5
            duration: 55
        }

        NumberAnimation {
            target: petCat
            property: "bodyTilt"
            to: -2.5
            duration: 55
        }

    }

    NumberAnimation {
        running: petCat.catState === "highcpu"
        target: petCat
        property: "glowOpacity"
        to: 0.45
        duration: 150
    }

    NumberAnimation {
        running: petCat.catState !== "highcpu" && petCat.catState !== "music" && petCat.catState !== "pomodoro" && petCat.catState !== "timerfinished"
        target: petCat
        property: "glowOpacity"
        to: 0
        duration: 300
    }

    // NOTIFICATION - Jump and alert look
    SequentialAnimation {
        running: petCat.catState === "notification"
        loops: 1
        onStopped: {
            petCat.eyesWide = false;
            petCat.jumpY = 0;
        }

        PropertyAction {
            target: petCat
            property: "eyesWide"
            value: true
        }

        NumberAnimation {
            target: petCat
            property: "jumpY"
            to: -8
            duration: 110
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: petCat
            property: "jumpY"
            to: 0
            duration: 190
            easing.type: Easing.InBounce
        }

        PauseAnimation {
            duration: 800
        }

        PropertyAction {
            target: petCat
            property: "eyesWide"
            value: false
        }

    }

    // POMODORO - Deep sleep
    SequentialAnimation {
        running: petCat.catState === "pomodoro"
        loops: Animation.Infinite
        onStopped: petCat.bobY = 0

        NumberAnimation {
            target: petCat
            property: "bobY"
            to: 1
            duration: 2000
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: petCat
            property: "bobY"
            to: -0.3
            duration: 2000
            easing.type: Easing.InOutSine
        }

    }

    SequentialAnimation {
        running: petCat.catState === "pomodoro"
        loops: Animation.Infinite
        onStopped: petCat.tailWag = 0

        NumberAnimation {
            target: petCat
            property: "tailWag"
            to: 4
            duration: 1800
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: petCat
            property: "tailWag"
            to: -4
            duration: 1800
            easing.type: Easing.InOutSine
        }

    }

    SequentialAnimation {
        running: petCat.catState === "pomodoro"
        loops: Animation.Infinite
        onStopped: petCat.eyesClosed = false

        PauseAnimation {
            duration: 2000
        }

        PropertyAction {
            target: petCat
            property: "eyesClosed"
            value: true
        }

        PauseAnimation {
            duration: 1400
        }

        PropertyAction {
            target: petCat
            property: "eyesClosed"
            value: false
        }

    }

    SequentialAnimation {
        running: petCat.catState === "pomodoro"
        loops: Animation.Infinite
        onStopped: petCat.glowOpacity = 0

        NumberAnimation {
            target: petCat
            property: "glowOpacity"
            to: 0.2
            duration: 1600
        }

        NumberAnimation {
            target: petCat
            property: "glowOpacity"
            to: 0
            duration: 1600
        }

    }

    // TIMER FINISHED - Victory spin
    SequentialAnimation {
        running: petCat.catState === "timerfinished"
        loops: 2
        onStopped: petCat.jumpY = 0

        NumberAnimation {
            target: petCat
            property: "jumpY"
            to: -9
            duration: 110
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: petCat
            property: "jumpY"
            to: 0
            duration: 180
            easing.type: Easing.InBounce
        }

        PauseAnimation {
            duration: 50
        }

    }

    NumberAnimation {
        running: petCat.catState === "timerfinished"
        target: petCat
        property: "spinAngle"
        from: 0
        to: 360
        duration: 500
        onStopped: petCat.spinAngle = 0
    }

    SequentialAnimation {
        running: petCat.catState === "timerfinished"
        loops: 3
        onStopped: petCat.glowOpacity = 0

        NumberAnimation {
            target: petCat
            property: "glowOpacity"
            to: 0.85
            duration: 120
        }

        NumberAnimation {
            target: petCat
            property: "glowOpacity"
            to: 0.1
            duration: 120
        }

    }

    // Glow rings
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 14
        height: parent.height + 14
        radius: 12
        color: petCat.accentColor
        opacity: petCat.glowOpacity * 0.18
        visible: petCat.glowOpacity > 0.01

        Behavior on color {
            ColorAnimation {
                duration: 300
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }

        }

    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 5
        height: parent.height + 5
        radius: 8
        color: "transparent"
        border.color: petCat.accentColor
        border.width: 1.5
        opacity: petCat.glowOpacity * 0.55
        visible: petCat.glowOpacity > 0.01

        Behavior on border.color {
            ColorAnimation {
                duration: 300
            }

        }

    }

    // Full-body Canvas
    Canvas {
        id: canvas

        property bool ec: petCat.eyesClosed
        property bool ew: petCat.eyesWide
        property real bl: petCat.blushOp
        property color ac: petCat.accentColor
        property string cs: petCat.catState
        property real tw: petCat.tailWag

        objectName: "canvasObj"
        width: petCat.width
        height: petCat.height
        anchors.horizontalCenter: parent.horizontalCenter
        y: petCat.bobY + petCat.jumpY
        renderStrategy: Canvas.Threaded
        antialiasing: true
        onEcChanged: requestPaint()
        onEwChanged: requestPaint()
        onBlChanged: requestPaint()
        onAcChanged: requestPaint()
        onCsChanged: requestPaint()
        onTwChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.save();
            const W = width;
            const cx = W / 2;
            // Chibi White Cat Color Scheme
            const furColor = "#ffffff";
            // Pure white
            const shadowColor = "#e1e4ea";
            // Shaded white for far legs & tail shadow
            const floorShadow = "rgba(0, 0, 0, 0.08)";
            // Soft shadow on floor
            const earPink = "#ffccd5";
            // Soft pink
            const eyeColor = "#2e3440";
            // Dark slate
            const collarColor = "#f38ba8";
            // Red collar
            const bellColor = "#f9e2af";
            // Gold bell
            const whiskerColor = "rgba(150, 160, 180, 0.4)";
            // Ground line
            const groundY = 38;
            // 0. FLOOR SHADOW
            const drawEllipse = function drawEllipse(ex, ey, rx, ry) {
                const kappa = 0.552285;
                const ox = rx * kappa;
                const oy = ry * kappa;
                ctx.moveTo(ex - rx, ey);
                ctx.bezierCurveTo(ex - rx, ey - oy, ex - ox, ey - ry, ex, ey - ry);
                ctx.bezierCurveTo(ex + ox, ey - ry, ex + rx, ey - oy, ex + rx, ey);
                ctx.bezierCurveTo(ex + rx, ey + oy, ex + ox, ey + ry, ex, ey + ry);
                ctx.bezierCurveTo(ex - ox, ey + ry, ex - rx, ey + oy, ex - rx, ey);
            };
            ctx.fillStyle = floorShadow;
            ctx.beginPath();
            drawEllipse(16, groundY, 12, 1.5);
            ctx.fill();
            // 1. FAR LEGS (Drawn in background, colored shadowColor)
            ctx.fillStyle = shadowColor;
            // Far back leg
            ctx.beginPath();
            ctx.moveTo(8, 25);
            ctx.lineTo(7.5, 32);
            ctx.quadraticCurveTo(7.5, groundY, 9, groundY);
            ctx.lineTo(10.5, groundY);
            ctx.quadraticCurveTo(9.5, 32, 10, 25);
            ctx.closePath();
            ctx.fill();
            // Far front leg
            ctx.beginPath();
            ctx.moveTo(18, 25);
            ctx.lineTo(18.5, 32);
            ctx.quadraticCurveTo(18.5, groundY, 20, groundY);
            ctx.lineTo(21.5, groundY);
            ctx.quadraticCurveTo(20.5, 32, 20, 25);
            ctx.closePath();
            ctx.fill();
            // 2. TAIL (Curves up from the rear-left, behind the body)
            const wagRad = tw * Math.PI / 180;
            const tStartX = 9;
            const tStartY = 24;
            const ttx = tStartX - 6 + Math.sin(wagRad) * 3;
            const tty = tStartY - 15 + Math.cos(wagRad) * 1.5;
            ctx.fillStyle = shadowColor;
            ctx.beginPath();
            ctx.moveTo(tStartX, tStartY);
            ctx.bezierCurveTo(4, tStartY - 2, 2, tStartY - 8, ttx, tty);
            ctx.arc(ttx + 0.6, tty + 0.6, 1.4, wagRad - Math.PI, wagRad);
            ctx.bezierCurveTo(4.5, tStartY - 6.5, 6.5, tStartY - 1.5, 11.5, tStartY + 1);
            ctx.closePath();
            ctx.fill();
            ctx.fillStyle = furColor;
            ctx.beginPath();
            ctx.moveTo(tStartX, tStartY);
            ctx.bezierCurveTo(4, tStartY - 2, 2, tStartY - 8, ttx, tty);
            ctx.arc(ttx + 0.6, tty + 0.6, 1, wagRad - Math.PI, wagRad);
            ctx.bezierCurveTo(4.2, tStartY - 6.8, 6.2, tStartY - 1.8, 11, tStartY);
            ctx.closePath();
            ctx.fill();
            // 3. BODY (Horizontal arched torso)
            ctx.fillStyle = shadowColor;
            // Shadow underlay
            ctx.beginPath();
            ctx.moveTo(8, 25.5);
            ctx.bezierCurveTo(7.5, 20.5, 11, 18.5, 16, 19);
            ctx.bezierCurveTo(19, 19.5, 21, 20.5, 21.5, 23.5);
            ctx.bezierCurveTo(22, 26.5, 21, 28.5, 18.5, 29);
            ctx.bezierCurveTo(15, 30, 11, 29.5, 8, 25.5);
            ctx.closePath();
            ctx.fill();
            ctx.fillStyle = furColor;
            ctx.beginPath();
            ctx.moveTo(8, 25);
            ctx.bezierCurveTo(7.5, 20, 11, 18, 16, 18.5);
            ctx.bezierCurveTo(19, 19, 21, 20, 21.5, 23);
            ctx.bezierCurveTo(22, 26, 21, 28, 18.5, 28.5);
            ctx.bezierCurveTo(15, 29.5, 11, 29, 8, 25);
            ctx.closePath();
            ctx.fill();
            // 4. NEAR LEGS (Drawn in front of the body, pure white)
            ctx.fillStyle = furColor;
            // Near back leg (with curved thigh/hip)
            ctx.beginPath();
            ctx.moveTo(11.5, 20); // Top of hip
            ctx.bezierCurveTo(7.5, 22, 7.5, 28, 9, 32); // Back of thigh
            ctx.lineTo(8.5, groundY); // Back of leg
            ctx.lineTo(10, groundY); // Paw bottom
            ctx.lineTo(11.5, groundY);
            ctx.quadraticCurveTo(10.5, 32, 13.5, 29); // Front of thigh
            ctx.bezierCurveTo(13.5, 25, 12.5, 21, 11.5, 20);
            ctx.closePath();
            ctx.fill();
            // Near front leg (with shoulder slope)
            ctx.beginPath();
            ctx.moveTo(20, 21);
            ctx.bezierCurveTo(19.5, 26, 20, 30, 21.5, groundY);
            ctx.lineTo(23.5, groundY);
            ctx.bezierCurveTo(23, 30, 22.5, 25, 22, 21);
            ctx.closePath();
            ctx.fill();
            // Foot lines for near legs
            ctx.strokeStyle = shadowColor;
            ctx.lineWidth = 0.6;
            ctx.beginPath();
            ctx.moveTo(10, groundY - 1.5);
            ctx.lineTo(10, groundY);
            ctx.moveTo(22.5, groundY - 1.5);
            ctx.lineTo(22.5, groundY);
            ctx.stroke();
            // 5. COLLAR & BELL (Visual separator between head and chest)
            ctx.strokeStyle = collarColor;
            ctx.lineWidth = 1.4;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(19.5, 21.5);
            ctx.lineTo(23.5, 22.8);
            ctx.stroke();
            ctx.fillStyle = bellColor;
            ctx.beginPath();
            ctx.arc(22, 23.4, 1.2, 0, Math.PI * 2);
            ctx.fill();
            // 6. EARS (Triangles on top of head)
            // Left/Far ear
            ctx.fillStyle = shadowColor;
            ctx.beginPath();
            ctx.moveTo(18.5, 10.5);
            ctx.lineTo(19, 5);
            ctx.lineTo(21.5, 10.5);
            ctx.closePath();
            ctx.fill();
            // Right/Near ear
            ctx.fillStyle = shadowColor;
            ctx.beginPath();
            ctx.moveTo(24, 10.5);
            ctx.lineTo(26.5, 4);
            ctx.lineTo(28, 10.5);
            ctx.closePath();
            ctx.fill();
            ctx.fillStyle = furColor;
            ctx.beginPath();
            ctx.moveTo(24, 10);
            ctx.lineTo(26.5, 4.5);
            ctx.lineTo(28, 10);
            ctx.closePath();
            ctx.fill();
            // Inner ear pink
            ctx.fillStyle = earPink;
            ctx.beginPath();
            ctx.moveTo(24.5, 9.8);
            ctx.lineTo(26.3, 6);
            ctx.lineTo(27.2, 9.8);
            ctx.closePath();
            ctx.fill();
            // 7. HEAD (Oblate shape with cheek fluff)
            ctx.fillStyle = shadowColor;
            ctx.beginPath();
            ctx.moveTo(24, 10.5);
            ctx.bezierCurveTo(28, 10.5, 29.5, 13.5, 30.5, 15.5);
            ctx.lineTo(31.5, 17);
            ctx.lineTo(29.5, 18);
            ctx.bezierCurveTo(29, 21.5, 25, 22, 23, 22);
            ctx.bezierCurveTo(19, 22, 18, 20, 18.5, 17);
            ctx.bezierCurveTo(18.5, 13.5, 20, 10.5, 24, 10.5);
            ctx.closePath();
            ctx.fill();
            ctx.fillStyle = furColor;
            ctx.beginPath();
            ctx.moveTo(24, 10);
            ctx.bezierCurveTo(28, 10, 29.5, 13, 30.5, 15);
            ctx.lineTo(31.5, 16.5);
            ctx.lineTo(29.5, 17.5);
            ctx.bezierCurveTo(29, 21, 25, 21.5, 23, 21.5);
            ctx.bezierCurveTo(19, 21.5, 18, 19.5, 18.5, 16.5);
            ctx.bezierCurveTo(18.5, 13, 20, 10, 24, 10);
            ctx.closePath();
            ctx.fill();
            // 8. EYES (3/4 Chibi perspective looking slightly right)
            const eyeY = 14.5;
            const lx = 21.5; // Far eye
            const rx = 26.5; // Near eye
            if (ec) {
                ctx.strokeStyle = eyeColor;
                ctx.lineWidth = 1;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(lx, eyeY - 0.3, 1, 0, Math.PI, false);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(rx, eyeY - 0.3, 1, 0, Math.PI, false);
                ctx.stroke();
            } else {
                ctx.fillStyle = eyeColor;
                ctx.beginPath();
                ctx.arc(lx, eyeY, 1, 0, Math.PI * 2);
                ctx.fill();
                ctx.beginPath();
                ctx.arc(rx, eyeY, 1.3, 0, Math.PI * 2);
                ctx.fill();
                // Tiny reflection on near eye
                ctx.fillStyle = "white";
                ctx.beginPath();
                ctx.arc(rx - 0.4, eyeY - 0.4, 0.45, 0, Math.PI * 2);
                ctx.fill();
            }
            // Blush (under near eye)
            if (bl > 0.01) {
                ctx.fillStyle = "rgba(255, 204, 213, " + (bl * 0.6) + ")";
                ctx.beginPath();
                ctx.arc(rx, eyeY + 1.8, 1.2, 0, Math.PI * 2);
                ctx.fill();
            }
            // Nose
            const noseX = 28.5;
            const noseY = 15.8;
            ctx.fillStyle = earPink;
            ctx.beginPath();
            ctx.moveTo(noseX - 0.6, noseY);
            ctx.lineTo(noseX + 0.6, noseY);
            ctx.lineTo(noseX, noseY + 0.5);
            ctx.closePath();
            ctx.fill();
            // Mouth (tiny smile)
            ctx.strokeStyle = eyeColor;
            ctx.lineWidth = 0.8;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(27.8, noseY + 0.8);
            ctx.quadraticCurveTo(28.4, noseY + 1.5, 29, noseY + 0.9);
            ctx.stroke();
            // Whiskers (peeking from front profile)
            ctx.strokeStyle = whiskerColor;
            ctx.lineWidth = 0.7;
            ctx.beginPath();
            ctx.moveTo(29.5, 16.5);
            ctx.lineTo(34, 16);
            ctx.moveTo(29.5, 17.8);
            ctx.lineTo(33.5, 18.8);
            ctx.stroke();
            // Sweat drop (highcpu)
            if (cs === "highcpu") {
                ctx.fillStyle = "#89dcef";
                ctx.beginPath();
                ctx.moveTo(cx + 9, headCY - 7);
                ctx.bezierCurveTo(cx + 11, headCY - 4, cx + 12, headCY - 1, cx + 9, headCY);
                ctx.bezierCurveTo(cx + 6, headCY - 1, cx + 7, headCY - 4, cx + 9, headCY - 7);
                ctx.fill();
            }
            ctx.restore();
        }

        transform: Rotation {
            origin.x: canvas.width / 2
            origin.y: canvas.height - 4
            angle: petCat.bodyTilt
        }

    }

    // Floating music note
    Text {
        property real ny: 2

        visible: petCat.catState === "music"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -4
        text: "♪"
        font.pixelSize: 11
        color: "#cba6f7"
        opacity: 0
        anchors.topMargin: ny

        SequentialAnimation on opacity {
            running: petCat.catState === "music"
            loops: Animation.Infinite

            PauseAnimation {
                duration: 300
            }

            NumberAnimation {
                to: 0.9
                duration: 300
            }

            PauseAnimation {
                duration: 300
            }

            NumberAnimation {
                to: 0
                duration: 400
            }

        }

        SequentialAnimation on ny {
            running: petCat.catState === "music"
            loops: Animation.Infinite

            PauseAnimation {
                duration: 300
            }

            NumberAnimation {
                to: -12
                duration: 700
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                to: 2
                duration: 0
            }

        }

    }

    // Timer sparkles
    Repeater {
        model: petCat.catState === "timerfinished" ? 4 : 0

        delegate: Text {
            required property int index

            x: petCat.width / 2 + Math.cos((index * 90 + 45) * Math.PI / 180) * 22 - 4
            y: petCat.height / 2 + Math.sin((index * 90 + 45) * Math.PI / 180) * 22 - 4
            text: "✦"
            font.pixelSize: 7
            color: "#fab387"
            opacity: 0

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite

                PauseAnimation {
                    duration: index * 120
                }

                NumberAnimation {
                    to: 1
                    duration: 140
                }

                NumberAnimation {
                    to: 0
                    duration: 290
                }

            }

        }

    }

    transform: Rotation {
        origin.x: petCat.width / 2
        origin.y: petCat.height / 2
        angle: petCat.spinAngle
    }

}
