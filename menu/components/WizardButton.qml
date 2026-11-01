import QtQuick
import ".."

// "Zurück" / "Weiter" / "Abbrechen": icon + label, rounded border, hover
// tint, dimmed and inert when disabled. iconRight puts the icon after the
// label ("Weiter →").
Rectangle {
    id: btn

    property string text: ""
    property string icon: ""
    property bool iconRight: false
    property bool primary: false
    signal clicked()

    readonly property bool hovered: mouse.containsMouse && enabled
    readonly property color tint: primary ? Theme.accent : Theme.text

    implicitWidth: Math.max(110, content.implicitWidth + 2 * Theme.spacingL)
    implicitHeight: Theme.buttonHeight
    radius: Theme.radiusSmall
    color: {
        if (!enabled) return "transparent";
        if (mouse.pressed) return Qt.alpha(tint, 0.24);
        if (hovered) return Qt.alpha(tint, primary ? 0.18 : 0.08);
        return primary ? Qt.alpha(Theme.accent, 0.1) : "transparent";
    }
    border.width: Theme.borderWidth
    border.color: primary ? Theme.accent : (hovered ? Theme.textDim : Theme.border)
    opacity: enabled ? 1 : 0.38

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Theme.spacingS
        layoutDirection: btn.iconRight ? Qt.RightToLeft : Qt.LeftToRight

        Icon {
            visible: btn.icon.length > 0
            text: btn.icon
            size: Theme.fontS
            color: btn.primary ? Theme.accent : Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: btn.text
            color: btn.primary ? Theme.accent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontM
            font.weight: btn.primary ? Font.DemiBold : Font.Normal
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: btn.enabled
        cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: btn.clicked()
    }
}
