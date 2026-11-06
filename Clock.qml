// Clock.qml
import Quickshell
import QtQuick

Item {
    id: clockText

    property bool hovered: false

    // ── Fonts ──
    readonly property string displayFont: "SF Pro Display"
    readonly property string textFont:    "SF Pro Text"

    readonly property string timeStr: Qt.formatDateTime(clock.date, "HH:mm")

    property real fontSize: hovered ? 26 : 17
    Behavior on fontSize {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    implicitWidth: displayRow.implicitWidth
    implicitHeight: displayRow.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: displayRow
        spacing: 2

        Repeater {
            model: 5

            delegate: Item {
                id: slot
                required property int index

                readonly property string myChar: clockText.timeStr.charAt(index)
                readonly property bool isColon: myChar === ":"

                Text {
                    id: measureText
                    text: slot.isColon ? ":" : "8"
                    visible: false
                    font {
                        family: clockText.displayFont
                        pixelSize: clockText.fontSize
                        weight: 500
                    }
                }

                width: measureText.implicitWidth
                height: measureText.implicitHeight
                clip: true

                property string currentChar: ""
                property string pendingChar: ""

                Component.onCompleted: {
                    currentChar = myChar
                    pendingChar = myChar
                }

                onMyCharChanged: {
                    if (currentChar === "") return
                    if (myChar === currentChar) return
                    if (isColon || currentChar === ":") {
                        currentChar = myChar
                        pendingChar = myChar
                        return
                    }
                    pendingChar = myChar
                    textContainer.y = 0
                    swapAnim.restart()
                }

                Item {
                    id: textContainer
                    width:  slot.width
                    height: slot.height
                    y: 0

                    Text {
                        anchors.centerIn: parent
                        text: slot.currentChar
                        color: "black"
                        font {
                            family: clockText.displayFont
                            pixelSize: clockText.fontSize
                            weight: 500
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -textContainer.height
                        text: slot.pendingChar
                        color: "black"
                        font {
                            family: clockText.displayFont
                            pixelSize: clockText.fontSize
                            weight: 500
                        }
                    }
                }

                NumberAnimation {
                    id: swapAnim
                    target: textContainer
                    property: "y"
                    to: slot.height
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2

                    onFinished: {
                        slot.currentChar = slot.pendingChar
                        textContainer.y = 0
                    }
                }
            }
        }
    }
}