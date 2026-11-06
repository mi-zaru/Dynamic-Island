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

    readonly property string textFont: "SF Pro Text"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // ─────────────── IPC ───────────────
    IpcHandler {
        target: "appLauncher"
        function toggle(): void {
            panel.wallpaperMode = false; wallpaperSwitcher.close()
            panel.emojiMode = false; emojiPicker.close()
            panel.powerMode = false; powerMenu.close()
            panel.launcherMode = !panel.launcherMode
            panel.clicked = false
            if (panel.launcherMode) appLauncher.open()
            else appLauncher.close()
        }
        function close(): void {
            panel.launcherMode = false; panel.clicked = false
            appLauncher.close()
        }
    }

    IpcHandler {
        target: "wallpaperSwitcher"
        function toggle(): void {
            panel.launcherMode = false; appLauncher.close()
            panel.emojiMode = false; emojiPicker.close()
            panel.powerMode = false; powerMenu.close()
            panel.wallpaperMode = !panel.wallpaperMode
            panel.clicked = false
            if (panel.wallpaperMode) wallpaperSwitcher.open()
            else wallpaperSwitcher.close()
        }
        function close(): void {
            panel.wallpaperMode = false; panel.clicked = false
            wallpaperSwitcher.close()
        }
    }

    IpcHandler {
        target: "emojiPicker"
        function toggle(): void {
            panel.launcherMode = false; appLauncher.close()
            panel.wallpaperMode = false; wallpaperSwitcher.close()
            panel.powerMode = false; powerMenu.close()
            panel.emojiMode = !panel.emojiMode
            panel.clicked = false
            if (panel.emojiMode) emojiPicker.open()
            else emojiPicker.close()
        }
        function close(): void {
            panel.emojiMode = false; panel.clicked = false
            emojiPicker.close()
        }
    }

    IpcHandler {
        target: "powerMenu"
        function toggle(): void {
            panel.launcherMode = false; appLauncher.close()
            panel.wallpaperMode = false; wallpaperSwitcher.close()
            panel.emojiMode = false; emojiPicker.close()
            panel.powerMode = !panel.powerMode
            panel.clicked = false
            if (panel.powerMode) powerMenu.open()
            else powerMenu.close()
        }
        function close(): void {
            panel.powerMode = false; panel.clicked = false
            powerMenu.close()
        }
    }

    PanelWindow {
        id: panel

        property bool hovered: false
        property bool clicked: false
        property bool launcherMode: false
        property bool wallpaperMode: false
        property bool emojiMode: false
        property bool powerMode: false

        readonly property bool monthMode:
            hovered && clicked
            && !launcherMode && !wallpaperMode && !emojiMode && !powerMode

        implicitWidth: 1200
        implicitHeight: 480
        aboveWindows: true
        exclusiveZone: 40
        focusable: true

        WlrLayershell.keyboardFocus:
            (panel.launcherMode || panel.wallpaperMode || panel.emojiMode || panel.powerMode)
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        WlrLayershell.layer:
            (panel.launcherMode || panel.wallpaperMode || panel.emojiMode || panel.powerMode)
                ? WlrLayer.Overlay : WlrLayer.Top

        anchors { top: true }
        margins { top: 10; bottom: 5 }
        color: "transparent"

        mask: Region {
            Region {
                x: capsule.x; y: capsule.y
                width: capsule.width; height: capsule.height
            }
            Region {
                x: musicPlayer.x; y: musicPlayer.y
                width: musicPlayer.spotifyRunning ? musicPlayer.width : 0
                height: musicPlayer.spotifyRunning ? musicPlayer.height : 0
            }
        }

        onLauncherModeChanged: {
            if (launcherMode) Qt.callLater(function() { appLauncher.open() })
            else appLauncher.close()
        }
        onWallpaperModeChanged: {
            if (wallpaperMode) Qt.callLater(function() { wallpaperSwitcher.open() })
            else wallpaperSwitcher.close()
        }
        onEmojiModeChanged: {
            if (emojiMode) Qt.callLater(function() { emojiPicker.open() })
            else emojiPicker.close()
        }
        onPowerModeChanged: {
            if (powerMode) Qt.callLater(function() { powerMenu.open() })
            else powerMenu.close()
        }

        Item {
            id: mainRow
            anchors.fill: parent

            Rectangle {
                id: capsule
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                z: 5

                readonly property int normalIdleWidth: 110
                readonly property int idleHeight: 33
                readonly property int hoverWidth: 300
                readonly property int hoverHeight: 120
                readonly property int monthWidth: 320
                readonly property int monthHeight: 246
                readonly property int volumeWidth: 260

                readonly property bool volumeMode: volumeOsd.active
                readonly property bool workspaceMode:
                    workspaceOsd.active && !panel.hovered
                    && !volumeMode && !panel.launcherMode
                    && !panel.wallpaperMode && !panel.emojiMode
                    && !panel.powerMode

                readonly property bool showOfflineIcon:
                    networkStatus.checked && !networkStatus.online
                    && !panel.monthMode && !volumeMode
                    && !panel.launcherMode && !panel.wallpaperMode
                    && !panel.emojiMode && !panel.powerMode
                    && !workspaceOsd.active

                readonly property real iconGap: 8
                readonly property real offlineIconW: Math.max(offlineIcon.implicitWidth, 20)
                readonly property real trailingW:
                    showOfflineIcon ? (iconGap + offlineIconW) : 0
                readonly property int workspaceWidth:
                    Math.max(normalIdleWidth, Math.round(workspaceLabel.implicitWidth + 56))
                readonly property int idleWidth:
                    showOfflineIcon
                        ? (normalIdleWidth + Math.round(iconGap + offlineIconW))
                        : normalIdleWidth

                width: volumeMode ? volumeWidth
                    : panel.launcherMode ? appLauncher.implicitWidth
                    : panel.wallpaperMode ? wallpaperSwitcher.implicitWidth
                    : panel.emojiMode ? emojiPicker.implicitWidth
                    : panel.powerMode ? powerMenu.implicitWidth
                    : panel.monthMode ? monthWidth
                    : panel.hovered ? hoverWidth
                    : workspaceMode ? workspaceWidth
                    : idleWidth

                height: panel.monthMode ? monthHeight
                    : panel.launcherMode ? appLauncher.implicitHeight
                    : panel.wallpaperMode ? wallpaperSwitcher.implicitHeight
                    : panel.emojiMode ? emojiPicker.implicitHeight
                    : panel.powerMode ? powerMenu.implicitHeight
                    : panel.hovered ? hoverHeight : idleHeight

                radius: 20
                color: "white"
                opacity: 0.95
                clip: true

                Behavior on width {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.10
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.10
                    }
                }

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
                        if (gx < 0 || gx >= gridW || gy < 0 || gy >= gridH) return -1
                        const cellW = gridW / 7
                        const cellH = (gridH - 10) / 6
                        const col = Math.floor(gx / cellW)
                        let row = Math.floor(gy / (cellH + 2))
                        if (row > 5) row = 5
                        return row * 7 + col
                    }

                    onEntered: panel.hovered = true
                    onExited: { panel.hovered = false; panel.clicked = false }
                    onClicked: {
                        if (panel.launcherMode || panel.wallpaperMode
                            || panel.emojiMode || panel.powerMode) return
                        if (overPrevBtn) { calendar.prevMonth(); return }
                        if (overNextBtn) { calendar.nextMonth(); return }
                        if (panel.hovered) panel.clicked = !panel.clicked
                    }
                }

                Clock {
                    id: clock
                    property real _shift: -capsule.trailingW / 2
                    Behavior on _shift {
                        NumberAnimation {
                            duration: 380
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.15
                        }
                    }
                    x: capsule.width / 2 - width / 2 + _shift
                    opacity: (panel.monthMode || panel.launcherMode
                        || capsule.volumeMode || workspaceOsd.active
                        || panel.wallpaperMode || panel.emojiMode
                        || panel.powerMode) ? 0 : 1
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                    property real centerY: panel.hovered
                        ? capsule.hoverHeight * 0.3 : capsule.idleHeight / 2
                    y: centerY - height / 2
                    Behavior on centerY {
                        NumberAnimation {
                            duration: 380
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.15
                        }
                    }
                    hovered: panel.hovered && !panel.monthMode
                        && !panel.launcherMode && !panel.wallpaperMode
                        && !panel.emojiMode && !capsule.volumeMode
                        && !panel.powerMode
                }

                Text {
                    id: workspaceLabel
                    text: workspaceOsd.workspaceId > 0
                        ? "Workspace " + workspaceOsd.workspaceId : ""

                    property real _shift: -capsule.trailingW / 2
                    Behavior on _shift {
                        NumberAnimation {
                            duration: 380
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.15
                        }
                    }
                    x: capsule.width / 2 - width / 2 + _shift
                    property real centerY: panel.hovered
                        ? capsule.hoverHeight * 0.3 : capsule.idleHeight / 2
                    y: centerY - height / 2
                    Behavior on centerY {
                        NumberAnimation {
                            duration: 380
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.15
                        }
                    }

                    color: "black"
                    font {
                        family: root.textFont
                        letterSpacing: 0
                        pixelSize: 17
                        weight: 500
                    }
                    opacity: (workspaceOsd.active && !panel.monthMode
                        && !panel.launcherMode && !panel.wallpaperMode
                        && !panel.emojiMode && !capsule.volumeMode
                        && !panel.powerMode) ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                Text {
                    id: offlineIcon
                    text: "󰖪"
                    color: "black"
                    font { family: root.iconFont; pixelSize: 20 }
                    width: capsule.offlineIconW
                    horizontalAlignment: Text.AlignHCenter
                    x: clock.x + clock.width + capsule.iconGap
                    anchors.verticalCenter: clock.verticalCenter
                    opacity: capsule.showOfflineIcon ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }
                }

                Calendar {
                    id: calendar
                    expanded: panel.hovered && !capsule.volumeMode
                        && !panel.launcherMode && !panel.wallpaperMode
                        && !panel.emojiMode && !panel.powerMode
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

                AppLauncher {
                    id: appLauncher
                    visible: panel.launcherMode && !capsule.volumeMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    z: 100
                    function closeAll() {
                        panel.launcherMode = false; panel.clicked = false
                        appLauncher.close()
                    }
                    onLaunched:  closeAll()
                    onDismissed: closeAll()
                }

                WallpaperSwitcher {
                    id: wallpaperSwitcher
                    visible: panel.wallpaperMode && !capsule.volumeMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    z: 100
                    function closeAll() {
                        panel.wallpaperMode = false; panel.clicked = false
                        wallpaperSwitcher.close()
                    }
                    onLaunched:  closeAll()
                    onDismissed: closeAll()
                }

                EmojiPicker {
                    id: emojiPicker
                    visible: panel.emojiMode && !capsule.volumeMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    z: 100
                    function closeAll() {
                        panel.emojiMode = false; panel.clicked = false
                        emojiPicker.close()
                    }
                    onSelected:  closeAll()
                    onDismissed: closeAll()
                }

                PowerMenu {
                    id: powerMenu
                    visible: panel.powerMode && !capsule.volumeMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    z: 100
                    function closeAll() {
                        panel.powerMode = false; panel.clicked = false
                        powerMenu.close()
                    }
                    onDismissed: closeAll()
                }

                Item {
                    id: prevButton
                    visible: panel.monthMode && !capsule.volumeMode && !panel.powerMode
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
                        font { family: root.textFont; pixelSize: 18; weight: 500 }
                    }
                }

                Item {
                    id: nextButton
                    visible: panel.monthMode && !capsule.volumeMode && !panel.powerMode
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
                        font { family: root.textFont; pixelSize: 18; weight: 500 }
                    }
                }

                VolumeOsd {
                    id: volumeOsd
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: capsule.volumeWidth
                }
            }

            WorkspaceOsd { id: workspaceOsd }
            NetCheck { id: networkStatus }

            MusicPlayer {
                id: musicPlayer
                anchors.right: capsule.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                z: 1
                transform: Translate {
                    x: musicPlayer.slideProgress * (musicPlayer.collapsedSize + 20)
                }
            }
        }
    }
}