import QtQuick

Item {
    id: root

    UserConfig {
        id: userConfig
    }

    property var items: []
    property var cavaLevels: []
    property string timeText: ""
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string timeFontFamily: userConfig.timeFontFamily
    property bool showCondition: false
    property bool showSecondaryText: true
    property bool persistentRingActive: false
    property bool bothRunning: false
    property real transitionProgress: 0
    property real minimumWidth: 220
    property real maximumWidth: minimumWidth
    property real horizontalPadding: 14
    property real hiddenLeftPadding: 18
    property real hiddenRightPadding: 18
    property real groupSpacing: 16
    property real iconSpacing: 8
    property int textPixelSize: 16
    property int iconPixelSize: 16
    property int iconBoxSize: 18
    property int batteryIconWidth: 30
    property int batteryIconHeight: 15
    property int batteryTipWidth: 3
    property int batteryTipHeight: 7
    property int batteryOuterRadius: 5
    property int batteryInnerRadius: 3
    property real iconVerticalOffset: 1

    property bool hovered: false
    property real cpuUsage: 0
    property real cpuTemp: 0
    property string cpuFreq: "0.00 GHz"
    property string cpuProcesses: "0/0"
    property real ramUsage: 0
    property real ramTotalGB: 0
    property real ramUsedGB: 0
    property real diskUsage: 0
    property real diskTotalGB: 0
    property real diskUsedGB: 0

    readonly property real clampedProgress: Math.max(0, Math.min(1, -transitionProgress))
    readonly property real textWidth: Math.max(0, width - horizontalPadding * 2)
    readonly property real centeredTimeX: horizontalPadding
    readonly property real centeredItemsX: (width - contentRow.implicitWidth) / 2
    readonly property real timeHiddenLeftX: -textWidth - hiddenLeftPadding
    readonly property real itemsHiddenRightX: width + hiddenRightPadding
    readonly property real timeExitDistance: Math.max(0, centeredTimeX - timeHiddenLeftX)
    readonly property real itemsEntryDistance: Math.max(0, itemsHiddenRightX - centeredItemsX)
    readonly property real dragDistance: Math.max(timeExitDistance, itemsEntryDistance)
    readonly property real itemsX: centeredItemsX + (1 - clampedProgress) * dragDistance
    readonly property real timeX: centeredTimeX - clampedProgress * dragDistance
    readonly property real preferredWidth: Math.max(
        minimumWidth,
        Math.min(Math.max(minimumWidth, maximumWidth), contentRow.implicitWidth + horizontalPadding * 2 + 28)
    )

    anchors.fill: parent
    clip: true
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 220 : 140
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: contentRow
        x: itemsX
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        opacity: clampedProgress * (root.hovered ? 0 : 1)
        spacing: groupSpacing

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        Repeater {
            model: root.items

            delegate: Item {
                readonly property bool hasIcon: modelData.icon !== ""
                readonly property bool isCava: modelData.kind === "cava"
                readonly property bool isBattery: modelData.kind === "battery"
                readonly property bool hasLeadingVisual: hasIcon || isBattery
                implicitWidth: isCava
                    ? cavaBars.implicitWidth
                    : leadingVisual.width + (hasLeadingVisual ? root.iconSpacing : 0) + valueText.implicitWidth
                implicitHeight: root.height
                width: implicitWidth
                height: implicitHeight

                SwipeCavaBars {
                    id: cavaBars
                    visible: parent.isCava
                    anchors.centerIn: parent
                    levels: root.cavaLevels
                }

                Item {
                    id: leadingVisual
                    visible: !parent.isCava && parent.hasLeadingVisual
                    width: parent.isBattery ? root.batteryIconWidth : (parent.hasIcon ? root.iconBoxSize : 0)
                    height: parent.isBattery ? Math.max(root.batteryIconHeight, valueText.implicitHeight) : root.iconBoxSize
                    anchors.left: parent.isBattery ? valueText.right : parent.left
                    anchors.leftMargin: parent.isBattery ? root.iconSpacing : 0
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: root.iconVerticalOffset
                        visible: parent.parent.hasIcon && !parent.parent.isBattery
                        text: modelData.icon || ""
                        color: "white"
                        font.pixelSize: root.iconPixelSize
                        font.family: root.iconFontFamily
                    }

                    Item {
                        visible: parent.parent.isBattery
                        width: root.batteryIconWidth
                        height: root.batteryIconHeight
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            anchors.rightMargin: root.batteryTipWidth
                            radius: root.batteryOuterRadius
                            color: "transparent"
                            border.color: "#8e8e93"
                            border.width: 1

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 2
                                radius: root.batteryInnerRadius
                                width: Math.max(0, (parent.width - 4) * (Math.max(0, Math.min(100, Number(modelData.level || 0))) / 100.0))
                                color: {
                                    const level = Math.max(0, Math.min(100, Number(modelData.level || 0)));
                                    if (level <= 10) return "#ff3b30";
                                    if (level <= 20) return "#ffcc00";
                                    return "#34c759";
                                }

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: root.batteryTipWidth
                            height: root.batteryTipHeight
                            radius: Math.round(root.batteryTipWidth / 2)
                            color: "#8e8e93"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Text {
                    visible: !parent.isCava
                    id: valueText
                    anchors.left: parent.isBattery ? parent.left : leadingVisual.right
                    anchors.leftMargin: parent.hasLeadingVisual && !parent.isBattery ? root.iconSpacing : 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.text || ""
                    color: "white"
                    font.pixelSize: root.textPixelSize
                    font.family: root.textFontFamily
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.15
                    wrapMode: Text.NoWrap
                }
            }
        }
    }

    Text {
        visible: timeText !== "" && showSecondaryText
        id: timeTextItem
        x: (clampedProgress > 0)
            ? timeX
            : (userConfig.petEnabled ? 58 : (root.bothRunning ? 56 : (root.persistentRingActive ? 16 : (parent.width - implicitWidth) / 2)))
        width: (clampedProgress > 0)
            ? textWidth
            : (userConfig.petEnabled ? (parent.width - 58 - 16) : implicitWidth)
        anchors.verticalCenter: parent.verticalCenter
        text: timeText
        color: "white"
        opacity: (1 - clampedProgress) * (root.hovered ? 0 : 1)
        font.pixelSize: root.textPixelSize + 1
        font.family: timeFontFamily
        font.weight: Font.Bold
        font.letterSpacing: -0.25
        horizontalAlignment: (clampedProgress > 0 || userConfig.petEnabled || root.persistentRingActive || root.bothRunning)
            ? Text.AlignLeft
            : Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }
    }

    Grid {
        id: detailedGrid
        anchors.centerIn: parent
        columns: 2
        spacing: 20
        opacity: root.hovered ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        // CPU Usage Cell
        Item {
            width: 140
            height: 48

            Row {
                id: cpuRow
                spacing: 8
                anchors.top: parent.top
                anchors.left: parent.left

                Text {
                    text: userConfig.statusIcons["cpu"]
                    font.family: root.iconFontFamily
                    font.pixelSize: 16
                    color: "#3498db" // Modern Blue
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: 2
                    Text {
                        text: "CPU: " + Math.round(root.cpuUsage * 100) + "%"
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "white"
                    }
                    Text {
                        text: "Freq: " + root.cpuFreq
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        color: "#a0a0a0"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(255, 255, 255, 0.1)
                anchors.bottom: parent.bottom

                Rectangle {
                    width: parent.width * root.cpuUsage
                    height: parent.height
                    radius: 2
                    color: "#3498db"

                    Behavior on width {
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                    }
                }
            }
        }

        // RAM Usage Cell
        Item {
            width: 140
            height: 48

            Row {
                id: ramRow
                spacing: 8
                anchors.top: parent.top
                anchors.left: parent.left

                Text {
                    text: userConfig.statusIcons["ram"]
                    font.family: root.iconFontFamily
                    font.pixelSize: 16
                    color: "#9b59b6" // Modern Purple
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: 2
                    Text {
                        text: "RAM: " + Math.round(root.ramUsage * 100) + "%"
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "white"
                    }
                    Text {
                        text: root.ramUsedGB.toFixed(1) + " / " + root.ramTotalGB.toFixed(1) + " GB"
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        color: "#a0a0a0"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(255, 255, 255, 0.1)
                anchors.bottom: parent.bottom

                Rectangle {
                    width: parent.width * root.ramUsage
                    height: parent.height
                    radius: 2
                    color: "#9b59b6"

                    Behavior on width {
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                    }
                }
            }
        }

        // Disk Usage Cell
        Item {
            width: 140
            height: 48

            Row {
                id: diskRow
                spacing: 8
                anchors.top: parent.top
                anchors.left: parent.left

                Text {
                    text: userConfig.statusIcons["disk"]
                    font.family: root.iconFontFamily
                    font.pixelSize: 16
                    color: "#f1c40f" // Modern Yellow
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: 2
                    Text {
                        text: "Disk: " + Math.round(root.diskUsage * 100) + "%"
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "white"
                    }
                    Text {
                        text: (root.diskTotalGB - root.diskUsedGB).toFixed(0) + " GB free of " + root.diskTotalGB.toFixed(0) + " GB"
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        color: "#a0a0a0"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(255, 255, 255, 0.1)
                anchors.bottom: parent.bottom

                Rectangle {
                    width: parent.width * root.diskUsage
                    height: parent.height
                    radius: 2
                    color: "#f1c40f"

                    Behavior on width {
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                    }
                }
            }
        }

        // Temp Cell
        Item {
            width: 140
            height: 48

            Row {
                id: tempRow
                spacing: 8
                anchors.top: parent.top
                anchors.left: parent.left

                Text {
                    text: userConfig.statusIcons["temp"]
                    font.family: root.iconFontFamily
                    font.pixelSize: 16
                    color: "#e74c3c" // Modern Red
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: 2
                    Text {
                        text: root.cpuTemp > 0 ? "Temp: " + Math.round(root.cpuTemp) + "°C" : "Temp: N/A"
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "white"
                    }
                    Text {
                        text: "Proc: " + root.cpuProcesses
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        color: "#a0a0a0"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(255, 255, 255, 0.1)
                anchors.bottom: parent.bottom

                Rectangle {
                    width: parent.width * Math.min(1.0, Math.max(0, root.cpuTemp / 100.0))
                    height: parent.height
                    radius: 2
                    color: "#e74c3c"

                    Behavior on width {
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
