import QtQuick
import ".."

// Basiskomponente fuer alle drei Blobs (Auftrag Abschnitt 3). Kennt nur die
// Form-Animation (Ruhe <-> Flaeche) und wo das Kopfzeilen-Symbol sitzt --
// wer wann oeffnet/schliesst, entscheidet die konkrete Komponente. Gleiches
// Prinzip wie bars/fisheye/bar/modules/ClockModule.qml: das Modul emittiert
// nur `clicked`, Bar.qml/der Owner haelt den eigentlichen State.
Item {
    id: root

    required property real restWidth
    property real restHeight: Theme.barHeight
    property real openWidth: root.restWidth
    property real openHeight: root.restHeight
    property bool open: false

    // Welche Kante beim Wachsen fix bleibt -- daran haengt auch, wo das
    // Kopfzeilen-Symbol sitzt (Auftrag Abschnitt 3, Tabelle "Verankerung
    // beim Verformen"): links waechst nach links -> Symbol bleibt rechts
    // fixiert ("right"), rechts waechst nach rechts -> Symbol bleibt links
    // fixiert ("left"), Mitte waechst beidseitig -> Symbol bleibt zentriert.
    property string iconAnchor: "center" // "left" | "center" | "right"

    signal clicked

    // Kopfzeilen-Inhalt (Zahl/Uhrzeit/Ring) -- default property, damit
    // Konsumenten ihn einfach als Kind-Item hinschreiben koennen. Bleibt
    // pixelfest an iconAnchor haengen (s.o.).
    default property alias headerData: iconHolder.data
    // Zusaetzlicher Kopfzeilen-Inhalt ueber die VOLLE (wachsende) Breite --
    // fuer Faelle, in denen das Symbol selbst ersetzt wird (Launcher-
    // Suchfeld statt Uhrzeit, Auftrag Abschnitt 5c), nicht nur ergaenzt.
    // Rendert ueber iconHolder (spaeter deklariert = oben in der Stapelreihenfolge).
    property alias headerWideData: headerWide.data
    // Zusatzbeschriftung neben dem fixen Symbol (z.B. "Workspace",
    // "CPU-Temperatur", Auftrag Abschnitt 3) -- sitzt auf der Seite, zu der
    // hin gewachsen wird (iconAnchor "left" -> Beschriftung rechts vom
    // Symbol, "right" -> links davon), blendet zeitgleich mit bodyData ein.
    property alias labelData: labelContainer.data
    // Menu-Inhalt, blendet verzoegert ein (siehe unten).
    property alias bodyData: bodyContainer.data

    width: root.open ? root.openWidth : root.restWidth
    height: root.open ? root.openHeight : root.restHeight

    Behavior on width {
        NumberAnimation {
            duration: root.open ? Theme.durMorphOpen : Theme.durMorphClose
            easing.type: Theme.easeMorph
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: root.open ? Theme.durMorphOpen : Theme.durMorphClose
            easing.type: Theme.easeMorph
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        // Inhalt wird waehrend des Wachsens von der Form beschnitten
        // (Auftrag Abschnitt 3).
        clip: true

        radius: root.open ? 16 : root.restHeight / 2
        Behavior on radius {
            NumberAnimation {
                duration: root.open ? Theme.durRadiusOpen : Theme.durMorphClose
                easing.type: Theme.easeMorph
            }
        }

        // Fixe restWidth x restHeight-Flaeche fuers Symbol -- bewusst NICHT
        // die volle (wachsende) Breite, und haengt an genau der Kante, die
        // beim Wachsen fix bleibt. Dadurch wandert das Symbol beim Oeffnen
        // keinen Pixel (Auftrag Abschnitt 3, "Verankerung beim Verformen").
        Item {
            id: iconHolder
            width: root.restWidth
            height: root.restHeight
            anchors.top: parent.top

            states: [
                State {
                    name: "left"
                    AnchorChanges {
                        target: iconHolder
                        anchors.left: surface.left
                    }
                },
                State {
                    name: "center"
                    AnchorChanges {
                        target: iconHolder
                        anchors.horizontalCenter: surface.horizontalCenter
                    }
                },
                State {
                    name: "right"
                    AnchorChanges {
                        target: iconHolder
                        anchors.right: surface.right
                    }
                }
            ]
            state: root.iconAnchor
        }

        // Volle Breite, gleiche Hoehe wie iconHolder -- rendert darueber,
        // damit ein voll deckender Ersatz (z.B. Suchfeld) die fixe Uhrzeit
        // darunter sauber verdeckt, sobald seine Opacity auf 1 steht.
        Item {
            id: headerWide
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.restHeight
        }

        // Neben dem Symbol, auf der Seite, zu der hin die Flaeche waechst.
        Item {
            id: labelContainer
            anchors.verticalCenter: iconHolder.verticalCenter
            opacity: 0

            states: [
                State {
                    name: "left"
                    AnchorChanges {
                        target: labelContainer
                        anchors.left: iconHolder.right
                    }
                    PropertyChanges {
                        target: labelContainer
                        anchors.leftMargin: 8
                    }
                },
                State {
                    name: "right"
                    AnchorChanges {
                        target: labelContainer
                        anchors.right: iconHolder.left
                    }
                    PropertyChanges {
                        target: labelContainer
                        anchors.rightMargin: 8
                    }
                }
            ]
            // "center" (Mitte-Blob) nutzt labelData nicht -- Zustand ist
            // dann irrelevant, "left" als harmloser Default.
            state: root.iconAnchor === "right" ? "right" : "left"
        }

        MouseArea {
            anchors.fill: iconHolder
            onClicked: root.clicked()
        }

        Item {
            id: bodyContainer
            anchors.top: iconHolder.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            opacity: 0
        }
    }

    onOpenChanged: {
        if (root.open) {
            bodyFadeIn.start();
        } else {
            // Schliessen: Inhalt verschwindet sofort, kein Delay, bevor die
            // Form schrumpft (Auftrag Abschnitt 3).
            bodyFadeIn.stop();
            bodyContainer.opacity = 0;
            labelContainer.opacity = 0;
        }
    }

    SequentialAnimation {
        id: bodyFadeIn
        PauseAnimation {
            duration: Theme.durBodyFadeDelay
        }
        ParallelAnimation {
            NumberAnimation {
                target: bodyContainer
                property: "opacity"
                to: 1
                duration: Theme.durBodyFade
                easing.type: Theme.easeMorph
            }
            NumberAnimation {
                target: labelContainer
                property: "opacity"
                to: 1
                duration: Theme.durBodyFade
                easing.type: Theme.easeMorph
            }
        }
    }
}
