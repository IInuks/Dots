import QtQuick

Text {
    id: root
    required property string outputName
    readonly property var _monitor: MangoIpc.monitorFor(outputName)

    text: (_monitor && _monitor.active_client && _monitor.active_client.title) || ""
    color: Theme.text
    font.pixelSize: 12
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
