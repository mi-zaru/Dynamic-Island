// VolumeOsd.qml
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: volumeOsd

    // ── Exposed to shell.qml ────────────────────────────────
    readonly property bool active: osdVisible
    readonly property real volume: audioSink && audioSink.audio ? audioSink.audio.volume : 0
    readonly property bool muted:  audioSink && audioSink.audio ? audioSink.audio.muted  : false

    // ── Pipewire sink ───────────────────────────────────────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    readonly property var audioSink: Pipewire.defaultAudioSink

    // ── Visibility / auto-hide ──────────────────────────────
    property bool osdVisible: false
    property real _lastVolume: -1
    property bool _armed: false

    Timer {
        interval: 600
        running: true
        onTriggered: {
            volumeOsd._armed = true
            volumeOsd._lastVolume = volumeOsd.volume
        }
    }

    // Only a volume change triggers the OSD.
    // Muting does NOT — the shell shows a mute glyph in idle instead.
    onVolumeChanged: {
        if (!_armed) return
        if (Math.abs(volume - _lastVolume) > 0.0005) {
            _lastVolume = volume
            osdVisible = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: volumeOsd.osdVisible = false
    }

    // ── Fade — matches the capsule's 260ms OutQuint ─────────
        // ── Fade — smooth in, instant out ───────────────────────
    // Fading out over time leaves the slider track partially
    // visible while the capsule is still shrinking, which reads
    // as a stray line. Showing is smooth; hiding is immediate.
    opacity: osdVisible ? 1 : 0
    visible: osdVisible

    Behavior on opacity {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: osdVisible ? 260 : 160
            easing.type: Easing.OutCubic
        }
    }

    // ── Speaker icon ────────────────────────────────────────
    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter

        text: {
            if (volumeOsd.muted || volumeOsd.volume <= 0.001) return "󰝟"
            if (volumeOsd.volume < 0.35) return "󰕿"
            if (volumeOsd.volume < 0.70) return "󰖀"
            return "󰕾"
        }
        color: "black"
        font {
            family: "JetBrainsMono Nerd Font"
            pixelSize: 18
        }
    }

    // ── Percentage ──────────────────────────────────────────
    Text {
        id: percent
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight

        text: Math.round(volumeOsd.volume * 100) + "%"
        color: "black"
        font {
            family: "SF Pro Display"
            pixelSize: 13
            weight: 600
            letterSpacing: 1
        }
    }

    // ── Slider ──────────────────────────────────────────────
    Rectangle {
        id: track
        anchors.left: icon.right
        anchors.leftMargin: 14
        anchors.right: percent.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter

        height: 4
        radius: height / 2
        color: "#dddddd"

        Rectangle {
            width: track.width * Math.min(1, Math.max(0, volumeOsd.volume))
            height: parent.height
            radius: parent.radius
            color: "#111111"

            Behavior on width {
                NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -12
            anchors.bottomMargin: -12
            cursorShape: Qt.PointingHandCursor

            function applyAt(x) {
                if (!volumeOsd.audioSink || !volumeOsd.audioSink.audio) return
                const ratio = Math.max(0, Math.min(1, x / track.width))
                volumeOsd.audioSink.audio.volume = ratio
                volumeOsd.audioSink.audio.muted  = false
                volumeOsd.osdVisible = true
                hideTimer.restart()
            }

            onPressed:         (mouse) => applyAt(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) applyAt(mouse.x) }
        }
    }
}