// NetCheck.qml
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    readonly property bool online:  _online
    readonly property bool checked: _checked

    // Assume online until the first check finishes (avoids
    // a flash of "offline" on shell startup).
    property bool _online:  true
    property bool _checked: false

    Component.onCompleted: {
        checkProc.running = true
        pollTimer.start()
    }

    Timer {
        id: pollTimer
        interval: 4000
        repeat: true
        running: false
        onTriggered: {
            if (!checkProc.running) checkProc.running = true
        }
    }

    Process {
        id: checkProc
        // 1) TCP connect to Cloudflare DNS (works even if ICMP is blocked)
        // 2) fallback to ping
        command: ["bash", "-c",
            "if timeout 2 bash -c 'echo >/dev/tcp/1.1.1.1/53' 2>/dev/null; then " +
            "  echo online; " +
            "elif ping -c1 -W1 -q 1.1.1.1 >/dev/null 2>&1; then " +
            "  echo online; " +
            "else " +
            "  echo offline; " +
            "fi"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const v = line.trim()
                if (v === "online") {
                    root._online = true
                    root._checked = true
                } else if (v === "offline") {
                    root._online = false
                    root._checked = true
                }
            }
        }
    }
}
