// MusicPlayer.qml
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: musicPlayer

    readonly property color bgColor: "white"
    readonly property color fgColor: "black"
    readonly property color accent:  '#343434'

    readonly property var spotifyPlayer: {
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            const p = players[i]
            if (p.identity && p.identity.toLowerCase() === "spotify")
                return p
        }
        return null
    }

    readonly property bool spotifyRunning: spotifyPlayer !== null
    readonly property bool isPlaying: spotifyPlayer ? spotifyPlayer.isPlaying : false

    readonly property real length: spotifyPlayer ? (spotifyPlayer.length || 0) : 0

    property real displayPosition: 0
    readonly property real progress: length > 0
        ? Math.min(1, displayPosition / length)
        : 0

    property bool hovered: false

    readonly property int collapsedSize: 37
    readonly property int expandedWidth: 340
    readonly property int expandedHeight: 120
    readonly property int padding: 7
    readonly property int rightPadding: 14

    implicitWidth:  !spotifyRunning ? 0 : (hovered ? expandedWidth  : collapsedSize)
    implicitHeight: !spotifyRunning ? 0 : (hovered ? expandedHeight : collapsedSize)

    visible: opacity > 0
    opacity: spotifyRunning ? 1 : 0

    Behavior on implicitWidth  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity        { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    function formatTime(sec) {
        if (!sec || sec < 0 || !isFinite(sec)) return "0:00"
        sec = Math.floor(sec)
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    Timer {
        interval: 1000
        repeat: true
        running: musicPlayer.spotifyRunning
        onTriggered: {
            const real = musicPlayer.spotifyPlayer
                ? (musicPlayer.spotifyPlayer.position || 0)
                : 0

            if (musicPlayer.isPlaying) {
                if (Math.abs(musicPlayer.displayPosition + 1 - real) < 2) {
                    musicPlayer.displayPosition += 1
                } else {
                    musicPlayer.displayPosition = real
                }
                if (musicPlayer.displayPosition > musicPlayer.length)
                    musicPlayer.displayPosition = musicPlayer.length
            } else {
                musicPlayer.displayPosition = real
            }
        }
    }

    Connections {
        target: musicPlayer.spotifyPlayer
        function onTrackTitleChanged() {
            musicPlayer.displayPosition = musicPlayer.spotifyPlayer
                ? (musicPlayer.spotifyPlayer.position || 0)
                : 0
        }
    }

    function seekTo(seconds) {
        if (!spotifyPlayer) return
        spotifyPlayer.position = seconds
        displayPosition = seconds
    }

    Rectangle {
        id: container
        anchors.fill: parent

        radius: musicPlayer.hovered ? 20 : 18.5
        Behavior on radius {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        color: musicPlayer.bgColor
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: musicPlayer.hovered = true
            onExited:  musicPlayer.hovered = false
        }

        // ════════════════════════════════════════════════════════
        //  EXPANDED — album pinned left, info column right
        // ════════════════════════════════════════════════════════
        Item {
            id: expandedContent
            width: musicPlayer.expandedWidth
            height: musicPlayer.expandedHeight
            anchors.top: parent.top
            anchors.left: parent.left

            opacity: musicPlayer.hovered ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            // ── Album ────────────────────────────────────────────
            Rectangle {
                id: expandedAlbumContainer
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: musicPlayer.padding
                anchors.topMargin: musicPlayer.padding
                anchors.bottomMargin: musicPlayer.padding
                width: height
                radius: 15
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: expandedAlbumContainer.radius
                    color: musicPlayer.fgColor
                    opacity: 0.15

                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        color: musicPlayer.fgColor
                        font.family: "SF Pro Display"
                        font.pixelSize: Math.round(parent.height * 0.4)
                        font.weight: 600
                    }
                }

                Image {
                    anchors.fill: parent
                    source: musicPlayer.spotifyPlayer
                        ? (musicPlayer.spotifyPlayer.trackArtUrl || "")
                        : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    cache: true
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: expandedAlbumContainer.width
                            height: expandedAlbumContainer.height
                            radius: expandedAlbumContainer.radius
                        }
                    }
                }
            }

            // ── Info column ──────────────────────────────────────
            Column {
                anchors.left: expandedAlbumContainer.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: musicPlayer.rightPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    width: parent.width
                    text: musicPlayer.spotifyPlayer
                        ? (musicPlayer.spotifyPlayer.trackTitle || "Nothing Playing")
                        : "Nothing Playing"
                    color: musicPlayer.fgColor
                    font.family: "SF Pro Display"
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: musicPlayer.spotifyPlayer
                        ? (musicPlayer.spotifyPlayer.trackArtist || "Unknown Artist")
                        : "Unknown Artist"
                    color: musicPlayer.accent
                    opacity: 0.75
                    font.family: "SF Pro Display"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                // ── Seek row ────────────────────────────────
                RowLayout {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: musicPlayer.formatTime(musicPlayer.displayPosition)
                        color: musicPlayer.accent
                        opacity: 0.75
                        font.family: "SF Pro Display"
                        font.pixelSize: 11
                        font.weight: 500
                    }

                    // Progress track — Rectangle directly in RowLayout
                    Rectangle {
                        id: progressTrack
                        Layout.fillWidth: true
                        Layout.minimumWidth: 40
                        Layout.preferredHeight: 4
                        Layout.maximumHeight: 4
                        Layout.alignment: Qt.AlignVCenter
                        color: "#cccccc"
                        opacity: 0.75

                        // Finished portion — song title color
                        Rectangle {
                            width: progressTrack.width * musicPlayer.progress
                            height: progressTrack.height
                            radius: progressTrack.radius
                            color: "#111111"
                            opacity: 1.0
                        }

                        // Seek hit area
                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -6
                            anchors.bottomMargin: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (!musicPlayer.spotifyPlayer || musicPlayer.length <= 0)
                                    return
                                const ratio = Math.max(0, Math.min(1, mouse.x / progressTrack.width))
                                musicPlayer.seekTo(ratio * musicPlayer.length)
                            }
                        }
                    }

                    Text {
                        text: musicPlayer.formatTime(musicPlayer.length)
                        color: musicPlayer.accent
                        opacity: 0.75
                        font.family: "SF Pro Display"
                        font.pixelSize: 11
                        font.weight: 500
                    }
                }

                // ── Controls — horizontally centered ────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Text {
                        text: "󰒮"
                        color: musicPlayer.fgColor
                        opacity: musicPlayer.spotifyPlayer
                                 && musicPlayer.spotifyPlayer.canGoPrevious ? 1 : 0.3
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (musicPlayer.spotifyPlayer
                                    && musicPlayer.spotifyPlayer.canGoPrevious)
                                    musicPlayer.spotifyPlayer.previous()
                            }
                        }
                    }

                    Text {
                        text: musicPlayer.isPlaying ? "󰏤" : "󰐊"
                        color: musicPlayer.fgColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (musicPlayer.spotifyPlayer)
                                    musicPlayer.spotifyPlayer.togglePlaying()
                            }
                        }
                    }

                    Text {
                        text: "󰒭"
                        color: musicPlayer.fgColor
                        opacity: musicPlayer.spotifyPlayer
                                 && musicPlayer.spotifyPlayer.canGoNext ? 1 : 0.3
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (musicPlayer.spotifyPlayer
                                    && musicPlayer.spotifyPlayer.canGoNext)
                                    musicPlayer.spotifyPlayer.next()
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════
        //  COLLAPSED — small circle album
        // ════════════════════════════════════════════════════════
        Item {
            id: collapsedAlbum
            z: 1
            width: 31
            height: 31
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 3
            anchors.topMargin: 3

            opacity: musicPlayer.hovered ? 0 : 1
            visible: opacity > 0.01
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: musicPlayer.fgColor
                opacity: 0.15

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: musicPlayer.fgColor
                    font.family: "SF Pro Display"
                    font.pixelSize: 14
                    font.weight: 600
                }
            }

            Image {
                anchors.fill: parent
                source: musicPlayer.spotifyPlayer
                    ? (musicPlayer.spotifyPlayer.trackArtUrl || "")
                    : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: true
                sourceSize.width: 62
                sourceSize.height: 62

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: collapsedAlbum.width
                        height: collapsedAlbum.height
                        radius: collapsedAlbum.width / 2
                    }
                }
            }
        }
    }
}