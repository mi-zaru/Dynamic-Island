// WorkspaceOsd.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick

Item {
    id: root

    readonly property var focused:     Hyprland.focusedWorkspace
    readonly property int workspaceId: focused ? focused.id : 0

    property bool active:  false
    property int  _lastId: 0
    property bool _armed:  false

    Timer {
        interval: 500
        running: true
        onTriggered: {
            root._armed  = true
            root._lastId = root.workspaceId
        }
    }

    onWorkspaceIdChanged: {
        if (!_armed) return
        if (workspaceId <= 0 || workspaceId === _lastId) return
        _lastId = workspaceId
        active  = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.active = false
    }
}