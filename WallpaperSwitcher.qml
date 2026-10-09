// WallpaperSwitcher.qml
import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    signal launched()
    signal dismissed()

    // ─────────────── CONFIG ───────────────
    readonly property string wallpaperDir: "$HOME/Pictures/Wallpapers"

    readonly property int visibleApps:    5
    readonly property int thumbWidth:     160
    readonly property int thumbHeight:    90
    readonly property int thumbGap:       10
    readonly property int thumbRadius:    12
    readonly property int liftAmount:     12
    readonly property int sidePadding:    12
    readonly property int searchHeight:   32
    readonly property int searchGap:      8
    readonly property int dividerHeight:  1
    readonly property int dividerGap:     8
    readonly property int topPadding:     8
    readonly property int bottomPadding:  12

    readonly property int rowHeight: thumbHeight + liftAmount

    readonly property int launcherWidth:
        sidePadding * 2
        + visibleApps * thumbWidth
        + (visibleApps - 1) * thumbGap

    readonly property int launcherHeight:
        topPadding + searchHeight + searchGap
        + dividerHeight + dividerGap
        + rowHeight + bottomPadding

    implicitWidth:  launcherWidth
    implicitHeight: launcherHeight
    width:  implicitWidth
    height: implicitHeight

    // ─────────────── STATE ───────────────
    property string searchText: ""
    property var wallpapers:   []
    property var filteredList: []
    property int currentIndex: 0

    property bool animateMoves: true
    property bool pendingCurrentQuery: false

    // Basename of the wallpaper currently applied to the desktop.
    property string activeWallpaperName: ""

    Timer {
        id: enableAnimTimer
        interval: 90
        repeat: false
        onTriggered: root.animateMoves = true
    }

    // ─────────────── SCAN ───────────────
    Process {
        id: listProc
        command: ["bash", "-c",
            "find " + root.wallpaperDir + " -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.webp' -o -iname '*.gif' \\) " +
            "2>/dev/null | sort"]
        running: false

        property var buffer: []

        stdout: SplitParser {
            onRead: (line) => {
                if (line && line.length > 0) listProc.buffer.push(line)
            }
        }

        onRunningChanged: { if (running) buffer = [] }

        onExited: {
            root.wallpapers = buffer.slice()
            buffer = []
            root.rebuild()
            if (root.pendingCurrentQuery) root.queryCurrent()
            else enableAnimTimer.restart()
        }
    }

    // ─────────────── QUERY CURRENT WALLPAPER ───────────────
    Process {
        id: queryProc
        command: ["awww", "query"]
        running: false

        property string output: ""

        stdout: SplitParser {
            onRead: (line) => { queryProc.output = line }
        }

        onRunningChanged: { if (running) output = "" }

        onExited: {
            root.pendingCurrentQuery = false

            const raw = queryProc.output.trim()
            queryProc.output = ""

            // awww query format: ": DP-1: 1920x1080, /path/to/wall.jpg"
            let cur = raw
            const commaIdx = raw.lastIndexOf(", ")
            if (commaIdx >= 0) cur = raw.substring(commaIdx + 2).trim()

            if (cur && cur.length > 0) {
                root.activeWallpaperName = root.baseName(cur)

                let idx = root.filteredList.indexOf(cur)
                if (idx < 0) {
                    for (let i = 0; i < root.filteredList.length; ++i) {
                        if (root.baseName(root.filteredList[i])
                            === root.activeWallpaperName) {
                            idx = i
                            break
                        }
                    }
                }
                if (idx >= 0) root.currentIndex = idx
            }

            enableAnimTimer.restart()
        }
    }

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    function queryCurrent() {
        queryProc.running = false
        queryProc.running = true
    }

    function baseName(path) {
        const parts = path.split("/")
        return parts[parts.length - 1]
    }

    function displayName(path) {
        const name = baseName(path)
        const dot = name.lastIndexOf(".")
        return dot > 0 ? name.substring(0, dot) : name
    }

    // ─────────────── FILTER ───────────────
    function rebuild() {
        const query = searchText.trim().toLowerCase()
        const list = []
        for (let i = 0; i < wallpapers.length; ++i) {
            const path = wallpapers[i]
            const name = baseName(path).toLowerCase()
            if (query.length === 0 || name.indexOf(query) !== -1)
                list.push(path)
        }
        filteredList = list
        if (currentIndex >= list.length)
            currentIndex = Math.max(0, list.length - 1)
    }

    onSearchTextChanged: {
        rebuild()
        currentIndex = 0
    }

    // ─────────────── NAVIGATION ───────────────
    function moveSelection(delta) {
        const count = filteredList.length
        if (count === 0) return
        let next = currentIndex + delta
        if (next < 0) next = 0
        if (next >= count) next = count - 1
        currentIndex = next
    }

    // ─────────────── APPLY (awww only) ───────────────
    Process {
        id: setProc
        running: false
    }

    function applyCurrent() {
        const count = filteredList.length
        if (count === 0) return
        const idx = Math.max(0, Math.min(count - 1, currentIndex))
        applyWallpaper(filteredList[idx])
    }

    function applyWallpaper(path) {
        if (!path) return

        // Track active wallpaper immediately so the "never dim"
        // rule kicks in before the next awww query.
        root.activeWallpaperName = root.baseName(path)

        setProc.command = [
            "awww", "img", path,
            "--transition-type", "any",
            "--transition-step", "255",
            "--transition-fps",  "60"
        ]
        setProc.running = true

        launched()
    }

    // ─────────────── OPEN / CLOSE ───────────────
    function open() {
        // Disable animations BEFORE touching currentIndex so the
        // jump from the previous index doesn't animate visibly.
        animateMoves = false
        enableAnimTimer.stop()

        searchText = ""
        currentIndex = 0
        pendingCurrentQuery = true

        if (wallpapers.length === 0) refresh()
        else queryCurrent()

        focusGrabTimer.restart()
        Qt.callLater(function() { searchInput.forceActiveFocus() })
    }

    function close() {
        searchText = ""
        currentIndex = 0
        pendingCurrentQuery = false
        enableAnimTimer.stop()
        animateMoves = true
        focusGrabTimer.stop()
    }

    Timer {
        id: focusGrabTimer
        interval: 40
        repeat: true
        running: false
        property int attempts: 0
        onTriggered: {
            attempts++
            if (!root.visible || attempts > 25) {
                stop(); attempts = 0; return
            }
            if (!searchInput.activeFocus)
                searchInput.forceActiveFocus()
        }
        onRunningChanged: { if (running) attempts = 0 }
    }

    Component.onCompleted: refresh()

    // ════════════════════════════════════════════════════════
    //  CONTENT
    // ════════════════════════════════════════════════════════
    Item {
        anchors.fill: parent

        // ── SEARCH ──
        Item {
            id: searchArea
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   parent.top
            anchors.leftMargin:  root.sidePadding
            anchors.rightMargin: root.sidePadding
            anchors.topMargin:   root.topPadding
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
                anchors.left:  searchIcon.right
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
                    case Qt.Key_Right:
                    case Qt.Key_Down:
                        root.moveSelection(1);  event.accepted = true; return
                    case Qt.Key_Left:
                    case Qt.Key_Up:
                        root.moveSelection(-1); event.accepted = true; return
                    case Qt.Key_PageDown:
                        root.moveSelection(root.visibleApps);  event.accepted = true; return
                    case Qt.Key_PageUp:
                        root.moveSelection(-root.visibleApps); event.accepted = true; return
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.applyCurrent(); event.accepted = true; return
                    }
                }
            }

            Text {
                anchors.left: searchInput.left
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text.length === 0
                text: "Search wallpapers"
                color: "#777777"
                font { family: "SF Pro Display"; pixelSize: 13; weight: 500 }
            }
        }

        // ── DIVIDER ──
        Rectangle {
            id: divider
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   searchArea.bottom
            anchors.leftMargin:  root.sidePadding
            anchors.rightMargin: root.sidePadding
            anchors.topMargin:   root.searchGap
            height: root.dividerHeight
            color: "#d5d5d5"
        }

        // ── CENTERED CAROUSEL ──
        Item {
            id: rowContainer
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   divider.bottom
            anchors.topMargin: root.dividerGap
            height: root.rowHeight
            clip: true

            readonly property real centerX: width / 2
            readonly property real step:    root.thumbWidth + root.thumbGap

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    const dy = event.angleDelta.y
                    const dx = event.angleDelta.x
                    if (dy === 0 && dx === 0) return
                    const d = (dy !== 0 ? dy : dx)
                    root.moveSelection(d < 0 ? 1 : -1)
                    event.accepted = true
                }
            }

            Repeater {
                model: root.filteredList

                delegate: Item {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    readonly property int distance: index - root.currentIndex
                    readonly property int absDistance: Math.abs(distance)
                    readonly property bool isSelected: distance === 0

                    readonly property bool isActive:
                        root.activeWallpaperName.length > 0
                        && root.baseName(delegateRoot.modelData)
                           === root.activeWallpaperName

                    width:  root.thumbWidth
                    height: root.thumbHeight

                    x: rowContainer.centerX
                       + distance * rowContainer.step
                       - width / 2

                    y: isSelected ? 0 : root.liftAmount

                    z: 100 - absDistance

                    // Active wallpaper stays full opacity, no matter
                    // its distance from the current selection.
                    opacity: {
                        if (isActive) return 1.0
                        const d = absDistance
                        if (d === 0) return 1.0
                        if (d === 1) return 0.75
                        if (d === 2) return 0.4
                        return 0
                    }

                    visible: opacity > 0.01

                    Behavior on x {
                        enabled: root.animateMoves
                        NumberAnimation { duration: 420; easing.type: Easing.OutQuart }
                    }
                    Behavior on y {
                        enabled: root.animateMoves
                        NumberAnimation { duration: 420; easing.type: Easing.OutQuart }
                    }
                    Behavior on opacity {
                        enabled: root.animateMoves
                        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                    }

                    // ── Thumbnail, rounded and masked ──
                    Rectangle {
                        id: thumbFrame
                        anchors.fill: parent
                        radius: root.thumbRadius
                        color: "#e5e5e5"

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width:  thumbFrame.width
                                height: thumbFrame.height
                                radius: thumbFrame.radius
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: "file://" + delegateRoot.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width:  root.thumbWidth  * 2
                            sourceSize.height: root.thumbHeight * 2
                        }

                        // ── Filename treatment ──
                        Rectangle {
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 44
                            color: "transparent"

                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: Qt.rgba(0, 0, 0, 0.0)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: {
                                        if (delegateRoot.isActive)
                                            return Qt.rgba(0, 0, 0, 0.0)
                                        return Qt.rgba(0, 0, 0,
                                            delegateRoot.isSelected ? 0.72 : 0.55)
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin:   10
                            anchors.rightMargin:  10
                            anchors.bottomMargin: 8

                            text: root.displayName(delegateRoot.modelData)
                            color: "white"
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignLeft

                            // Active wallpaper has no gradient backdrop,
                            // so outline keeps the text legible on any image.
                            style: delegateRoot.isActive
                                   ? Text.Outline : Text.Normal
                            styleColor: Qt.rgba(0, 0, 0, 0.55)

                            font {
                                family: "SF Pro Display"
                                pixelSize: delegateRoot.isSelected ? 12 : 11
                                weight:    delegateRoot.isSelected ? 700 : 500
                                letterSpacing: 0.4
                            }

                            Behavior on font.pixelSize {
                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // No border ring — selection is conveyed by lift,
                    // opacity falloff, and bolded filename.

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (delegateRoot.isSelected)
                                root.applyWallpaper(delegateRoot.modelData)
                            else
                                root.currentIndex = delegateRoot.index
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.filteredList.length === 0
                text: root.wallpapers.length === 0
                    ? "Loading wallpapers…"
                    : "No wallpapers found"
                color: "#777777"
                font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
            }
        }
    }
}