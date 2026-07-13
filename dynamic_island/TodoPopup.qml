pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool popupVisible: false

    function toggle() {
        popupVisible = !popupVisible;
        if (popupVisible) todoModel.reload();
    }

    anchors { top: true; left: true; right: true }
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: popupVisible
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    implicitHeight: popupVisible ? Math.min(cardContent.implicitHeight + 68, screen.height / 2) : 0
    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
    }

    readonly property color clrBase:    "#1e1e2e"
    readonly property color clrSurface: "#313244"
    readonly property color clrOverlay: "#6c7086"
    readonly property color clrText:    "#cdd6f4"
    readonly property color clrSubtext: "#a6adc8"
    readonly property color clrMauve:   "#cba6f7"
    readonly property color clrGreen:   "#a6e3a1"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string todoPath: Quickshell.env("HOME") + "/.local/share/todo.md"

    // ── File processes ────────────────────────────────────────────────────────
    Process {
        id: fileReader
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                itemModel.clear();
                const cleanText = text.replace(/\\n/g, "\n");
                const lines = cleanText.split("\n");
                for (const line of lines) {
                    const m = line.match(/^-\s\[\s\]\s(.+)$/);
                    if (m) itemModel.append({ itemText: m[1].trim() });
                }
            }
        }
    }
    Process { id: appendWriter }
    Process { id: removeWriter }
    Process { id: rewriteWriter }

    Component.onCompleted: {
        fileEnsure.exec(["sh", "-c",
            'mkdir -p "$(dirname "$0")" && touch "$0"', root.todoPath]);
    }
    Process { id: fileEnsure }

    // ── ListModel (real Qt model — transitions work properly) ─────────────────
    ListModel { id: itemModel }

    QtObject {
        id: todoModel

        function reload() {
            fileReader.exec(["cat", root.todoPath]);
        }

        function add(text) {
            const t = text.trim();
            if (!t) return;
            itemModel.append({ itemText: t });
            appendWriter.exec(["sh", "-c", 'printf "%s\\n" "$1" >> "$0"', root.todoPath, "- [ ] " + t]);
            scrollTimer.start();
        }

        function remove(index) {
            itemModel.remove(index);
            saveAll();
        }

        function move(from, to) {
            if (from === to) return;
            itemModel.move(from, to, 1);
            saveAll();
        }

        function saveAll() {
            let lines = [];
            for (let i = 0; i < itemModel.count; i++) {
                lines.push("- [ ] " + itemModel.get(i).itemText);
            }
            if (lines.length === 0) {
                rewriteWriter.exec(["sh", "-c", '> "$0"', root.todoPath]);
            } else {
                rewriteWriter.exec(["sh", "-c", 'printf "%s\\n" "$@" > "$0"', root.todoPath, ...lines]);
            }
        }
    }

    // ── Dismiss on outside click ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: root.popupVisible
        onClicked: root.popupVisible = false
        z: -1
    }

    // ── Scroll-to-bottom timer ────────────────────────────────────────────────
    Timer {
        id: scrollTimer
        interval: 60; repeat: false
        onTriggered: listView.positionViewAtEnd()
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Item {
        id: cardWrapper
        anchors.top: parent.top
        anchors.topMargin: 32
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320
        height: Math.min(cardContent.implicitHeight + 24, screen.height / 2 - 36)

        opacity: root.popupVisible ? 1.0 : 0.0
        scale:   root.popupVisible ? 1.0 : 0.93
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        Rectangle {
            anchors.fill: parent; radius: 20
            color: root.clrBase
            border.color: Qt.rgba(1,1,1,0.07); border.width: 1
        }

        // Prevent click propagation to parent dismiss MouseArea
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => { mouse.accepted = true; }
        }

        Column {
            id: cardContent
            anchors { top:parent.top; left:parent.left; right:parent.right; margins:16; topMargin:16 }
            spacing: 10

            // header
            Row {
                width: parent.width; spacing: 6
                Text {
                    text:"󰄬"; color:root.clrMauve
                    font.pixelSize:14; font.family:root.fontFamily
                    anchors.verticalCenter:parent.verticalCenter
                }
                Text {
                    text:"todo"; color:root.clrText
                    font.pixelSize:13; font.family:root.fontFamily; font.weight:Font.Bold
                    anchors.verticalCenter:parent.verticalCenter
                }
                Item { width:1; height:1 }
                Text {
                    text: itemModel.count + " items"
                    color:root.clrOverlay; font.pixelSize:10; font.family:root.fontFamily
                    anchors.verticalCenter:parent.verticalCenter
                }
            }

            Rectangle { width:parent.width; height:1; color:Qt.rgba(1,1,1,0.06) }

            // ── scrollable list ───────────────────────────────────────────────
            Item {
                width: parent.width
                height: Math.min(itemModel.count > 0 ? itemModel.count * 38 : 36, screen.height / 2 - 160)
                clip: true

                // drag state
                property int  dragFrom:  -1
                property int  dragTo:    -1
                property real ghostY:    0
                property bool dragging:  dragFrom !== -1
                id: listContainer

                ListView {
                    id: listView
                    anchors.fill: parent
                    model: itemModel
                    spacing: 2
                    clip: true
                    // disable scroll flick while user is dragging a row
                    interactive: !listContainer.dragging

                    ScrollBar.vertical: ScrollBar {
                        policy: listView.contentHeight > listView.height
                            ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        width: 4
                        contentItem: Rectangle { radius:2; color:"#cba6f7"; opacity:0.5 }
                    }

                    // ── transitions ───────────────────────────────────────────
                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property:"opacity"; from:0; to:1; duration:200; easing.type:Easing.OutCubic }
                            NumberAnimation { property:"x"; from:16; to:0; duration:200; easing.type:Easing.OutCubic }
                        }
                    }
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property:"opacity"; from:1; to:0; duration:180; easing.type:Easing.InCubic }
                            NumberAnimation { property:"x"; from:0; to:20; duration:180; easing.type:Easing.InCubic }
                        }
                    }
                    displaced: Transition {
                        NumberAnimation { property:"y"; duration:220; easing.type:Easing.OutCubic }
                    }
                    move: Transition {
                        NumberAnimation { property:"y"; duration:220; easing.type:Easing.OutCubic }
                    }

                    delegate: Item {
                        id: delegate
                        required property string itemText
                        required property int    index
                        width: listView.width - 6
                        height: 36

                        // hide original while it's being dragged (ghost floats above)
                        opacity: (listContainer.dragFrom === index) ? 0.0 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        // drop zone highlight
                        Rectangle {
                            anchors.fill: parent; radius: 10
                            color: (listContainer.dragTo === index && listContainer.dragFrom !== index)
                                ? Qt.rgba(203/255,166/255,247/255,0.14)
                                : (rowHover.hovered ? Qt.rgba(1,1,1,0.04) : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        HoverHandler { id: rowHover }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4; anchors.rightMargin: 4
                            spacing: 8

                            // drag handle — plain MouseArea so it beats the ListView gesture
                            Item {
                                width: 18; height: parent.height

                                Text {
                                    anchors.centerIn: parent
                                    text: "⠿"
                                    color: dragMA.pressed ? "#cba6f7" : "#45475a"
                                    font.pixelSize: 14; font.family: root.fontFamily
                                    opacity: rowHover.hovered || dragMA.pressed ? 1.0 : 0.35
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                    Behavior on color   { ColorAnimation  { duration: 140 } }
                                }

                                MouseArea {
                                    id: dragMA
                                    anchors.fill: parent
                                    // prevent event from reaching ListView scroll handler
                                    preventStealing: true

                                    property real startY: 0

                                    onPressed: (mouse) => {
                                        startY = mapToItem(listView, 0, mouse.y).y;
                                        listContainer.dragFrom = delegate.index;
                                        listContainer.dragTo   = delegate.index;
                                        listContainer.ghostY   = delegate.y - listView.contentY;
                                    }

                                    onPositionChanged: (mouse) => {
                                        if (!pressed) return;
                                        const curY = mapToItem(listView, 0, mouse.y).y + listView.contentY;
                                        const rowH = delegate.height + listView.spacing;
                                        const target = Math.max(0, Math.min(
                                            itemModel.count - 1,
                                            Math.round(curY / rowH)
                                        ));
                                        listContainer.dragTo = target;
                                        listContainer.ghostY = mapToItem(listView, 0, mouse.y).y;
                                    }

                                    onReleased: {
                                        if (listContainer.dragFrom !== -1 &&
                                            listContainer.dragTo   !== -1 &&
                                            listContainer.dragFrom !== listContainer.dragTo) {
                                            todoModel.move(listContainer.dragFrom, listContainer.dragTo);
                                        }
                                        listContainer.dragFrom = -1;
                                        listContainer.dragTo   = -1;
                                    }
                                    onCanceled: {
                                        listContainer.dragFrom = -1;
                                        listContainer.dragTo   = -1;
                                    }
                                }
                            }

                            // checkbox
                            Rectangle {
                                id: checkbox
                                width:18; height:18; radius:5
                                anchors.verticalCenter: parent.verticalCenter
                                color: checked ? Qt.rgba(166/255,227/255,161/255,0.18) : "transparent"
                                border.color: checked ? root.clrGreen : root.clrMauve
                                border.width: 1.5
                                property bool checked: false
                                Behavior on color        { ColorAnimation { duration: 180 } }
                                Behavior on border.color { ColorAnimation { duration: 180 } }

                                Text {
                                    anchors.centerIn: parent; text:"✓"
                                    color:root.clrGreen; font.pixelSize:11; font.family:root.fontFamily
                                    visible: checkbox.checked
                                    opacity: checkbox.checked ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                TapHandler {
                                    onTapped: {
                                        checkbox.checked = true;
                                        checkTimer.idx = delegate.index;
                                        checkTimer.start();
                                    }
                                }
                                Timer {
                                    id: checkTimer; property int idx:0
                                    interval:350; repeat:false
                                    onTriggered: todoModel.remove(idx)
                                }
                            }

                            // text
                            Text {
                                text: delegate.itemText
                                color: checkbox.checked ? root.clrOverlay : root.clrText
                                font.pixelSize:12; font.family:root.fontFamily
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 56
                                elide: Text.ElideRight
                                font.strikeout: checkbox.checked
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }

                    // empty state
                    Text {
                        visible: itemModel.count === 0
                        width: listView.width
                        text: "nothing here — add something"
                        color: root.clrOverlay
                        font.pixelSize:11; font.family:root.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        topPadding:8; bottomPadding:8
                    }
                }

                // ── floating ghost row while dragging ─────────────────────────
                Rectangle {
                    visible: listContainer.dragging
                    x: 0; y: listContainer.ghostY
                    width: listView.width - 6; height: 36; radius: 10
                    color: Qt.rgba(203/255,166/255,247/255,0.13)
                    border.color: "#cba6f7"; border.width: 1.2
                    opacity: 0.92
                    z: 20

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin:4; anchors.rightMargin:4
                        spacing: 8
                        Text {
                            width:18; text:"⠿"; color:"#cba6f7"
                            font.pixelSize:14; font.family:root.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            text: listContainer.dragFrom >= 0 && listContainer.dragFrom < itemModel.count
                                ? itemModel.get(listContainer.dragFrom).itemText : ""
                            color: root.clrText
                            font.pixelSize:12; font.family:root.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 30
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Rectangle { width:parent.width; height:1; color:Qt.rgba(1,1,1,0.06) }

            // ── add input ─────────────────────────────────────────────────────
            Rectangle {
                width:parent.width; height:36; radius:10
                color: addInput.activeFocus
                    ? Qt.rgba(203/255,166/255,247/255,0.09)
                    : root.clrSurface
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.fill:parent; anchors.leftMargin:12; spacing:8
                    Text {
                        text:"+"; color: addInput.activeFocus ? root.clrMauve : root.clrOverlay
                        font.pixelSize:16; font.family:root.fontFamily
                        anchors.verticalCenter:parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    TextInput {
                        id: addInput
                        width: parent.width - 36; height:parent.height
                        color:root.clrText; font.pixelSize:12; font.family:root.fontFamily
                        verticalAlignment: TextInput.AlignVCenter; clip:true

                        onActiveFocusChanged: if (activeFocus) scrollTimer.restart()
                        onTextChanged:        scrollTimer.restart()

                        Text {
                            anchors.fill:parent
                            text:"add a todo..."
                            color:root.clrOverlay; font.pixelSize:12; font.family:root.fontFamily
                            verticalAlignment:Text.AlignVCenter
                            visible: !addInput.activeFocus && addInput.text.length === 0
                        }

                        Keys.onReturnPressed: {
                            todoModel.add(text);
                            text = "";
                        }
                        Keys.onEscapePressed: {
                            text = "";
                            root.popupVisible = false;
                        }
                    }
                }
            }

            Item { width:1; height:4 }
        }
    }
}
