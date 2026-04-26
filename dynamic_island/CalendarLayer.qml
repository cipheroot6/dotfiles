import QtQuick

Item {
    id: calendarPanel

    UserConfig {
        id: userConfig
    }

    // Emitted on any user interaction so the parent can reset the inactivity timer
    signal userInteracted()

    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property string iconFontFamily: userConfig.iconFontFamily
    property real presentationProgress: 1.0

    // ── Theme colours (mirrors ControlCenterLayer) ────────────────────────
    readonly property color panelBg:        "#000000"
    readonly property color moduleColor:    "#1c1c1e"
    readonly property color moduleHover:    "#2a2a2d"
    readonly property color trackColor:     "#2c2c2e"
    readonly property color textPrimary:    "#f5f5f7"
    readonly property color textSecondary:  "#8e8e93"
    readonly property color cardAccent:     "#0a84ff"
    readonly property color saturdayColor:  "#5ac8fa"
    readonly property color sundayColor:    "#ff453a"

    // ── Calendar state ────────────────────────────────────────────────────
    property var today: new Date()

    property int viewYear:      today.getFullYear()
    property int viewMonth:     today.getMonth()        // 0-based
    property int selectedDay:   today.getDate()
    property int selectedMonth: today.getMonth()
    property int selectedYear:  today.getFullYear()

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var dayHeaders: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    // ── Helpers ───────────────────────────────────────────────────────────
    function daysInMonth(yr, mo) {
        return new Date(yr, mo + 1, 0).getDate();
    }

    function firstWeekday(yr, mo) {
        return new Date(yr, mo, 1).getDay();   // 0 = Sunday
    }

    function isTodayCell(d) {
        let t = today;
        return d === t.getDate() && viewMonth === t.getMonth() && viewYear === t.getFullYear();
    }

    function isSelectedCell(d) {
        return d === selectedDay && viewMonth === selectedMonth && viewYear === selectedYear;
    }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear -= 1; }
        else                 { viewMonth -= 1; }
    }

    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear += 1; }
        else                  { viewMonth += 1; }
    }

    function goToday() {
        let t = new Date();
        viewYear  = t.getFullYear();
        viewMonth = t.getMonth();
        selectedDay   = t.getDate();
        selectedMonth = t.getMonth();
        selectedYear  = t.getFullYear();
    }

    // ── Root background card ──────────────────────────────────────────────
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: panelBg

        // Inner highlight ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: "#1fffffff"
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // ── Header row ──────────────────────────────────────────────
            Item {
                width: parent.width
                height: 34

                // Today chip (tap to jump to current month)
                Rectangle {
                    id: todayChip
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: todayChipText.implicitWidth + 16
                    height: 24
                    radius: 12
                    color: todayChipMouse.containsMouse ? "#1e1e21" : "#141416"
                    border.width: 1
                    border.color: "#2affffff"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: todayChipText
                        anchors.centerIn: parent
                        text: "Today"
                        color: cardAccent
                        font.pixelSize: 11
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: todayChipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            calendarPanel.goToday();
                            calendarPanel.userInteracted();
                        }
                    }
                }

                // Month + Year label (centred)
                Text {
                    anchors.centerIn: parent
                    text: monthNames[viewMonth] + " " + viewYear
                    color: textPrimary
                    font.pixelSize: 15
                    font.family: heroFontFamily
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }

                // Prev / Next arrows
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: prevHover.containsMouse ? moduleHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: textPrimary
                            font.pixelSize: 20
                            font.family: textFontFamily
                            font.weight: Font.Light
                        }

                        MouseArea {
                            id: prevHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calendarPanel.prevMonth();
                                calendarPanel.userInteracted();
                            }
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: nextHover.containsMouse ? moduleHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: textPrimary
                            font.pixelSize: 20
                            font.family: textFontFamily
                            font.weight: Font.Light
                        }

                        MouseArea {
                            id: nextHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calendarPanel.nextMonth();
                                calendarPanel.userInteracted();
                            }
                        }
                    }
                }
            }

            // Thin separator
            Rectangle {
                width: parent.width
                height: 1
                color: "#18ffffff"
            }

            // ── Day-of-week column headers ───────────────────────────────
            Row {
                width: parent.width
                spacing: 0

                Repeater {
                    model: dayHeaders

                    Item {
                        width: parent.width / 7
                        height: 24

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: {
                                if (index === 0) return sundayColor;
                                if (index === 6) return saturdayColor;
                                return textSecondary;
                            }
                            font.pixelSize: 10
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.4
                        }
                    }
                }
            }

            // ── Day grid ─────────────────────────────────────────────────
            Grid {
                id: dayGrid
                width: parent.width
                columns: 7
                rowSpacing: 2
                columnSpacing: 0

                property int firstDay: calendarPanel.firstWeekday(viewYear, viewMonth)
                property int numDays:  calendarPanel.daysInMonth(viewYear, viewMonth)

                // Previous month's trailing days (greyed out, non-interactive)
                Repeater {
                    model: dayGrid.firstDay

                    Item {
                        width: dayGrid.width / 7
                        height: width

                        property int prevMoDays: calendarPanel.daysInMonth(
                            viewMonth === 0 ? viewYear - 1 : viewYear,
                            viewMonth === 0 ? 11 : viewMonth - 1
                        )
                        property int displayDay: prevMoDays - (dayGrid.firstDay - 1 - index)

                        Text {
                            anchors.centerIn: parent
                            text: parent.displayDay
                            color: "#2effffff"
                            font.pixelSize: 13
                            font.family: textFontFamily
                        }
                    }
                }

                // Current month's days
                Repeater {
                    model: dayGrid.numDays

                    Item {
                        id: dayCell
                        property int dayNum:  index + 1
                        property int weekCol: (dayGrid.firstDay + index) % 7
                        property bool isToday:    calendarPanel.isTodayCell(dayNum)
                        property bool isSelected: calendarPanel.isSelectedCell(dayNum)
                        property bool hovered:    cellMouse.containsMouse

                        width: dayGrid.width / 7
                        height: width

                        // Background circle
                        Rectangle {
                            id: dayBg
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 6
                            height: width
                            radius: width / 2

                            color: {
                                if (isToday)    return cardAccent;
                                if (isSelected) return moduleHover;
                                if (hovered)    return "#18ffffff";
                                return "transparent";
                            }

                            Behavior on color { ColorAnimation { duration: 110 } }

                            // Selection ring (shown when selected but not today)
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: 1.5
                                border.color: isSelected && !isToday ? "#40ffffff" : "transparent"
                                Behavior on border.color { ColorAnimation { duration: 110 } }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayNum
                            color: {
                                if (isToday) return "#ffffff";
                                if (weekCol === 0) return sundayColor;
                                if (weekCol === 6) return saturdayColor;
                                return textPrimary;
                            }
                            opacity: 1.0
                            font.pixelSize: 13
                            font.family: textFontFamily
                            font.weight: isToday ? Font.Bold : Font.Normal
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calendarPanel.selectedDay   = dayNum;
                                calendarPanel.selectedMonth = viewMonth;
                                calendarPanel.selectedYear  = viewYear;
                                calendarPanel.userInteracted();
                            }
                        }
                    }
                }

                // Next month's leading days (greyed out, non-interactive)
                Repeater {
                    model: {
                        let filled = dayGrid.firstDay + dayGrid.numDays;
                        let rem = filled % 7;
                        return rem === 0 ? 0 : 7 - rem;
                    }

                    Item {
                        width: dayGrid.width / 7
                        height: width

                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            color: "#2effffff"
                            font.pixelSize: 13
                            font.family: textFontFamily
                        }
                    }
                }
            }

            // ── Selected date label ──────────────────────────────────────
            Item {
                width: parent.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: moduleColor

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""    // calendar icon via Nerd Font
                            color: cardAccent
                            font.pixelSize: 12
                            font.family: userConfig.iconFontFamily
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                let d = new Date(selectedYear, selectedMonth, selectedDay);
                                let days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
                                let mos  = ["Jan","Feb","Mar","Apr","May","Jun",
                                            "Jul","Aug","Sep","Oct","Nov","Dec"];
                                return days[d.getDay()] + ", " + mos[d.getMonth()] + " " + d.getDate() + " " + d.getFullYear();
                            }
                            color: textSecondary
                            font.pixelSize: 11
                            font.family: textFontFamily
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }
}
