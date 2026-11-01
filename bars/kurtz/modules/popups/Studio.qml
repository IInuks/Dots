import QtQuick
import "../../"
import "../../components"
import "../../services"

// "Studio": live customisation of the whole shell. Every control writes
// straight into Config (-> config.json), and everything reacts instantly.
FocusScope {
    id: root
    implicitHeight: col.implicitHeight

    property int tab: 0
    readonly property var tabs: [
        { label: "Farben", glyph: Glyphs.palette },
        { label: "Leiste", glyph: Glyphs.monitor },
        { label: "Kosmos", glyph: Glyphs.star4 },
        { label: "Bewegung", glyph: Glyphs.animation }
    ]

    Keys.onLeftPressed: tab = (tab + tabs.length - 1) % tabs.length
    Keys.onRightPressed: tab = (tab + 1) % tabs.length

    Column {
        id: col
        width: parent.width
        spacing: Theme.s4

        // ---- title
        Row {
            spacing: Theme.s3
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30
                Orb {
                    anchors.fill: parent
                    visible: Config.s.planetStyle !== "blackhole"
                    color: Theme.accent
                    ring: true
                    glowing: true
                }
                BlackHole {
                    anchors.centerIn: parent
                    visible: Config.s.planetStyle === "blackhole"
                    width: 42; height: 42
                    palette: "tint"
                    tint: Theme.accent
                    glowStrength: 0.9
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                KLabel { role: "big"; text: "Studio" }
                KLabel { role: "muted"; text: "Alles live · gespeichert in config.json" }
            }
        }

        // ---- tab strip with a sliding orb indicator
        Rectangle {
            id: strip
            width: parent.width
            height: 40
            radius: height / 2
            color: Theme.surfaceSunken
            readonly property real tw: (width - 8) / root.tabs.length

            Rectangle {
                id: indicator
                y: 4
                height: parent.height - 8
                width: strip.tw
                x: 4 + root.tab * strip.tw
                radius: height / 2
                color: Theme.surfaceRaised
                Behavior on x { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.1 } }
            }
            Row {
                x: 4
                y: 4
                Repeater {
                    model: root.tabs
                    Item {
                        required property var modelData
                        required property int index
                        width: strip.tw
                        height: strip.height - 8
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            KIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.glyph
                                size: 14
                                color: root.tab === index ? Theme.accent : Theme.textMuted
                                Behavior on color { ColorAnimation { duration: Theme.tMed } }
                            }
                            KLabel {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                font.pixelSize: Theme.fSmall + 1
                                color: root.tab === index ? Theme.text : Theme.textMuted
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = index
                        }
                    }
                }
            }
        }

        // ---- pages (crossfade + small slide on switch)
        Item {
            width: parent.width
            height: pages.children[root.tab] ? pages.children[root.tab].implicitHeight : 0
            Behavior on height { NumberAnimation { duration: Theme.tMed; easing.type: Theme.easeOut } }
            clip: true

            Item {
                id: pages
                anchors.fill: parent

                // ================================================ Farben
                Page {
                    index: 0
                    SectionTitle { width: parent.width; text: "Himmel" }
                    Row {
                        spacing: Theme.s2
                        Repeater {
                            model: Theme.skyNames
                            Column {
                                id: skyItem
                                required property string modelData
                                readonly property bool sel: Config.s.sky === modelData
                                spacing: 4
                                Rectangle {
                                    width: 58
                                    height: 46
                                    radius: Theme.rSmall
                                    scale: skyMouse.containsMouse ? 1.06 : sel ? 1.03 : 1
                                    Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Theme.easePop } }
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: Theme.skies[skyItem.modelData][0] }
                                        GradientStop { position: 0.5; color: Theme.skies[skyItem.modelData][1] }
                                        GradientStop { position: 1; color: Theme.skies[skyItem.modelData][2] }
                                    }
                                    Repeater {
                                        model: 6
                                        Rectangle {
                                            required property int index
                                            width: index % 3 === 0 ? 2 : 1.5
                                            height: width
                                            radius: 1
                                            color: Theme.text
                                            opacity: 0.4 + (index % 3) * 0.2
                                            x: 8 + ((index * 37) % 42)
                                            y: 6 + ((index * 23) % 32)
                                        }
                                    }
                                    Orb {
                                        visible: skyItem.sel
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 6
                                        width: 12; height: 12
                                        color: Theme.accent
                                        glowing: true
                                    }
                                    MouseArea {
                                        id: skyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.set("sky", skyItem.modelData)
                                    }
                                }
                                KLabel {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    role: "caps"
                                    text: skyItem.modelData
                                    color: skyItem.sel ? Theme.text : Theme.textMuted
                                }
                            }
                        }
                    }
                    SectionTitle { width: parent.width; text: "Akzent" }
                    Row {
                        spacing: Theme.s2
                        Repeater {
                            model: Theme.accentChoices
                            Item {
                                id: acc
                                required property string modelData
                                readonly property bool sel: Config.s.accent === modelData
                                width: 36
                                height: 40
                                Orb {
                                    anchors.centerIn: parent
                                    visible: Config.s.planetStyle !== "blackhole"
                                    width: acc.sel ? 30 : accMouse.containsMouse ? 26 : 22
                                    height: width
                                    color: Theme.accentColor(acc.modelData)
                                    glowing: acc.sel
                                    ring: acc.sel && Theme.c.planetRings
                                    Behavior on width { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 2 } }
                                }
                                BlackHole {
                                    anchors.centerIn: parent
                                    visible: Config.s.planetStyle === "blackhole"
                                    width: acc.sel ? 40 : accMouse.containsMouse ? 34 : 30
                                    height: width
                                    palette: "tint"
                                    tint: Theme.accentColor(acc.modelData)
                                    spinning: acc.sel && Config.s.blackHoleSpin
                                    glowStrength: acc.sel ? 0.9 : 0.3
                                    Behavior on width { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 2 } }
                                }
                                MouseArea {
                                    id: accMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.set("accent", acc.modelData)
                                }
                            }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        visible: Wallpaper.wanted
                        label: "Wallpaper-Farben"
                        sub: Wallpaper.error !== "" ? Wallpaper.error
                             : Wallpaper.ready ? Wallpaper.path.split("/").pop()
                             : "matugen liest das Bild …"
                        Chip { text: "Neu lesen"; onClicked: Wallpaper.regenerate() }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Form"
                        sub: "Auch in der Leiste"
                        Row {
                            spacing: 6
                            Chip { text: "Kugel"; selected: Config.s.planetStyle !== "blackhole" && !Config.s.planetRings; onClicked: { Config.set("planetStyle", "planet"); Config.set("planetRings", false); } }
                            Chip { text: "Mit Ring"; selected: Config.s.planetStyle !== "blackhole" && Config.s.planetRings; onClicked: { Config.set("planetStyle", "planet"); Config.set("planetRings", true); } }
                            Chip { text: "Schwarzes Loch"; selected: Config.s.planetStyle === "blackhole"; onClicked: Config.set("planetStyle", "blackhole") }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Leuchten"
                        sub: "Stärke aller Glows"
                        Slider { width: 170; value: Config.s.glow; onMoved: v => Config.set("glow", Math.round(v * 100) / 100) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Arbeitsflächen"
                        sub: "Farbe der Tag-Planeten"
                        Row {
                            spacing: 6
                            Chip { text: "Akzent"; selected: Config.s.tagPalette === "accent"; onClicked: Config.set("tagPalette", "accent") }
                            Chip { text: "Sonnensystem"; selected: Config.s.tagPalette === "planets"; onClicked: Config.set("tagPalette", "planets") }
                        }
                    }
                }

                // ================================================ Leiste
                Page {
                    index: 1
                    SettingRow {
                        width: parent.width
                        label: "Position"
                        Row {
                            spacing: 6
                            Chip { text: "Oben"; selected: Theme.barTop; onClicked: Config.set("barPosition", "top") }
                            Chip { text: "Unten"; selected: !Theme.barTop; onClicked: Config.set("barPosition", "bottom") }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Form"
                        sub: "Eine Kapsel oder drei Inseln"
                        Row {
                            spacing: 6
                            Chip { text: "Kapsel"; selected: !Theme.islands; onClicked: Config.set("barStyle", "capsule") }
                            Chip { text: "Inseln"; selected: Theme.islands; onClicked: Config.set("barStyle", "islands") }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Höhe"
                        sub: Config.s.barHeight + " px"
                        Slider { width: 170; from: 36; to: 60; step: 1; value: Config.s.barHeight; onMoved: v => Config.set("barHeight", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Abstand zum Rand"
                        sub: Config.s.barMargin + " px"
                        Slider { width: 170; from: 0; to: 28; step: 1; value: Config.s.barMargin; onMoved: v => Config.set("barMargin", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Deckkraft"
                        sub: Math.round(Config.s.barAlpha * 100) + " %"
                        Slider { width: 170; from: 0.4; to: 1; value: Config.s.barAlpha; onMoved: v => Config.set("barAlpha", Math.round(v * 100) / 100) }
                    }
                    SectionTitle { width: parent.width; text: "Module" }
                    Grid {
                        width: parent.width
                        columns: 2
                        rowSpacing: 2
                        columnSpacing: Theme.s4
                        component Opt: SettingRow {
                            id: opt
                            property string key
                            width: (parent.width - Theme.s4) / 2
                            Toggle { checked: Config.s[opt.key]; onToggled: v => Config.set(opt.key, v) }
                        }
                        Opt { label: "Fenstertitel"; key: "showTitle" }
                        Opt { label: "Medien"; key: "showMedia" }
                        Opt { label: "System-Ringe"; key: "showStats" }
                        Opt { label: "Tray"; key: "showTray" }
                        Opt { label: "Launcher-Planet"; key: "showLauncher" }
                        Opt { label: "Uhr-Sonne"; key: "showClockOrb" }
                        Opt { label: "Datum"; key: "showDate" }
                        Opt { label: "24-Stunden"; key: "clock24" }
                        Opt { label: "Sekunden"; key: "showSeconds" }
                    }
                }

                // ================================================ Kosmos
                Page {
                    index: 2
                    SettingRow {
                        width: parent.width
                        label: "Sterne"
                        sub: "Sternenfeld auf Leiste und Karten"
                        Toggle { checked: Config.s.stars; onToggled: v => Config.set("stars", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Sternendichte"
                        sub: Config.s.starCount + " Sterne"
                        Slider { width: 170; from: 0; to: 90; step: 1; value: Config.s.starCount; onMoved: v => Config.set("starCount", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Funkeln"
                        sub: "Langsames Flackern, 3–8 s"
                        Toggle { checked: Config.s.twinkle; onToggled: v => Config.set("twinkle", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Leiste lebendig"
                        sub: "Funkeln + Sonnenpuls auch in der Leiste (kostet etwas CPU)"
                        Toggle { checked: Config.s.barTwinkle; onToggled: v => Config.set("barTwinkle", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Nebel"
                        sub: "Weiche Farbwolken hinter Leiste und Karten"
                        Toggle { checked: Config.s.nebula; onToggled: v => Config.set("nebula", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Sternschnuppen"
                        sub: "Im Schnitt alle " + Config.s.cometEvery + " s"
                        Row {
                            spacing: Theme.s3
                            Slider {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 116; from: 8; to: 120; step: 1
                                enabled: Config.s.shootingStars
                                opacity: enabled ? 1 : 0.4
                                value: Config.s.cometEvery
                                onMoved: v => Config.set("cometEvery", v)
                            }
                            Toggle { anchors.verticalCenter: parent.verticalCenter; checked: Config.s.shootingStars; onToggled: v => Config.set("shootingStars", v) }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Filmkorn"
                        sub: "4 % Rauschen auf großen Flächen"
                        Toggle { checked: Config.s.grain; onToggled: v => Config.set("grain", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Planetenringe"
                        sub: "Saturn-Ring um aktive Orbs"
                        Toggle { checked: Config.s.planetRings; onToggled: v => Config.set("planetRings", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Planetengröße"
                        sub: "× " + Config.s.planetScale.toFixed(2)
                        Slider { width: 170; from: 0.7; to: 1.4; value: Config.s.planetScale; onMoved: v => Config.set("planetScale", Math.round(v * 20) / 20) }
                    }

                    SectionTitle { width: parent.width; text: "Schwarze Löcher" }
                    Item {
                        width: parent.width
                        height: 150
                        // big live preview on the left, choices on the right
                        BlackHole {
                            id: preview
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.s2
                            width: 96
                            height: 96
                            spinning: Config.s.blackHoleSpin
                            opacity: Config.s.emptyTags === "blackhole" ? 1 : 0.45
                            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                        }
                        Column {
                            anchors.left: preview.right
                            anchors.leftMargin: Theme.s4
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.s2
                            KLabel { role: "muted"; text: "Leere Arbeitsflächen" }
                            Row {
                                spacing: 6
                                Chip { text: "Schwarzes Loch"; selected: Config.s.emptyTags === "blackhole"; onClicked: Config.set("emptyTags", "blackhole") }
                                Chip { text: "Staub"; selected: Config.s.emptyTags === "dust"; onClicked: Config.set("emptyTags", "dust") }
                                Chip { text: "Aus"; selected: Config.s.emptyTags === "hidden"; onClicked: Config.set("emptyTags", "hidden") }
                            }
                            KLabel { role: "muted"; text: "Am Heimat-Planeten" }
                            Row {
                                spacing: 6
                                Chip { text: "Umkreist"; selected: Config.s.launcherHole === "orbit"; onClicked: Config.set("launcherHole", "orbit") }
                                Chip { text: "Daneben"; selected: Config.s.launcherHole === "beside"; onClicked: Config.set("launcherHole", "beside") }
                                Chip { text: "Aus"; selected: Config.s.launcherHole === "off"; onClicked: Config.set("launcherHole", "off") }
                            }
                            KLabel { role: "muted"; text: "Scheibe" }
                            Row {
                                spacing: 6
                                Repeater {
                                    model: [
                                        { key: "warm", label: "Glut", tint: Theme.orange },
                                        { key: "accent", label: "Akzent", tint: Theme.accent },
                                        { key: "violet", label: "Violett", tint: Theme.magenta },
                                        { key: "ice", label: "Eis", tint: Theme.cyan }
                                    ]
                                    Chip {
                                        required property var modelData
                                        text: modelData.label
                                        tint: modelData.tint
                                        selected: Config.s.blackHoleColor === modelData.key
                                        onClicked: Config.set("blackHoleColor", modelData.key)
                                    }
                                }
                            }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Rotation"
                        sub: "Die Scheibe dreht sich (Leiste zeichnet dann laufend neu)"
                        Toggle { checked: Config.s.blackHoleSpin; onToggled: v => Config.set("blackHoleSpin", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Drehtempo"
                        sub: "× " + Config.s.blackHoleSpeed.toFixed(2)
                        Slider {
                            width: 170; from: 0.25; to: 3
                            enabled: Config.s.blackHoleSpin
                            opacity: enabled ? 1 : 0.4
                            value: Config.s.blackHoleSpeed
                            onMoved: v => Config.set("blackHoleSpeed", Math.round(v * 20) / 20)
                        }
                    }
                }

                // ============================================== Bewegung
                Page {
                    index: 3
                    SettingRow {
                        width: parent.width
                        label: "Animationen"
                        sub: "Aus = alles sofort, keine Ambient-Effekte"
                        Toggle { checked: Config.s.animations; onToggled: v => Config.set("animations", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Tempo"
                        sub: Config.s.animSpeed < 0.9 ? "flott" : Config.s.animSpeed > 1.3 ? "gemütlich" : "ausgewogen"
                        Slider { width: 170; from: 0.5; to: 2; value: Config.s.animSpeed; onMoved: v => Config.set("animSpeed", Math.round(v * 20) / 20) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Tag-Wechsel"
                        sub: "Ein Komet fliegt zum neuen Tag"
                        Row {
                            spacing: 6
                            Chip { text: "Komet"; selected: Config.s.tagSwitch !== "off"; onClicked: Config.set("tagSwitch", "comet") }
                            Chip { text: "Aus"; selected: Config.s.tagSwitch === "off"; onClicked: Config.set("tagSwitch", "off") }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Rundung"
                        sub: "× " + Config.s.radiusScale.toFixed(2)
                        Slider { width: 170; from: 0.5; to: 1.5; value: Config.s.radiusScale; onMoved: v => Config.set("radiusScale", Math.round(v * 20) / 20) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Schriftgröße"
                        sub: "× " + Config.s.fontScale.toFixed(2)
                        Slider { width: 170; from: 0.85; to: 1.3; value: Config.s.fontScale; onMoved: v => Config.set("fontScale", Math.round(v * 20) / 20) }
                    }

                    SectionTitle { width: parent.width; text: "Popups & Mitteilungen" }
                    SettingRow {
                        width: parent.width
                        label: "Launcher"
                        sub: "Karte oder Apps im Orbit um ein schwarzes Loch"
                        Row {
                            spacing: 6
                            Chip { text: "Liste"; selected: Config.s.launcherStyle !== "orbit"; onClicked: Config.set("launcherStyle", "list") }
                            Chip { text: "Schwarzes Loch"; selected: Config.s.launcherStyle === "orbit"; onClicked: Config.set("launcherStyle", "orbit") }
                        }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Abdunkeln"
                        sub: "Desktop hinter Popups · " + Math.round(Config.s.popupDim * 100) + " %"
                        Slider { width: 170; from: 0; to: 0.36; value: Config.s.popupDim; onMoved: v => Config.set("popupDim", Math.round(v * 100) / 100) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Lautstärke-Anzeige"
                        sub: "Kapsel beim Ändern der Lautstärke"
                        Toggle { checked: Config.s.osd; onToggled: v => Config.set("osd", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Mitteilungen"
                        sub: "Anzeigedauer " + Config.s.toastTimeout + " s"
                        Slider { width: 170; from: 2; to: 15; step: 1; value: Config.s.toastTimeout; onMoved: v => Config.set("toastTimeout", v) }
                    }
                    SettingRow {
                        width: parent.width
                        label: "Mitteilungs-Seite"
                        Row {
                            spacing: 6
                            Chip { text: "Links"; selected: Config.s.toastSide === "left"; onClicked: Config.set("toastSide", "left") }
                            Chip { text: "Rechts"; selected: Config.s.toastSide !== "left"; onClicked: Config.set("toastSide", "right") }
                        }
                    }
                    Item { width: 1; height: Theme.s2 }
                    Chip {
                        anchors.right: parent.right
                        text: "Alles zurücksetzen"
                        glyph: Glyphs.refresh
                        tint: Theme.orange
                        onClicked: Config.reset()
                    }
                }
            }
        }
    }

    // One tab page: fades/slides in when selected.
    component Page: Column {
        property int index
        readonly property bool current: root.tab === index
        width: pages.width
        spacing: Theme.s3
        visible: opacity > 0.01
        opacity: current ? 1 : 0
        x: current ? 0 : (index < root.tab ? -24 : 24)
        Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        Behavior on x { NumberAnimation { duration: Theme.tMed; easing.type: Theme.easeOut } }
    }
}
