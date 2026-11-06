// VolumeOsd.qml
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: volumeOsd

    // ── Fonts ──
    readonly property string textFont: "SF Pro Text"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    readonly property bool active: osdVisible
    readonly property real volume: audioSink && audioSink.audio ? audioSink.audio.volume : 0
    readonly property bool muted:  audioSink && audioSink.audio ? audioSink.audio.muted  : false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    readonly property var audioSink: Pipewire.defaultAudioSink

    property bool osdVisible: false
    property real _lastVolume: -1
    property bool _armed: false

    property real pulseScale: 1.0

    SequentialAnimation {
        id: pulseAnim
        NumberAnimation {
            target: volumeOsd
            property: "pulseScale"
            to: 1.18
            duration: 140
            easing.type: Easing.OutBack
            easing.overshoot: 2.5
        }
        NumberAnimation {
            target: volumeOsd
            property: "pulseScale"
            to: 1.0
            duration: 340
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    Timer {
        interval: 600
        running: true
        onTriggered: {
            volumeOsd._armed = true
            volumeOsd._lastVolume = volumeOsd.volume
        }
    }

    onVolumeChanged: {
        if (!_armed) return
        if (Math.abs(volume - _lastVolume) > 0.0005) {
            _lastVolume = volume
            osdVisible = true
            hideTimer.restart()
            pulseAnim.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: volumeOsd.osdVisible = false
    }

    opacity: osdVisible ? 1 : 0
    visible: osdVisible

    Behavior on opacity {
        NumberAnimation {
            duration: osdVisible ? 260 : 160
            easing.type: Easing.OutCubic
        }
    }

    scale: osdVisible ? 1.0 : 0.90
    Behavior on scale {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.5
        }
    }

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter

        scale: volumeOsd.pulseScale

        text: {
            if (volumeOsd.muted || volumeOsd.volume <= 0.001) return "󰝟"
            if (volumeOsd.volume < 0.35) return "󰕿"
            if (volumeOsd.volume < 0.70) return "󰖀"
            return "󰕾"
        }
        color: "black"
        font {
            family: volumeOsd.iconFont
            pixelSize: 18
        }
    }

    Text {
        id: percent
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight

        scale: volumeOsd.pulseScale

        text: Math.round(volumeOsd.volume * 100) + "%"
        color: "black"
        font {
            family: volumeOsd.textFont
            pixelSize: 13
            weight: 500
            letterSpacing: 0
        }
    }

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
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.8
                }
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