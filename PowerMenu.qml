// PowerMenu.qml
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    signal dismissed()

    readonly property string textFont: "SF Pro Text"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    readonly property string lockCommand:     "hyprlock"
    readonly property string logoutCommand:   "hyprctl dispatch exit"
    readonly property string rebootCommand:   "systemctl reboot"
    readonly property string poweroffCommand: "systemctl poweroff"

    readonly property int buttonSize:    100
    readonly property int buttonGap:     10
    readonly property int sidePadding:   10
    readonly property int topPadding:    10
    readonly property int bottomPadding: 10
    readonly property int buttonRadius:  16

    readonly property int launcherWidth:
        sidePadding * 2 + buttonSize * 4 + buttonGap * 3

    readonly property int launcherHeight:
        topPadding + buttonSize + bottomPadding

    implicitWidth:  launcherWidth
    implicitHeight: launcherHeight
    width:  implicitWidth
    height: implicitHeight

    property int selectedIndex: 0

    focus: true

    Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Escape:
            root.dismissed(); event.accepted = true; return
        case Qt.Key_Left:
        case Qt.Key_H:
            root.selectedIndex = Math.max(0, root.selectedIndex - 1)
            event.accepted = true; return
        case Qt.Key_Right:
        case Qt.Key_L:
            root.selectedIndex = Math.min(3, root.selectedIndex + 1)
            event.accepted = true; return
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            switch (root.selectedIndex) {
            case 0: root.doLock();     break
            case 1: root.doLogout();   break
            case 2: root.doReboot();   break
            case 3: root.doPoweroff(); break
            }
            event.accepted = true; return
        }
    }

    Process { id: lockProc;     running: false }
    Process { id: logoutProc;   running: false }
    Process { id: rebootProc;   running: false }
    Process { id: poweroffProc; running: false }

    function doLock() {
        lockProc.command = ["bash", "-c", lockCommand]
        lockProc.running = true
        dismissed()
    }
    function doLogout() {
        logoutProc.command = ["bash", "-c", logoutCommand]
        logoutProc.running = true
        dismissed()
    }
    function doReboot() {
        rebootProc.command = ["bash", "-c", rebootCommand]
        rebootProc.running = true
        dismissed()
    }
    function doPoweroff() {
        poweroffProc.command = ["bash", "-c", poweroffCommand]
        poweroffProc.running = true
        dismissed()
    }

    function open() {
        selectedIndex = 0
        focusGrabTimer.restart()
    }
    function close() {
        focusGrabTimer.stop()
    }

    Timer {
        id: focusGrabTimer
        interval: 40; repeat: true; running: false
        property int attempts: 0
        onTriggered: {
            attempts++
            if (!root.visible || attempts > 25) { stop(); attempts = 0; return }
            if (!root.activeFocus) root.forceActiveFocus()
        }
        onRunningChanged: { if (running) attempts = 0 }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.topPadding
        spacing: root.buttonGap

        PowerButton {
            size: root.buttonSize
            radius: root.buttonRadius
            index: 0
            isSelected: root.selectedIndex === 0
            icon: "󰌾"
            label: "Lock"
            onActivated: root.doLock()
        }
        PowerButton {
            size: root.buttonSize
            radius: root.buttonRadius
            index: 1
            isSelected: root.selectedIndex === 1
            icon: "󰍃"
            label: "Log out"
            onActivated: root.doLogout()
        }
        PowerButton {
            size: root.buttonSize
            radius: root.buttonRadius
            index: 2
            isSelected: root.selectedIndex === 2
            icon: "󰑓"
            label: "Reboot"
            onActivated: root.doReboot()
        }
        PowerButton {
            size: root.buttonSize
            radius: root.buttonRadius
            index: 3
            isSelected: root.selectedIndex === 3
            icon: "󰐥"
            label: "Power off"
            danger: true
            onActivated: root.doPoweroff()
        }
    }

    component PowerButton: Item {
        id: btn

        property int size: 120
        property int radius: 22
        property int index: 0
        property string icon: ""
        property string label: ""
        property bool danger: false
        property bool isSelected: false

        signal activated()

        readonly property bool highlighted: isSelected || hover.hovered

        width: size
        height: size

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hover.hovered) root.selectedIndex = btn.index
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: btn.radius

            color: {
                if (btn.danger)
                    return btn.highlighted ? "#fecaca" : "#fee2e2"
                return btn.highlighted ? "#dcdcdc" : "#ececec"
            }

            Behavior on color {
                ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
        }

        Column {
            id: content
            anchors.centerIn: parent
            spacing: 6

            y: btn.highlighted ? -4 : 0
            scale: mouse.pressed ? 0.88 : (btn.highlighted ? 1.22 : 1.0)

            Behavior on scale {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 2.2
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.8
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.icon
                color: btn.danger ? "#dc2626" : "#111111"
                font { family: root.iconFont; pixelSize: 36 }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.label
                color: btn.danger ? "#dc2626" : "#555555"
                font { family: root.textFont; pixelSize: 13; weight: 500 }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }
    }
}
