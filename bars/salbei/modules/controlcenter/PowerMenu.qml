import QtQuick
import "../../"
import "../../components"
import "../../services"

// Standalone power popup (bar power button / `ipc call power toggle`).
GlassPanel {
    id: root

    namespace: "qs-power"
    open: Ui.powerOpen
    panelWidth: Session.actions.length * 104 + (Session.actions.length - 1) * Theme.tileGap + 2 * padding
    panelHeight: 104 + 2 * padding + hint.height + 8
    onDismissed: Ui.powerOpen = false
    onOpenChanged: if (open) { actions.armed = ""; actions.replay(); }

    Column {
        width: parent.width
        spacing: 8
        Txt {
            id: hint
            text: actions.armed === "" ? "Power" : "Click again to confirm"
            color: Theme.textDim
            font.pixelSize: Theme.fontSmall
        }
        PowerActions {
            id: actions
            width: parent.width
            tileHeight: 104
            onDone: Ui.powerOpen = false
        }
    }
}
