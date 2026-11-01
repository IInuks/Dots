# ksp — Mission-Control-Bar für mango

Auftrag: "eine Status-Bar mit vielen Animationen und Menüs, die aussieht
wie das UI in Kerbal Space Program". Eigenständiger Aufbau (kein Code aus
den Nachbar-Bars übernommen, nur die etablierten Architektur-Muster:
Singleton-Theme, PopupFrame-Flyouts, MangoIpc-Kopie — siehe
`bars/chamaeleon/README.md` für die Erklärung, warum das jede Bar hier
für sich dupliziert).

**KSP-Optik, konkret umgesetzt:**
- **Hazard-Stripe-Akzente** (`HazardStripe.qml`, Canvas-gezeichnete
  Diagonalstreifen) statt einfacher Trennlinien — Bar-Unterkante und
  Flyout-Header.
- **HUD-Eckklammern** (`CornerBrackets.qml`) mit langsamer
  "System online"-Puls-Animation um jedes Flyout.
- **Chronometer** in der Bar-Mitte: Monospace, blinkender Doppelpunkt,
  Datum darüber — Anlehnung an KSP's MET-Anzeige.
- **Stage-Badges** statt normaler Tag-Punkte: runde Nummern-Badges für
  mango-Tags, aktives Tag pulsiert mit einem sich ausdehnenden Ring
  (wie die "nächste Stufe"-Hervorhebung im Spiel).
- **Segmentierte Ressourcen-Gauges** (`Gauge.qml`) statt Balken/Zahlen —
  wie LiquidFuel/Oxidizer/ElectricCharge-Anzeigen; genutzt für die
  Signal-Anzeige in der Bar und die Lautstärke im Comms-Tab.
- **Drei "Livery"-Farbschemata** (Orange/Cyan/Crimson, benannt nach
  Kerbin/Mun/Duna) statt hell/dunkel/adaptiv — dieser Build hat bewusst
  *kein* Theme-Switching-System wie die Nachbar-Bars, der Fokus liegt auf
  Optik + Animation, nicht auf Adaptivität.
- **Scanline-Reveal**: jedes Flyout zieht beim Öffnen einen horizontalen
  Leuchtstreifen einmal von oben nach unten durch (`PopupFrame.qml`,
  `scanline`-SequentialAnimation).
- **CRT-Overlay** (`CrtOverlay.qml`): dauerhafte, per Canvas gezeichnete
  Scanlines + radiale Vignette über Bar und jedem Flyout, plus ein
  gelegentliches kurzes Helligkeits-Flackern ("die Röhre lebt"). Stärke
  in Echtzeit einstellbar über Control Center -> Display.
  **Wichtig für spätere Sessions:** `CrtOverlay` erwartet, dass sein
  Elternelement `clip: true` hat (in `PopupFrame.qml`/`Bar.qml` bereits
  der Fall) -- sonst ragen die Scanlines über runde Ecken hinaus.
- **Sieben-Segment-Anzeige** (`SevenSegment.qml`/`SevenSegmentDisplay.qml`):
  echte LED/LCD-Optik mit sichtbaren "Geister"-Segmenten im Aus-Zustand
  (Opacity 0.08 statt unsichtbar) -- der stärkste neue Retro-Effekt,
  aktuell nur im Telemetry-Panel genutzt (die Bar-Uhr bleibt aus
  Platzgründen normaler Monospace-Text).
- **Vierte Livery "Phosphor"** (`#39ff14`, grünes Monochrom-Terminal) --
  reiner Retro-Anstrich neben den drei Himmelskörper-Farben.

**Abgrenzung zu den Nachbar-Bars:** kein adaptives/pywal-Theme (siehe
oben), Flyouts heißen thematisch um (Launcher → "Mission Database",
Notifications → "Mission Log", Control Center-Tabs → Livery/Comms/Flight),
und `Gauge.qml`/`HazardStripe.qml`/`CornerBrackets.qml` gibt es in keiner
anderen Bar.

## Kurzfassung

**Abhängigkeiten:**
- Quickshell ≥ 0.3.0
- mango (`mmsg`) für Tags
- Pipewire/wireplumber (Comms-Tab, Lautstärke-Gauge)
- keine Icon-Fonts/SVGs — alle Glyphen sind Unicode-Emoji, wie in jeder
  Nachbar-Bar

**Start (Test/Debug, ohne Bar-Switcher):**
```
qs -p ~/quickdots/bars/ksp -n
```

