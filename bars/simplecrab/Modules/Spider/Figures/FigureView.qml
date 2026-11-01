import QtQuick
import "Spider"
import "Crab"

// Laedt die zu SpiderState.figureId passende Figur-Komponente und haelt
// deren Properties live (nicht nur einmalig bei onLoaded) synchron -- siehe
// FigureRegistry.qml fuer den "neue Figur hinzufuegen"-Ablauf, der hier bei
// Schritt 2 landet.
Item {
    id: root

    required property string figureId
    property real size: 48
    property real heading: 0
    property bool moving: false

    implicitWidth: size
    implicitHeight: size

    Component {
        id: spiderComp
        Spider {}
    }
    Component {
        id: crabComp
        Crab {}
    }

    readonly property var _componentMap: ({
            spider: spiderComp,
            crab: crabComp
        })

    Loader {
        id: figureLoader
        anchors.fill: parent
        sourceComponent: root._componentMap[root.figureId] || spiderComp
    }

    Binding {
        target: figureLoader.item
        property: "size"
        value: root.size
        when: figureLoader.item !== null
    }
    Binding {
        target: figureLoader.item
        property: "heading"
        value: root.heading
        when: figureLoader.item !== null
    }
    Binding {
        target: figureLoader.item
        property: "moving"
        value: root.moving
        when: figureLoader.item !== null
    }
}
