import QtQuick
import Quickshell
import ".."
import "../components"

// "Widgets" tab: desktop widgets of the salbei bar -- with any other bar
// active they run on their own (WidgetsStore.hosted), laid out like "Bars" and
// "Launcher". Left 25 %: every widget with its own on/off switch, plus the
// accent color. Right: name + description, a live preview of the desktop on
// the real wallpaper and the settings of the selected widget.
//
// "Verschieben" turns the preview into an editor: drag widgets (they snap to
// the center lines and the 2.5 % margins), arrow keys nudge the selected one
// (Shift = coarse), Enter/Esc = done. Positions are % of the screen, so the
// desktop follows live while dragging. Every change is written to
// salbei-widgets.json right away (WidgetsStore) -- no "Anwenden".
//
// The preview uses the same light/dark decision as salbei (wallpaper
// brightness under each widget, WidgetsStore.lumAt) for widgets that have
// "An Hintergrund anpassen" on.
FocusScope {
    id: page

    readonly property string sel: WidgetsStore.selected
    readonly property var selMeta: WidgetsStore.meta(sel)
    readonly property bool isAccent: sel === "accent"
    readonly property var entries: WidgetsStore.widgetIds.concat(["accent"])

    readonly property var screen: Quickshell.screens[0] ?? null
    readonly property real screenW: screen?.width ?? 2560
    readonly property real screenH: screen?.height ?? 1440

    property bool moving: false

    // salbei's font (Theme._pick there), so the preview text has the real size
    readonly property string deskFont: {
        const fams = Qt.fontFamilies();
        for (const f of ["Outfit", "Lexend", "Adwaita Sans", "Inter", "DejaVu Sans"])
            if (fams.indexOf(f) >= 0) return f;
        return "sans-serif";
    }
    // salbei's Theme colors
    readonly property color deskText: "#E8EDE6"
    readonly property color deskDim: "#9DA89C"
    readonly property color deskFaint: "#6B766B"
    readonly property color accent: WidgetsStore.currentAccent

    Component.onCompleted: {
        if (entries.indexOf(WidgetsStore.selected) < 0) WidgetsStore.selected = "clock";
    }

    function select(id: string): void {
        WidgetsStore.selected = id;
        if (id === "accent") moving = false;
    }
    function step(delta: int): void {
        const i = entries.indexOf(sel);
        select(entries[Math.max(0, Math.min(entries.length - 1, i + delta))]);
    }
    function toggle(id: string): void {
        if (id !== "accent") WidgetsStore.set(id + "Visible", !WidgetsStore.v(id + "Visible"));
    }
    function nudge(dx: real, dy: real): void {
        if (isAccent) return;
        const r = v => Math.round(Math.max(0, Math.min(100, v)) * 10) / 10;
        if (dx) WidgetsStore.set(sel + "X", r(WidgetsStore.v(sel + "X") + dx));
        if (dy) WidgetsStore.set(sel + "Y", r(WidgetsStore.v(sel + "Y") + dy));
    }

    Keys.onPressed: event => {
        const coarse = event.modifiers & Qt.ShiftModifier;
        const d = coarse ? 2 : 0.2;
        if (moving) {
            if (event.key === Qt.Key_Left) { nudge(-d, 0); event.accepted = true; }
            else if (event.key === Qt.Key_Right) { nudge(d, 0); event.accepted = true; }
            else if (event.key === Qt.Key_Up) { nudge(0, -d); event.accepted = true; }
            else if (event.key === Qt.Key_Down) { nudge(0, d); event.accepted = true; }
            else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return
                     || event.key === Qt.Key_Enter || event.key === Qt.Key_V) { moving = false; event.accepted = true; }
            else if (event.key === Qt.Key_Tab) { step(1); if (isAccent) select("clock"); event.accepted = true; }
            return;
        }
        if (event.key === Qt.Key_Up) { step(-1); event.accepted = true; }
        else if (event.key === Qt.Key_Down) { step(1); event.accepted = true; }
        else if (event.key === Qt.Key_Space) { toggle(sel); event.accepted = true; }
        else if (event.key === Qt.Key_V && !isAccent) { moving = true; event.accepted = true; }
    }

    component SectionLabel: Text {
        color: Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontXs
        font.weight: Font.Bold
        font.letterSpacing: 1
    }

    Row {
        anchors.fill: parent
        spacing: Theme.spacingM

        // -- List ------------------------------------------------------
        Panel {
            id: listPanel
            width: Math.round(parent.width * 0.25)
            height: parent.height

            Text {
                id: listTitle
                anchors { top: parent.top; left: parent.left; margins: Theme.spacingM }
                text: "WIDGETS  ·  " + WidgetsStore.visibleCount + " / " + WidgetsStore.widgetIds.length + " an"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontXs
                font.weight: Font.Bold
                font.letterSpacing: 1
            }

            Row {
                id: statusLine
                anchors { top: listTitle.bottom; topMargin: Theme.spacingXs; left: parent.left; leftMargin: Theme.spacingM }
                spacing: 6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7; height: 7; radius: 3.5
                    color: WidgetsStore.running ? Theme.success : Theme.danger
                }
                Text {
                    text: (WidgetsStore.running ? "läuft" : "läuft nicht")
                          + (WidgetsStore.hosted ? "  ·  eigenständig neben „" + BarsModel.activeBar + "“" : "  ·  in salbei")
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontXs
                }
            }

            ListView {
                id: list
                anchors {
                    top: statusLine.bottom; topMargin: Theme.spacingS
                    left: parent.left; right: parent.right; bottom: listHint.top
                    leftMargin: Theme.spacingS; rightMargin: Theme.spacingS; bottomMargin: Theme.spacingXs
                }
                clip: true
                model: page.entries
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                highlightMoveDuration: Theme.animFast
                currentIndex: Math.max(0, page.entries.indexOf(page.sel))
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                highlight: Item {
                    width: list.width
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        radius: Theme.radiusSmall
                        color: Theme.select
                    }
                }

                delegate: Item {
                    id: row
                    required property string modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property bool accentRow: modelData === "accent"
                    readonly property var meta: WidgetsStore.meta(modelData)
                    readonly property bool on: !accentRow && WidgetsStore.v(modelData + "Visible") === true

                    width: ListView.view.width
                    height: Theme.listRowHeight

                    // divider above the accent entry
                    Rectangle {
                        visible: row.accentRow
                        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                        height: 1
                        color: Theme.border
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        radius: Theme.radiusSmall
                        color: rowMouse.containsMouse && !row.current ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    // icon tile: lit in the accent color while the widget is on
                    Rectangle {
                        id: tile
                        anchors { left: parent.left; leftMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                        width: 26; height: 26; radius: 7
                        color: row.accentRow ? page.accent : (row.on ? Qt.alpha(page.accent, 0.2) : Theme.panelAlt)
                        border.width: 1
                        border.color: row.current ? Qt.rgba(1, 1, 1, 0.6) : (row.on ? Qt.alpha(page.accent, 0.5) : Theme.border)
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Icon {
                            anchors.centerIn: parent
                            text: row.accentRow ? "" : row.meta.icon
                            size: Theme.fontS
                            color: row.accentRow ? "#18201a" : (row.on ? page.accent : Theme.textFaint)
                        }
                    }

                    Column {
                        anchors {
                            left: tile.right; leftMargin: Theme.spacingS
                            right: row.accentRow ? parent.right : sw.left; rightMargin: Theme.spacingS
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 1
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.accentRow ? "Akzentfarbe" : row.meta.name
                            color: row.current ? Theme.selectText : (row.on || row.accentRow ? Theme.text : Theme.textDim)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontM
                            font.weight: row.current ? Font.DemiBold : Font.Normal
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.accentRow
                                ? (WidgetsStore.accentMode === "wallpaper" ? "aus dem Wallpaper" : "fest  ·  " + WidgetsStore.accentColor)
                                : row.meta.title
                            color: row.current ? Qt.rgba(1, 1, 1, 0.8) : Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontXs
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.select(row.modelData)
                        onDoubleClicked: page.toggle(row.modelData)
                    }

                    // on/off switch right in the row
                    Rectangle {
                        id: sw
                        visible: !row.accentRow
                        anchors { right: parent.right; rightMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                        width: 32; height: 18
                        radius: height / 2
                        color: row.on ? (row.current ? Qt.rgba(1, 1, 1, 0.9) : Theme.accent) : (row.current ? Qt.rgba(1, 1, 1, 0.2) : Theme.panelAlt)
                        border.width: Theme.borderWidth
                        border.color: row.on ? "transparent" : (swMouse.containsMouse ? Theme.textDim : (row.current ? Qt.rgba(1, 1, 1, 0.35) : Theme.border))
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Rectangle {
                            width: parent.height - 6
                            height: width
                            radius: width / 2
                            y: 3
                            x: row.on ? parent.width - width - 3 : 3
                            color: row.on ? (row.current ? Theme.select : Theme.accentText) : (row.current ? "#ffffff" : Theme.textDim)
                            Behavior on x { NumberAnimation { duration: Theme.animPage; easing.type: Easing.OutBack } }
                        }
                        MouseArea {
                            id: swMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { page.select(row.modelData); page.toggle(row.modelData); }
                        }
                    }
                }
            }

            Text {
                id: listHint
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.spacingM }
                wrapMode: Text.WordWrap
                text: "Leertaste = an/aus  ·  V = verschieben"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontXs
            }
        }

        // -- Preview + settings ----------------------------------------
        Panel {
            id: previewPanel
            width: parent.width - listPanel.width - parent.spacing
            height: parent.height

            Item {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.spacingL

                // heading: name, subtitle, actions
                Row {
                    id: actions
                    anchors { top: parent.top; right: parent.right }
                    spacing: Theme.spacingS
                    visible: !page.isAccent

                    WizardButton {
                        text: "Position zurück"
                        icon: ""
                        visible: !page.moving
                        onClicked: WidgetsStore.resetPosition(page.sel)
                    }
                    WizardButton {
                        text: page.moving ? "Fertig" : "Verschieben"
                        icon: page.moving ? "" : ""
                        primary: true
                        onClicked: { page.moving = !page.moving; page.forceActiveFocus(); }
                    }
                }

                Row {
                    id: heading
                    anchors { top: parent.top; left: parent.left; right: actions.visible ? actions.left : parent.right; rightMargin: Theme.spacingM }
                    spacing: Theme.spacingM
                    Text {
                        id: nameText
                        text: page.isAccent ? "Akzentfarbe" : (page.selMeta?.name ?? "")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontXl
                        font.weight: Font.Bold
                    }
                    Text {
                        anchors.baseline: nameText.baseline
                        width: parent.width - nameText.width - parent.spacing
                        elide: Text.ElideRight
                        text: page.moving ? "Verschieben  ·  ziehen oder Pfeiltasten"
                            : page.isAccent ? "für alle Widgets" : (page.selMeta?.title ?? "")
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontM
                    }
                }

                Text {
                    id: descText
                    anchors { top: heading.bottom; topMargin: 4; left: parent.left; right: actions.visible ? actions.left : parent.right; rightMargin: Theme.spacingM }
                    text: page.moving
                        ? "Rastet an Mitte und Rändern ein  ·  Pfeile = 0,2 %, Shift+Pfeile = 2 %  ·  Tab = nächstes Widget  ·  Enter/Esc = fertig"
                        : page.isAccent
                        ? "Farbe für Uhr, aktiven Tag, Ringe, Schalter und Visualizer."
                        : (page.selMeta?.description ?? "")
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontS
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                // -- Desktop preview ------------------------------------
                Item {
                    id: stageBox
                    anchors { top: descText.bottom; topMargin: Theme.spacingM; left: parent.left; right: parent.right }
                    height: page.moving ? content.height - y : Math.round((content.height - y) * 0.56)
                    Behavior on height { NumberAnimation { duration: Theme.animWindow; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: stage
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width, parent.height * page.screenW / page.screenH)
                        height: width * page.screenH / page.screenW
                        radius: Theme.radiusSmall
                        color: "#16251F"
                        clip: true

                        readonly property real s: width / page.screenW

                        // wallpaper; webp can't be decoded here → salbei's color grid instead
                        Image {
                            id: wallImg
                            anchors.fill: parent
                            source: WidgetsStore.wallpaper !== "" ? "file://" + WidgetsStore.wallpaper : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 960
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
                        }
                        Grid {
                            id: gridFallback
                            readonly property var g: WidgetsStore._palette.grid
                            readonly property int gw: WidgetsStore._palette.gridW
                            visible: wallImg.status !== Image.Ready && g.length > 0 && gw > 0
                            anchors.fill: parent
                            columns: Math.max(1, gw)
                            Repeater {
                                model: gridFallback.visible ? gridFallback.g.length / 3 : 0
                                Rectangle {
                                    required property int index
                                    width: stage.width / gridFallback.gw
                                    height: stage.height / WidgetsStore._palette.gridH
                                    color: Qt.rgba(gridFallback.g[index * 3] / 255, gridFallback.g[index * 3 + 1] / 255, gridFallback.g[index * 3 + 2] / 255, 1)
                                }
                            }
                        }

                        // dim the wallpaper a little while editing, so outlines read well
                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: page.moving ? 0.22 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
                        }

                        // salbei's bar pill
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 6 * stage.s
                            width: page.screenW * 0.48 * stage.s
                            height: Math.max(3, 36 * stage.s)
                            radius: height / 2
                            color: Qt.rgba(30 / 255, 44 / 255, 52 / 255, 0.8)
                        }

                        // click on empty desktop: nothing selected changes, but keys come back here
                        MouseArea {
                            anchors.fill: parent
                            onClicked: page.forceActiveFocus()
                        }

                        // everything below is in real screen pixels, scaled down
                        Item {
                            id: screenSpace
                            width: page.screenW
                            height: page.screenH
                            scale: stage.s
                            transformOrigin: Item.TopLeft

                            // grid + snap guides while editing
                            Repeater {
                                model: page.moving ? 9 : 0
                                Rectangle {
                                    required property int index
                                    x: page.screenW * (index + 1) / 10
                                    width: 1 / stage.s
                                    height: page.screenH
                                    color: Qt.rgba(1, 1, 1, 0.07)
                                }
                            }
                            Repeater {
                                model: page.moving ? 9 : 0
                                Rectangle {
                                    required property int index
                                    y: page.screenH * (index + 1) / 10
                                    height: 1 / stage.s
                                    width: page.screenW
                                    color: Qt.rgba(1, 1, 1, 0.07)
                                }
                            }
                            Rectangle {
                                id: guideV
                                property real at: -1
                                visible: at >= 0
                                x: at - width / 2
                                width: 1.5 / stage.s
                                height: page.screenH
                                color: Theme.accent
                            }
                            Rectangle {
                                id: guideH
                                property real at: -1
                                visible: at >= 0
                                y: at - height / 2
                                height: 1.5 / stage.s
                                width: page.screenW
                                color: Theme.accent
                            }

                            Repeater {
                                model: WidgetsStore.widgetIds

                                delegate: Item {
                                    id: m
                                    required property string modelData
                                    readonly property var meta: WidgetsStore.meta(modelData)
                                    readonly property bool on: WidgetsStore.v(modelData + "Visible") === true
                                    readonly property bool selected: page.sel === modelData
                                    readonly property bool adapt: WidgetsStore.v(modelData + "Adapt") !== false
                                    readonly property bool backdrop: meta.backdrop && WidgetsStore.v(modelData + "Backdrop") === true
                                    readonly property real margin: backdrop ? 18 : 0
                                    readonly property real sc: WidgetsStore.v(modelData + "Scale") ?? 1

                                    width: ld.item ? ld.item.width : 0
                                    height: ld.item ? ld.item.height : 0
                                    x: Math.round(Math.max(margin, Math.min(page.screenW - width - margin, page.screenW * WidgetsStore.v(modelData + "X") / 100)))
                                    y: Math.round(Math.max(margin, Math.min(page.screenH - height - margin, page.screenH * WidgetsStore.v(modelData + "Y") / 100)))
                                    z: selected ? 2 : 1

                                    visible: on || selected
                                    opacity: on ? 1 : 0.35

                                    // same colors as salbei's DeskWidget
                                    readonly property real bgLum: adapt
                                        ? WidgetsStore.lumAt((x - margin) / page.screenW, (y - margin) / page.screenH,
                                                             (x + width + margin) / page.screenW, (y + height + margin) / page.screenH)
                                        : 0
                                    readonly property bool onLight: bgLum > 0.58
                                    readonly property color ink: onLight ? "#17201A" : page.deskText
                                    readonly property color inkDim: onLight ? Qt.rgba(0.09, 0.13, 0.1, 0.74) : page.deskDim
                                    readonly property color inkFaint: onLight ? Qt.rgba(0.09, 0.13, 0.1, 0.5) : page.deskFaint
                                    readonly property color accent: onLight
                                        ? Qt.hsla(page.accent.hslHue < 0 ? 0.33 : page.accent.hslHue, Math.min(0.65, page.accent.hslSaturation + 0.15), 0.32, 1)
                                        : page.accent
                                    readonly property color accentInk: onLight ? "#F3F6F1"
                                        : Qt.hsla(page.accent.hslHue < 0 ? 0.33 : page.accent.hslHue, Math.min(0.35, page.accent.hslSaturation), 0.12, 1)
                                    readonly property color soft: onLight ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.12)

                                    // glass card
                                    Rectangle {
                                        visible: m.backdrop
                                        anchors.fill: parent
                                        anchors.margins: -18
                                        radius: 18
                                        color: m.onLight ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(14 / 255, 20 / 255, 16 / 255, 0.42)
                                        border.width: 1 / stage.s
                                        border.color: m.onLight ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.08)
                                    }

                                    Loader {
                                        id: ld
                                        sourceComponent: ({
                                            clock: clockC, analog: analogC, calendar: calendarC, visualizer: visualizerC, greeting: greetingC,
                                            media: mediaC, system: systemC, weather: weatherC
                                        })[m.modelData] ?? null
                                    }

                                    // selection / edit outline (constant width on screen)
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: -Math.max(m.margin, 10)
                                        radius: 14
                                        color: "transparent"
                                        visible: m.selected || (page.moving && m.on) || dragMouse.containsMouse
                                        border.width: (m.selected ? 2 : 1) / stage.s
                                        border.color: m.selected ? Theme.select : Qt.rgba(1, 1, 1, dragMouse.containsMouse ? 0.7 : 0.35)
                                        Rectangle {
                                            visible: m.selected && page.moving
                                            // above the outline, below it near the top edge; never off the left edge
                                            transformOrigin: Item.TopLeft
                                            x: Math.max(-parent.x - m.x, 0)
                                            y: m.y - Math.max(m.margin, 10) > 40 / stage.s ? -(height + 6) / stage.s : parent.height + 6 / stage.s
                                            width: tagText.implicitWidth + 12
                                            height: tagText.implicitHeight + 4
                                            scale: 1 / stage.s
                                            radius: 4
                                            color: Theme.select
                                            Text {
                                                id: tagText
                                                anchors.centerIn: parent
                                                text: m.meta.name + "  " + Number(WidgetsStore.v(m.modelData + "X")).toFixed(1)
                                                      + " / " + Number(WidgetsStore.v(m.modelData + "Y")).toFixed(1) + " %"
                                                color: "white"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontXs
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: dragMouse
                                        anchors.fill: parent
                                        anchors.margins: -Math.max(m.margin, 10)
                                        hoverEnabled: true
                                        cursorShape: page.moving ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
                                        property point press
                                        property real startX
                                        property real startY
                                        onPressed: mouse => {
                                            page.select(m.modelData);
                                            page.forceActiveFocus();
                                            press = mapToItem(screenSpace, mouse.x, mouse.y);
                                            startX = m.x;
                                            startY = m.y;
                                        }
                                        onDoubleClicked: { if (!page.moving) page.moving = true; }
                                        onReleased: { guideV.at = -1; guideH.at = -1; }
                                        onPositionChanged: mouse => {
                                            if (!pressed || !page.moving) return;
                                            const p = mapToItem(screenSpace, mouse.x, mouse.y);
                                            const W = page.screenW, H = page.screenH;
                                            const w = m.width, h = m.height, mg = m.margin;
                                            let nx = Math.max(mg, Math.min(W - w - mg, startX + p.x - press.x));
                                            let ny = Math.max(mg, Math.min(H - h - mg, startY + p.y - press.y));
                                            const t = 10 / stage.s;           // 10 preview px
                                            // snap: [edge position, guide line, stored % (null = from px)]
                                            let gx = -1, gy = -1, fx = null, fy = null;
                                            const xs = [[W * 0.025, W * 0.025], [W / 2 - w / 2, W / 2], [W * 0.975 - w, W * 0.975], [W - w - mg, -1]];
                                            for (const c of xs) if (Math.abs(nx - c[0]) < t) { nx = c[0]; gx = c[1]; break; }
                                            const ys = [[H * 0.025, H * 0.025], [H / 2 - h / 2, H / 2], [H * 0.975 - h, H * 0.975], [H - h - mg, -1]];
                                            for (const c of ys) if (Math.abs(ny - c[0]) < t) { ny = c[0]; gy = c[1]; break; }
                                            // touching the right/bottom edge: store 100 so it stays glued there
                                            if (nx >= W - w - mg - 0.5) fx = 100;
                                            if (ny >= H - h - mg - 0.5) fy = 100;
                                            guideV.at = gx;
                                            guideH.at = gy;
                                            WidgetsStore.set(m.modelData + "X", fx ?? Math.round(nx / W * 1000) / 10);
                                            WidgetsStore.set(m.modelData + "Y", fy ?? Math.round(ny / H * 1000) / 10);
                                        }
                                    }

                                    // -- mock contents, in real pixels ----------------
                                    Component {
                                        id: clockC
                                        Text {
                                            text: (WidgetsStore.v("clock24h") ? "14:58" : "2:58") + (WidgetsStore.v("clockSeconds") ? ":07" : "")
                                            color: m.accent
                                            font.family: page.deskFont
                                            font.pixelSize: WidgetsStore.v("clockSize")
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: -4
                                        }
                                    }

                                    // same face as salbei's modules/widgets/AnalogClock.qml
                                    Component {
                                        id: analogC
                                        Canvas {
                                            readonly property real size: WidgetsStore.v("analogSize")
                                            readonly property bool seconds: WidgetsStore.v("analogSeconds")
                                            readonly property bool numbers: WidgetsStore.v("analogNumbers")
                                            readonly property bool ticks: WidgetsStore.v("analogTicks")
                                            readonly property var colors: [m.ink, m.inkDim, m.inkFaint, m.accent]
                                            width: size
                                            height: size
                                            onSizeChanged: requestPaint()
                                            onSecondsChanged: requestPaint()
                                            onNumbersChanged: requestPaint()
                                            onTicksChanged: requestPaint()
                                            onColorsChanged: requestPaint()
                                            onPaint: {
                                                const ctx = getContext("2d");
                                                ctx.reset();
                                                const s = size, r = s / 2;
                                                ctx.translate(r, r);
                                                ctx.lineCap = "round";
                                                ctx.strokeStyle = m.inkFaint;
                                                ctx.lineWidth = Math.max(1.5, s * 0.012);
                                                ctx.beginPath();
                                                ctx.arc(0, 0, r - ctx.lineWidth / 2, 0, 2 * Math.PI);
                                                ctx.stroke();
                                                for (let i = 0; i < 60; i++) {
                                                    const hour = i % 5 === 0;
                                                    if (!hour && !ticks) continue;
                                                    if (numbers && i % 15 === 0) continue;
                                                    const a = i * Math.PI / 30;
                                                    const len = hour ? s * 0.07 : s * 0.03;
                                                    const out = r - s * 0.045;
                                                    ctx.strokeStyle = hour ? m.inkDim : m.inkFaint;
                                                    ctx.lineWidth = hour ? Math.max(2, s * 0.022) : Math.max(1, s * 0.008);
                                                    ctx.beginPath();
                                                    ctx.moveTo(Math.sin(a) * out, -Math.cos(a) * out);
                                                    ctx.lineTo(Math.sin(a) * (out - len), -Math.cos(a) * (out - len));
                                                    ctx.stroke();
                                                }
                                                if (numbers) {
                                                    ctx.fillStyle = m.ink;
                                                    ctx.font = "600 " + Math.round(s * 0.13) + "px \"" + page.deskFont + "\"";
                                                    ctx.textAlign = "center";
                                                    ctx.textBaseline = "middle";
                                                    const nr = r - s * 0.13;
                                                    [12, 3, 6, 9].forEach((n, k) => {
                                                        const a = k * Math.PI / 2;
                                                        ctx.fillText(String(n), Math.sin(a) * nr, -Math.cos(a) * nr);
                                                    });
                                                }
                                                function hand(angle, len, tail, width, color) {
                                                    ctx.strokeStyle = color;
                                                    ctx.lineWidth = width;
                                                    ctx.beginPath();
                                                    ctx.moveTo(-Math.sin(angle) * tail, Math.cos(angle) * tail);
                                                    ctx.lineTo(Math.sin(angle) * len, -Math.cos(angle) * len);
                                                    ctx.stroke();
                                                }
                                                // 14:58:07, like the digital clock's mock
                                                hand((2 + 58 / 60) * Math.PI / 6, r * 0.5, r * 0.08, Math.max(3, s * 0.04), m.ink);
                                                hand((58 + (seconds ? 7 / 60 : 0)) * Math.PI / 30, r * 0.74, r * 0.08, Math.max(2, s * 0.028), m.ink);
                                                if (seconds)
                                                    hand(7 * Math.PI / 30, r * 0.8, r * 0.16, Math.max(1, s * 0.01), m.accent);
                                                ctx.fillStyle = m.accent;
                                                ctx.beginPath();
                                                ctx.arc(0, 0, Math.max(3, s * 0.03), 0, 2 * Math.PI);
                                                ctx.fill();
                                            }
                                        }
                                    }

                                    Component {
                                        id: calendarC
                                        Row {
                                            id: calRoot
                                            spacing: 18
                                            readonly property bool wk: WidgetsStore.v("calendarWeekNumbers")
                                            readonly property real cw: WidgetsStore.v("calendarWidth")
                                            readonly property real cell: Math.floor(cw / (wk ? 8 : 7))
                                            readonly property date today: new Date()
                                            readonly property var days: {
                                                const f = new Date(today.getFullYear(), today.getMonth(), 1);
                                                const out = [];
                                                for (let i = 0; i < 42; i++) {
                                                    const d = new Date(f.getFullYear(), f.getMonth(), 1 - f.getDay() + i);
                                                    out.push({ n: d.getDate(), inMonth: d.getMonth() === today.getMonth(), isToday: d.toDateString() === today.toDateString() });
                                                }
                                                return out;
                                            }
                                            Column {
                                                id: calCol
                                                width: parent.cw
                                                spacing: 8
                                                Row {
                                                    spacing: 10
                                                    Text { text: Qt.locale("en_US").toString(calRoot.today, "dddd"); color: m.inkDim; font.family: page.deskFont; font.pixelSize: 12 }
                                                    Text { text: Qt.formatDate(calRoot.today, "yyyy-MM-dd"); color: m.inkDim; font.family: page.deskFont; font.pixelSize: 12 }
                                                }
                                                Column {
                                                    width: parent.width
                                                    spacing: 6
                                                    Item {
                                                        width: parent.width
                                                        height: 26
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: Qt.locale("en_US").standaloneMonthName(calRoot.today.getMonth()) + " " + calRoot.today.getFullYear()
                                                            color: m.ink
                                                            font.family: page.deskFont
                                                            font.pixelSize: 14
                                                            font.weight: Font.DemiBold
                                                        }
                                                        Text { anchors.verticalCenter: parent.verticalCenter; x: 6; text: "‹"; color: m.inkDim; font.pixelSize: 18 }
                                                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 6; text: "›"; color: m.inkDim; font.pixelSize: 18 }
                                                    }
                                                    Grid {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        columns: calRoot.wk ? 8 : 7
                                                        Repeater {
                                                            model: (calRoot.wk ? [""] : []).concat(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"])
                                                            Text {
                                                                required property string modelData
                                                                width: calRoot.cell
                                                                height: calRoot.cell * 0.8
                                                                horizontalAlignment: Text.AlignHCenter
                                                                verticalAlignment: Text.AlignVCenter
                                                                text: modelData
                                                                color: m.inkDim
                                                                font.family: page.deskFont
                                                                font.pixelSize: 11
                                                            }
                                                        }
                                                        Repeater {
                                                            model: calRoot.wk ? 48 : 42
                                                            Item {
                                                                required property int index
                                                                readonly property bool weekCell: calRoot.wk && index % 8 === 0
                                                                readonly property var info: weekCell ? null : calRoot.days[calRoot.wk ? index - Math.floor(index / 8) - 1 : index]
                                                                width: calRoot.cell
                                                                height: calRoot.cell
                                                                Rectangle {
                                                                    anchors.centerIn: parent
                                                                    width: parent.width - 4
                                                                    height: width
                                                                    radius: 6
                                                                    color: m.accent
                                                                    visible: parent.info?.isToday ?? false
                                                                }
                                                                Text {
                                                                    anchors.fill: parent
                                                                    horizontalAlignment: Text.AlignHCenter
                                                                    verticalAlignment: Text.AlignVCenter
                                                                    text: parent.weekCell ? "" + (Math.floor(parent.index / 8) + 40) : parent.info.n
                                                                    color: parent.weekCell ? m.inkFaint : parent.info.isToday ? m.accentInk : parent.info.inMonth ? m.ink : m.inkFaint
                                                                    font.family: page.deskFont
                                                                    font.pixelSize: 12
                                                                    font.weight: (parent.info?.isToday ?? false) ? Font.Bold : Font.Medium
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            Column {
                                                visible: WidgetsStore.v("calendarEvents")
                                                width: 120
                                                spacing: 4
                                                topPadding: 34
                                                Text {
                                                    width: parent.width
                                                    wrapMode: Text.Wrap
                                                    text: Qt.locale("en_US").toString(calRoot.today, "dddd d MMMM")
                                                    color: m.ink
                                                    font.family: page.deskFont
                                                    font.pixelSize: 13
                                                    font.weight: Font.Bold
                                                }
                                                Text { text: "No events."; color: m.inkDim; font.family: page.deskFont; font.pixelSize: 12 }
                                            }
                                        }
                                    }

                                    Component {
                                        id: visualizerC
                                        Canvas {
                                            width: Math.round(page.screenW * WidgetsStore.v("visualizerWidth") / 100)
                                            height: WidgetsStore.v("visualizerHeight")
                                            property color fill: m.accent
                                            onFillChanged: requestPaint()
                                            onWidthChanged: requestPaint()
                                            onHeightChanged: requestPaint()
                                            onPaint: {
                                                const ctx = getContext("2d");
                                                ctx.reset();
                                                ctx.fillStyle = fill;
                                                const n = Math.floor(width / 4), half = n / 2;
                                                for (let i = 0; i < n; i++) {
                                                    const t = (i + 0.5 - half) / half;
                                                    const wave = 0.55 + 0.45 * Math.abs(Math.sin(i * 1.7) * Math.cos(i * 0.43));
                                                    const h = height * wave * Math.exp(-(t * t) / (2 * 0.38 * 0.38));
                                                    if (h >= 1) ctx.fillRect(i * 4, height - h, 2, h);
                                                }
                                            }
                                        }
                                    }

                                    Component {
                                        id: greetingC
                                        Column {
                                            spacing: 4 * m.sc
                                            Text {
                                                text: "Good evening, " + ((WidgetsStore.v("greetingName") ?? "").trim() || (Quickshell.env("USER") ?? "you").replace(/^./, c => c.toUpperCase()))
                                                color: m.ink
                                                font.family: page.deskFont
                                                font.pixelSize: Math.round(34 * m.sc)
                                                font.weight: Font.DemiBold
                                            }
                                            Text {
                                                visible: WidgetsStore.v("greetingDate")
                                                text: Qt.locale("en_US").toString(new Date(), "dddd, d MMMM yyyy")
                                                color: m.accent
                                                font.family: page.deskFont
                                                font.pixelSize: Math.round(16 * m.sc)
                                            }
                                        }
                                    }

                                    Component {
                                        id: mediaC
                                        Row {
                                            spacing: 14 * m.sc
                                            Rectangle {
                                                visible: WidgetsStore.v("mediaArt")
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 72 * m.sc
                                                height: width
                                                radius: 14 * m.sc
                                                gradient: Gradient {
                                                    GradientStop { position: 0; color: Qt.lighter(m.accent, 1.1) }
                                                    GradientStop { position: 1; color: Qt.darker(m.accent, 1.8) }
                                                }
                                                Icon { anchors.centerIn: parent; text: ""; size: 28 * m.sc; color: Qt.rgba(1, 1, 1, 0.85) }
                                            }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 3 * m.sc
                                                Text { text: "Song Title"; color: m.ink; font.family: page.deskFont; font.pixelSize: Math.round(15 * m.sc); font.weight: Font.DemiBold }
                                                Text { text: "Artist"; color: m.inkDim; font.family: page.deskFont; font.pixelSize: Math.round(13 * m.sc) }
                                                Row {
                                                    visible: WidgetsStore.v("mediaControls")
                                                    topPadding: 4 * m.sc
                                                    spacing: 4 * m.sc
                                                    Repeater {
                                                        model: ["", "", ""]
                                                        Rectangle {
                                                            required property string modelData
                                                            required property int index
                                                            width: 30 * m.sc; height: width; radius: width / 2
                                                            color: index === 1 ? m.accent : "transparent"
                                                            Icon {
                                                                anchors.centerIn: parent
                                                                text: parent.modelData
                                                                size: 13 * m.sc
                                                                color: parent.index === 1 ? m.accentInk : m.ink
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Component {
                                        id: systemC
                                        Row {
                                            spacing: 16 * m.sc
                                            Repeater {
                                                model: [
                                                    { key: "systemCpu", label: "CPU", v: 0.23, t: "23%" },
                                                    { key: "systemRam", label: "RAM", v: 0.41, t: "41%" },
                                                    { key: "systemTemp", label: "TEMP", v: 0.52, t: "52°C" }
                                                ]
                                                Column {
                                                    id: ringCol
                                                    required property var modelData
                                                    visible: WidgetsStore.v(modelData.key)
                                                    spacing: 6
                                                    readonly property real size: 64 * m.sc
                                                    Item {
                                                        width: ringCol.size
                                                        height: ringCol.size
                                                        Canvas {
                                                            anchors.fill: parent
                                                            property color fill: m.accent
                                                            property color track: m.soft
                                                            onFillChanged: requestPaint()
                                                            onTrackChanged: requestPaint()
                                                            onWidthChanged: requestPaint()
                                                            onPaint: {
                                                                const ctx = getContext("2d");
                                                                ctx.reset();
                                                                const lw = Math.max(3, width * 0.09), r = width / 2 - lw / 2;
                                                                ctx.lineWidth = lw;
                                                                ctx.lineCap = "round";
                                                                ctx.strokeStyle = track;
                                                                ctx.beginPath(); ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI); ctx.stroke();
                                                                ctx.strokeStyle = fill;
                                                                ctx.beginPath(); ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + ringCol.modelData.v * 2 * Math.PI); ctx.stroke();
                                                            }
                                                        }
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: ringCol.modelData.t
                                                            color: m.ink
                                                            font.family: page.deskFont
                                                            font.pixelSize: Math.round(ringCol.size * 0.22)
                                                            font.weight: Font.DemiBold
                                                        }
                                                    }
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: ringCol.modelData.label
                                                        color: m.inkDim
                                                        font.family: page.deskFont
                                                        font.pixelSize: Math.round(ringCol.size * 0.17)
                                                        font.letterSpacing: 1
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Component {
                                        id: weatherC
                                        Row {
                                            id: weatherRoot
                                            spacing: 14 * m.sc
                                            readonly property bool f: WidgetsStore.v("weatherFahrenheit")
                                            Icon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: ""
                                                size: 50 * m.sc
                                                color: m.accent
                                            }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2 * m.sc
                                                Row {
                                                    spacing: 10 * m.sc
                                                    Text {
                                                        anchors.baseline: wDesc.baseline
                                                        text: weatherRoot.f ? "57°" : "14°"
                                                        color: m.ink
                                                        font.family: page.deskFont
                                                        font.pixelSize: Math.round(40 * m.sc)
                                                        font.weight: Font.DemiBold
                                                    }
                                                    Text { id: wDesc; text: "Partly cloudy"; color: m.inkDim; font.family: page.deskFont; font.pixelSize: Math.round(15 * m.sc) }
                                                }
                                                Text {
                                                    visible: WidgetsStore.v("weatherDetails")
                                                    text: "↑ 18°  ↓ 9°  ·  72%  ·  " + ((WidgetsStore.v("weatherCity") ?? "").trim() || "Ort")
                                                    color: m.inkFaint
                                                    font.family: page.deskFont
                                                    font.pixelSize: Math.round(12 * m.sc)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -- Settings of the selected entry -----------------------
                Flickable {
                    id: flick
                    anchors { top: stageBox.bottom; topMargin: Theme.spacingL; left: parent.left; right: parent.right; bottom: parent.bottom }
                    visible: opacity > 0
                    opacity: page.moving ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
                    contentHeight: page.isAccent ? accentBox.implicitHeight : settingsGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    // generic rows: the widget's own settings + the common ones
                    Grid {
                        id: settingsGrid
                        visible: !page.isAccent
                        width: flick.width
                        columns: 2
                        columnSpacing: Theme.spacingXl
                        rowSpacing: Theme.spacingS
                        readonly property real colW: (width - columnSpacing) / 2

                        readonly property var rows: {
                            if (page.isAccent || !page.selMeta) return [];
                            const id = page.sel;
                            const out = page.selMeta.settings.slice();
                            out.push({ type: "toggle", key: id + "Adapt", label: "An Hintergrund anpassen", hint: "Schrift hell/dunkel je nach Wallpaper darunter" });
                            if (page.selMeta.backdrop)
                                out.push({ type: "toggle", key: id + "Backdrop", label: "Glas-Karte", hint: "halbtransparente Fläche dahinter" });
                            out.push({ type: "slider", key: id + "X", label: "Position links", from: 0, to: 100, decimals: 1, suffix: " %" });
                            out.push({ type: "slider", key: id + "Y", label: "Position oben", from: 0, to: 100, decimals: 1, suffix: " %" });
                            return out;
                        }

                        Repeater {
                            model: settingsGrid.rows
                            delegate: Loader {
                                id: setting
                                required property var modelData
                                width: settingsGrid.colW
                                enabled: WidgetsStore.v(page.sel + "Visible") === true
                                sourceComponent: modelData.type === "toggle" ? toggleC : modelData.type === "slider" ? sliderC : textC
                            }
                        }
                    }

                    Component {
                        id: toggleC
                        ToggleRow {
                            readonly property var spec: parent.modelData
                            label: spec.label
                            hint: spec.hint ?? ""
                            checked: WidgetsStore.v(spec.key) === true
                            onToggled: v => WidgetsStore.set(spec.key, v)
                        }
                    }
                    Component {
                        id: sliderC
                        SliderRow {
                            readonly property var spec: parent.modelData
                            label: spec.label
                            from: spec.from; to: spec.to; decimals: spec.decimals; suffix: spec.suffix
                            value: WidgetsStore.v(spec.key)
                            onMoved: v => WidgetsStore.set(spec.key, v)
                        }
                    }
                    Component {
                        id: textC
                        Item {
                            id: textRow
                            readonly property var spec: parent.modelData
                            implicitHeight: 40
                            opacity: enabled ? 1 : 0.4
                            Text {
                                id: textLabel
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                width: 90
                                elide: Text.ElideRight
                                text: textRow.spec.label
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontM
                            }
                            Rectangle {
                                anchors { left: textLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                                height: 30
                                radius: Theme.radiusSmall
                                color: Theme.panelAlt
                                border.width: Theme.borderWidth
                                border.color: field.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border
                                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                                Text {
                                    anchors { left: parent.left; leftMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }
                                    visible: field.text.length === 0
                                    text: textRow.spec.placeholder ?? ""
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontS
                                }
                                TextInput {
                                    id: field
                                    anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    selectByMouse: true
                                    color: Theme.text
                                    selectionColor: Theme.select
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontS
                                    text: WidgetsStore.v(textRow.spec.key) ?? ""
                                    // debounced: the weather widget fetches on every city change
                                    onTextEdited: commit.restart()
                                    onEditingFinished: { commit.stop(); WidgetsStore.set(textRow.spec.key, text.trim()); }
                                    Keys.onEscapePressed: event => { page.forceActiveFocus(); event.accepted = true; }
                                    Keys.onReturnPressed: event => { page.forceActiveFocus(); event.accepted = true; }
                                    Timer {
                                        id: commit
                                        interval: 700
                                        onTriggered: WidgetsStore.set(textRow.spec.key, field.text.trim())
                                    }
                                }
                            }
                        }
                    }

                    // accent color entry
                    Column {
                        id: accentBox
                        visible: page.isAccent
                        width: flick.width
                        spacing: Theme.spacingM

                        Row {
                            spacing: 6
                            Repeater {
                                model: [{ key: "fixed", label: "Fest" }, { key: "wallpaper", label: "Aus dem Wallpaper" }]
                                delegate: Rectangle {
                                    id: modePill
                                    required property var modelData
                                    readonly property bool active: WidgetsStore.accentMode === modelData.key
                                    width: modeText.implicitWidth + 22
                                    height: 26
                                    radius: height / 2
                                    color: active ? Qt.alpha(Theme.accent, 0.18) : (modeMouse.containsMouse ? Theme.panelAlt : "transparent")
                                    border.width: Theme.borderWidth
                                    border.color: active ? Qt.alpha(Theme.accent, 0.7) : Theme.border
                                    Text {
                                        id: modeText
                                        anchors.centerIn: parent
                                        text: modePill.modelData.label
                                        color: modePill.active ? Theme.text : Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontS
                                    }
                                    MouseArea {
                                        id: modeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: WidgetsStore.set("accentMode", modePill.modelData.key)
                                    }
                                }
                            }
                        }

                        // presets (fixed) or the colors salbei found in the wallpaper
                        Row {
                            spacing: 10
                            readonly property bool wall: WidgetsStore.accentMode === "wallpaper"
                            Repeater {
                                model: parent.wall ? WidgetsStore.wallCandidates : WidgetsStore.presets
                                delegate: Rectangle {
                                    id: swatch
                                    required property var modelData
                                    required property int index
                                    readonly property bool wall: WidgetsStore.accentMode === "wallpaper"
                                    readonly property bool active: wall ? WidgetsStore.accentPick === index
                                                                        : WidgetsStore.accentColor.toLowerCase() === String(modelData).toLowerCase()
                                    width: 28; height: 28; radius: 14
                                    color: modelData
                                    border.width: active ? 2 : 0
                                    border.color: Theme.text
                                    scale: active ? 1.15 : (swatchMouse.containsMouse ? 1.08 : 1)
                                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                                    MouseArea {
                                        id: swatchMouse
                                        anchors.fill: parent
                                        anchors.margins: -3
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: swatch.wall ? WidgetsStore.set("accentPick", swatch.index)
                                                               : WidgetsStore.set("accentColor", String(swatch.modelData))
                                    }
                                }
                            }
                            Text {
                                visible: parent.wall && WidgetsStore.wallCandidates.length === 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Noch keine Farben – salbei liest gerade das Wallpaper."
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontS
                            }
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: WidgetsStore.accentMode === "wallpaper"
                                ? "Passt sich beim Wallpaper-Wechsel automatisch an (Prüfung alle 15 s, auch webp). Die Farben werden zu ruhigen Pastelltönen abgeschwächt. Auf hellem Hintergrund nehmen Widgets mit „An Hintergrund anpassen“ eine kräftigere Variante."
                                : "Auf hellem Hintergrund nehmen Widgets mit „An Hintergrund anpassen“ automatisch eine kräftigere Variante dieser Farbe."
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontXs
                        }
                        WizardButton {
                            text: "Alle Widgets auf Standard"
                            icon: ""
                            onClicked: WidgetsStore.resetDefaults()
                        }
                    }
                }
            }
        }
    }
}
