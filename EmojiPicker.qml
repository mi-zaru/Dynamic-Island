// EmojiPicker.qml
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    signal selected(string emoji)
    signal dismissed()

    readonly property int columns:        8
    readonly property int cellWidth:      45
    readonly property int cellHeight:     45
    readonly property int visibleRows:    4
    readonly property int sidePadding:    10
    readonly property int topPadding:     8
    readonly property int searchHeight:   32
    readonly property int searchGap:      6
    readonly property int dividerHeight:  1
    readonly property int dividerGap:     6
    readonly property int bottomPadding:  10

    readonly property int gridHeight: cellHeight * visibleRows

    readonly property int launcherWidth:
        sidePadding * 2 + cellWidth * columns

    readonly property int launcherHeight:
        topPadding + searchHeight + searchGap
        + dividerHeight + dividerGap
        + gridHeight + bottomPadding

    implicitWidth:  launcherWidth
    implicitHeight: launcherHeight
    width:  implicitWidth
    height: implicitHeight

    property string searchText: ""
    property var emojiList:    []
    property var filteredList: []
    property int currentIndex: 0

    readonly property var fallbackEmojis: [
        ["😀","grin happy smile"],   ["😃","smile happy"],
        ["😄","smile happy grinning"],["😁","beaming grin"],
        ["😆","laugh grin"],          ["😅","sweat grin"],
        ["🤣","rofl laughing"],       ["😂","joy tears lol"],
        ["🙂","slight smile"],        ["🙃","upside down"],
        ["😉","wink"],                ["😊","blush smile"],
        ["😇","angel halo"],          ["🥰","love smile hearts"],
        ["😍","love heart eyes"],     ["🤩","star struck"],
        ["😘","kiss love"],           ["😋","yum tasty"],
        ["😜","wink tongue"],         ["🤔","think hmm"],
        ["😐","neutral meh"],         ["😏","smirk"],
        ["😒","unamused"],            ["🙄","eye roll"],
        ["😴","sleep zzz"],           ["😷","mask sick"],
        ["🤒","sick thermometer"],    ["🤕","hurt bandage"],
        ["🤢","nausea"],              ["🤮","vomit"],
        ["🤧","sneeze"],              ["🥵","hot sweat"],
        ["🥶","cold freeze"],         ["😵","dizzy"],
        ["🤯","mind blown"],          ["🤠","cowboy"],
        ["🥳","party celebrate"],     ["😎","cool sunglasses"],
        ["🤓","nerd glasses"],        ["😕","confused"],
        ["😟","worried"],             ["🙁","sad"],
        ["😮","surprised"],           ["😲","astonished"],
        ["😳","flushed blush"],       ["🥺","plead puppy"],
        ["😨","fearful"],             ["😰","anxious sweat"],
        ["😢","cry tear"],            ["😭","cry sob"],
        ["😱","scream fear"],         ["😤","steam angry"],
        ["😡","angry pout"],          ["😠","angry"],
        ["🤬","curse swear"],         ["😈","devil smile"],
        ["💀","skull dead"],          ["💩","poop"],
        ["🤡","clown"],               ["👻","ghost"],
        ["👽","alien"],               ["🤖","robot"],
        ["❤️","red heart love"],      ["🧡","orange heart"],
        ["💛","yellow heart"],        ["💚","green heart"],
        ["💙","blue heart"],          ["💜","purple heart"],
        ["🖤","black heart"],         ["🤍","white heart"],
        ["💔","broken heart"],        ["💯","100 perfect"],
        ["✨","sparkles magic"],      ["⭐","star"],
        ["🌟","glowing star"],        ["🔥","fire hot"],
        ["🌈","rainbow"],             ["☀️","sun sunny"],
        ["🌙","moon night"],          ["⚡","lightning"],
        ["❄️","snow cold"],           ["🎉","party celebrate"],
        ["🎊","confetti"],            ["🎈","balloon"],
        ["🎁","gift present"],        ["👍","thumbs up like"],
        ["👎","thumbs down"],         ["👌","ok perfect"],
        ["✌️","victory peace"],       ["🤞","cross fingers"],
        ["🤘","rock horns"],          ["🤙","shaka call me"],
        ["👈","point left"],          ["👉","point right"],
        ["👆","point up"],            ["👇","point down"],
        ["☝️","point up index"],      ["✋","stop raise"],
        ["🖖","vulcan spock"],        ["👋","wave hi"],
        ["🤝","handshake"],           ["🙏","pray thanks"],
        ["💪","muscle strong"],       ["👏","clap applause"],
        ["🙌","raise hands"],         ["✊","fist"],
        ["👊","punch fist"],          ["🐶","dog puppy"],
        ["🐱","cat kitten"],          ["🐭","mouse"],
        ["🐹","hamster"],             ["🐰","rabbit bunny"],
        ["🦊","fox"],                 ["🐻","bear"],
        ["🐼","panda"],               ["🐨","koala"],
        ["🐯","tiger"],               ["🦁","lion"],
        ["🐮","cow"],                 ["🐷","pig"],
        ["🐸","frog"],                ["🐵","monkey"],
        ["🐔","chicken"],             ["🐧","penguin"],
        ["🐦","bird"],                ["🦆","duck"],
        ["🦅","eagle"],               ["🦉","owl"],
        ["🐺","wolf"],                ["🦄","unicorn"],
        ["🐝","bee"],                 ["🦋","butterfly"],
        ["🐢","turtle"],              ["🐍","snake"],
        ["🐙","octopus"],             ["🦀","crab"],
        ["🐬","dolphin"],             ["🐳","whale"],
        ["🦈","shark"],               ["🐘","elephant"],
        ["🦒","giraffe"],             ["🍎","apple red"],
        ["🍊","orange fruit"],        ["🍋","lemon"],
        ["🍌","banana"],              ["🍉","watermelon"],
        ["🍇","grapes"],              ["🍓","strawberry"],
        ["🍑","peach"],               ["🍍","pineapple"],
        ["🥝","kiwi"],                ["🥑","avocado"],
        ["🥕","carrot"],              ["🌽","corn"],
        ["🌶️","chili spicy"],         ["🍞","bread"],
        ["🥐","croissant"],           ["🧀","cheese"],
        ["🍔","burger"],              ["🍟","fries"],
        ["🍕","pizza"],               ["🌭","hotdog"],
        ["🌮","taco"],                ["🍜","ramen"],
        ["🍝","pasta"],               ["🍣","sushi"],
        ["🍦","icecream"],            ["🍩","donut"],
        ["🍪","cookie"],              ["🎂","cake birthday"],
        ["🍰","shortcake"],           ["🍫","chocolate"],
        ["🍬","candy"],               ["☕","coffee hot"],
        ["🍵","tea"],                 ["🧋","bubble boba"],
        ["🍺","beer"],                ["🍻","beer cheers"],
        ["🍷","wine"],                ["🥂","champagne"],
        ["💻","laptop computer"],     ["🖥️","desktop pc"],
        ["⌨️","keyboard"],           ["🖱️","mouse"],
        ["🎮","game controller"],     ["📱","phone mobile"],
        ["📷","camera"],              ["🎥","video camera"],
        ["📺","tv television"],       ["🎵","music note"],
        ["🎶","music notes"],         ["🎤","microphone"],
        ["🎧","headphones"],          ["🎸","guitar"],
        ["🎹","piano"],               ["📚","books"],
        ["📖","book open"],           ["✏️","pencil"],
        ["📝","memo note"],           ["✂️","scissors cut"],
        ["🔒","lock"],                ["🔑","key"],
        ["🔨","hammer"],              ["⚙️","gear settings"],
        ["🗑️","trash delete"],       ["📦","package"],
        ["✉️","envelope email"],      ["🏠","home house"],
        ["🌍","globe world"],         ["🌲","tree pine"],
        ["🌴","palm tree"],           ["🌵","cactus"],
        ["🌹","rose flower"],         ["🌻","sunflower"],
        ["🌸","cherry blossom"],      ["🚀","rocket launch"],
        ["✈️","airplane"],            ["🚗","car"],
        ["🚕","taxi"],                ["🚲","bicycle bike"],
        ["🏆","trophy win"],          ["🥇","gold medal"],
        ["⚽","soccer"],              ["🏀","basketball"],
        ["🎾","tennis"],              ["🎯","target bullseye"],
        ["🎲","dice"],                ["✅","check yes done"],
        ["❌","cross no delete"],     ["❓","question"],
        ["❗","exclamation"],         ["⚠️","warning"],
        ["🚫","prohibited no"],       ["♻️","recycle"],
        ["🔴","red circle"],          ["🟠","orange circle"],
        ["🟡","yellow circle"],       ["🟢","green circle"],
        ["🔵","blue circle"],         ["🟣","purple circle"],
        ["⚫","black circle"],        ["⚪","white circle"]
    ]

    Process {
        id: emojiFileProc
        command: ["bash", "-c",
            "cat /usr/share/unicode/emoji/emoji-test.txt 2>/dev/null " +
            "|| cat /usr/share/unicode/emoji-test.txt 2>/dev/null " +
            "|| true"]
        running: true

        property var buffer: []

        stdout: SplitParser {
            onRead: (line) => { emojiFileProc.buffer.push(line) }
        }

        onRunningChanged: { if (running) buffer = [] }

        onExited: {
            let parsed = []
            if (buffer.length > 0) parsed = root.parseEmojiTest(buffer)

            if (parsed.length > 0) {
                root.emojiList = parsed
            } else {
                root.emojiList = root.fallbackEmojis
            }
            buffer = []
            root.rebuild()
        }
    }

    function parseEmojiTest(lines) {
        const result = []
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i]
            if (!line || line.charAt(0) === "#") continue

            const semi = line.indexOf(";")
            if (semi < 0) continue
            const hash = line.indexOf("#", semi)
            if (hash < 0) continue

            const status = line.substring(semi + 1, hash).trim()
            if (status !== "fully-qualified") continue

            const after = line.substring(hash + 1).trim()
            const sp1 = after.indexOf(" ")
            if (sp1 < 0) continue

            const emoji = after.substring(0, sp1)
            const rest  = after.substring(sp1 + 1)
            const sp2   = rest.indexOf(" ")
            const name  = sp2 >= 0 ? rest.substring(sp2 + 1).toLowerCase() : ""

            if (/[\u{1F3FB}-\u{1F3FF}]/u.test(emoji)) continue

            result.push([emoji, name])
        }
        return result
    }

    function scoreEmoji(entry, q) {
        const name = String(entry[1]).toLowerCase()
        const idx = name.indexOf(q)
        if (idx < 0) return -1
        let score = 1000 - Math.min(idx, 500)
        if (idx === 0) score += 300
        else {
            const prev = name.charAt(idx - 1)
            if (prev === " " || prev === "-") score += 150
        }
        return score
    }

    function rebuild() {
        const q = searchText.trim().toLowerCase()
        if (q.length === 0) {
            filteredList = emojiList.slice()
        } else {
            const scored = []
            for (let i = 0; i < emojiList.length; ++i) {
                const entry = emojiList[i]
                const s = scoreEmoji(entry, q)
                if (s >= 0) scored.push({ entry: entry, score: s })
            }
            scored.sort(function(a, b) { return b.score - a.score })
            filteredList = scored.map(function(x) { return x.entry })
        }
        currentIndex = 0
        if (grid) grid.contentY = 0
    }

    onSearchTextChanged: rebuild()

    function moveSelection(dx, dy) {
        const count = filteredList.length
        if (count === 0) return
        let next = currentIndex + dx + dy * columns
        if (next < 0) next = 0
        if (next >= count) next = count - 1
        if (next === currentIndex) return

        currentIndex = next

        if (grid) {
            const row = Math.floor(next / columns)
            const topRow = Math.floor(grid.contentY / grid.cellHeight)
            const botRow = Math.floor((grid.contentY + grid.height - 1)
                                      / grid.cellHeight)
            if (row < topRow || row > botRow)
                grid.positionViewAtIndex(next, GridView.Contain)
        }
    }

    function selectIndex(i) {
        currentIndex = i
        copyEmoji(filteredList[i][0])
    }

    Process {
        id: copyProc
        running: false
    }

    function copyEmoji(emoji) {
        copyProc.command = ["wl-copy", "--", emoji]
        copyProc.running = true
        root.selected(emoji)
    }

    function applyCurrent() {
        const count = filteredList.length
        if (count === 0) return
        const idx = Math.max(0, Math.min(count - 1, currentIndex))
        copyEmoji(filteredList[idx][0])
    }

    function open() {
        searchText = ""
        currentIndex = 0
        if (grid) grid.contentY = 0
        focusGrabTimer.restart()
        Qt.callLater(function() { searchInput.forceActiveFocus() })
    }

    function close() {
        searchText = ""
        currentIndex = 0
        if (grid) grid.contentY = 0
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

    Item {
        anchors.fill: parent

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
                font { family: "Manrope"; pixelSize: 19 }
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
                font { family: "Manrope"; pixelSize: 13; weight: 500 }

                onTextChanged: {
                    if (root.searchText !== text) root.searchText = text
                }

                Keys.onPressed: function(event) {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        root.dismissed(); event.accepted = true; return
                    case Qt.Key_Right:
                        root.moveSelection(1, 0);  event.accepted = true; return
                    case Qt.Key_Left:
                        root.moveSelection(-1, 0); event.accepted = true; return
                    case Qt.Key_Down:
                        root.moveSelection(0, 1);  event.accepted = true; return
                    case Qt.Key_Up:
                        root.moveSelection(0, -1); event.accepted = true; return
                    case Qt.Key_PageDown:
                        root.moveSelection(0, root.visibleRows);  event.accepted = true; return
                    case Qt.Key_PageUp:
                        root.moveSelection(0, -root.visibleRows); event.accepted = true; return
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
                text: "Search emoji…"
                color: "#777777"
                font { family: "Manrope"; pixelSize: 13; weight: 500 }
            }
        }

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

        Item {
            id: gridArea
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   divider.bottom
            anchors.topMargin: root.dividerGap
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.bottomPadding
            clip: true

            GridView {
                id: grid
                anchors.fill: parent
                anchors.leftMargin:  root.sidePadding
                anchors.rightMargin: root.sidePadding
                cellWidth:  root.cellWidth
                cellHeight: root.cellHeight
                model: root.filteredList
                currentIndex: root.currentIndex
                clip: true
                focus: false
                boundsBehavior: Flickable.StopAtBounds
                interactive: false
                flickableDirection: Flickable.VerticalFlick

                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.OutCubic }
                }
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutCubic }
                }
                displaced: Transition {
                    NumberAnimation { property: "x"; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }

                onCurrentIndexChanged: {
                    if (root.currentIndex !== currentIndex)
                        root.currentIndex = currentIndex
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        const dy = event.angleDelta.y
                        if (dy === 0) return
                        root.moveSelection(0, dy < 0 ? 1 : -1)
                        event.accepted = true
                    }
                }

                delegate: Item {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    width:  grid.cellWidth
                    height: grid.cellHeight

                    readonly property bool isSelected: index === grid.currentIndex

                    HoverHandler { id: hoverHandler }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 38
                        height: 38
                        radius: 8
                        color: delegateRoot.isSelected
                            ? "#e1e1e1"
                            : "#eaeaea"

                        scale: delegateRoot.isSelected
                            ? 1.0
                            : (hoverHandler.hovered ? 0.85 : 0.0)

                        // ★ OutBack — pill pops into place
                        Behavior on scale {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutBack
                                easing.overshoot: 2.5
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: delegateRoot.modelData[0]
                        font {
                            family: "Noto Color Emoji"
                            pixelSize: 24
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectIndex(delegateRoot.index)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.filteredList.length === 0
                text: root.searchText.length > 0
                    ? "No emoji found"
                    : "Loading emoji…"
                color: "#777777"
                font { family: "Manrope"; pixelSize: 12; weight: 500 }
            }
        }
    }
}
