import QtQuick

Item {
    id: root

    UserConfig {
        id: userConfig
    }

    property string lyricText: ""
    property string timeText: ""
    property string textFontFamily: userConfig.textFontFamily
    property string timeFontFamily: userConfig.timeFontFamily
    property bool showCondition: false
    property bool showSecondaryText: true
    property bool persistentRingActive: false
    property bool bothRunning: false
    property real transitionProgress: 0
    property int textPixelSize: 16
    property real minimumWidth: 220
    property real maximumWidth: minimumWidth
    property real horizontalPadding: 14
    property real hiddenLeftPadding: 18
    property real hiddenRightPadding: 16
    property string activeLyricText: lyricText
    property string previousLyricText: ""
    property real lyricChangeProgress: 1

    readonly property real timeClampedProgress: Math.max(0, Math.min(1, transitionProgress))
    readonly property real lyricClampedProgress: Math.max(0, Math.min(1, transitionProgress - 1))
    readonly property bool lyricMostlyVisible: lyricClampedProgress > 0.92
    readonly property real textWidth: Math.max(0, width - horizontalPadding * 2)
    readonly property real centeredX: horizontalPadding
    readonly property real lyricHiddenLeftX: -textWidth - hiddenLeftPadding
    readonly property real timeHiddenRightX: width + hiddenRightPadding
    readonly property real lyricEntryDistance: Math.max(0, centeredX - lyricHiddenLeftX)
    readonly property real timeExitDistance: Math.max(0, timeHiddenRightX - centeredX)
    readonly property real dragDistance: Math.max(lyricEntryDistance, timeExitDistance)
    readonly property real lyricX: centeredX - (1 - lyricClampedProgress) * dragDistance
    readonly property real timeX: centeredX + timeClampedProgress * dragDistance
    readonly property real preferredWidth: Math.max(
        minimumWidth,
        Math.min(Math.max(minimumWidth, maximumWidth), lyricMetrics.advanceWidth + horizontalPadding * 2 + 28)
    )

    onLyricTextChanged: {
        if (lyricText === activeLyricText) return;

        if (activeLyricText === "" || !lyricMostlyVisible) {
            lyricChangeAnimation.stop();
            previousLyricText = "";
            activeLyricText = lyricText;
            lyricChangeProgress = 1;
            return;
        }

        previousLyricText = activeLyricText;
        activeLyricText = lyricText;
        lyricChangeProgress = 0;
        lyricChangeAnimation.restart();
    }

    onShowConditionChanged: {
        if (showCondition) return;
        lyricChangeAnimation.stop();
        previousLyricText = "";
        activeLyricText = lyricText;
        lyricChangeProgress = 1;
    }

    onTransitionProgressChanged: {
        if (lyricMostlyVisible) return;
        lyricChangeAnimation.stop();
        previousLyricText = "";
        activeLyricText = lyricText;
        lyricChangeProgress = 1;
    }

    anchors.fill: parent
    clip: true
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 220 : 140
            easing.type: Easing.InOutQuad
        }
    }

    TextMetrics {
        id: lyricMetrics
        font.family: textFontFamily
        font.pixelSize: textPixelSize
        font.weight: Font.DemiBold
        text: activeLyricText !== "" ? activeLyricText : lyricText
    }

    SequentialAnimation {
        id: lyricChangeAnimation

        NumberAnimation {
            target: root
            property: "lyricChangeProgress"
            from: 0
            to: 1
            duration: 260
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: root.previousLyricText = ""
        }
    }

    Text {
        visible: previousLyricText !== ""
        x: lyricX
        width: textWidth
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -14 * lyricChangeProgress
        text: previousLyricText
        color: "white"
        opacity: lyricClampedProgress * (1 - lyricChangeProgress)
        font.pixelSize: textPixelSize
        font.family: textFontFamily
        font.weight: Font.DemiBold
        font.letterSpacing: -0.15
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }

    Text {
        visible: activeLyricText !== ""
        x: lyricX
        width: textWidth
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: previousLyricText !== "" ? 12 * (1 - lyricChangeProgress) : 0
        text: activeLyricText
        color: "white"
        opacity: lyricClampedProgress * (previousLyricText !== "" ? lyricChangeProgress : 1)
        font.pixelSize: textPixelSize
        font.family: textFontFamily
        font.weight: Font.DemiBold
        font.letterSpacing: -0.15
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }

    Text {
        visible: timeText !== "" && showSecondaryText
        id: timeTextItem
        x: (timeClampedProgress > 0)
            ? timeX
            : (userConfig.petEnabled ? 58 : (root.bothRunning ? 56 : (root.persistentRingActive ? 16 : (parent.width - implicitWidth) / 2)))
        width: (timeClampedProgress > 0)
            ? textWidth
            : (userConfig.petEnabled ? (parent.width - 58 - 16) : implicitWidth)
        anchors.verticalCenter: parent.verticalCenter
        text: timeText
        color: "white"
        opacity: 1 - timeClampedProgress
        font.pixelSize: textPixelSize + 1
        font.family: timeFontFamily
        font.weight: Font.Bold
        font.letterSpacing: -0.25
        horizontalAlignment: (timeClampedProgress > 0 || userConfig.petEnabled || root.persistentRingActive || root.bothRunning)
            ? Text.AlignLeft
            : Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }
}
