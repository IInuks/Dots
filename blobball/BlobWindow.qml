import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Der Blob selbst: Darstellung (Formen, Squash&Stretch, Idle-Wobble),
// Physik und Nachrichten-Flaeche. Eingestellt wird er im Tab "Blob" des
// quickdots-Menues (siehe Settings.qml).
PanelWindow {
    id: root

    screen: Quickshell.screens[0] ?? null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "blobball-blob"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: Settings.blobVisible

    property real blobSize: Settings.blobSize
    property real blobRadius: root.blobSize / 2

    property Physics physics: Physics {
        radius: root.blobRadius
        boundsWidth: root.width
        boundsHeight: root.height
        restitution: Settings.restitution
        gravityEnabled: Settings.gravityEnabled
        preferredCorner: Settings.idleCorner
        topMargin: Settings.barMargin
        onBounced: edge => eyeZone.squash(edge)
        onArrivedAtCorner: {
            eyeZone.squash("bottom");
            root.atIdleCorner = true;
        }
    }

    // Ist der Blob gerade selbststaendig in eine Ecke geflogen und liegt dort
    // noch unbewegt? Nur in diesem Zustand oeffnet ein Klick (ohne Ziehen,
    // siehe mouseArea unten) den Nachrichten-Verlauf statt normal zu greifen
    // -- ausserhalb der Ecke bleibt ein Klick-ohne-Wurf wirkungslos wie bisher.
    property bool atIdleCorner: false

    // Ausgeblendet, solange das quickdots-Menue offen ist (sonst laege er
    // ueber dem Menuefenster, siehe Settings.menuOpen) oder sich der Blob
    // zur Nachrichten-Flaeche verformt (siehe _messagesPanelActive unten).
    readonly property bool _blobHidden: Settings.menuOpen || root._messagesPanelActive

    // Nachrichten-Flaeche ist aktiv, sobald entweder der Verlauf geoeffnet
    // ist (Klick auf den in der Ecke geparkten Blob, siehe mouseArea unten)
    // ODER gerade eine frische Nachricht per IPC hereingekommen ist
    // (Message.visible, automatisch fuer ein paar Sekunden, siehe
    // Message.qml/hideTimer -- kein Klick noetig, verschwindet von selbst).
    readonly property bool _messagesPanelActive: Settings.messagesOpen || Message.visible

    // In welche Richtung die Nachrichten-Flaeche waechst, damit sie an der
    // Seite/Ecke haengen bleibt, an der der Blob gerade ist, statt ueber den
    // Bildschirmrand hinauszuwachsen.
    readonly property bool _leftHalf: root.physics.posX < root.width / 2
    readonly property bool _topHalf: root.physics.posY < root.height / 2

    // Adaptives Theme (Settings.blobAdaptiveTheme) ersetzt die manuell
    // gewaehlte Settings.blobColor durch die live Wallpaper-Akzentfarbe aus
    // Theme.qml. _blobTextColor
    // zieht daraus (bzw. aus Settings.textColorMode, falls nicht "auto")
    // eine lesbare Schriftfarbe fuer die Nachrichten-Flaeche, die denselben
    // Farbton wie der Blob traegt (siehe messagesPanel unten).
    readonly property color _blobDisplayColor: Settings.blobAdaptiveTheme ? Theme.accent : Settings.blobColor
    readonly property color _blobTextColor: Theme.textColorFor(root._blobDisplayColor, Settings.textColorMode)

    // Nach Settings.idleToCornerDelay Sekunden Stillstand (kein Drag, keine
    // Bewegung, noch nicht schon in der Ecke) fliegt der Blob selbststaendig
    // in die naechste Ecke -- siehe Physics.qml, flyToCorner()/stepToCorner().
    // running wird reaktiv neu ausgewertet: jede Bewegung/jedes Greifen
    // stoppt den Timer, jedes erneute Zur-Ruhe-Kommen startet ihn neu.
    // Untergrenze 50ms statt 0, damit Settings.idleToCornerDelay = 0 ("quasi
    // sofort") nicht auf ein Timer-Intervall von 0 laeuft.
    property Timer _idleCornerTimer: Timer {
        interval: Math.max(50, Settings.idleToCornerDelay * 1000)
        running: Settings.idleToCornerEnabled
            && root.physics.atRest
            && !root.physics.dragging
            && !root.physics.flyingToCorner
            && !root.physics.parked
        onTriggered: root.physics.flyToCorner()
    }

    // Layer-Shell-Fenster haben bei initial_commit zunaechst width/height 0,
    // bis der Compositor die Groesse bestaetigt (siehe
    // feedback_qml_maptoitem_non_reactive) -- Startposition erst setzen,
    // sobald eine echte Geometrie da ist, sonst haengt der Blob in der Ecke.
    property bool _initialized: false
    onWidthChanged: root._maybePlaceInitial()
    onHeightChanged: root._maybePlaceInitial()
    function _maybePlaceInitial() {
        if (root._initialized || root.width <= 0 || root.height <= 0) return;
        root._initialized = true;
        root.physics.posX = root.width / 2;
        root.physics.posY = root.height / 2;
    }

    property FrameAnimation _ticker: FrameAnimation {
        running: root.physics.dragging || !root.physics.atRest || root.physics.flyingToCorner
        onTriggered: {
            if (root.physics.flyingToCorner) root.physics.stepToCorner(frameTime);
            else root.physics.step(frameTime);
        }
    }

    // Erkennungszone fuer die Augen: deutlich groesser als der Blob selbst,
    // damit die Pupillen schon reagieren, bevor die Maus den Blob beruehrt.
    // Wayland-Input-Regionen kennen aber nur "empfaengt Events" oder "laesst
    // durch" fuer die GANZE Flaeche -- es gibt kein Motion-only/Klick-durch.
    // Innerhalb dieser Zone schluckt das Fenster deshalb zwangslaeufig auch
    // Klicks, die sonst an ein Fenster/Icon dahinter gegangen waeren (siehe
    // README, Abschnitt "Bewusste Entscheidungen"). Deshalb bewusst nur ein
    // maessiger Rand, kein ganzer Bildschirm.
    readonly property real _eyeMargin: 170
    readonly property real _eyeDetectRadius: root.blobRadius + root._eyeMargin
    readonly property real _eyeLookRange: Math.max(40, root.blobRadius * 1.6)

    // Solange die Nachrichten-Flaeche aktiv ist, ersetzt ihr (abgerundetes)
    // Rechteck die normale Augen-Ellipse als Eingabe-Maske -- sonst wuerde
    // die gewachsene Flaeche ausserhalb der urspruenglichen Blob-Ellipse gar
    // keine Klicks zum Schliessen empfangen.
    mask: Region {
        item: root._messagesPanelActive ? messagesPanel : eyeZone
        shape: root._messagesPanelActive ? Region.Rect : Region.Ellipse
        radius: root._messagesPanelActive ? Math.round(messagesPanel._radius) : 0
    }

    // Globale Zeigerposition fuer die Augen. Eine Layer-Shell-Flaeche
    // bekommt unter Wayland nur Zeiger-Events ueber ihrer Eingabe-Maske,
    // daher fragt blobball den eigenen Compositor: `wirbel pos loop xy`
    // schreibt bei jeder Bewegung eine Zeile "X Y" (Layout-Pixel).
    // Umgerechnet auf dieses Fenster ueber die Position seines Bildschirms.
    property real _pointerX: 0
    property real _pointerY: 0
    property bool _pointerKnown: false

    property Process _globalPointer: Process {
        command: ["sh", "-c", "exec \"$(command -v wirbel || echo \"$HOME/.local/lib/wirbel/wirbel\")\" pos loop xy 1"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(/\s+/);
                const x = parseFloat(parts[0]);
                const y = parseFloat(parts[1]);
                if (isNaN(x) || isNaN(y)) return;
                root._pointerX = x - (root.screen ? root.screen.x : 0);
                root._pointerY = y - (root.screen ? root.screen.y : 0);
                root._pointerKnown = true;
            }
        }
        onExited: {
            root._pointerKnown = false;
            root._pointerRetry.restart();
        }
    }

    // Kein wirbel (anderer Compositor) oder wirbel neu gestartet: spaeter
    // nochmal versuchen, ohne in einer schnellen Schleife zu laufen.
    property Timer _pointerRetry: Timer {
        interval: 5000
        onTriggered: root._globalPointer.running = true
    }

    Item {
        id: eyeZone
        width: root._eyeDetectRadius * 2
        height: root._eyeDetectRadius * 2
        x: root.physics.posX - width / 2
        y: root.physics.posY - height / 2

        function squash(edge) { blob.squash(edge); }

        Blob {
            id: blob
            anchors.centerIn: parent
            size: root.blobSize
            shapeKind: Settings.blobShape
            blobColor: root._blobDisplayColor
            dragging: root.physics.dragging || root.physics.slingshotActive
            atRest: root.physics.atRest
            jiggle: Settings.jiggleAmount
            // Ueber dem Blob (oder beim Ziehen) gilt die eigene MouseArea,
            // sonst die globale Zeigerposition von `wirbel pos` (siehe
            // _globalPointer oben) -- so schauen die Augen dem Cursor
            // ueberall auf dem Bildschirm nach. Ohne wirbel (z.B. unter
            // mango) bleibt es beim alten Verhalten: nur in der Naehe.
            readonly property bool _local: mouseArea.containsMouse || root.physics.dragging || root.physics.slingshotActive
            readonly property real _dx: _local ? mouseArea.mouseX - eyeZone.width / 2 : root._pointerX - root.physics.posX
            readonly property real _dy: _local ? mouseArea.mouseY - eyeZone.height / 2 : root._pointerY - root.physics.posY
            // Richtung erhalten statt pro Achse zu kappen: ein weit entfernter
            // Cursor schiebt die Pupille an den Rand in genau seine Richtung.
            readonly property real _dist: Math.max(0.001, Math.sqrt(_dx * _dx + _dy * _dy))
            readonly property real _reach: Math.min(1, _dist / root._eyeLookRange)
            lookTracking: _local || root._pointerKnown
            targetLookX: _dx / _dist * _reach
            targetLookY: _dy / _dist * _reach
            pullX: root.physics.slingshotActive ? root.physics.slingshotPullX / root.physics.maxSlingshotPull : 0
            pullY: root.physics.slingshotActive ? root.physics.slingshotPullY / root.physics.maxSlingshotPull : 0

            // Blendet aus, solange das quickdots-Menue offen ist oder sich
            // der Blob gerade zur Nachrichten-Flaeche streckt (siehe
            // root._blobHidden oben).
            opacity: root._blobHidden ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            // Waehrend die Nachrichten-Flaeche aktiv ist, empfaengt ohnehin
            // nur noch deren eigene MouseArea Klicks (siehe mask oben) --
            // trotzdem explizit deaktiviert, damit kein Hover/Blick-Tracking
            // auf dem unsichtbaren Blob darunter weiterlaeuft.
            enabled: !root._messagesPanelActive
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: mouse => {
                const p = mapToItem(root.contentItem, mouse.x, mouse.y);
                // Rechte Maustaste: Steinschleuder statt normalem Greifen --
                // der Blob friert an seiner aktuellen Position ein (Anker),
                // siehe Physics.beginSlingshot().
                if (mouse.button === Qt.RightButton) {
                    root.atIdleCorner = false;
                    root.physics.beginSlingshot(p.x, p.y);
                    return;
                }
                root._wasCornerClick = root.atIdleCorner;
                root.atIdleCorner = false;
                root._pressContentX = p.x;
                root._pressContentY = p.y;
                root.physics.beginDrag(p.x, p.y);
            }
            onPositionChanged: mouse => {
                const p = mapToItem(root.contentItem, mouse.x, mouse.y);
                if (root.physics.slingshotActive) {
                    root.physics.updateSlingshot(p.x, p.y);
                    return;
                }
                if (!root.physics.dragging) return;
                root.physics.updateDrag(p.x, p.y);
            }
            onReleased: mouse => {
                // Steinschleuder loslassen: schiesst in die dem Zug
                // entgegengesetzte Richtung ab (Physics.endSlingshot()) --
                // unabhaengig davon, mit welcher Taste losgelassen wird,
                // solange gerade gespannt ist.
                if (root.physics.slingshotActive) {
                    root.physics.endSlingshot();
                    return;
                }
                if (mouse.button === Qt.RightButton) return;
                const p = mapToItem(root.contentItem, mouse.x, mouse.y);
                const dist = Math.hypot(p.x - root._pressContentX, p.y - root._pressContentY);
                root.physics.endDrag();
                // War der Blob vorm Klick in der Ecke geparkt und wurde dabei
                // kaum bewegt (kein Wurf, nur ein Klick) -- dann Nachrichten
                // oeffnen statt den normalen Wurf-Weg zu nehmen. Bei echtem
                // Ziehen (dist >= 6) bleibt es beim gewohnten Wurf.
                if (root._wasCornerClick && dist < 6) {
                    root.atIdleCorner = true;
                    root.physics.parked = true; // nicht wieder runterfallen
                    Message.markAllRead();
                    Settings.messagesOpen = true;
                }
            }
        }

        // Kleines Badge oben rechts am Blob mit der Anzahl ungelesener
        // Nachrichten (Message.unreadCount) -- unabhaengig davon, ob der Blob
        // gerade in der Ecke liegt oder frei herumsteht, aber besonders
        // sichtbar, wenn er dort laenger unbewegt "wartet".
        Item {
            id: unreadBadge
            width: 24
            height: 24
            x: blob.x + blob.width - width * 0.65
            y: blob.y - height * 0.3
            opacity: (Message.unreadCount > 0 && !root._blobHidden) ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#ff5a5a"
                border.color: "#26262b"
                border.width: 1.5
            }
            Text {
                anchors.centerIn: parent
                text: Message.unreadCount > 99 ? "99+" : Message.unreadCount
                color: "white"
                font.pixelSize: 11
                font.bold: true
            }
        }
    }

    // Klick-vs-Wurf-Erkennung fuer mouseArea oben: Startposition und ob der
    // Blob beim Druecken gerade in der Ecke geparkt war.
    property real _pressContentX: 0
    property real _pressContentY: 0
    property bool _wasCornerClick: false

    // Nachrichten-Flaeche: der Blob selbst streckt sich an Ort und Stelle zu
    // einer abgerundeten Karte statt eine eigene Sprechblase/ein eigenes
    // Fenster daneben zu zeigen -- "der Blob wird zum Nachrichten-Menue".
    // Bleibt an der Seite/Ecke haengen, an der der Blob gerade ist
    // (root._leftHalf/_topHalf), und waechst nur in die freie Richtung.
    // Zwei Ausloeser (root._messagesPanelActive):
    //  - Settings.messagesOpen: Klick auf den in der Ecke geparkten Blob,
    //    zeigt den ganzen Verlauf, bleibt offen bis erneut angetippt.
    //  - Message.visible: frische Nachricht per IPC, zeigt nur den einen
    //    Text, schliesst sich nach Message.hideTimer von selbst wieder --
    //    kein Klick noetig.
    Item {
        id: messagesPanel

        readonly property real _closedSize: root.blobSize
        readonly property real _openWidth: Math.min(280, root.width - 24)
        readonly property real _openHeight: Math.max(
            messagesPanel._closedSize,
            Math.min(Math.min(360, root.height - 24), panelContent.implicitHeight + 32))

        width: root._messagesPanelActive ? messagesPanel._openWidth : messagesPanel._closedSize
        height: root._messagesPanelActive ? messagesPanel._openHeight : messagesPanel._closedSize
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

        x: root._leftHalf ? (root.physics.posX - root.blobRadius) : (root.physics.posX + root.blobRadius - width)
        y: root._topHalf ? (root.physics.posY - root.blobRadius) : (root.physics.posY + root.blobRadius - height)

        property real _radius: root._messagesPanelActive ? 26 : root.blobRadius
        Behavior on _radius { NumberAnimation { duration: 220 } }

        opacity: root._messagesPanelActive ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 200 } }

        readonly property var _recentHistory: [...Message.history].slice(-8).reverse()

        // Fuellfarbe = Settings.blobColor, keine eigene Menue-Farbe/Rand:
        // die Flaeche soll wie der Blob selbst aussehen, der sich nur
        // verformt hat, nicht wie ein eigenstaendiges Menue daneben.
        Rectangle {
            anchors.fill: parent
            radius: messagesPanel._radius
            color: root._blobDisplayColor
        }

        Item {
            anchors.fill: parent
            anchors.margins: 14
            clip: true

            Column {
                id: panelContent
                // Feste Ziel-Breite statt parent.width: waechst nicht mit
                // der noch animierenden messagesPanel.width mit, sonst
                // wuerde implicitHeight (und damit das Wachs-Ziel fuer
                // height selbst) waehrend der Animation staendig
                // nachzittern.
                width: messagesPanel._openWidth - 28
                spacing: 8

                Item {
                    visible: Settings.messagesOpen
                    width: panelContent.width
                    height: headerTitle.height

                    Text {
                        id: headerTitle
                        text: "Nachrichten"
                        color: root._blobTextColor
                        font.pixelSize: 15
                        font.bold: true
                    }

                    // Loescht den ganzen Verlauf (Message.clearHistory()) --
                    // nur sichtbar, wenn ueberhaupt etwas zu loeschen da ist.
                    // Eigene MouseArea akzeptiert den Klick selbst, sodass er
                    // nicht an die schliessende MouseArea von messagesPanel
                    // (siehe unten) durchgereicht wird.
                    Rectangle {
                        id: deleteHistoryButton
                        visible: Message.history.length > 0
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: deleteLabel.implicitWidth + 16
                        height: 22
                        radius: height / 2
                        color: deleteArea.pressed ? Qt.darker(root._blobDisplayColor, 1.5) : Qt.darker(root._blobDisplayColor, 1.25)

                        Text {
                            id: deleteLabel
                            anchors.centerIn: parent
                            text: "Löschen"
                            color: root._blobTextColor
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: deleteArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Message.clearHistory()
                        }
                    }
                }

                Text {
                    visible: Settings.messagesOpen && Message.history.length === 0
                    text: "Noch keine Nachrichten."
                    color: root._blobTextColor
                    opacity: 0.75
                    font.pixelSize: 13
                }

                Repeater {
                    model: Settings.messagesOpen ? messagesPanel._recentHistory : []
                    delegate: Column {
                        id: entry
                        required property var modelData
                        width: panelContent.width
                        spacing: 2
                        Text {
                            width: parent.width
                            text: entry.modelData.text
                            color: root._blobTextColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            text: Qt.formatDateTime(new Date(entry.modelData.time), "dd.MM. hh:mm")
                            color: root._blobTextColor
                            opacity: 0.6
                            font.pixelSize: 10
                        }
                    }
                }

                Text {
                    visible: !Settings.messagesOpen && Message.visible
                    width: parent.width
                    text: Message.text
                    color: root._blobTextColor
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    visible: Settings.messagesOpen
                    text: "Zum Schliessen antippen"
                    color: root._blobTextColor
                    opacity: 0.6
                    font.pixelSize: 10
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root._messagesPanelActive
            onClicked: {
                if (Settings.messagesOpen) Settings.messagesOpen = false;
                else Message.clear();
            }
        }
    }
}
