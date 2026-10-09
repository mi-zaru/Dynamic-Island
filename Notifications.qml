// Notifications.qml
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Item {
    id: root

    readonly property bool active: _count > 0
    property int _count: 0

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        actionsSupported: false
        imageSupported: false

        onNotification: (notification) => {
            root._count++
            notification.closed.connect(() => {
                if (root._count > 0) root._count--
            })
        }
    }
}