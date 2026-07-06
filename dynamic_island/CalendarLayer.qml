import QtQuick

Item {
    id: calendarPanel

    UserConfig {
        id: userConfig
    }

    Timer {
        id: todayUpdater
        interval: 60000 // update every minute
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            calendarPanel.today = new Date();
        }
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

    property int viewYear:      today ? today.getFullYear() : new Date().getFullYear()
    property int viewMonth:     today ? today.getMonth() : new Date().getMonth()        // 0-based
    property int selectedDay:   today ? today.getDate() : new Date().getDate()
    property int selectedMonth: today ? today.getMonth() : new Date().getMonth()
    property int selectedYear:  today ? today.getFullYear() : new Date().getFullYear()

    readonly property int prevMonthYear: viewMonth === 0 ? viewYear - 1 : viewYear
    readonly property int prevMonthMonth: viewMonth === 0 ? 11 : viewMonth - 1
    readonly property int nextMonthYear: viewMonth === 11 ? viewYear + 1 : viewYear
    readonly property int nextMonthMonth: viewMonth === 11 ? 0 : viewMonth + 1

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var dayHeaders: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    // ── Helpers ───────────────────────────────────────────────────────────
    function daysInMonth(yr, mo) {
        return new Date(yr, mo + 1, 0, 12, 0, 0).getDate();
    }

    // Returns 0 = Sunday, 1 = Monday, etc. at 12:00 PM (noon) to avoid DST offsets
    function firstWeekday(yr, mo) {
        return new Date(yr, mo, 1, 12, 0, 0).getDay();
    }

    function isTodayCell(d) {
        let t = today;
        return t && d === t.getDate() && viewMonth === t.getMonth() && viewYear === t.getFullYear();
    }

    function isSelectedCell(d) {
        return d === selectedDay && viewMonth === selectedMonth && viewYear === selectedYear;
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear -= 1;
        } else {
            viewMonth -= 1;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear += 1;
        } else {
            viewMonth += 1;
        }
    }

    function goToday() {
        today = new Date();
        viewYear  = today.getFullYear();
        viewMonth = today.getMonth();
        selectedDay   = today.getDate();
        selectedMonth = today.getMonth();
        selectedYear  = today.getFullYear();
    }

    // ── Root background card ──────────────────────────────────────────────
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: panelBg

        // Prevent clicks on the panel background from propagating to dismissArea
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => { mouse.accepted = true; }
        }

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

                Repeater {
                    model: 42

                    Item {
                        id: dayCell
                        width: dayGrid.width / 7
                        height: width

                        readonly property string cellType: {
                            if (index < dayGrid.firstDay) return "prev";
                            if (index < dayGrid.firstDay + dayGrid.numDays) return "curr";
                            return "next";
                        }

                        readonly property int dayNum: {
                            if (cellType === "prev") {
                                let prevMoDays = calendarPanel.daysInMonth(prevMonthYear, prevMonthMonth);
                                return prevMoDays - (dayGrid.firstDay - 1 - index);
                            }
                            if (cellType === "curr") {
                                return index - dayGrid.firstDay + 1;
                            }
                            return index - (dayGrid.firstDay + dayGrid.numDays) + 1;
                        }

                        readonly property int weekCol: index % 7
                        readonly property bool isToday: cellType === "curr" && calendarPanel.isTodayCell(dayNum)
                        readonly property bool isSelected: cellType === "curr" && calendarPanel.isSelectedCell(dayNum)
                        readonly property bool hovered: cellType === "curr" && cellMouse.containsMouse

                        Rectangle {
                            id: dayBg
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 6
                            height: width
                            radius: width / 2

                            color: {
                                if (cellType !== "curr") return "transparent";
                                if (isToday) return cardAccent;
                                if (isSelected) return moduleHover;
                                if (hovered) return "#18ffffff";
                                return "transparent";
                            }

                            Behavior on color { ColorAnimation { duration: 110 } }

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
                                if (cellType !== "curr") return "#2effffff";
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
                            enabled: cellType === "curr"
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
                            text: "󰃭"    // calendar icon via Nerd Font
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
