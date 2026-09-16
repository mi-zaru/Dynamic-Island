// Calendar.qml
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: calendar

    property bool expanded: false

    readonly property color weekendColor: "#ff5f5f"
    readonly property color normalColor:  "black"

    opacity: expanded ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Row {
        id: daysRow

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: 16
            rightMargin: 16
        }

        spacing: 0

        Repeater {
            model: 7

            delegate: Item {
                width: daysRow.width / 7
                height: daysRow.height

                property int dayOffset: index - 3

                property date currentDate: {
                    let date = new Date(systemClock.date)
                    date.setDate(date.getDate() + dayOffset)
                    return date
                }

                property bool isToday: dayOffset === 0

                property bool isWeekend: {
                    let d = currentDate.getDay()
                    return d === 5 || d === 6
                }

                property real fadeOpacity: {
                    let d = Math.abs(dayOffset)
                    if (d === 3) return 0.2
                    if (d === 2) return 0.55
                    return 1.0
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: isToday
                            ? Qt.formatDate(currentDate, "ddd")
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