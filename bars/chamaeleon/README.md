# chamaeleon — Mini-DE-Shell für mango

Entstanden aus dem Auftrag "überrasch mich mit einer Art Desktop
Environment — nicht vom Aussehen her, sondern von den Features: Bar,
Einstellungsmenüs, adaptives Theme". Der Ordner hieß ursprünglich
`überaschung`; umbenannt zu `chamaeleon`, weil ein Chamäleon sichtbar
seine Farbe ändert — passend zum adaptiven Theme-System, das den Kern
dieses Builds ausmacht.

**Abgrenzung zu den Nachbar-Bars:** Oben statt unten/floating/Dock, ein
einziges tab-basiertes "Kontrollzentrum" statt mehrerer unabhängiger
Flyouts, und ein **vierter Theme-Modus, den keine andere Bar hier hat**:
`auto` schaltet Hell/Dunkel per Uhrzeit um (nicht nur per Wallpaper-Farbe
wie `adaptive`) — die Bar zeigt außerdem im Kontrollzentrum-Auslöser
sichtbar an, welcher Modus gerade aktiv ist (☀/🌙/🕐/💧).

## Kurzfassung

**Abhängigkeiten:**
- Quickshell ≥ 0.3.0
- mango (`mmsg`) für Tags
- Pipewire/wireplumber (Sound-Tab)
- `wal` (pywal) für den "Adaptiv"-Modus — `~/.cache/wal/colors.json`,
  wird von `shellwall` bei jedem Hintergrundbild-Wechsel neu geschrieben
- keine Icon-Fonts/SVGs nötig — alle Glyphen sind einfache Unicode-Zeichen

**Start (Test/Debug, ohne Bar-Switcher):**
```
qs -p ~/quickdots/bars/chamaeleon -n
```

