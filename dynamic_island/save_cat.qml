import QtQuick

Item {
    width: 38
    height: 56

    Canvas {
        id: canvas
        width: 38
        height: 56
        anchors.centerIn: parent

        property bool   ec: false
        property bool   ew: false
        property real   bl: 0.8
        property color  ac: "#89b4fa"
        property string cs: "idle"
        property real   tw: 0.0

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.save();

            const W  = width;
            const cx = W / 2; // 19

            // Colors
            const furColor      = "#ffffff"; // Pure white
            const shadowColor   = "#e5e7eb"; // Pastel gray for shading
            const floorShadow   = "rgba(0, 0, 0, 0.08)"; // Soft shadow on floor
            const earPink       = "#ffccd5"; // Soft pink
            const eyeColor      = "#2e3440"; // Dark slate
            const collarColor   = "#f38ba8"; // Red collar
            const bellColor     = "#f9e2af"; // Gold bell
            const whiskerColor  = "rgba(150, 160, 180, 0.4)";

            // Ground line
            const groundY = 38;

            // 0. FLOOR SHADOW
            const drawEllipse = function(ex, ey, rx, ry) {
                const kappa = 0.5522848;
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
            // Far back leg (curved slightly forward)
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
            const ttx  = tStartX - 6 + Math.sin(wagRad) * 3;
            const tty  = tStartY - 15 + Math.cos(wagRad) * 1.5;

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
            ctx.arc(ttx + 0.6, tty + 0.6, 1.0, wagRad - Math.PI, wagRad);
            ctx.bezierCurveTo(4.2, tStartY - 6.8, 6.2, tStartY - 1.8, 11.0, tStartY);
            ctx.closePath();
            ctx.fill();

            // 3. BODY (Horizontal arched torso)
            ctx.fillStyle = shadowColor; // Shadow underlay
            ctx.beginPath();
            ctx.moveTo(8, 25.5);
            ctx.bezierCurveTo(7.5, 20.5, 11, 18.5, 16, 19.0);
            ctx.bezierCurveTo(19, 19.5, 21, 20.5, 21.5, 23.5);
            ctx.bezierCurveTo(22, 26.5, 21, 28.5, 18.5, 29.0);
            ctx.bezierCurveTo(15, 30.0, 11, 29.5, 8, 25.5);
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
            ctx.moveTo(10, groundY - 1.5); ctx.lineTo(10, groundY);
            ctx.moveTo(22.5, groundY - 1.5); ctx.lineTo(22.5, groundY);
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
            ctx.arc(22.0, 23.4, 1.2, 0, Math.PI * 2);
            ctx.fill();

            // 6. EARS (Triangles on top of head)
            // Left/Far ear
            ctx.fillStyle = shadowColor;
            ctx.beginPath();
            ctx.moveTo(18.5, 10.5);
            ctx.lineTo(19.0, 5.0);
            ctx.lineTo(21.5, 10.5);
            ctx.closePath(); ctx.fill();

            // Right/Near ear
            ctx.fillStyle = shadowColor;
            ctx.beginPath();
            ctx.moveTo(24, 10.5);
            ctx.lineTo(26.5, 4.0);
            ctx.lineTo(28, 10.5);
            ctx.closePath(); ctx.fill();

            ctx.fillStyle = furColor;
            ctx.beginPath();
            ctx.moveTo(24, 10);
            ctx.lineTo(26.5, 4.5);
            ctx.lineTo(28, 10);
            ctx.closePath(); ctx.fill();
            // Inner ear pink
            ctx.fillStyle = earPink;
            ctx.beginPath();
            ctx.moveTo(24.5, 9.8);
            ctx.lineTo(26.3, 6.0);
            ctx.lineTo(27.2, 9.8);
            ctx.closePath(); ctx.fill();

            // 7. HEAD (Oblate shape with cheek fluff)
            ctx.fillStyle = shadowColor;
            ctx.beginPath();
            ctx.moveTo(24, 10.5);
            ctx.bezierCurveTo(28, 10.5, 29.5, 13.5, 30.5, 15.5);
            ctx.lineTo(31.5, 17.0);
            ctx.lineTo(29.5, 18.0);
            ctx.bezierCurveTo(29, 21.5, 25, 22.0, 23, 22.0);
            ctx.bezierCurveTo(19, 22.0, 18, 20.0, 18.5, 17.0);
            ctx.bezierCurveTo(18.5, 13.5, 20, 10.5, 24, 10.5);
            ctx.closePath(); ctx.fill();

            ctx.fillStyle = furColor;
            ctx.beginPath();
            ctx.moveTo(24, 10);
            ctx.bezierCurveTo(28, 10, 29.5, 13, 30.5, 15);
            ctx.lineTo(31.5, 16.5);
            ctx.lineTo(29.5, 17.5);
            ctx.bezierCurveTo(29, 21, 25, 21.5, 23, 21.5);
            ctx.bezierCurveTo(19, 21.5, 18, 19.5, 18.5, 16.5);
            ctx.bezierCurveTo(18.5, 13, 20, 10, 24, 10);
            ctx.closePath(); ctx.fill();

            // 8. EYES (3/4 Chibi perspective looking slightly right)
            const eyeY = 14.5;
            const lx   = 21.5; // Far eye
            const rx   = 26.5; // Near eye

            if (ec) {
                ctx.strokeStyle = eyeColor;
                ctx.lineWidth = 1.0; ctx.lineCap = "round";
                ctx.beginPath(); ctx.arc(lx, eyeY - 0.3, 1.0, 0, Math.PI, false); ctx.stroke();
                ctx.beginPath(); ctx.arc(rx, eyeY - 0.3, 1.0, 0, Math.PI, false); ctx.stroke();
            } else {
                ctx.fillStyle = eyeColor;
                ctx.beginPath(); ctx.arc(lx, eyeY, 1.0, 0, Math.PI*2); ctx.fill();
                ctx.beginPath(); ctx.arc(rx, eyeY, 1.3, 0, Math.PI*2); ctx.fill();
                // Tiny reflection on near eye
                ctx.fillStyle = "white";
                ctx.beginPath(); ctx.arc(rx - 0.4, eyeY - 0.4, 0.45, 0, Math.PI*2); ctx.fill();
            }

            // Blush (under near eye)
            if (bl > 0.01) {
                ctx.fillStyle = "rgba(255, 204, 213, " + (bl * 0.6) + ")";
                ctx.beginPath(); ctx.arc(rx, eyeY + 1.8, 1.2, 0, Math.PI*2); ctx.fill();
            }

            // Nose
            const noseX = 28.5;
            const noseY = 15.8;
            ctx.fillStyle = earPink;
            ctx.beginPath();
            ctx.moveTo(noseX - 0.6, noseY);
            ctx.lineTo(noseX + 0.6, noseY);
            ctx.lineTo(noseX,       noseY + 0.5);
            ctx.closePath(); ctx.fill();

            // Mouth (tiny smile)
            ctx.strokeStyle = eyeColor;
            ctx.lineWidth = 0.8; ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(27.8, noseY + 0.8);
            ctx.quadraticCurveTo(28.4, noseY + 1.5, 29.0, noseY + 0.9);
            ctx.stroke();

            // Whiskers (peeking from front profile)
            ctx.strokeStyle = whiskerColor;
            ctx.lineWidth = 0.7;
            ctx.beginPath();
            ctx.moveTo(29.5, 16.5); ctx.lineTo(34.0, 16.0);
            ctx.moveTo(29.5, 17.8); ctx.lineTo(33.5, 18.8);
            ctx.stroke();

            ctx.restore();

            console.log("Saving canvas...");
            canvas.save("cat.png");
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            Qt.quit();
        }
    }
}
