import QtQuick
import QtQuick.Controls
import Quickshell
import "../../"
import "../../components"

// App launcher: search field + fuzzy-filtered list of DesktopEntries.
GlassPanel {
    id: root

    namespace: "qs-launcher"
    open: Ui.launcherOpen
    panelWidth: Theme.launcherWidth
    panelHeight: Theme.launcherHeight
    surfaceToColor: Theme.panelFrom
    padding: 12
    onDismissed: Ui.launcherOpen = false

    property string query: ""
    // DesktopEntries fills in asynchronously, so recompute on change instead of binding once
    property var apps: []
    property var results: []

    function refreshApps() {
        const seen = {};
        apps = DesktopEntries.applications.values
            .filter(a => !a.noDisplay && !seen[a.id] && (seen[a.id] = true))
            .sort((a, b) => a.name.localeCompare(b.name));
        filter();
    }

    // subsequence match; rewards prefixes, word starts and consecutive runs
    function score(text, q) {
        text = text.toLowerCase();
        if (text.startsWith(q)) return 1000 - text.length;
        const idx = text.indexOf(q);
        if (idx >= 0) return 800 - idx;
        let s = 0, ti = 0, run = 0;
        for (let qi = 0; qi < q.length; qi++) {
            const c = q[qi];
            let found = false;
            for (; ti < text.length; ti++) {
                if (text[ti] === c) {
                    run = (ti > 0 && text[ti - 1] === q[qi - 1]) ? run + 1 : 0;
                    s += 10 + run * 5 + ((ti === 0 || " -_.".includes(text[ti - 1])) ? 15 : 0);
                    ti++;
                    found = true;
                    break;
                }
            }
            if (!found) return -1;
        }
        return s;
    }

    function filter() {
        const q = query.trim().toLowerCase();
        if (q === "") {
            results = apps;
        } else {
            const scored = [];
            for (const a of apps) {
                const s = Math.max(score(a.name, q),
                                   score(a.genericName || "", q) - 200,
                                   score((a.keywords || []).join(" "), q) - 300);
                if (s >= 0) scored.push({ a, s });
            }
            scored.sort((x, y) => y.s - x.s);
            results = scored.map(x => x.a);
        }
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }

    function launch(entry) {
        if (!entry) return;
        entry.execute();
        Ui.launcherOpen = false;
    }

    onQueryChanged: filter()
    onOpenChanged: {
        if (open) {
            search.text = "";
            refreshApps();
            search.forceActiveFocus();
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.refreshApps(); }
    }
    Component.onCompleted: refreshApps()

    // search field
    Rectangle {
        id: field
        width: parent.width
        height: 40
        radius: Theme.radiusField
        color: Theme.inset
        border.width: 1.5
        border.color: search.activeFocus ? Theme.insetBorderFocus : Theme.insetBorder
        Behavior on border.color { ColorAnimation { duration: Theme.animSlow } }

        // accent underline grows from the center while there is a query
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            height: 2
            radius: 1
            color: Theme.accent
            width: root.query !== "" ? parent.width - 2 * Theme.radiusField : 0
            Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingEmph } }
        }

        Icon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            size: Theme.iconItem
            color: root.query !== "" ? Theme.accent : Theme.textDim
            // little hop on every keystroke
            SequentialAnimation {
                id: typeHop
                NumberAnimation { target: searchIcon; property: "anchors.verticalCenterOffset"; to: -3; duration: 60; easing.type: Easing.OutQuad }
                NumberAnimation { target: searchIcon; property: "anchors.verticalCenterOffset"; to: 0; duration: 300; easing.type: Theme.easingSpring; easing.overshoot: 3 }
            }
        }

        TextInput {
            id: search
            anchors.left: searchIcon.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            font.family: Theme.fontFamily
            font.pixelSize: 14
            clip: true
            focus: true
            onTextChanged: { root.query = text; if (text !== "") typeHop.restart(); }

            Txt {
                anchors.fill: parent
                text: "Search applications..."
                color: Theme.textDim
                font.pixelSize: 14
                font.weight: Font.Normal
                opacity: search.text === "" ? 1 : 0
                anchors.leftMargin: search.text === "" ? 0 : 24
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                Behavior on anchors.leftMargin { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
            }

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) { Ui.launcherOpen = false; e.accepted = true; }
                else if (e.key === Qt.Key_Down || (e.key === Qt.Key_N && e.modifiers & Qt.ControlModifier)) {
                    list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); e.accepted = true;
                } else if (e.key === Qt.Key_Up || (e.key === Qt.Key_P && e.modifiers & Qt.ControlModifier)) {
                    list.currentIndex = Math.max(0, list.currentIndex - 1); e.accepted = true;
                } else if (e.key === Qt.Key_PageDown) {
                    list.currentIndex = Math.min(list.count - 1, list.currentIndex + 10); e.accepted = true;
                } else if (e.key === Qt.Key_PageUp) {
                    list.currentIndex = Math.max(0, list.currentIndex - 10); e.accepted = true;
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    root.launch(root.results[list.currentIndex]); e.accepted = true;
                }
            }
        }
    }

    ListView {
        id: list
        anchors.top: field.bottom
        anchors.topMargin: Theme.grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        // ScriptModel diffs the arrays, so filtering animates rows in/out instead of rebuilding
        model: ScriptModel { values: root.results }
        spacing: 2
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 220
        highlightMoveVelocity: -1
        highlightResizeDuration: 0
        boundsBehavior: Flickable.StopAtBounds

        // accent pill that glides to the selection
        highlight: Rectangle {
            width: list.width
            height: Theme.rowHeight
            radius: Theme.radiusRow
            color: Theme.accent
            opacity: list.count > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        add: Transition {
            SequentialAnimation {
                PropertyAction { property: "enter"; value: 0 }
                PauseAnimation { duration: Math.max(0, Math.min(ViewTransition.index, 10)) * 14 }
                ParallelAnimation {
                    NumberAnimation { property: "enter"; to: 1; duration: Theme.animNormal }
                    NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Theme.animSlow; easing.type: Theme.easingSpring }
                }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "enter"; to: 0; duration: Theme.animFast }
                NumberAnimation { property: "scale"; to: 0.9; duration: Theme.animFast }
            }
        }
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: Theme.animNormal + 60; easing.type: Theme.easing }
            NumberAnimation { properties: "enter,scale"; to: 1; duration: Theme.animFast }
        }

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool selected: ListView.isCurrentItem
            width: list.width
            height: Theme.rowHeight
            radius: Theme.radiusRow
            color: !selected && rowMouse.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            // cascade when the launcher opens
            readonly property real reveal: Math.max(0, Math.min(1, root.progress * 2.4 - Math.min(index, 12) * 0.1))
            // `enter` is driven by the add/remove transitions
            property real enter: 1
            opacity: reveal * enter
            transform: Translate { y: (1 - row.reveal) * 12 }

            AppIcon {
                id: appIcon
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                size: 28
                icon: row.modelData.icon
                fallbackText: row.modelData.name
                scale: row.selected ? 1.12 : 1
                rotation: row.selected ? -6 : 0
                Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
                Behavior on rotation { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
            }
            Txt {
                anchors.left: appIcon.right
                anchors.leftMargin: row.selected ? 14 : 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name
                color: row.selected ? Theme.accentInk : Theme.text
                font.weight: row.selected ? Font.DemiBold : Font.Medium
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                Behavior on anchors.leftMargin { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring } }
            }
            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { launchFx.restart(); }
            }
            // launch: quick squish, then go
            SequentialAnimation {
                id: launchFx
                NumberAnimation { target: row; property: "scale"; to: 0.94; duration: 80 }
                NumberAnimation { target: row; property: "scale"; to: 1.03; duration: 120; easing.type: Easing.OutQuad }
                ScriptAction { script: root.launch(row.modelData) }
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: bar
            policy: ScrollBar.AsNeeded
            width: 3
            padding: 0
            contentItem: Rectangle {
                implicitWidth: 3
                radius: 1.5
                color: Theme.textFaint
                opacity: bar.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
            }
            background: Item {}
        }

        Txt {
            anchors.centerIn: parent
            opacity: list.count === 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
            text: root.apps.length === 0 ? "Loading applications…" : "No matches"
            color: Theme.textDim
        }
    }
}
