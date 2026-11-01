import QtQuick
import Quickshell
import "../../"
import "../../components"
import "../../services"

// App launcher: search pill, ranked results with circular icon badges, the
// selected row raised with an accent orb sliding along on the left.
// "=" prefix turns the field into a small calculator.
//   Up/Down/Tab select · Enter launch · Esc close
FocusScope {
    id: root
    implicitHeight: col.implicitHeight

    property string query: ""
    readonly property bool calcMode: query.startsWith("=")
    readonly property var results: calcMode ? [] : Apps.search(query)
    readonly property string calcResult: calcMode ? Apps.calc(query) : ""

    function launch(i) {
        const e = root.results[i];
        if (!e)
            return;
        Popups.close();
        Apps.launch(e);
    }

    onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()

    Column {
        id: col
        width: parent.width
        spacing: Theme.s3

        // ---- search pill
        Rectangle {
            width: parent.width
            height: 56
            radius: height / 2
            color: Theme.surfaceSunken

            Orb {
                id: glass
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36
                color: root.calcMode ? Theme.orange : Theme.accent
                glowing: input.text.length > 0
                KIcon {
                    anchors.centerIn: parent
                    text: root.calcMode ? "=" : Glyphs.search
                    font.family: root.calcMode ? Theme.font : Theme.iconFont
                    font.weight: Font.Bold
                    size: 18
                    color: Theme.shadeOf(Theme.shadeOf(glass.color))
                }
            }
            TextInput {
                id: input
                anchors.left: glass.right
                anchors.leftMargin: Theme.s3
                anchors.right: count.left
                anchors.rightMargin: Theme.s3
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Theme.alpha(Theme.accent, 0.4)
                font.family: Theme.font
                font.pixelSize: Theme.fTitle + 2
                font.weight: Font.Medium
                focus: true
                clip: true
                onTextChanged: {
                    root.query = text;
                    list.currentIndex = 0;
                }
                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onTabPressed: list.incrementCurrentIndex()
                Keys.onBacktabPressed: list.decrementCurrentIndex()
                Keys.onReturnPressed: root.launch(list.currentIndex)
                Keys.onEnterPressed: root.launch(list.currentIndex)

                KLabel {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    role: "muted"
                    font.pixelSize: Theme.fTitle + 2
                    text: "Wohin soll die Reise gehen?"
                }
            }
            KLabel {
                id: count
                anchors.right: parent.right
                anchors.rightMargin: Theme.s4 + 2
                anchors.verticalCenter: parent.verticalCenter
                role: "caps"
                text: root.calcMode ? "Rechner" : root.results.length + " Apps"
            }
        }

        // ---- calculator
        Rectangle {
            visible: root.calcMode
            width: parent.width
            height: 76
            radius: Theme.rMed
            color: Theme.surface
            Row {
                anchors.centerIn: parent
                spacing: Theme.s3
                Orb {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34
                    color: Theme.orange
                    glowing: root.calcResult !== ""
                }
                KLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.calcResult !== "" ? root.calcResult : "…"
                    font.pixelSize: Theme.fHuge * 0.66
                    font.weight: Font.Bold
                }
            }
        }

        // ---- results
        ListView {
            id: list
            visible: !root.calcMode && root.results.length > 0
            width: parent.width
            height: Math.min(7, root.results.length) * 58
            clip: true
            model: root.results
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.tMed
            highlightFollowsCurrentItem: true
            keyNavigationWraps: true

            highlight: Rectangle {
                width: list.width
                height: 56
                radius: height / 2
                color: Theme.surfaceRaised
                Orb {
                    x: -2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12; height: 12
                    color: Theme.accent
                    glowing: true
                    rim: false
                }
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool sel: ListView.isCurrentItem
                readonly property color hue: Theme.accents[Theme.accentNames[Apps.hue(modelData) % Theme.accentNames.length]]
                width: list.width
                height: 56

                // icon badge
                Item {
                    id: badge
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40
                    scale: row.sel ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: Theme.easePop; easing.overshoot: 2 } }
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: row.sel ? Theme.surfaceHover : Theme.surface
                        visible: icon.status === Image.Ready
                    }
                    Image {
                        id: icon
                        anchors.centerIn: parent
                        width: 26; height: 26
                        source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                        sourceSize.width: 52
                        sourceSize.height: 52
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    // fallback: letter planet in a stable per-app color
                    Orb {
                        anchors.fill: parent
                        visible: icon.status !== Image.Ready
                        color: row.hue
                        KLabel {
                            anchors.centerIn: parent
                            text: row.modelData.name.charAt(0).toUpperCase()
                            font.weight: Font.Bold
                            font.pixelSize: 17
                            color: Theme.shadeOf(Theme.shadeOf(row.hue))
                        }
                    }
                }
                Column {
                    anchors.left: badge.right
                    anchors.leftMargin: Theme.s3 + 2
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.s4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    KLabel {
                        width: parent.width
                        text: row.modelData.name
                        font.weight: row.sel ? Font.DemiBold : Font.Medium
                    }
                    KLabel {
                        width: parent.width
                        role: "muted"
                        visible: text !== ""
                        text: row.modelData.comment || row.modelData.genericName || ""
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: list.currentIndex = row.index
                    onClicked: root.launch(row.index)
                }
            }
        }

        // ---- nothing found
        Column {
            visible: !root.calcMode && root.results.length === 0
            width: parent.width
            spacing: Theme.s2
            Item { width: 1; height: Theme.s2 }
            Orb {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56; height: 56
                color: Theme.textFaint
                ring: true
            }
            KLabel { anchors.horizontalCenter: parent.horizontalCenter; role: "title"; text: "Nichts gefunden" }
            KLabel { anchors.horizontalCenter: parent.horizontalCenter; role: "muted"; text: "Unendliche Weiten – aber keine App namens „" + root.query + "“" }
            Item { width: 1; height: Theme.s2 }
        }

        KLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "caps"
            text: "↑↓ wählen  ·  ⏎ starten  ·  = rechnen  ·  esc zurück"
            color: Theme.textFaint
        }
    }
}
