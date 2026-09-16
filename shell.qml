// shell.qml
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
  PanelWindow {
    id: panel

    property bool hovered: false

    implicitWidth: 1000
    implicitHeight: 260

    aboveWindows: true
    exclusiveZone: 40

    anchors { top: true }

    margins {
      top: 10
      bottom: 5
    }

    color: "transparent"

    Item {
      id: mainRow
      anchors.fill: parent

      // ── Main capsule ──
      Rectangle {
        id: capsule
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        readonly property int collapsedWidth:  130
        readonly property int collapsedHeight: 37
        readonly property int expandedWidth:   300
        readonly property int expandedHeight:  120

        width:  panel.hovered ? expandedWidth  : collapsedWidth
        height: panel.hovered ? expandedHeight : collapsedHeight

        radius: 20
        color: "white"
        opacity: 0.95
        clip: true

        Behavior on width  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: panel.hovered = true
          onExited:  panel.hovered = false
        }

        Clock {
          id: clock
          anchors.horizontalCenter: parent.horizontalCenter

          property real centerY: panel.hovered
                                 ? capsule.expandedHeight * 0.3
                                 : capsule.collapsedHeight / 2

          y: centerY - height / 2

          Behavior on centerY {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
          }

          hovered: panel.hovered
        }

        Calendar {
          id: calendar
          expanded: panel.hovered

          anchors {
            left: parent.left
            right: parent.right
          }

          property real centerY: capsule.expandedHeight * 0.7

          height: 44
          y: centerY - height / 2
        }
      }

      // ── Music player — grows leftward from the capsule ──
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