import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "."
import "widgets"

ShellRoot {

    // ─────────────── IPC ───────────────
    IpcHandler {
        target: "appLauncher"

        function toggle(): void {
            // ◀── CHANGED — close wallpaper mode when opening launcher
            panel.wallpaperMode = false
            wallpaperSwitcher.close()

            panel.launcherMode = !panel.launcherMode
            panel.clicked = false
            if (panel.launcherMode) appLauncher.open()
            else appLauncher.close()
        }

        function close(): void {
            panel.launcherMode = false
            panel.clicked = false
            appLauncher.close()
        }
    }

    // ◀── NEW — wallpaper switcher IPC
    IpcHandler {
        target: "wallpaperSwitcher"

        function toggle(): void {
            // close launcher when opening wallpaper switcher
            panel.launcherMode = false
            appLauncher.close()

            panel.wallpaperMode = !panel.wallpaperMode
            panel.clicked = false
            if (panel.wallpaperMode) wallpaperSwitcher.open()
            else wallpaperSwitcher.close()
        }

        function close(): void {
            panel.wallpaperMode = false
            panel.clicked = false
            wallpaperSwitcher.close()
        }
    }

    // ─────────────── PANEL ───────────────
    PanelWindow {
        id: panel

        property bool hovered: false
        property bool clicked: false
        property bool launcherMode: false
        property bool wallpaperMode: false           // ◀── NEW

        // ◀── CHANGED — exclude wallpaperMode from month mode
        readonly property bool monthMode:
            hovered && clicked && !launcherMode && !wallpaperMode

        implicitWidth: 1000
        implicitHeight: 420
        aboveWindows: true
        exclusiveZone: 40

        focusable: true

        // ◀── CHANGED — keyboard focus for wallpaper mode
        WlrLayershell.keyboardFocus:
            (panel.launcherMode || panel.wallpaperMode)
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

        // ◀── CHANGED — overlay layer for wallpaper mode
        WlrLayershell.layer:
            (panel.launcherMode || panel.wallpaperMode)
                ? WlrLayer.Overlay
                : WlrLayer.Top

        anchors { top: true }
        margins { top: 10; bottom: 5 }
        color: "transparent"

        onLauncherModeChanged: {
            if (launcherMode) Qt.callLater(function() { appLauncher.open() })
            else appLauncher.close()
        }

        // ◀── NEW — drive open/close of the wallpaper switcher
        onWallpaperModeChanged: {
            if (wallpaperMode) Qt.callLater(function() { wallpaperSwitcher.open() })
            else wallpaperSwitcher.close()
        }

        Item {
            id: mainRow
            anchors.fill: parent

            // ─── CAPSULE ───
            Rectangle {
                id: capsule
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top

                readonly property int idleWidth: 130
                readonly property int idleHeight: 37
                readonly property int hoverWidth: 300
                readonly property int hoverHeight: 120
                readonly property int monthWidth: 320
                readonly property int monthHeight: 246
                readonly property int volumeWidth: 260
                readonly property int bothIconsWidth: 165

                readonly property bool volumeMode: volumeOsd.active

                readonly property bool workspaceMode:
                    workspaceOsd.active && !panel.hovered
                    && !volumeMode && !panel.launcherMode
                    && !panel.wallpaperMode                          // ◀── CHANGED

                readonly property bool showMuteIcon:
                    volumeOsd.muted && !panel.hovered && !volumeMode
                    && !workspaceOsd.active && !panel.launcherMode
                    && !panel.wallpaperMode                          // ◀── CHANGED

                readonly property bool showNotifIcon:
                    notifications.active && !panel.hovered && !volumeMode
                    && !workspaceOsd.active && !panel.launcherMode
                    && !panel.wallpaperMode                          // ◀── CHANGED

                readonly property bool showBothIcons: showMuteIcon && showNotifIcon

                readonly property real iconGap: 10
                readonly property real muteIconW: muteIcon.implicitWidth
                readonly property real notifIconW: notifIcon.implicitWidth

                readonly property real trailingW:
                    (showMuteIcon ? iconGap + muteIconW : 0)
                    + (showNotifIcon ? iconGap + notifIconW : 0)

                readonly property int workspaceWidth:
                    Math.max(idleWidth, Math.round(workspaceLabel.implicitWidth + 56))

                // ◀── CHANGED — add wallpaper branch
                width: volumeMode
                    ? volumeWidth
                    : panel.launcherMode
                        ? appLauncher.implicitWidth
                        : panel.wallpaperMode
                            ? wallpaperSwitcher.implicitWidth
                            : panel.monthMode
                                ? monthWidth
                                : panel.hovered
                                    ? hoverWidth
                                    : workspaceMode
                                        ? workspaceWidth
                                        : (showBothIcons ? bothIconsWidth : idleWidth)

                // ◀── CHANGED — add wallpaper branch
                height: panel.monthMode
                    ? monthHeight
                    : panel.launcherMode
                        ? appLauncher.implicitHeight
                        : panel.wallpaperMode
                            ? wallpaperSwitcher.implicitHeight
                            : panel.hovered ? hoverHeight : idleHeight

                radius: 20
                color: "white"
                opacity: 0.95
                clip: true

                Behavior on width {
                    NumberAnimation { duration: 260; easing.type: Easing.OutQuint }
                }
                Behavior on height {
                    NumberAnimation { duration: 260; easing.type: Easing.OutQuint }
                }

                // ─── CAPSULE MOUSE AREA ───
                MouseArea {
                    id: capsuleArea
                    anchors.fill: parent
                    hoverEnabled: true

                    readonly property int btnW: 26
                    readonly property int btnH: 26
                    readonly property int btnX: 12
                    readonly property int btnY: 6

                    readonly property bool overPrevBtn:
                        panel.monthMode && !capsule.volumeMode
                        && mouseX >= btnX && mouseX <= btnX + btnW
                        && mouseY >= btnY && mouseY <= btnY + btnH

                    readonly property bool overNextBtn:
                        panel.monthMode && !capsule.volumeMode
                        && mouseX >= capsule.width - btnX - btnW
                        && mouseX <= capsule.width - btnX
                        && mouseY >= btnY && mouseY <= btnY + btnH

                    readonly property int hoveredCell: {
                        if (!panel.monthMode || capsule.volumeMode) return -1

                        const calW = 276
                        const calX = (capsule.width - calW) / 2
                        const calY = 12
                        const gridX = calX
                        const gridY = calY + 62
                        const gridW = calW
                        const gridH = (capsule.height - 24) - 62

                        const gx = mouseX - gridX
                        const gy = mouseY - gridY

                        if (gx < 0 || gx >= gridW || gy < 0 || gy >= gridH)
                            return -1

                        const cellW = gridW / 7
                        const cellH = (gridH - 10) / 6
                        const col = Math.floor(gx / cellW)
                        let row = Math.floor(gy / (cellH + 2))
                        if (row > 5) row = 5
                        return row * 7 + col
                    }

                    onEntered: panel.hovered = true

                    onExited: {
                        panel.hovered = false
                        panel.clicked = false
                    }

                    onPositionChanged: {
                        if (mouseX < 0 || mouseY < 0
                            || mouseX > width || mouseY > height) {
                            panel.hovered = false
                            panel.clicked = false
                        }
                    }

                    onClicked: {
                        // ◀── CHANGED — don't toggle click state in fullscreen modes
                        if (panel.launcherMode || panel.wallpaperMode) return
                        if (overPrevBtn) { calendar.prevMonth(); return }
                        if (overNextBtn) { calendar.nextMonth(); return }
                        if (panel.hovered) panel.clicked = !panel.clicked
                    }
                }

                // ─── CLOCK ───
                Clock {
                    id: clock

                    property real _shift: -capsule.trailingW / 2
                    Behavior on _shift {
                        NumberAnimation { duration: 500; easing.type: Easing.OutQuart }
                    }

                    x: capsule.width / 2 - width / 2 + _shift

                    // ◀── CHANGED — hide during wallpaper mode
                    opacity: (panel.monthMode || panel.launcherMode
                        || capsule.volumeMode || workspaceOsd.active
                        || panel.wallpaperMode) ? 0 : 1
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    property real centerY: panel.hovered
                        ? capsule.hoverHeight * 0.3
                        : capsule.idleHeight / 2
                    y: centerY - height / 2
                    Behavior on centerY {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    hovered: panel.hovered && !panel.monthMode
                        && !panel.launcherMode && !panel.wallpaperMode
                        && !capsule.volumeMode
                }

                // ─── WORKSPACE LABEL ───
                Text {
                    id: workspaceLabel

                    text: workspaceOsd.workspaceId > 0
                        ? "Workspace " + workspaceOsd.workspaceId
                        : ""

                    property real _shift: -capsule.trailingW / 2
                    Behavior on _shift {
                        NumberAnimation { duration: 500; easing.type: Easing.OutQuart }
                    }

                    x: capsule.width / 2 - width / 2 + _shift

                    property real centerY: panel.hovered
                        ? capsule.hoverHeight * 0.3
                        : capsule.idleHeight / 2
                    y: centerY - height / 2
                    Behavior on centerY {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    color: "black"
                    font {
                        family: "SF Pro Display"
                        letterSpacing: 2
                        pixelSize: 17
                        weight: 600
                    }

                    // ◀── CHANGED — hide during wallpaper mode
                    opacity: (workspaceOsd.active && !panel.monthMode
                        && !panel.launcherMode && !panel.wallpaperMode
                        && !capsule.volumeMode) ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                // ─── MUTE ICON ───
                Text {
                    id: muteIcon
                    text: "󰝟"
                    color: "black"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 20 }
                    x: clock.x + clock.width + capsule.iconGap
                    opacity: capsule.showMuteIcon ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }

                // ─── NOTIFICATION ICON ───
                Text {
                    id: notifIcon
                    text: "󰂞"
                    color: "black"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }

                    property real _localShift: capsule.showMuteIcon
                        ? capsule.muteIconW + capsule.iconGap
                        : 0
                    Behavior on _localShift {
                        NumberAnimation { duration: 500; easing.type: Easing.OutQuart }
                    }

                    x: clock.x + clock.width + capsule.iconGap + _localShift
                    opacity: capsule.showNotifIcon ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }

                // ─── CALENDAR ───
                Calendar {
                    id: calendar
                    // ◀── CHANGED — exclude wallpaper mode
                    expanded: panel.hovered && !capsule.volumeMode
                        && !panel.launcherMode && !panel.wallpaperMode
                    showMonth: panel.monthMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    width: 300
                    height: capsule.monthHeight - 24
                    hoveredCell: capsuleArea.hoveredCell
                    prevButtonHovered: capsuleArea.overPrevBtn
                    nextButtonHovered: capsuleArea.overNextBtn
                }

                // ─── APP LAUNCHER ───
                AppLauncher {
                    id: appLauncher
                    visible: panel.launcherMode && !capsule.volumeMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    z: 100

                    function closeAll() {
                        panel.launcherMode = false
                        panel.clicked = false
                        appLauncher.close()
                    }

                    onLaunched:  closeAll()
                    onDismissed: closeAll()
                }

                // ◀── NEW — WALLPAPER SWITCHER ─────────────────────
                WallpaperSwitcher {
                    id: wallpaperSwitcher
                    visible: panel.wallpaperMode && !capsule.volumeMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    z: 100

                    function closeAll() {
                        panel.wallpaperMode = false
                        panel.clicked = false
                        wallpaperSwitcher.close()
                    }

                    onLaunched:  closeAll()
                    onDismissed: closeAll()
                }

                // ─── PREV MONTH BUTTON ───
                Item {
                    id: prevButton
                    visible: panel.monthMode && !capsule.volumeMode
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 6
                    anchors.topMargin: 6
                    width: 26
                    height: 26

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "#c4c4c4"
                        opacity: capsuleArea.overPrevBtn ? 0.5 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: "‹"
                        color: "#111111"
                        font { family: "SF Pro Display"; pixelSize: 18; weight: 600 }
                    }
                }

                // ─── NEXT MONTH BUTTON ───
                Item {
                    id: nextButton
                    visible: panel.monthMode && !capsule.volumeMode
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 6
                    anchors.topMargin: 6
                    width: 26
                    height: 26

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "#c4c4c4"
                        opacity: capsuleArea.overNextBtn ? 0.5 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: "›"
                        color: "#111111"
                        font { family: "SF Pro Display"; pixelSize: 18; weight: 600 }
                    }
                }

                // ─── VOLUME OSD ───
                VolumeOsd {
                    id: volumeOsd
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: capsule.volumeWidth
                }
            }

            // ─── SIDE COMPONENTS ───
            Notifications { id: notifications }
            WorkspaceOsd { id: workspaceOsd }

            MusicPlayer {
                id: musicPlayer
                anchors.right: capsule.left
                anchors.rightMargin: musicPlayer.spotifyRunning ? 8 : 0
                anchors.top: parent.top
                Behavior on anchors.rightMargin {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}