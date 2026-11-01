import QtQuick
import ".."
import "../components"
import "../tabs"

// "Editor" tab: the custom-bar builder (tabs/CustomTab.qml, unchanged
// logic). New bars saved here show up in the "Bars" tab's list.
FocusScope {
    id: page

    StepHeader {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        title: "Eigene Bars"
        subtitle: CustomBarsStore.editingSlug.length
            ? "Editor geöffnet -- speichern oder zurück zur Übersicht."
            : "Eigene Bar aus Modulen bauen -- sie erscheint danach im Tab „Bars“."
    }

    Panel {
        anchors { top: header.bottom; topMargin: Theme.spacingM; left: parent.left; right: parent.right; bottom: parent.bottom }

        CustomTab {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            focus: true
        }
    }
}
