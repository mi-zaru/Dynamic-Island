// Calendar.qml
import Quickshell
import QtQuick

Item {
    id: calendar

    property bool expanded: false
    property bool showMonth: false

    // Injected from shell.qml's single MouseArea:
    property int  hoveredCell:        -1
    property bool prevButtonHovered:  false
    property bool nextButtonHovered:  false

    readonly property bool miniVisible:  expanded && !showMonth
    readonly property bool monthVisible: expanded &&  showMonth

    // ─── Colors ─────────────────────────────────────────────
    readonly property color weekendColor:    "#ff5f5f"
    readonly property color normalColor:     "#1a1a1a"
    readonly property color otherMonthColor: "#c4c4c4"
    readonly property color headerColor:     "#111111"
    readonly property color hoverBgColor:    "#e6e6e6"

    // ─── Month navigation state ─────────────────────────────
    property int viewYear:  new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    function prevMonth() {
        let m = viewMonth - 1, y = viewYear
        if (m < 0) { m = 11; y-- }
        viewMonth = m; viewYear = y
    }
    function nextMonth() {
        let m = viewMonth + 1, y = viewYear
        if (m > 11) { m = 0; y++ }
        viewMonth = m; viewYear = y
    }

    readonly property string monthLabel:
        Qt.formatDate(new Date(viewYear, viewMonth, 1), "MMMM yyyy")

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
    readonly property date today: systemClock.date

    // ════════════════════════════════════════════════════════
    //  MINI — 5-day strip
    // ════════════════════════════════════════════════════════
    Item {
        id: miniView
        anchors.horizontalCenter: parent.horizontalCenter
        y: 50
        width: parent.width - 48
        height: 44

        opacity: miniVisible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Row {
            id: daysRow
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 0

            Repeater {
                model: 7
                delegate: Item {
                    width: daysRow.width / 7
                    height: daysRow.height

                    property int dayOffset: index - 3
                    property date currentDate: {
                        let d = new Date(systemClock.date)
                        d.setDate(d.getDate() + dayOffset)
                        return d
                    }
                    property bool isToday: dayOffset === 0
                    property bool isWeekend: {
                        const d = currentDate.getDay()
                        return d === 5 || d === 6
                    }
                    property real fadeOpacity: {
                        const a = Math.abs(dayOffset)
                        return a === 3 ? 0.2 : a === 2 ? 0.55 : 1.0
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: isToday ? Qt.formatDate(currentDate, "ddd")
                                          : Qt.formatDate(currentDate, "ddd").charAt(0)
                            color: isWeekend ? calendar.weekendColor : calendar.normalColor
                            opacity: fadeOpacity
                            font {
                                family: "SF Pro Display"
                                pixelSize: isToday ? 14 : 10
                                weight: isToday ? 700 : 500
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(currentDate, "d")
                            color: isWeekend ? calendar.weekendColor : calendar.normalColor
                            opacity: fadeOpacity
                            font {
                                family: "SF Pro Display"
                                pixelSize: isToday ? 15 : 11
                                weight: isToday ? 700 : 500
                            }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════
    //  MONTH — full month grid
    // ════════════════════════════════════════════════════════
    Item {
        id: monthView
        anchors.fill: parent
        opacity: monthVisible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        readonly property var gridModel: {
            const y = calendar.viewYear, m = calendar.viewMonth
            const firstDow = new Date(y, m, 1).getDay()
            const start = new Date(y, m, 1 - firstDow)
            const ty = calendar.today.getFullYear()
            const tm = calendar.today.getMonth()
            const td = calendar.today.getDate()
            const cells = []
            for (let i = 0; i < 42; i++) {
                const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
                const dow = d.getDay()
                cells.push({
                    day: d.getDate(),
                    current: d.getFullYear() === y && d.getMonth() === m,
                    isToday: d.getFullYear() === ty && d.getMonth() === tm && d.getDate() === td,
                    isWeekend: dow === 5 || dow === 6
                })
            }
            return cells
        }

        // ── Header (lifted up) ──────────────────────────────
        Item {
            id: headerRow
            anchors.top: parent.top
            anchors.topMargin: -4
            anchors.left: parent.left
            anchors.right: parent.right
            height: 26

            Text {
                anchors.centerIn: parent
                text: calendar.monthLabel
                color: calendar.headerColor
                font {
                    family: "SF Pro Display"
                    pixelSize: 16
                    weight: 700
                    letterSpacing: 0.5
                }
            }
        }

        // ── Content column (weekday + grid) — unchanged position ──
        Column {
            id: contentColumn
            anchors.top: parent.top
            anchors.topMargin: 36
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 10

            Row {
                id: weekdayRow
                width: parent.width
                height: 16

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    delegate: Item {
                        width: parent.width / 7
                        height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: (index === 5 || index === 6)
                                   ? calendar.weekendColor : "#888888"
                            font {
                                family: "SF Pro Display"
                                pixelSize: 11
                                weight: 600
                            }
                        }
                    }
                }
            }

            Grid {
                id: grid
                width: parent.width
                height: contentColumn.height - weekdayRow.height - contentColumn.spacing
                columns: 7
                rowSpacing: 2
                columnSpacing: 0

                Repeater {
                    model: monthView.gridModel
                    delegate: Item {
                        width: grid.width / 7
                        height: (grid.height - 10) / 6

                        // Lifted container so pill + digit look
                        // truly centered in the cell.
                        Item {
                            anchors.centerIn: parent
                            width: 22
                            height: 22

                            // Hover bg — current-month, non-today only
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: calendar.hoverBgColor
                                opacity: (calendar.hoveredCell === index
                                          && !modelData.isToday
                                          && modelData.current) ? 1.0 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }
                            }

                            // Today bg
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: modelData.isToday ? "#111111" : "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: {
                                    if (modelData.isToday)   return "white"
                                    if (!modelData.current)  return calendar.otherMonthColor
                                    if (modelData.isWeekend) return calendar.weekendColor
                                    return calendar.normalColor
                                }
                                opacity: modelData.current ? 1.0 : 0.85
                                font {
                                    family: "SF Pro Display"
                                    pixelSize: 12
                                    weight: modelData.isToday ? 700 : 500
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