**Als aktive Bar registrieren** (noch nicht getan — siehe "Nächste
Schritte"):
```
~/quickdots/menu/scripts/switch-bar.sh chamaeleon
```
Adapter: `quickdots/menu/adapters/chamaeleon.json` (`hasLauncher: true`,
zwei Keybinds — `SUPER+Space` öffnet den Launcher, `CTRL+SUPER+C` das
Kontrollzentrum, beide über `ipc call <target> toggle`).

## Struktur

```
shell.qml            Root: Bar per Bildschirm (Variants), ein Overlay-
                      Fenster mit FocusScope+Backdrop+ControlCenter+
                      Launcher+Notifications, drei IpcHandler ("settings",
                      "launcher", "notifications"), NotificationServer
                      (Lebensdauer ans Root gebunden, wie in bars/claude)
Config.qml             Singleton: persistierte Wahl (Theme-Modus, Accent-
                        Override, Bar-Deckkraft, Tag-Sichtbarkeit,
                        Auto-Zeitfenster) -> Quickshell.statePath("config.json")
Theme.qml                Singleton: dark/light/auto/adaptive, live
                          adaptiv per pywal, `auto` per Uhrzeit-Timer
                          (bewusst nicht "Palette"/"Colors" genannt, siehe
                          "Bekannte Fallen")
Metrics.qml                 Singleton: Geometrie/Zeiten (bewusst nicht
                             "Layout" genannt — kollidiert sonst mit
                             QtQuick.Layouts' `Layout`-Attached-Property)
Popups.qml                     Singleton: welches Flyout offen ist +
                                Anker-x-Position + focusToken (erzwingt
                                Tastaturfokus auf das Suchfeld beim Öffnen)
MangoIpc.qml                     Singleton: mango-Tags per mmsg watch
                                  (eigene Kopie, wie in jeder Nachbar-Bar)
AppIndex.qml                       Singleton: Substring-Suche über
                                    Quickshells DesktopEntries-Index
NotifyHub.qml                        Singleton: Notification-Log +
                                      Unread-Zähler; der eigentliche
                                      NotificationServer sitzt in shell.qml
                                      (braucht App-Lebensdauer)
Slider.qml                          Minimaler Klick/Drag-Regler
PopupFrame.qml                        Gemeinsames Flyout-Gehäuse:
                                       Position/Klemmung/Aufstieg/Fade,
                                       dauerhaft geladen (nie per Loader
                                       zerstört)
ControlCenter.qml                       Das Einstellungsmenü: fünf Tabs
                                         (Appearance/Bar/Sound/Network/
                                         Power) — Network fasst Wi-Fi
                                         (Quickshell.Networking) und
                                         Bluetooth (Quickshell.Bluetooth)
                                         in einem Tab zusammen
Launcher.qml                              Suchfeld + Ergebnisliste, Pfeiltasten
                                           + Enter, Icon-Fallback = erster
                                           Buchstabe (kein eigenes Glyph-Set)
Notifications.qml                           Notification-Flyout: Log neuester
                                             zuerst, einzeln dismissbar,
                                             "Clear all", markiert beim
                                             Öffnen alles als gesehen
Bar/Bar.qml           Oberer Balken: Launcher-Auslöser + Tags links, Uhr
                       mittig, Notification-Glocke (roter Punkt bei
                       ungelesenen) + Kontrollzentrum-Auslöser rechts
                       (Glyph = aktueller Theme-Modus)
```

## Fahrplan (nächste Sessions)

Wie jede Nachbar-Bar hier ist das ein Mehr-Sitzungs-Aufbau.

- **Stage 1 (fertig):** Bar + Kontrollzentrum (Appearance/Bar/Sound/Power)
  + vierstufiges adaptives Theme
- **Stage 2 (fertig):** Launcher-Flyout (`AppIndex.qml` + `Launcher.qml`),
  Adapter auf `hasLauncher: true` + `SUPER+Space`-Keybind nachgezogen
- **Stage 3 (fertig):** Network-Tab im Kontrollzentrum (Wi-Fi +
  Bluetooth in einem Tab, `Quickshell.Networking`/`Quickshell.Bluetooth`,
  analog `bars/shellbar/SettingsMenu.qml` + `bars/fisheye/menus/
  BluetoothMenu.qml`), Benachrichtigungs-Flyout (`NotifyHub.qml` +
  `Notifications.qml`, `NotificationServer` in shell.qml, analog
  `bars/claude/NotifyHub.qml`) — bewusst **kein** Toast-Popup, nur der
  Unread-Punkt auf der Glocke; Kontrollzentrum-Panelbreite/-höhe
  unverändert gelassen, Tab-Button-Breite jetzt aus `root.tabs.length`
  berechnet statt hart auf 4 codiert
- **Stage 4:** `menu/adapters/live/ChamaeleonLive.qml` für eine echte
  Live-Vorschau im Bar-Switcher-Menü (aktuell nur statische Adapter-Farben)
- Erst danach über `switch-bar.sh chamaeleon` aktiv schalten

## Bekannte Fallen (für künftige Sessions in diesem Verzeichnis)

- Singleton-Namen wie `Palette`/`Colors`/`Layout` kollidieren
  stillschweigend mit Qt/QtQuick-Builtins — jede Property liest sich dann
  überall als `undefined`, ohne jede Fehlermeldung im Log. Deshalb
  `Theme.qml` und `Metrics.qml` statt der naheliegenden Namen.
- `Behavior on` auf einer `readonly property` schlägt beim Laden fehl
  ("is a read-only property") — betrifft hier nichts direkt, aber falls
  später ein weiterer abgeleiteter Wert eine Behavior bekommen soll: erst
  prüfen, ob die Property tatsächlich schreibbar ist.
- Getestet mit `qs -p . -n` und live per `ipc call settings toggle` /
  `ipc call launcher toggle` über die Kommandozeile — keine Fehler/
  Warnungen in `log.qslog` oder `log.log`. Noch nicht per Maus/Tastatur im
  echten Compositor durchgeklickt (alle vier Theme-Modi, Sound-Tab mit
  echtem Pipewire-Sink, Power-Tab-Bestätigung, Launcher-Suche/Pfeiltasten/
  Enter, Icon-Fallback-Avatare, Network-Tab mit echtem Wi-Fi/Bluetooth-
  Gerät, Notification-Flyout mit einer echten `notify-send`) — das sollte
  vor `switch-bar.sh` einmal manuell passieren. Dieser Rechner hat laut
  bisherigen Sessions (siehe `bars/fisheye/menus/BluetoothMenu.qml`)
  keinen aktiven Bluetooth-Adapter — der Adapter-Pfad im Network-Tab ist
  damit nur strukturell verifiziert, nicht mit echtem Gerät.
- `qs -p . -n` beendet sich sofort mit "An instance of this configuration
  is already running", falls eine vorherige Test-Instanz noch lebt (auch
  nach `pkill -f "qs -p ..."`, wenn das Pattern nicht exakt passt) —
  zuverlässig mit `qs -p <pfad> list` prüfen und `qs -p <pfad> kill`
  beenden, nicht auf `pkill` verlassen.