**Als aktive Bar registrieren** (noch nicht getan — siehe "Nächste
Schritte"):
```
~/quickdots/menu/scripts/switch-bar.sh ksp
```
Adapter `quickdots/menu/adapters/ksp.json` existiert noch nicht — muss
vor dem Registrieren angelegt werden (Vorlage: `adapters/chamaeleon.json`).

## Struktur

```
shell.qml            Root: Bar pro Bildschirm (Variants), Overlay-Fenster
                      mit FocusScope+Backdrop+ControlCenter+Launcher+
                      Notifications, drei IpcHandler ("settings",
                      "launcher", "notifications"), NotificationServer
                      (Lebensdauer ans Root gebunden)
Config.qml              Singleton: persistierte Wahl (Livery, Bar-
                        Deckkraft, Tag-Sichtbarkeit) -> Quickshell.
                        statePath("config.json")
Theme.qml                 Singleton: feste "Mission Control"-Palette +
                           drei Livery-Akzentfarben (kein Hell/Dunkel/
                           Adaptiv wie bei den Nachbar-Bars)
Metrics.qml                  Singleton: Geometrie/Zeiten (bewusst nicht
                              "Layout" genannt — kollidiert sonst mit
                              QtQuick.Layouts' `Layout`-Attached-Property)
Popups.qml                      Singleton: welches Flyout offen ist +
                                 Anker-x-Position + focusToken
MangoIpc.qml                       Singleton: mango-Tags per mmsg watch
                                    (eigene Kopie, wie in jeder Nachbar-Bar)
AppIndex.qml                          Singleton: Substring-Suche über
                                       Quickshells DesktopEntries-Index
NotifyHub.qml                            Singleton: Notification-Log +
                                          Unread-Zähler; NotificationServer
                                          selbst sitzt in shell.qml
SysStats.qml                                Singleton: CPU/RAM/Uptime per
                                             `/proc`-Polling (eigene
                                             `cat`-Prozesse, 2s-Timer,
                                             exit-dann-neustart wie
                                             MangoIpc)
HazardStripe.qml    Canvas-Diagonalstreifen (Warnstreifen-Optik)
CornerBrackets.qml    HUD-Eckklammern mit Puls-Animation
CrtOverlay.qml           Scanlines + Vignette + gelegentliches Flackern
SevenSegment.qml            Ein LED/LCD-Zeichen (7 Segmente + Doppelpunkt)
SevenSegmentDisplay.qml        Row aus SevenSegment für einen ganzen String
Gauge.qml               Segmentierte Ressourcen-Anzeige
Slider.qml                 Klick/Drag-Regler (mit Farbverlaufs-Rand)
PopupFrame.qml                Gemeinsames Flyout-Gehäuse: Hazard-Stripe-
                               Header, Eckklammern, Scanline-Reveal beim
                               Öffnen, CrtOverlay, Position/Klemmung/Fade
ControlCenter.qml                Einstellungsmenü: vier Tabs (Livery/
                                  Comms/Flight/Display), gleitender
                                  Tab-Indikator
Launcher.qml                        App-Suche ("Mission Database"),
                                     gleitende Auswahl-Schiene
Notifications.qml                      "Mission Log": Log neuester zuerst,
                                        gestaffelter Slide-in beim Öffnen
Telemetry.qml                             Neues Flyout: MET-Uptime als
                                           große Sieben-Segment-Anzeige,
                                           CPU/RAM-Gauges, scrollender
                                           Terminal-Ticker (Host/Kernel)
Bar/Bar.qml           Bar selbst: Launcher-Badge + Stage-Badges links,
                       Chronometer mittig, Signal-Gauge + Telemetrie-Badge
                       (🛰) + Comms-Log-Badge + Control-Center-Badge (mit
                       45°-Dreh-Animation) rechts; gesamter Inhalt slided
                       beim Start rein, CrtOverlay obendrauf
```

## Bekannte Fallen (aus Erfahrung der Nachbar-Bars, hier vorsorglich
## vermieden)

- Singleton-Namen dürfen keine Quickshell/QtQuick-Builtins verdecken
  (`Theme`/`Metrics` statt `Palette`/`Layout` — siehe oben).
- `Component { id: x; Item { ... x.foo ... } }` funktioniert **nicht**
  wie man denkt: `x` referenziert das `Component`-Objekt selbst, nicht
  die daraus erzeugte Instanz — `x.foo` ist dann still `undefined`. Im
  Comms-Tab (`ControlCenter.qml`) deshalb ein eigenes `id` auf dem
  inneren `Item` (`commsRoot`), nicht auf dem `Component`.
- `WlrKeyboardFocus.None` fest verdrahtet würde alle Tastatureingaben im
  Overlay für immer blocken — hier an `Popups.openId !== ""` gebunden.

## Fahrplan (nächste Sessions)

- **Stage 1 (fertig, per Screenshot verifiziert):** Bar + Launcher +
  Mission Log + Control Center (Livery/Comms/Flight), volle KSP-Optik,
  Mount-Animation, Scanline-Reveal, Stage-Badge-Puls.
- **Stage 1.5 (fertig, per Screenshot verifiziert):** Telemetry-Flyout
  (echtes CPU/RAM/Uptime per `/proc`, Sieben-Segment-MET-Anzeige,
  scrollender Ticker), CRT-Overlay (Scanlines/Vignette/Flackern, per
  Display-Tab einstellbar) auf Bar + allen Flyouts, vierte Livery
  "Phosphor". Damit ist das ursprüngliche Stage-2-Ziel (CPU/RAM-Gauges)
  bereits erledigt.
- **Stage 2:** Disk-I/O als weitere Gauge, evtl. Netzwerk-Durchsatz im
  Telemetry-Ticker statt nur Host/Kernel.
- **Stage 3:** Als aktive Bar registrieren (`adapters/ksp.json` anlegen,
  `switch-bar.sh ksp` ausführen), danach echtes manuelles Testen in der
  laufenden mango-Session (Hover/Klick auf alle vier Flyouts, Lautstärke-
  Drag, Livery-Wechsel, Power-Aktionen scharf/entschärft, CRT-Intensität-
  Slider).
