import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../../components"

// Control center: sidebar with pages on the left, page content on the right.
GlassPanel {
    id: root

    namespace: "qs-controlcenter"
    open: Ui.controlCenterOpen
    panelWidth: Theme.ccWidth
    panelHeight: Theme.ccHeight
    onDismissed: Ui.controlCenterOpen = false

    readonly property var pages: [
        { id: "home", label: "Home", icon: "home" },
        { id: "media", label: "Media", icon: "music_note" },
        { id: "audio", label: "Audio", icon: "volume_up" },
        { id: "monitor", label: "Monitor", icon: "desktop_windows" },
        { id: "system", label: "System", icon: "computer" },
        { id: "server", label: "Server", icon: "dns" },
        { id: "power", label: "Power", icon: "power_settings_new" },
        { id: "network", label: "Network", icon: "wifi" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
        { id: "calendar", label: "Calendar", icon: "calendar_month" },
        { id: "notifications", label: "Notifications", icon: "notifications" }
    ]
    readonly property var current: pages.find(p => p.id === Ui.ccPage) ?? pages[0]
    readonly property int currentIndex: Math.max(0, pages.indexOf(current))
    // +1 = moved down the sidebar, -1 = up; the new page slides in from that side
    property int direction: 1
    property int _lastIndex: 0
    onCurrentIndexChanged: { direction = currentIndex >= _lastIndex ? 1 : -1; _lastIndex = currentIndex; }

    RowLayout {
        anchors.fill: parent
        spacing: Theme.panelPadding

        // sidebar
        Item {
            Layout.preferredWidth: Theme.ccSidebar - Theme.panelPadding
            Layout.fillHeight: true

            // accent pill that springs to the selected row (stretching on the way)
            Rectangle {
                id: selPill
                readonly property real target: root.currentIndex * (Theme.rowHeight + 2)
                property real edgeTop: target
                property real edgeBottom: target + Theme.rowHeight
                Behavior on edgeTop { NumberAnimation { duration: root.direction < 0 ? 260 : 440; easing.type: Theme.easingSpring; easing.overshoot: 1.2 } }
                Behavior on edgeBottom { NumberAnimation { duration: root.direction > 0 ? 260 : 440; easing.type: Theme.easingSpring; easing.overshoot: 1.2 } }
                y: edgeTop
                width: parent.width
                height: edgeBottom - edgeTop
                radius: Theme.radiusRow
                color: Theme.accent
            }

            Column {
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: root.pages
                    ListRow {
                        required property var modelData
                        required property int index
                        width: parent.width
                        icon: modelData.icon
                        label: modelData.label
                        selected: Ui.ccPage === modelData.id
                        fillSelected: false
                        onClicked: Ui.ccPage = modelData.id
                        // cascade in each time the panel opens
                        opacity: Math.max(0, Math.min(1, root.progress * 2.2 - index * 0.12))
                        transform: Translate { x: (1 - Math.max(0, Math.min(1, root.progress * 2.2 - index * 0.12))) * -16 }
                    }
                }
            }
        }

        // content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                Layout.fillHeight: false

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    Txt {
                        id: title
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.current.label
                        font.pixelSize: Theme.fontHeading
                        font.weight: Font.DemiBold
                        onTextChanged: titleIn.restart()
                        ParallelAnimation {
                            id: titleIn
                            NumberAnimation { target: title; property: "opacity"; from: 0; to: 1; duration: Theme.animSlow }
                            NumberAnimation { target: title; property: "anchors.verticalCenterOffset"; from: 10 * root.direction; to: 0; duration: Theme.animSlow; easing.type: Theme.easingSpring }
                            NumberAnimation { target: title; property: "font.letterSpacing"; from: 2; to: 0; duration: Theme.animSlow; easing.type: Theme.easing }
                        }
                    }
                }
                IconButton {
                    icon: "settings"
                    iconItem.rotation: hovered ? 90 : 0
                    Behavior on iconItem.rotation { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring } }
                    onClicked: {
                        Ui.terminal(["-e", "sh", "-c", "${EDITOR:-nvim} \"$0\"", Quickshell.shellDir + "/Theme.qml"]);
                        Ui.controlCenterOpen = false;
                    }
                }
                IconButton {
                    icon: "close"
                    iconItem.rotation: hovered ? 90 : 0
                    Behavior on iconItem.rotation { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
                    onClicked: Ui.controlCenterOpen = false
                }
            }

            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                // only build the page while the panel is shown
                active: root.visible
                sourceComponent: ({
                    home: homePage, media: mediaPage, audio: audioPage, monitor: monitorPage,
                    system: systemPage, server: serverPage, power: powerPage, network: networkPage,
                    bluetooth: bluetoothPage, calendar: calendarPage, notifications: notificationsPage
                })[root.current.id]
                // page change: new page glides in from the direction of travel
                onLoaded: if (root.open) pageIn.restart()
                ParallelAnimation {
                    id: pageIn
                    NumberAnimation { target: pageLoader.item; property: "opacity"; from: 0; to: 1; duration: Theme.animSlow; easing.type: Theme.easing }
                    NumberAnimation { target: pageShift; property: "y"; from: 26 * root.direction; to: 0; duration: Theme.animSlow + 80; easing.type: Theme.easingEmph }
                }
                transform: Translate { id: pageShift }
            }
        }
    }

    Component { id: homePage; HomePage {} }
    Component { id: mediaPage; MediaPage {} }
    Component { id: audioPage; AudioPage {} }
    Component { id: monitorPage; MonitorPage {} }
    Component { id: systemPage; SystemPage {} }
    Component { id: serverPage; ServerPage {} }
    Component { id: powerPage; PowerPage {} }
    Component { id: networkPage; NetworkPage {} }
    Component { id: bluetoothPage; BluetoothPage {} }
    Component { id: calendarPage; CalendarPage {} }
    Component { id: notificationsPage; NotificationsPage {} }
}
