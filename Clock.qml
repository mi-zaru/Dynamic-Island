// Clock.qml
import Quickshell
import QtQuick

Text {
    id: clockText

    property bool hovered: false

    text: Qt.formatDateTime(clock.date, "H:mm")
    color: "black"

    font {
        family: "SF Pro Display"
        letterSpacing: 2
        pixelSize: hovered ? 26 : 17
        weight: 600
    }

    Behavior on font.pixelSize {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
