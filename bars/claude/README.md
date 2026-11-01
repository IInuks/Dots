# claude — Dock-Shell für mango

Eigenständiger, von Grund auf neu entworfener Quickshell-Aufbau (keine
Übernahme von Code/Architektur aus den anderen `quickdots/bars/*`) im
Geist von caelestia-shell: eine Leiste plus mehrere echte Menüs — Launcher,
Hintergrundbild-Wechsler, einfache Einstellungen, Benachrichtigungen,
Power — mit adaptivem Theme und durchgehenden Animationen. Struktur und
Optik unterscheiden sich aber bewusst von jeder vorhandenen Bar hier:

- **Unten statt oben.** Ein schmaler Dock am unteren Bildschirmrand statt
  einer Leiste/Pille oben.
- **Fünf unabhängige Flyouts statt einem Tab-Panel.** Jedes Menü ist ein
  eigenständiges, unterschiedlich großes Fenster, das direkt über seinem
  eigenen Auslöser-Icon aufsteigt (`Popups.anchorX`, beim Klick per
  `mapToItem` erfasst) — kein zentrales Panel mit Tab-Leiste.
- **Radiale Ringmesser statt Text/Icon-Zeilen.** CPU und Lautstärke im
  Dock, plus alle vier Power-Aktionen: Halten füllt den Ring, Loslassen
  vor Fertigstellung bricht ab — kein Klick-dann-Bestätigen-Dialog.
- **Handgezeichnete Canvas-Icons** (`Glyph.qml`, `context2d`-Pfade) statt
  eines SVG-Pfad-Sets.
- **"Slate & Verdigris"**-Palette (Graphit/Kohle + Türkis/Gold), adaptiv
  per pywal.

## Kurzfassung

**Abhängigkeiten:**
- Quickshell ≥ 0.3.0
- mango (`mmsg`) für Tags
- Pipewire/wireplumber (Lautstärke-Ringmesser)
- `awww` (ehem. `swww`) + `wal` (pywal) für den Hintergrundbild-Wechsler;
  `~/.cache/wal/colors.json` treibt auch das "Adaptiv"-Farbschema
- kein Icon-Font nötig — alle Icons sind `Glyph.qml`-Canvas-Zeichnungen

**Start (Test/Debug, ohne Bar-Switcher):**
```
qs -p ~/quickdots/bars/claude
```

**Als aktive Bar registrieren:**
```
~/quickdots/menu/scripts/switch-bar.sh claude
```
Adapter: `quickdots/menu/adapters/claude.json` (`hasLauncher: true`, fünf
Keybinds — `SUPER+Space` Launcher, `CTRL+SUPER+W` Wallpaper,
`CTRL+SUPER+S` Einstellungen, `CTRL+SUPER+N` Benachrichtigungen,
`CTRL+SUPER+P` Power — alle über `ipc call <target> toggle`).

## Struktur

```
shell.qml                 Root: Bar per Bildschirm (Variants), ein Overlay-
                           Fenster mit FocusScope+Backdrop+fünf Popups+Toast,
                           IpcHandler je Popup, NotificationServer
Config.qml                  Singleton: persistierte Wahl (Theme-Modus,
                             Bar-Deckkraft, DND, letztes Wallpaper)
Chroma.qml                   Singleton: "Slate & Verdigris"-Farben, live
                              adaptiv per pywal (bewusst NICHT "Palette"
                              genannt — siehe Kommentar in der Datei, ein
                              Qt/QtQuick-Builtin gleichen Namens hätte sie
                              sonst überall im Baum kommentarlos überdeckt,
                              jede Farbe wäre undefined gewesen)
Metrics.qml                    Singleton: Geometrie/Zeiten (bewusst nicht
                                "Layout" genannt — kollidiert sonst mit
                                QtQuick.Layouts' `Layout`-Attached-Property)
Session.qml                      Singleton: mango-Tags per mmsg watch
Popups.qml                         Singleton: welches Flyout offen ist +
                                    Anker-x-Position
AppIndex.qml                         Singleton: Desktop-Einträge, simple
                                      Substring-Suche
NotifyHub.qml                          Singleton: Verlauf + Ungelesen-
                                        Zähler + aktueller Toast
Glyph.qml                    Canvas-Icon-Set (kein Icon-Font, keine SVG-
                              Pfade)
Slider.qml                     Minimaler Klick/Drag-Regler
Toast.qml                        Transiente Karte oben rechts (Dock ist
                                  unten, bewusst getrennt)
Bar/Bar.qml                 Dock-PanelWindow: Tags links, fünf Popup-
                             Auslöser mittig, CPU/Lautstärke/Tray/Uhr rechts
Bar/Tags.qml                  Equalizer-Ticks statt Zahlen-Pillen
Bar/Meter.qml                  Radiales Ringmesser (Canvas), Basis für
                                CpuGauge/VolumeGauge und die Power-Aktionen
Bar/DockButton.qml               Auslöser-Icon: hebt bei Hover, glüht wenn
                                  aktiv, meldet seine x-Position
Popups/PopupFrame.qml       Gemeinsames Flyout-Gehäuse: Position/Klemmung/
                             Aufstieg/Fade — jede Instanz bleibt dauerhaft
                             geladen (nie per Loader zerstört), damit das
                             Ausblenden nicht mitten in der Animation
                             abgeschnitten wird
Popups/Launcher.qml            Such-Liste
Popups/Wallpapers.qml            Horizontaler Filmstreifen statt Grid
Popups/QuickSettings.qml           Theme-Modus, Bar-Deckkraft, DND
Popups/NotificationsPanel.qml        Verlauf, Aktionen, Einzel-/Alle-löschen
Popups/PowerPanel.qml                  Halten-zum-Bestätigen per Ringmesser
```

