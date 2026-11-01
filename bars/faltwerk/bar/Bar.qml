import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../fold"

// Die Leiste: drei Papierstuecke (links Kranich + Tags, Mitte Banderole mit
// Fenstertitel, rechts Werkzeuge + Uhr). Beim Start falten sie sich nach-
// einander auf; beim Papierwechsel blaettern sie kaskadierend um.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: modelData.name

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Paper.barZone
    exclusiveZone: Paper.barZone
    color: "transparent"
    WlrLayershell.namespace: "faltwerk-bar"
    WlrLayershell.layer: WlrLayer.Top

    // ---- Start: Stuecke falten sich auf ----
    property real unfold: 0
    NumberAnimation on unfold {
        from: 0
        to: 1
        duration: 1100
        running: true
    }
    function stage(i) {
        return Math.max(0, Math.min(1, win.unfold * 2 - i * 0.4));
    }

    // ---- Papierwechsel: kaskadierendes Umblaettern ----
    property real flipL: 0
    property real flipC: 0
    property real flipR: 0
    Connections {
        target: Paper
        function onPendingChanged() {
            if (Paper.pending !== "")
                flipAnim.restart();
        }
    }
    component FlipStep: SequentialAnimation {
        id: fs
        property string prop
        property bool commits: false
        NumberAnimation { target: win; property: fs.prop; from: 0; to: 90; duration: 200; easing.type: Easing.InQuad }
        ScriptAction { script: if (fs.commits) Paper.commit() }
        NumberAnimation { target: win; property: fs.prop; from: -90; to: 0; duration: 420; easing.type: Easing.OutBack }
    }
    ParallelAnimation {
        id: flipAnim
        FlipStep { prop: "flipL"; commits: true }
        SequentialAnimation {
            PauseAnimation { duration: 90 }
            FlipStep { prop: "flipC" }
        }
        SequentialAnimation {
            PauseAnimation { duration: 180 }
            FlipStep { prop: "flipR" }
        }
    }

    function openAt(id, item) {
        const p = item.mapToItem(null, item.width / 2, 0);
        Falt.toggle(id, win.screenName, p.x);
    }

    Item {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Paper.barMargin + 2
        anchors.rightMargin: Paper.barMargin + 2
        anchors.topMargin: Paper.barMargin

        // ---------- links ----------
        Fold {
            id: leftFold
            vertical: false
            segments: 4
            progress: win.stage(0)
            width: leftPiece.implicitWidth
            height: Paper.barHeight
            transform: Rotation {
                origin.x: leftFold.width / 2
                origin.y: leftFold.height / 2
                axis { x: 1; y: 0; z: 0 }
                angle: win.flipL
            }
            LeftPiece {
                id: leftPiece
                anchors.fill: parent
                screenName: win.screenName
                onLauncher: item => win.openAt("launcher", item)
            }
        }

        // ---------- Mitte ----------
        Fold {
            id: centerFold
            vertical: false
            segments: 3
            progress: win.stage(1)
            anchors.horizontalCenter: parent.horizontalCenter
            width: banner.implicitWidth
            height: Paper.barHeight
            transform: Rotation {
                origin.x: centerFold.width / 2
                origin.y: centerFold.height / 2
                axis { x: 1; y: 0; z: 0 }
                angle: win.flipC
            }
            Banner {
                id: banner
                anchors.fill: parent
                maxWidth: Math.max(160, row.width - Math.max(leftFold.width, rightFold.width) * 2 - 60)
            }
        }

        // ---------- rechts ----------
        Fold {
            id: rightFold
            vertical: false
            segments: 5
            progress: win.stage(2)
            anchors.right: parent.right
            width: rightPiece.implicitWidth
            height: Paper.barHeight
            transform: Rotation {
                origin.x: rightFold.width / 2
                origin.y: rightFold.height / 2
                axis { x: 1; y: 0; z: 0 }
                angle: win.flipR
            }
            RightPiece {
                id: rightPiece
                anchors.fill: parent
                onOpen: (id, item) => win.openAt(id, item)
            }
        }
    }
}
