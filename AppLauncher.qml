import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    signal launched()
    signal dismissed()

    // ─────────────── CONFIG ───────────────
    readonly property int launcherWidth: 400
    readonly property int visibleApps: 5
    readonly property int rowHeight: 38
    readonly property int rowGap: 3
    readonly property int sidePadding: 10
    readonly property int searchHeight: 32
    readonly property int searchGap: 6
    readonly property int dividerHeight: 1
    readonly property int dividerGap: 6
    readonly property int topPadding: 8
    readonly property int bottomPadding: 10

    // ─────────────── DYNAMIC HEIGHT ───────────────
    readonly property int resultCount: appList.length
    readonly property int visibleCount: Math.min(resultCount, visibleApps)

    readonly property int appListHeight:
        visibleCount > 0
            ? visibleCount * rowHeight + (visibleCount - 1) * rowGap
            : rowHeight

    readonly property int launcherHeight:
        topPadding + searchHeight + searchGap
        + dividerHeight + dividerGap
        + appListHeight + bottomPadding

    // No Behavior on our own height. The capsule in shell.qml owns the
    // single source of height animation; our content is top-anchored so
    // an instantaneous size change is invisible.
    implicitWidth: launcherWidth
    implicitHeight: launcherHeight
    width: implicitWidth
    height: implicitHeight

    // ─────────────── STATE ───────────────
    property string searchText: ""
    property int currentIndex: 0
    property var usage: ({ })
    property var appList: []
    property bool hasLoaded: false

    // ─────────────── USAGE PERSISTENCE ───────────────
    FileView {
        id: usageFile
        path: Quickshell.statePath("app-usage.json")
        preload: true
        onLoaded: root.loadUsage()
        onLoadFailed: root.usage = ({ })
    }

    function usageKey(entry) {
        if (!entry) return ""
        if (entry.id && entry.id.length > 0) return entry.id
        if (entry.name && entry.name.length > 0) return entry.name
        return ""
    }

    function usageCount(entry) {
        const key = usageKey(entry)
        if (!key) return 0
        return Number(usage[key] || 0)
    }

    function loadUsage() {
        const raw = usageFile.text().trim()
        if (raw.length === 0) {
            usage = ({ })
            rebuild()
            return
        }
        try {
            const parsed = JSON.parse(raw)
            usage = (parsed && typeof parsed === "object") ? parsed : ({ })
        } catch (e) {
            console.log("AppLauncher: invalid usage file")
            usage = ({ })
        }
        rebuild()
    }

    function recordLaunch(entry) {
        if (!entry) return
        const key = usageKey(entry)
        if (!key) return

        const updated = { }
        for (const k in usage) updated[k] = usage[k]
        updated[key] = Number(updated[key] || 0) + 1
        usage = updated

        usageFile.setText(JSON.stringify(usage, null, 2))
    }

    // ─────────────── SEARCH SCORING ───────────────
    function isBoundary(str, idx) {
        if (idx === 0) return true
        const c = str.charCodeAt(idx - 1)
        return c === 32 || c === 45 || c === 95
    }

    function scoreString(str, query, requireBoundary) {
        if (query.length === 0) return 0
        const idx = str.indexOf(query)
        if (idx === -1) return -1

        const atBoundary = isBoundary(str, idx)
        if (requireBoundary && !atBoundary) return -1

        let score = 100 - Math.min(idx, 100)
        if (idx === 0) score += 60
        if (atBoundary) score += 25
        return score
    }

    function scoreEntry(entry) {
        const query = searchText.trim().toLowerCase()
        if (query.length === 0) return 0

        const requireBoundary = query.length <= 2

        const name = (entry.name || "").toLowerCase()
        const generic = (entry.genericName || "").toLowerCase()

        let best = -1

        let s = scoreString(name, query, requireBoundary)
        if (s >= 0) best = Math.max(best, s + 1000)

        if (requireBoundary) return best

        s = scoreString(generic, query, false)
        if (s >= 0) best = Math.max(best, s + 400)

        if (entry.keywords) {
            for (let i = 0; i < entry.keywords.length; ++i) {
                s = scoreString(String(entry.keywords[i]).toLowerCase(), query, false)
                if (s >= 0) best = Math.max(best, s + 200)
            }
        }

        return best
    }

    // ─────────────── MODEL REBUILD ───────────────
    function rebuild() {
        const entries = [...DesktopEntries.applications.values]
        const hasQuery = searchText.trim().length > 0
        const scored = []

        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            if (!entry) continue
            if (entry.noDisplay) continue
            if (!entry.command || entry.command.length === 0) continue

            const score = scoreEntry(entry)
            if (score < 0) continue

            scored.push({ entry, score, used: usageCount(entry) })
        }

        scored.sort(function(a, b) {
            if (hasQuery && b.score !== a.score) return b.score - a.score
            if (b.used !== a.used) return b.used - a.used
            return a.entry.name.localeCompare(b.entry.name)
        })

        appList = scored.map(function(x) { return x.entry })
    }

    onUsageChanged: rebuild()

    onSearchTextChanged: {
        rebuild()
        currentIndex = 0
        if (appListView)
            appListView.positionViewAtBeginning()
    }

    // ─────────────── NAVIGATION ───────────────
    function moveSelection(delta) {
        const count = appList.length
        if (count === 0) return
        let next = currentIndex + delta
        if (next < 0) next = 0
        if (next >= count) next = count - 1
        currentIndex = next
    }

    function launchCurrent() {
        const count = appList.length
        if (count === 0) return
        const idx = Math.max(0, Math.min(count - 1, currentIndex))
        launchApp(appList[idx])
    }

    // ─────────────── OPEN / CLOSE / LAUNCH ───────────────
    function open() {
        searchText = ""
        currentIndex = 0
        focusGrabTimer.restart()
        Qt.callLater(function() { searchInput.forceActiveFocus() })
    }

    function close() {
        searchText = ""
        currentIndex = 0
        focusGrabTimer.stop()
    }

    function launchApp(entry) {
        if (!entry) return
        recordLaunch(entry)
        entry.execute()
        launched()
    }

    // ─────────────── TIMERS ───────────────
    Timer {
        id: focusGrabTimer
        interval: 40
        repeat: true
        running: false
        property int attempts: 0

        onTriggered: {
            attempts++
            if (!root.visible || attempts > 25) {
                stop()
                attempts = 0
                return
            }
            if (!searchInput.activeFocus)
                searchInput.forceActiveFocus()
        }

        onRunningChanged: {
            if (running) attempts = 0
        }
    }

    Timer {
        id: loadRetryTimer
        interval: 150
        running: !root.hasLoaded
        repeat: true
        property int attempts: 0

        onTriggered: {
            attempts++
            root.rebuild()
            if (root.appList.length > 0 || attempts > 30) {
                root.hasLoaded = true
                stop()
            }
        }
    }

    Component.onCompleted: rebuild()

    // ─────────────── CONTENT ───────────────
    Item {
        anchors.fill: parent

        // ─── SEARCH ───
        Item {
            id: searchArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.sidePadding
            anchors.rightMargin: root.sidePadding
            anchors.topMargin: root.topPadding
            height: root.searchHeight

            Text {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                text: "󰍉"
                color: "#555555"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 19 }
            }

            TextInput {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 9
                height: parent.height
                text: root.searchText
                color: "#111111"
                selectionColor: "#b5b5b5"
                selectedTextColor: "#111111"
                cursorVisible: activeFocus
                clip: true
                selectByMouse: true
                verticalAlignment: TextInput.AlignVCenter
                font { family: "SF Pro Display"; pixelSize: 13; weight: 500 }

                onTextChanged: {
                    if (root.searchText !== text) root.searchText = text
                }

                Keys.onPressed: function(event) {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        root.dismissed(); event.accepted = true; return
                    case Qt.Key_Down:
                        root.moveSelection(1); event.accepted = true; return
                    case Qt.Key_Up:
                        root.moveSelection(-1); event.accepted = true; return
                    case Qt.Key_PageDown:
                        root.moveSelection(root.visibleApps); event.accepted = true; return
                    case Qt.Key_PageUp:
                        root.moveSelection(-root.visibleApps); event.accepted = true; return
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.launchCurrent(); event.accepted = true; return
                    }
                }
            }

            Text {
                anchors.left: searchInput.left
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text.length === 0
                text: "Search applications"
                color: "#777777"
                font { family: "SF Pro Display"; pixelSize: 13; weight: 500 }
            }
        }

        // ─── DIVIDER ───
        Rectangle {
            id: divider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: searchArea.bottom
            anchors.leftMargin: root.sidePadding
            anchors.rightMargin: root.sidePadding
            anchors.topMargin: root.searchGap
            height: root.dividerHeight
            color: "#d5d5d5"
        }

        // ─── LIST ───
        Item {
            id: listContainer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: divider.bottom
            anchors.leftMargin: root.sidePadding
            anchors.rightMargin: root.sidePadding
            anchors.topMargin: root.dividerGap
            height: root.appListHeight
            clip: true

            ListView {
                id: appListView
                anchors.fill: parent
                model: root.appList
                spacing: root.rowGap
                clip: true
                orientation: ListView.Vertical

                currentIndex: root.currentIndex

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: height

                highlightMoveDuration: 0
                highlightResizeDuration: 0
                highlightFollowsCurrentItem: true

                boundsBehavior: Flickable.StopAtBounds
                interactive: false

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        const dy = event.angleDelta.y
                        if (dy === 0) return
                        if (dy < 0) root.moveSelection(1)
                        else root.moveSelection(-1)
                        event.accepted = true
                    }
                }

                delegate: Item {
                    id: delegateRoot

                    required property var modelData
                    required property int index

                    readonly property var app: modelData
                    readonly property bool selected: root.currentIndex === index

                    width: appListView.width
                    height: root.rowHeight

                    HoverHandler {
                        id: hoverHandler
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: delegateRoot.selected
                            ? "#e1e1e1"
                            : hoverHandler.hovered ? "#eaeaea" : "transparent"
                    }

                    Rectangle {
                        id: iconBackground
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 7
                        color: "#e5e5e5"

                        readonly property string resolvedIcon: {
                            if (app.icon && app.icon.length > 0) {
                                const p = Quickshell.iconPath(app.icon, true)
                                if (p) return p
                            }
                            if (app.execString && app.execString.length > 0) {
                                const parts = app.execString.split(" ")
                                for (let i = 0; i < parts.length; ++i) {
                                    const tok = parts[i]
                                    if (!tok || tok.charAt(0) === "-" || tok.charAt(0) === "%")
                                        continue
                                    const base = tok.split("/").pop().toLowerCase()
                                    if (!base) continue
                                    const p = Quickshell.iconPath(base, true)
                                    if (p) return p
                                }
                            }
                            if (app.name && app.name.length > 0) {
                                const p = Quickshell.iconPath(app.name.toLowerCase(), true)
                                if (p) return p
                            }
                            return ""
                        }

                        IconImage {
                            id: appIcon
                            anchors.centerIn: parent
                            implicitWidth: 20
                            implicitHeight: 20
                            asynchronous: true
                            source: iconBackground.resolvedIcon
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: appIcon.source === ""
                                || appIcon.status === Image.Error
                            text: app.name && app.name.length > 0
                                ? app.name.charAt(0).toUpperCase()
                                : "?"
                            color: "#111111"
                            font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
                        }
                    }

                    Text {
                        anchors.left: iconBackground.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: app.name
                        color: "#111111"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font { family: "SF Pro Display"; pixelSize: 13; weight: 500 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentIndex = delegateRoot.index
                            root.launchApp(delegateRoot.app)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.appList.length === 0
                text: root.searchText.length > 0
                    ? "No applications found"
                    : "No applications"
                color: "#777777"
                font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
            }
        }
    }
}