## Bekannte Lücken

- Nur **ein** Overlay-Fenster (nicht per Bildschirm dupliziert) — bei
  mehreren Monitoren erscheinen Flyouts immer auf dem Bildschirm, dem
  Quickshell dieses Fenster zuweist; die x-Ankerposition eines Docks auf
  einem *anderen* Monitor wird dann leicht falsch übernommen (durch
  `PopupFrame`s Klemmung bleibt sie aber immer sichtbar, nur nicht exakt
  unter dem geklickten Icon).
  <br>Grund: koexistiert mit dem `mango`-IPC-Modell dieses Systems und
  Quickshells `PanelWindow`, das (anders als ein Item) keine
  `Keys`/`focus`-Properties besitzt — Tastaturfokus/Esc laufen daher über
  einen `FocusScope` im Fensterinhalt, nicht über das Fenster selbst.
- `.webp`-Hintergrundbilder: manche lassen sich mit der hier installierten
  Qt-Image-Plugin-Auswahl nicht dekodieren ("Unsupported image format") —
  betrifft nur deren Thumbnail/Anwenden im Wallpaper-Flyout, kein Bug in
  diesem Code.
- Adapter liefert dem Bar-Switcher-Menü nur statische Farbwerte, kein
  `adapters/live/ClaudeLive.qml` (wie aktuell nur quickbar/shellbar/klasic
  haben) — Kartenvorschau zeigt die Slate-&-Verdigris-Grundfarben, nicht
  live extrahierte.
- Getestet mit `qs -p . -n` (Konfiguration lädt fehlerfrei, alle fünf
  Popups per IPC geöffnet/geschlossen, keine Warnungen mehr außer dem
  einmaligen "Konfigurationsdatei existiert noch nicht" beim allerersten
  Start) — noch nicht über `switch-bar.sh` als aktive Bar durchgeschaltet.

## Bug-Fundstücke (für künftige Sessions in diesem Verzeichnis)

Drei stille, aber vollständig blockierende bzw. verfälschende Fehler beim
ersten Durchlauf, keiner davon mit einer hilfreichen Fehlermeldung:

1. **Singleton-Name kollidiert mit einem Qt/QtQuick-Builtin.** Die
   Farb-Singleton hieß zunächst `Palette.qml` — lädt ohne jede
   Fehlermeldung, registriert sich korrekt im synthetisierten `qmldir`,
   aber *jede* Property darauf (auch komplett statische wie
   `readonly property int rSmall: 7`) liest sich von überall im Baum als
   `undefined` ("Unable to assign [undefined] to ..."), dauerhaft, nicht
   nur beim Start. Durch isolierten Minimal-Repro bestätigt: derselbe
   Dateiinhalt funktioniert fehlerfrei unter jedem anderen Namen (hier:
   `Chroma`). Vermutlich dieselbe Fehlerklasse wie die bereits bekannte
   `DesktopEntries`-Kollision, nur eben mit einem QtQuick- statt einem
   Quickshell-Typnamen.
2. **Singleton-Name kollidiert mit `QtQuick.Layouts`' `Layout`-Attached-
   Property.** Die Geometrie-Singleton hieß zunächst `Layout.qml` — jede
   `Layout.xyz`-Property-Referenz (Metrik-Singleton) funktionierte, aber
   `RowLayout`-Kinder mit `Layout.alignment: ...` scheiterten mit
   `Type Bar unavailable … Non-existent attached object`, weil der lokale
   Singleton-Typname den Attached-Property-Typ gleichen Namens verdeckt.
   Umbenannt zu `Metrics`.
3. **`Behavior on` einer `readonly property`.** Führt zu `Invalid property
   assignment: "_riseOffset" is a read-only property` beim Laden — eine
   Behavior muss die Property beschreiben können, `readonly` verbietet das
   kategorisch, unabhängig davon, ob die Property eine deklarative Bindung
   hat.

Alle drei sind reine Lade-/Bindungsfehler ohne jede JS-Exception im Log
(weder `log.qslog` noch das ausführlichere `log.log`) — bei "manche
Property liest sich als `undefined`, aber es gibt keinen Fehler" lohnt es
sich als Erstes, den Singleton-Namen selbst zu verdächtigen, nicht die
Logik darin.
