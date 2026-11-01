# fisheye — Y2K-LCD Quickshell Bar

Statusbar im Stil einer späten-90er/frühen-2000er Digitaluhr (Casio/Fossil-
Sportuhr): 7-/14-Segment-Anzeigen statt Schriftarten, Geistersegmente,
Bevel-Kanten statt Schatten, LCD-Textur, alles adaptiv eingefärbt aus der
laufenden Wallpaper-Palette. Voller Auftrag steht unten unter "Ursprungs-Prompt".

Stand: **Etappe 9 von 9 fertig — alle Etappen abgeschlossen**, plus vier
Nachträge (App-Launcher, globaler Launcher-Hotkey + ein Input-Mask-Fix, der
allen Popups zugutekommt, ein eigenes Fenster für den Launcher wegen eines
mango-Fokus-Bugs, sowie Wetter + Monatskalender im Uhr-Popup). Die echte Bar
läuft produktiv mit Uhr, Workspaces,
Fenstertitel, allen rechten Statusmodulen, sechs Popup-Menüs (Power,
Sound-Mixer, Analoguhr, Netzwerk, Bluetooth, App-Launcher), Boot-Selbsttest,
periodischem Idle-Glanz und einem optionalen Performance-Overlay;
`shell.qml`s `testMode` steht auf `false`.

## Woran als nächstes zu arbeiten ist

Kein offener Punkt aus dem ursprünglichen Etappenplan mehr. Mögliche
Nachträge, falls gewünscht (keiner davon Teil des Originalauftrags):

- **Noch mit echter Tastatur gegenprüfen**: der Launcher-Fenster-Fix (siehe
  "Nachtrag: Launcher bekommt eigenes Fenster") lief nur per IPC-Zyklen ohne
  Log-Fehler durch, nicht per echtem Tastendruck (kein `wtype`/`ydotool` in
  dieser Umgebung). Einmal SUPER+space und einmal Klick auf den
  Launcher-Button probieren, jeweils direkt tippen + Escape.
- Kein Klick-daneben-Schließen mehr beim Launcher (eigenes Fenster hat
  keinen Zugriff auf `Bar.qml`s gemeinsamen `popupLayer`/`mask` mehr) —
  falls das im Alltag stört, bei Gelegenheit nachrüsten.
- Battery/Media könnten nachträglich ein eigenes Popup bekommen (Etappe-8-
  Entscheidung war bewusst dagegen, siehe dort).
- `Theme.idleGlintInterval` (45s) ist ein sinnvoll wirkender Startwert,
  nicht aus dem Originalauftrag abgeleitet — bei Bedarf beim Nutzer
  nachjustieren.

## Was funktioniert (Etappe 1)

- `Theme.qml` — Singleton, komplette semantische Palette (`surface`,
  `surfaceDim`, `surfaceInk`, `accent`, `accentInk`, `critical`, `warning`,
  `success`, `bevelLight`, `bevelDark`, `glassTint`, `segmentOn`,
  `segmentOff`). Lädt live `~/.cache/wal/colors.json` (pywal, per FileView +
  `watchChanges: true`), fällt sonst auf eine aus einem Seed-Hex per
  HSL abgeleitete Palette zurück. Bevel-Farben werden automatisch aus
  `surface` berechnet (headroom-relative Mischung Richtung Weiß/Schwarz —
  dreht sich bei hellen Paletten von selbst um, kein if/else nötig). Alle
  Rollen haben `Behavior { ColorAnimation }` für weichen 400ms-Crossfade bei
  Palettenwechsel. Zentrale Dauern/Easings (`durFast`, `durBase`, `durSlow`,
  `durPalette`, `durBoot`, `durIdle`, `easeOut`, `easeOutBack`, `easeInOut`).
  `Theme.reducedMotion`/`Theme.density` kommen aus Config und schlagen global
  durch (alle Dauern → 0 bei reducedMotion).
- `Config.qml` — Singleton, lädt live `~/.config/fisheye-bar/config.json`
  (FileView, `watchChanges: true`), schreibt Default-Inhalt falls die Datei
  fehlt. Felder: `reducedMotion`, `density`, `bootSequence`, `clockFormat`,
  `showSeconds`, `moduleOrder`, `visibleModules` (+ `Config.isVisible(name)`).
- `shell.qml` + `bar/Bar.qml` — leere Bar, `Variants` über `Quickshell.screens`,
  sitzt korrekt oben auf jedem Monitor (`PanelWindow`, `exclusiveZone`,
  `WlrLayershell.layer: Top`, `namespace: "fisheye-bar"`). Aktuell nur
  Hintergrund, keine Module.
- `widgets/common/BevelPanel.qml` — die vier Bevel-Streifen (hell oben/links,
  dunkel unten/rechts), `layer.enabled` gecacht.
- `widgets/common/LcdSurface.qml` — Grundfläche + feines Pixelraster (Canvas,
  einmalig gerendert + gecacht, keine Live-Neuzeichnung) + diagonaler
  Glasglanz-Streifen (rotiertes Gradient-Rectangle, kein Canvas/Shape nötig).
- `widgets/segment/SevenSegment.qml` — eine Ziffer (0-9, Leerzeichen, `-`),
  sieben `ShapePath`-Hexagone mit abgeschrägten Enden (`property real
  digitHeight` skaliert alles, keine absoluten Pixel). Ungelit = `Theme.
  segmentOff` (Geistersegment), gelit = `Theme.segmentOn`.
- `widgets/segment/RollingDigits.qml` — wrapt zwei `SevenSegment` für den
  Rausroll/Reinroll-Effekt beim Ziffernwechsel (`Theme.durBase`,
  `Theme.easeOut`), plus kurzer Opacity-Flicker beim Einrasten
  (`Theme.durFast`). Property `value` (ein Zeichen) setzen, Rest läuft.
- `widgets/segment/SegmentBar.qml` — segmentierter Balken, `value` (0..1),
  `segmentCount`, `critical` (langsames Pulsieren). Segmente füllen sich mit
  `Theme.staggerStep`-Versatz (neu in Theme, 25ms) statt alle gleichzeitig.
- `test/SegmentTestScene.qml` — eigenes `FloatingWindow` mit allen drei
  Widgets nebeneinander (0-9 statisch, Ghost-vs-Lit-Vergleich, eine live
  tickende Uhr aus `RollingDigits` mit echtem `Timer`, vier `SegmentBar`
  inkl. eine kritische). `shell.qml`s `testMode: true` zeigt aktuell dieses
  Fenster statt der echten Bar.

Getestet mit `qs -p .` — lädt sauber, keine Warnungen, mehrfach über 20s
stabil durchlaufen (Timer tickt, Rolling-Digits-Animation und
Critical-Pulse laufen ohne Laufzeitfehler). **Per Screenshot visuell
verifiziert** (siehe unten, "Screenshot machen") — Ziffern, Ghost-Segmente
und Segmentbalken sehen wie erwartet aus.

## Was funktioniert (Etappe 3)

- `widgets/segment/FourteenSegment.qml` — ein 14-Segment-Zeichen, gleicher
  Ansatz wie `SevenSegment` (QtQuick.Shapes-Hexagone statt Font), aber mit
  einer verallgemeinerten `_hexAt(p0, p1, thick)` statt der achsen-only
  `_hexPoints` von SevenSegment, weil die vier Diagonalen (h/j/k/m) beliebige
  Winkel brauchen. **Bewusst nur ein Teilalphabet** definiert —
  `A,B,D,E,F,G,I,J,K,L,M,N,O,P,R,S,T,U,V,Z` plus Ziffern/Leerzeichen/Minus —
  weil das die Vereinigungsmenge der Buchstaben ist, die die deutschen
  Wochentags-/Monatskürzel (`SA`, `MO`, …, `JAN`, `MRZ`, …) tatsächlich
  brauchen. Fehlende Buchstaben (C,H,Q,W,X,Y) bei Bedarf genauso ergänzen:
  Pattern hinzufügen, per Testszene screenshotten, gegenchecken.
- `bar/modules/ClockModule.qml` — `SystemClock` (aus `Quickshell` core,
  `precision: SystemClock.Seconds`, kein Timer/Polling) treibt zwei
  `RollingDigits`-Paare für HH:MM, einen Doppelpunkt aus zwei Kreisen mit
  `Behavior on opacity` (weiches Ein-/Ausblenden im Sekundentakt statt
  harter Sichtbarkeits-Umschaltung), Sekunden klein/tiefgestellt
  (`Config.showSeconds`-gated) und das Datum als `FourteenSegment`-Reihe
  daneben (`Config.clockFormat` schaltet 12h/24h um). Deutsches Kurzformat
  `SA 12 SEP` aus `clock.date.getDay()/getDate()/getMonth()` plus zwei
  Lookup-Arrays (Wochentage/Monate ohne Umlaute, z. B. `MRZ` statt `MÄR`,
  damit sie ins definierte Buchstaben-Subset passen).
- In `Bar.qml` eingebaut (`anchors.centerIn: parent`) und
  `shell.qml`s `testMode` auf `false` — die Digitaluhr läuft jetzt
  produktiv auf jedem Monitor. **Per Screenshot visuell verifiziert**, real
  in der Bar bei Normalgröße (`digitHeight: 20`, Datum `13px`): Uhrzeit,
  Sekunden-Subscript und Datum alle klar lesbar, keine Warnungen.

## Was funktioniert (Etappe 4)

- `MangoIpc.qml` — Singleton (Root-Ebene, gleicher Grund wie Theme/Config),
  1:1 aus `bars/klasic/MangoIpc.qml` übernommen: `mmsg watch all-monitors`
  und `mmsg watch focusing-client` als Dauer-Prozesse mit Auto-Restart nach
  1s falls `mmsg` stirbt, geparst zu `monitors`/`focusedTitle`/
  `focusedAppId`. `viewTag(screenName, index)` dispatcht `viewcrossmon`
  (nicht `view`), damit ein Klick auf einen Tag auf einem nicht-fokussierten
  Monitor trotzdem funktioniert. Struktur gegen echten `mmsg get
  all-monitors`-Output verifiziert (Feldnamen, Nesting).
- `bar/modules/WorkspacesModule.qml` — 9 mango-Tags pro Monitor als kleine
  LCD-Kacheln mit `SevenSegment`-Ziffer (1-9) statt Text. Aktiver Tag:
  `Theme.accent`-Hintergrund; belegter (nicht aktiver) Tag: gedimmte Ziffer
  (`opacity: 0.4`); dringender Tag: pulsierendes `Theme.critical`-Overlay
  als separates Rectangle (nicht als Animation direkt auf der
  `color`-Property der Kachel — siehe Stolperfalle 8 unten). Klick
  dispatcht über `MangoIpc.viewTag`.
- `bar/modules/WindowTitleModule.qml` — Titel des fokussierten Fensters
  pro Monitor (`MangoIpc.monitorFor(outputName).active_client.title`),
  als normaler `Text` statt 14-Segment: Fenstertitel sind beliebige Strings
  in beliebiger Sprache, das Segment-Alphabet deckt nur die für das Datum
  gebrauchte Teilmenge ab (siehe `FourteenSegment.qml`) — ein volles
  Glyphen-Set nur dafür zu bauen wäre exakt das "36-Zeichen blind bauen"-
  Risiko, das in Etappe 2 schon verworfen wurde. Scrollt (Marquee, Pause-
  Scroll-Pause-Scroll) nur wenn der Titel breiter ist als der verfügbare
  Platz.
- `SevenSegment.qml` um `onColor`/`offColor`-Properties erweitert (default
  weiterhin `Theme.segmentOn`/`Theme.segmentOff`, für alle bestehenden
  Verwender unverändert) — nötig, weil eine Ziffer auf `Theme.accent`-
  Hintergrund mit der Standard-Segmentfarbe kaum noch lesbar war (beide aus
  dem gleichen Akzent-Farbton abgeleitet); `WorkspacesModule` nutzt für den
  aktiven Tag `Theme.accentInk` statt `Theme.segmentOn`. Gefunden und
  gefixt per Screenshot-Vergleich (siehe "Screenshot machen").
- In `Bar.qml` eingebaut: Workspaces links, Fenstertitel füllt die Lücke
  bis zur zentrierten Uhr. **Per `mmsg get all-monitors` verifiziert**, dass
  die echte Bar korrekt als Layer-Surface existiert
  (`last_open_surface: "fisheye-bar"`) — sie war beim Testen zeitweise
  nicht auf dem Screenshot sichtbar, weil der gerade fokussierte Client
  (`is_fullscreen: true`) sie überdeckt hat, nicht wegen eines Fehlers in
  fisheye selbst (jeder wlroots-Compositor legt einen echten Fullscreen-
  Client über Top-Layer-Shell-Flächen). Bei künftigen Screenshot-Checks:
  vorher per `mmsg get focusing-client` `is_fullscreen` prüfen, bevor man
  eine leere Bar als Bug interpretiert.

## Was funktioniert (Etappe 5)

Alle sieben rechten Statusmodule, jedes einzeln per `mmsg`/Live-Screenshot
oder direkte Systemabfrage gegen echte Daten verifiziert (siehe
`test/StatusModulesTestScene.qml`):

- `bar/modules/VolumeModule.qml` — `Pipewire.defaultAudioSink`, `SegmentBar`
  für den Pegel, Mute als zwei gekreuzte Rectangles statt Icon-Font. Klick
  = Mute-Toggle, Scroll = ±5% Lautstärke.
- `bar/modules/NetworkModule.qml` — Verbindungsstatus als `SegmentBar`.
  **Kabelgebunden hat Vorrang vor Wi-Fi**: dieser Rechner ist ein Desktop
  an Ethernet (`eno1`) mit einer ungenutzten, getrennten Wi-Fi-Karte
  (`wlp9s0`) — ein erster Entwurf, der nur `DeviceType.Wifi` prüfte, zeigte
  deshalb dauerhaft "kein Signal" trotz aktiver Verbindung. Gefixt: erst
  `DeviceType.Wired`-Gerät auf `connected` prüfen (volle Bar, kabelgebunden
  kennt keine Signalstärke), erst danach Wi-Fi-`signalStrength` als
  Fallback. Kein Klick-Handler (Netz an/aus gehört in Etappe 6, nicht in
  einen versehentlichen Bar-Klick).
- `bar/modules/BluetoothModule.qml` — LCD-Kachel wie ein Workspace-Tag:
  `Bluetooth.defaultAdapter.enabled` fürs Lit/Unlit, `SevenSegment`-Ziffer
  für die Zahl verbundener Geräte. Blendet sich komplett aus, wenn kein
  Adapter da ist (`Bluetooth.defaultAdapter` ist `null`, siehe
  System-Fakten unten zu `bluetooth.service`).
- `bar/modules/BatteryModule.qml` — `UPower.displayDevice`, `SegmentBar`
  für den Ladestand, kritisches Pulsieren unter 15% beim Entladen.
  Blendet sich komplett aus ohne Laptop-Akku (dieser Rechner hat keinen,
  siehe System-Fakten unten zu `upower.service` — Lade-Optik ungetestet,
  vor Vertrauen auf echter Laptop-Hardware nachprüfen).
- `bar/modules/MediaModule.qml` — `Mpris.players`, gezeichnetes
  Play/Pause-Icon (zwei Balken bzw. ein `Shape`-Dreieck, kein Font) +
  Titel als eingekürzter `Text`. Klick = Play/Pause, Scroll = Prev/Next.
  Blendet sich komplett aus ohne aktiven Player.
- `bar/modules/TrayModule.qml` — 1:1 das bewährte Muster aus
  `bars/fullshell/Tray.qml`/`bars/shellbar/Tray.qml`: `SystemTray.items`
  als `Image` (echte Icon-Pixeldaten vom Client, kein Font — die einzige
  legitime Ausnahme von der Segment-Regel). Rechtsklick öffnet das
  Client-eigene Kontextmenü über `.display(hostWindow, x, y)`.
- `bar/modules/PowerButton.qml` — reines Icon, aus Rectangles komponiert
  (Ring + Kerbe + Strich), Klick bewusst No-op bis Etappe 6 eine
  Bestätigung dafür hat.
- `SevenSegment.qml` um `onColor`/`offColor`-Properties erweitert (siehe
  Etappe-4-Eintrag oben) — `BluetoothModule` nutzt das genauso wie
  `WorkspacesModule` für den aktiven Zustand.
- Alle sieben rechts in `Bar.qml` in einer `Row` (`anchors.right`),
  Reihenfolge Media → Tray → Netzwerk → Bluetooth → Volume → Akku → Power.

**Zwei bekannte, umgebungsbedingte Konsolen-Warnungen** — bewusste
Ausnahme von der sonst geltenden "warnungsfrei laden"-Regel, siehe
System-Fakten unten:
```
WARN quickshell.dbus.objectmanager: Failed to create DBusObjectManagerInterface for "org.bluez" "/"
WARN quickshell.dbus: Could not launch service org.freedesktop.UPower: ... ServiceUnknown
WARN quickshell.service.upower: Could not start UPower. The UPower service will not work.
```
Beide kommen direkt aus Quickshells eigenem Service-Plugin beim
Instanziieren der `Bluetooth`-/`UPower`-Singletons, nicht aus fisheye-Code
— auf diesem Rechner existieren `bluetooth.service` und `upower.service`
schlicht nicht (`systemctl status` bestätigt "could not be found"). Beide
Module fangen das ab und blenden sich sauber aus (`defaultAdapter`/
`displayDevice` sind dann `null`) statt zu crashen. Auf einem System mit
aktivem `bluetoothd`/`upowerd` sollten diese zwei Zeilen verschwinden — bei
Gelegenheit dort nachtesten, aber nicht auf diesem Rechner als Bug
behandeln.

## Was funktioniert (Etappe 6)

**Welches zweite Menü** (neben dem ohnehin feststehenden Power-Menü) war
aus dieser README/dem sichtbaren Originalauftrag-Auszug allein nicht
eindeutig — beim Nutzer nachgefragt, Antwort: **Sound-Mixer für
`VolumeModule`** (nicht Netzwerkliste). Falls der tatsächliche
Original-Auftrag etwas anderes vorsah, zählt trotzdem diese Nutzer-
Entscheidung als das, was gebaut werden sollte.

- `widgets/common/PopupShell.qml` — gemeinsame Popup-Hülle, wiederverwendet
  vom bewährten Reparenting-Trick aus `bars/shellbar/LiquidMenu.qml`:
  ein Popup meldet sich per `parent: root.overlay` auf einen gemeinsamen
  Overlay-Layer um, damit es über die schmale Bar-Leiste hinauswachsen
  kann, statt vom Row-Layout seines Triggers abgeschnitten zu werden.
  Deutlich einfacher als das Original (kein Multi-Edge-Fillet-SVG, fisheye
  hat nur eine Bar-Kante) — Position per `anchorItem.mapToItem(overlay,
  ...)`, Höhe animiert über `Behavior on height`, Inhalt über `default
  property alias content: contentArea.data`.
- `bar/Bar.qml` reserviert weiterhin nur `Theme.barHeight` als
  `exclusiveZone`, ist aber selbst höher (`+ popupMaxHeight`) — der
  ungenutzte Rest ist Teil der echten Wayland-Surface, aber nicht vom
  Compositor reserviert, also können andere Fenster den Platz normal
  nutzen, solange kein Popup offen ist (gleiche Technik wie
  `bars/shellbar/Bar.qml`). Dafür in einen `stripLayer` (die sichtbare
  Leiste, oben angepinnt, `Theme.barHeight` hoch) und einen `popupLayer`
  (volle Fensterhöhe, Overlay für die Popups) aufgeteilt.
  Klick-außerhalb-schließt: eine `MouseArea`, die das volle Fenster deckt,
  aber nur sichtbar/aktiv ist während `bar.openPopup !== ""`.
- `menus/PowerMenu.qml` — Sperren/Abmelden/Neustart/Herunterfahren, Aktionen
  1:1 aus `bars/fullshell/PowerTab.qml` übernommen (auf diesem Compositor
  bereits verifiziert): `swaylock`, `mmsg dispatch quit` (mangos eigenes
  IPC-Kommando fürs Abmelden, nicht `loginctl`), `systemctl reboot`/
  `poweroff`. Neustart/Herunterfahren fragen erst inline "SICHER?" mit
  JA/NEIN nach (4s Timeout, fällt automatisch zurück), Sperren/Abmelden
  laufen sofort. `PowerButton.qml` emittiert dafür nur noch `clicked` statt
  No-op — Bar.qml besitzt den Popup-Zustand, ein einzelner Klick auf das
  Icon kann also nie mehr direkt etwas Destruktives auslösen.
- `menus/SoundMixerMenu.qml` — Master-Lautstärke + Pro-App-Mixer
  (`Pipewire.nodes`, gleicher Stream-Filter wie
  `bars/shellbar/SettingsMenu.qml`s bewährter `soundTabComponent`).
  Regler sind `widgets/common/SegmentSlider.qml` (neu: `SegmentBar` +
  Drag-`MouseArea`) statt einer glatten Progress-Fill, damit sie optisch
  zu jedem anderen Pegel-Widget in der Bar passen; Prozentzahl daneben als
  `SevenSegment`-Ziffern statt Text. `VolumeModule.qml` dafür umgebaut:
  Linksklick öffnet jetzt den Mixer (`clicked`-Signal), Mute ist auf
  Mittelklick gewandert — exakt der Split, den `fullshell`/`quickbar` an
  anderer Stelle im System schon nutzen.
- Beide Popups per Screenshot visuell verifiziert (isoliert in
  `test/MenuTestScene.qml`). Kein `wlrctl`/`ydotool`/`wtype` im System, also
  keine echte Klick-Simulation möglich — stattdessen den Öffnen- bzw.
  Bestätigen-Zustand kurzzeitig über die jeweilige `property bool`
  (`win.openPopup`, `confirming`) direkt im Code erzwungen, gescreenshottet,
  danach wieder auf den echten Default zurückgesetzt. Sound-Mixer zeigte
  live echte Pipewire-Streams (`Sober`, `WEBRTC Voi…`, sauber elidiert).

## Was funktioniert (Etappe 7)

- `widgets/watch/AnalogClock.qml` — das Zifferblatt: `Rectangle{radius:
  width/2}` fürs runde Gehäuse, ein zweifarbiger Bezel-Ring (hell/dunkel,
  gleiche Bevel-Farben wie `BevelPanel`) aus zwei `Shape`/`ShapePath`/
  `PathAngleArc`-Halbkreisen, zwölf Stundenticks (per Trigonometrie
  positioniert statt `Repeater`+`transformOrigin`, siehe Code-Kommentar),
  drei per `rotation` gedrehte `Rectangle`-Zeiger (Stunde/Minute/Sekunde,
  aus `SystemClock` wie `ClockModule`) und ein `Canvas` mit gebogenem
  Ringtext ("QUARTZ", entlang des unteren Bogens, jedes Zeichen einzeln
  tangential rotiert) — die einzige bewusste Canvas-Text-Ausnahme laut
  Konventionen-Abschnitt. Sekundenzeiger tickt hart pro Sekunde statt zu
  gleiten (kein `Behavior on rotation` auf den Zeigern: der Wraparound
  354°→0° einmal pro Minute/Stunde würde sonst einen vollen Rückwärts-Sweep
  animieren, verwandt mit Stolperfalle 7 unten).
- `menus/ClockMenu.qml` — reines Anzeige-Popup ohne Interaktion (anders als
  Power/Sound-Mixer), zeigt nur `AnalogClock` zentriert.
- `bar/modules/ClockModule.qml` bekam ein `signal clicked()` + `MouseArea`
  (gleicher Split wie `VolumeModule`); `Bar.qml` verdrahtet ein drittes
  `openPopup`-Value `"clock"` mit eigener `PopupShell`.
- **Gefundener und gefixter Bug, der auch Power/Sound-Mixer betraf:**
  `PopupShell`s Positionierung (`_anchor`, per `Item.mapToItem()`) fror auf
  den Zustand beim allerersten Binding-Evaluierungslauf ein (alle Anker-Items
  noch bei Breite/Position ~0, bevor Layout/Wayland-Configure durch sind) und
  aktualisierte sich danach **nie wieder** — `mapToItem()` liest die Geometrie
  des Zielitems intern über einen C++-Aufruf, den QMLs Bindungs-Engine nicht
  als Abhängigkeit mitschneidet. Unbemerkt seit Etappe 6, weil dort nur in
  einer `FloatingWindow`-Testszene gescreenshottet wurde (Layout dort schon
  beim ersten Bindungslauf synchron fertig) — in der echten `PanelWindow`
  (wartet auf den asynchronen Wayland-Configure fürs richtige `width`)
  reproduzierbar als alle drei Popups fest bei `x:9` (Theme.gap), egal wo ihr
  Anker-Item tatsächlich sitzt. Gefunden per `console.log` in `onXChanged`
  (zeigte `overlayWidth=0` beim einzigen Log-Treffer). Fix in
  `widgets/common/PopupShell.qml`: eine zusätzliche `_anchorDep`-Property,
  die Anker- und Overlay-Geometrie direkt liest (echte QML-Property-Reads,
  keine `mapToItem`-Interna) und im `_anchor`-Binding referenziert wird, rein
  um dessen Neuberechnung zu erzwingen, sobald echte Zahlen da sind. Nach dem
  Fix per `console.log` verifiziert: alle drei Popups springen von `x:9`
  (Startzustand) auf ihre tatsächlich korrekte Position (`x:1200`/`2311`/
  `2381`), sobald `overlayWidth` von `0` auf `2560` wechselt. Volle Details:
  `feedback_qml_maptoitem_non_reactive.md` in memory.
- Screenshot-verifiziert sowohl isoliert (`test/MenuTestScene.qml`, dort
  mit auf `650` verbreiterter `implicitWidth` fürs dritte Popup) als auch
  **in der echten produktiven `PanelWindow`-Bar** — Etappe 6 hatte nur
  ersteres gemacht, was den obigen Bug verdeckt hatte; ab jetzt beides
  prüfen, nicht nur die Testszene.

## Was funktioniert (Etappe 8)

**Welche Module noch ein Menü brauchen** war wieder nicht eindeutig aus dem
sichtbaren Originalauftrag-Auszug ableitbar — beim Nutzer nachgefragt,
Antwort: **nur Network + Bluetooth** (nicht auch Battery/Media). Begründung
in der Nutzer-Antwort selbst: `NetworkModule.qml`s eigener Code-Kommentar
hatte das seit Etappe 5 bereits explizit als offenen Punkt markiert ("Read-
only status display -- no click-to-toggle, that belongs in \[a later
stage\]'s popup"), Bluetooth passt zum gleichen Muster (Geräteliste,
Verbinden/Trennen) — Battery/Media funktionieren dagegen schon als reine
Inline-Anzeige/-Steuerung.

- `widgets/common/ToggleSwitch.qml` — neuer gemeinsamer An/Aus-Schalter
  (Pille + Knopf, `checked`/`toggled(bool)` nach dem gleichen Muster wie
  `SegmentSlider`s `value`/`moved`: der Aufrufer besitzt den Zustand, das
  Widget schlägt nur eine Änderung vor). Von beiden neuen Menüs benutzt
  (Wi-Fi-Enable, Bluetooth-Adapter-Enable) — deshalb als eigene Datei
  gerechtfertigt statt dupliziert.
- `menus/NetworkMenu.qml` — Kabelstatus (nur Anzeige, ein Kabel steckt oder
  steckt nicht), Wi-Fi-Enable-Toggle, sortierte Netzwerkliste
  (`WifiDevice.networks`, `SegmentBar` fürs Signal). Klick auf einen Eintrag:
  verbunden → trennen, bekannt/offen → verbinden, unbekannt+gesichert → klappt
  eine Passwort-Zeile darunter auf (gleicher Inline-Zweitzustand-Trick wie
  PowerMenus "SICHER?"-Bestätigung, statt eines nativen Dialogs, den
  Quickshell nicht hat) und ruft `connectWithPsk()`.
- `menus/BluetoothMenu.qml` — Adapter-Enable-Toggle + Geräteliste
  (`BluetoothAdapter.devices`, `SegmentBar` fürs Akkulevel wo verfügbar).
  Klick: verbunden → trennen, gekoppelt → verbinden, neu → `pair()`. Auf
  diesem Rechner ohne `bluetooth.service` bleibt `defaultAdapter` `null` —
  nur der "KEIN ADAPTER"-Zustand ist hier tatsächlich screenshot-verifiziert,
  die Geräteliste selbst ist nur strukturell geprüft (gleiche Einschränkung
  wie `BatteryModule`s Lade-Optik seit Etappe 5).
- `NetworkModule.qml`/`BluetoothModule.qml` bekamen je ein `signal
  clicked()` + `MouseArea` (gleicher Split wie `VolumeModule`/`ClockModule`);
  `Bar.qml` verdrahtet zwei weitere `openPopup`-Werte (`"network"`,
  `"bluetooth"`).
- Screenshot-verifiziert sowohl isoliert (`test/MenuTestScene.qml`, jetzt
  fünf Spalten, `implicitWidth` auf `950` verbreitert) als auch in der
  echten `PanelWindow`-Bar (Lehre aus Etappe 7 direkt angewendet: beides
  prüfen, nicht nur die Testszene) — beide Popups erscheinen korrekt unter
  ihrem jeweiligen Modul, dank des in Etappe 7 gefixten `PopupShell`-Bugs.
- **Eigener kleiner Stolperfall beim Bauen:** `ToggleSwitch.qml` bekam beim
  ersten Entwurf `import ".."` statt `import "../.."` und scheiterte mit
  `module ".." is not installed` — `widgets/common/` liegt zwei Ebenen
  unter dem `fisheye/`-Root, nicht eine, wie jede andere Datei in diesem
  Ordner (`BevelPanel.qml`, `LcdSurface.qml`, `PopupShell.qml`,
  `SegmentSlider.qml`) bereits vorher richtig macht. Kein neues Problem,
  nur ein Abtipp-Fehler gegen Stolperfalle 1 oben — beim nächsten neuen
  File in `widgets/common/` (oder tiefer) die Hop-Anzahl an einer
  bestehenden Nachbardatei gegenchecken, nicht aus dem Gedächtnis tippen.

## Was funktioniert (Etappe 9)

**Welches konkrete Verhalten für Boot-Selbsttest/Idle-Glanz/Performance-
Messung** war aus dem sichtbaren Originalauftrag-Auszug nicht eindeutig
ableitbar (nur die Namen der drei Teile standen fest) — beim Nutzer
nachgefragt, Antworten: **LCD-Selbsttest-Wisch** (alle Segmente aller
Widgets leuchten kurz komplett auf, kein sequentielles Modul-Einblenden),
**periodischer Glanz-Sweep** (regelmäßig, nicht an echte Inaktivität
gekoppelt) und **internes Debug-Overlay** (kein reiner Messlauf-Eintrag im
README).

- `Boot.qml` — neuer Root-Singleton (gleicher Grund wie Theme/Config: jede
  Datei, die bereits `import ".."`/`import "../.."` zu Theme macht, sieht
  ihn automatisch mit, kein separater Import nötig). Ein `selfTest`-Flag,
  startet `true` (gebunden an `Config.bootSequence`), fällt einmalig nach
  `Theme.durBoot` (1150ms) auf `false` — danach bleibt es aus, auch wenn
  `Config.bootSequence` sich später live ändert (die imperative Zuweisung im
  `Timer.onTriggered` ersetzt die anfängliche Bindung, gewollt: kein
  erneuter Wisch mitten in der Session). **Eigener kleiner Stolperfall:**
  ein nackter `Timer {}` direkt als Kind eines `QtObject` scheiterte mit
  `Cannot assign to non-existent default property` — `QtObject` hat kein
  Default-Property, exakt das in `feedback_qml_qtobject_no_default_
  property.md` dokumentierte Muster. Fix: `property Timer _wipeTimer: Timer
  {...}` statt eines bloßen Kind-Elements.
- `SevenSegment.qml`/`FourteenSegment.qml`: `isLit(id)` gibt jetzt
  `Boot.selfTest || <normales Pattern>` zurück — jedes Segment jeder Ziffer/
  jedes Buchstabens rendert während des Selbsttests voll gelit, unabhängig
  vom tatsächlichen `char`. `SegmentBar.qml`s Füllstands-Rechtecke ebenso
  (`(Boot.selfTest || displayLit) ? Theme.segmentOn : Theme.segmentOff`) —
  damit leuchten auch Lautstärke-/Netzwerk-/Akku-Balken beim Wisch komplett.
  Kein Widget musste selbst etwas über Boot wissen außer diesen drei
  gemeinsamen Bausteinen, jeder Verwender (Uhr, Workspaces, Statusmodule)
  bekommt den Effekt automatisch mit.
- `widgets/common/LcdSurface.qml`: zweites, schmaleres/helleres Highlight-
  `Rectangle` neben dem seit Etappe 1 immer sichtbaren statischen Glasglanz
  — läuft alle `Theme.idleGlintInterval` (45s) einmal quer über die Fläche
  (`Theme.durIdle`, 6s, `Theme.easeInOut`), ruht davor/danach komplett
  außerhalb der Fläche (`x: -width`), kostet also im Ruhezustand nichts.
  `Theme.durIdle` trug schon seit Etappe 1 den Kommentar "idle bevel glint
  cycle" — dafür war die Property offensichtlich schon vorgesehen, nur der
  fehlende Intervall-Wert (`idleGlintInterval`, neu in Theme.qml) musste
  noch ergänzt werden. Deaktiviert sich vollständig bei
  `Theme.reducedMotion` (Loop-`running` direkt daran gebunden, nicht nur
  über die übliche Dauer-auf-0-Kollabierung).
- `bar/modules/DebugModule.qml` — neues Modul, FPS über QtQuick-eigenes
  `FrameAnimation` (`smoothFrameTime`, geglätteter Mittelwert, keine eigene
  Timestamp-Buchhaltung nötig — Property gegen die echten `.qmltypes` unter
  `/nix/store/*qtdeclarative-6.11.1/lib/qt-6/qml/QtQuick/plugins.qmltypes`
  verifiziert, nicht aus dem Gedächtnis geraten), als drei `SevenSegment`-
  Ziffern statt Text gerendert (gleiche No-Font-Regel wie überall sonst).
  Läuft nur, wenn sichtbar (`FrameAnimation.running: root.visible`), damit
  es im Normalfall keine Kosten verursacht. Opt-in über neues
  `Config.debugOverlay` (Default `false`, live-reloadbar wie jedes andere
  Config-Feld) — bewusst kein Eintrag in `moduleOrder`/`visibleModules`,
  weil es ein reines Entwicklerwerkzeug ist, kein Modul, das ein Nutzer in
  der normalen Bar umsortiert.
- In `Bar.qml` eingebaut: `DebugModule` als erstes Element der rechten Row
  (unsichtbar/keine Layoutbreite, solange `Config.debugOverlay` `false`
  ist — `Row` überspringt `visible: false`-Kinder bei der Positionierung).
- **Screenshot-verifiziert** (siehe "Screenshot machen"): Boot-Wisch zeigt
  alle Workspace-Kacheln als `8`, Uhr als `88:88`, alle Statusbalken voll
  gefüllt kurz nach dem Start, danach sauberer Übergang zu echten Werten
  (Workspace 1 aktiv, echte Uhrzeit/Datum, echte Statusicons). Debug-Overlay
  zeigt eine plausible dreistellige FPS-Zahl (`82`/`83`) rechts vor der
  Tray. Idle-Glanz-Sweep mechanisch bestätigt: `idleGlintInterval` und die
  Gradient-Farbe kurzzeitig auf einen auffälligen Testwert (`800`/`"red"`)
  gesetzt, zwei Screenshots ~2s auseinander zeigen den Streifen klar an
  unterschiedlicher x-Position (siehe zweiter Screenshot: roter Streifen bei
  ~85% Bar-Breite) — danach beide Testwerte sofort auf die echten
  (`45000`/`Theme.glassTint`) zurückgesetzt, per erneutem warnungsfreiem
  Lauf nachgeprüft. Alle drei Testläufe (normal, 30s-Stabilität, Debug/
  Glint-Testwerte) liefen ohne Konsolen-Warnung außer den zwei bekannten
  umgebungsbedingten (bluez/upower, siehe System-Fakten), kein Zombie-
  Prozess nach irgendeinem Lauf übrig.

## Was funktioniert (Nachtrag: App-Launcher)

Nicht Teil des ursprünglichen 9-Etappen-Auftrags, auf Nutzerwunsch
nachgebaut ("passender App-Launcher, selbes Theme, schöne Animationen"):

- `AppEntries.qml` — Root-Singleton (gleicher Grund wie Theme/Config/
  MangoIpc), scannt `.desktop`-Dateien über alle `XDG_DATA_DIRS` plus
  `~/.local/share/applications` mit einem einzelnen `sh`-Pass (jede Datei
  hinter einem Marker verkettet, ein Parse-Durchlauf). Bewusst kein
  Wrapper um den eingebauten `Quickshell.DesktopEntries`-Singleton, weil
  dieses Repo bereits zwei zueinander inkompatible Vorstellungen von dessen
  Form hat (`bars/quickbar` erwartet `.apps`/`.ready`, `bars/shellbar`
  `.applications.values`) — nicht stabil genug, um dagegen zu bauen.
  **Musste umbenannt werden** von `DesktopEntries.qml` zu `AppEntries.qml`,
  siehe Stolperfalle 11 unten.
- `bar/modules/LauncherButton.qml` — 2×2-Raster aus vier kleinen LEDs
  (gleiches Prinzip wie `WorkspacesModule`s Tag-Kacheln), keine Schrift.
  Hover lässt die LEDs nacheinander aufleuchten (`Theme.staggerStep`-Verzug
  pro LED, wie schon `SegmentBar`/`WorkspacesModule`), Klick löst einen
  kurzen Scale-Press aus. Ganz links in der Bar, vor `WorkspacesModule`.
- `menus/LauncherMenu.qml` — Suchfeld + Live-gefilterte Ergebnisliste.
  Namen sind beliebige Strings (jede Sprache, jede App) → `Text`, nicht
  `FourteenSegment`, gleiche Begründung wie `WindowTitleModule`. Icons über
  `Quickshell.iconPath`/`hasThemeIcon` (fehlendes Icon → leerer Slot statt
  kaputtem Bild). Jede Listenzeile blendet gestaffelt ein (gleicher
  `staggerStep`-Trick), Auswahl per Maus-Hover oder Pfeiltasten/Enter,
  Escape/Klick-daneben schließt. `active`-Property (von `Bar.qml` an
  `bar.openPopup === "launcher"` gebunden) statt eigenem Open-State, damit
  Feld-Reset/Fokus exakt beim Öffnen passiert, nicht bei jedem Tastendruck.
- In `Bar.qml` eingehängt: `popupMaxHeight` von 220 auf 260 angehoben
  (Launcher-Popup ist mit Suchfeld + 8 Zeilen höher als die anderen Menüs),
  eigener `PopupShell`-Eintrag wie bei jedem anderen Modul. **Per
  Live-Screenshot verifiziert** (siehe "Screenshot machen") — LED-Raster
  sitzt korrekt links neben den Workspace-Kacheln, gleiche LCD-Optik.

## Was funktioniert (Nachtrag: Launcher-Hotkey + Input-Mask-Fix)

Zwei Dinge auf einmal nachgetragen, weil der Nutzer beim Testen des
Launchers einen echten, vorbestehenden Bug meldete ("im oberen Bereich des
Bildschirms werden keine Klicks registriert, z. B. keine Tabs in Brave
öffnen"):

- **Bug gefunden und gefixt**: `bar.qml`s `PanelWindow` ist absichtlich
  höher (`Theme.barHeight + popupMaxHeight`, jetzt 298px) als die sichtbare
  Bar-Leiste (`exclusiveZone: Theme.barHeight`), damit Popups darunter Platz
  zum Aufklappen haben (siehe Etappe-6-Notiz). Ohne explizite `mask`-Property
  nimmt eine Layer-Shell-Surface aber **über ihre gesamte Fenstergeometrie**
  Zeigereingaben entgegen, nicht nur dort, wo tatsächlich etwas gezeichnet
  wird — jeder Klick irgendwo in diesem ~260px hohen, bildschirmbreiten Band
  wurde von diesem (unsichtbaren, transparenten) Fenster verschluckt statt an
  das Fenster darunter durchgereicht zu werden, und zwar **auch mit
  geschlossenen Popups**. Fix: `mask: Region { Region { item: ... } ... }`
  auf dem `PanelWindow`, mit je einer `Region` pro echtem Klick-Ziel
  (`stripLayer`, jedes `PopupShell` einzeln, der Klick-daneben-Fänger) —
  jedes dieser Items kollabiert bereits selbst auf Höhe 0, wenn es inaktiv
  ist (`PopupShell` tut das schon für `open: false`; der
  Klick-daneben-`MouseArea` bekam dafür extra eine echte `height`-Bindung
  statt nur `visible`, weil `visible` allein die Item-Geometrie nicht
  schrumpft und der Mask-Fix sonst wirkungslos gewesen wäre). Gleiches
  Prinzip wie `bars/shellbar`s eigene `mask: Region { Region { item:
  hitArea } ... }`-Lösung, nur dort schon von Anfang an vorhanden.
- `MangoIpc.qml` — neue `focusedMonitorName`-Property (aus dem `active`-Feld
  von `mmsg get all-monitors` pro Monitor), damit ein globaler IPC-Trigger
  weiß, auf welchem Screen er tatsächlich etwas öffnen soll.
- `LauncherState.qml` — neues Root-Singleton, reine Signal-Pulse
  (`togglePulse`/`openPulse`/`closePulse`) statt eines geteilten Bools: es
  gibt eine `Bar`-Instanz pro Screen (`Variants` in `shell.qml`), jede mit
  eigenem lokalem `openPopup` — ein einzelner Bool hätte nicht ausgedrückt,
  *welcher* Screen gemeint ist. Jede `Bar` hört per `Connections` auf den
  Puls, reagiert aber nur, wenn `bar.outputName === MangoIpc.
  focusedMonitorName` — Öffnen/Schließen passiert also nur auf dem gerade
  fokussierten Monitor, nicht auf allen gleichzeitig.
- `shell.qml` — `IpcHandler { target: "launcher" }` (`toggle`/`open`/
  `close`), ruft nur `LauncherState` auf. Gleiches Muster wie
  `quickdots/menu/shell.qml`s eigener `launcher`-Handler.
- **mango-Keybind umgebogen**: `bind=SUPER,space,...` zeigte bisher auf
  `quickdots/menu/scripts/toggle-launcher.sh` (das generische, themenfremde
  Such-Popup von `quickdots/menu` — `menu`s Adapter-System kennt `fisheye`
  gar nicht, hätte also nie an dessen eigenen Launcher übergeben). Jetzt
  direkt `qs -p ~/quickdots/bars/fisheye ipc call launcher
  toggle`, gleiche Inline-Schreibweise wie `shellwall`s Coverflow-Bind in
  derselben `config.conf`. **Per Live-Test verifiziert**: `qs -p .`-Instanz
  gestartet, `qs -p . ipc call launcher toggle` von außen aufgerufen,
  Screenshot zeigt das Launcher-Popup korrekt geöffnet mit LCD-Optik.
  Danach den echten Produktions-Prozess (`qs -p .../fisheye -n`) neu
  gestartet, damit Hotkey + Mask-Fix auch live tatsächlich greifen (der lief
  vorher noch mit dem alten Code).

## Was funktioniert (Nachtrag: Escape schließt jedes Menü)

Auf Nutzerwunsch ("alle Menüs mit Escape schließen können nachrüsten").
Zwei Teile, wieder aus demselben Grund wie der Hotkey-Nachtrag: ohne den
ersten Teil hätte der zweite nie etwas bewirkt.

- **`Bar.qml`s `WlrLayershell.keyboardFocus` war fest auf `None`** — seit
  Etappe 1 unverändert. `None` heißt bei wlr-layer-shell nicht nur "kein
  Autofokus", sondern **"dieses Surface bekommt niemals Tastatureingaben,
  Punkt"** — der Compositor liefert gar keine Taste an dieses Fenster,
  völlig unabhängig davon, was in der QML-Szene gerade `focus: true` trägt
  oder `forceActiveFocus()` aufgerufen hat. Damit war nicht nur Escape tot,
  sondern z. B. auch Tippen in `LauncherMenu`s Suchfeld oder in
  `NetworkMenu`s PSK-Feld (dessen `Keys.onReturnPressed` existierte zwar
  schon, konnte aber genauso wenig je feuern). Fix: `keyboardFocus: bar.
  openPopup !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None` —
  `OnDemand`, nicht `Exclusive`, damit ein offen gelassenes Menü nicht der
  gesamten Session die Tastatur wegschnappt (`quickdots/menu` nutzt an der
  analogen Stelle `Exclusive`, aber dort ist das Popup ein zentriertes,
  bewusst modales Fenster — hier sind es schmale Dropdown-Menüs, für die
  das too much wäre).
- **`widgets/common/PopupShell.qml`** bekam ein generisches `signal
  closeRequested()` + `Keys.onEscapePressed: root.closeRequested()` +
  `onOpenChanged: if (open) root.forceActiveFocus()` — deckt Power/
  Sound-Mixer/Analoguhr/Netzwerk/Bluetooth ab, die alle kein eigenes
  fokussiertes Eingabefeld haben. `LauncherMenu` behält seinen eigenen
  Escape-Pfad (Suchfeld ruft selbst `forceActiveFocus()` in seinem
  `onActiveChanged` auf, das nach `PopupShell`s eigenem Aufruf für dieselbe
  `open`-Änderung läuft, weil es als Kind-Element später instanziiert wird —
  gewinnt also zuverlässig; PopupShells `Keys.onEscapePressed` feuert dort
  einfach nie, weil das Fokus auf dem Suchfeld liegt). Für `NetworkMenu`s
  PSK-Feld (das Escape selbst nicht behandelt) reicht das unbehandelte
  Escape automatisch an `PopupShell`s Handler weiter hoch — exakt dasselbe
  Bubble-Prinzip, das `quickdots/menu/shell.qml`s eigener Kommentar zum
  Tab-fokussierten Menü schon beschreibt ("unhandled key events bubble up
  from the focused child").
  In `Bar.qml`: `onCloseRequested: bar.openPopup = ""` an jeder der sechs
  `PopupShell`-Instanzen.
- **Nicht per echtem Tastendruck end-to-end testbar** in dieser Umgebung
  (kein `wtype`/`ydotool` verfügbar, um synthetische Tastenevents an mango
  zu schicken) — nur per mehrfachem Öffnen/Schließen des Launchers über die
  IPC-Bridge verifiziert, dass die neue `keyboardFocus`-Bindung, `mask` und
  `PopupShell`s neue Signal-Verdrahtung sauber laufen (keine
  QML-Warnungen/-Fehler über mehrere Zyklen). Bei Gelegenheit real mit der
  Tastatur gegenprüfen.

## Was funktioniert (Nachtrag: Launcher bekommt eigenes Fenster)

Der vorige Nachtrag ("Escape schließt jedes Menü") hatte `keyboardFocus` an
`bar.openPopup !== ""` gebunden und lief ohne QML-Fehler durch mehrere
IPC-Zyklen — wurde aber nie mit einem echten Tastendruck gegengeprüft (siehe
dessen letzter Punkt). Der Nutzer meldete danach: Tippen im Launcher-Suchfeld
tut nichts, Escape schließt ihn nicht. Ursache tiefer als der letzte Fix,
verifiziert direkt im mango-Quellcode (`/nix/store/*-source/src/`, Version
0.16.1 — nicht geraten):

- `manage/layer.h`s `focuslayer()` wird nur an **zwei** Stellen aufgerufen:
  einmal beim allerersten Commit eines Surfaces überhaupt
  (`commitlayersurfacenotify`, nur im `initial_commit`-Zweig, läuft genau
  einmal pro Surface-Leben), und einmal in `input/pointer.h`s
  Button-Press-Handler — aber nur, wenn `layer_surface->current.
  keyboard_interactive` in **genau diesem Moment** bereits `ON_DEMAND` ist.
  Ein späterer Commit (z. B. weil eine QML-Property sich ändert) triggert
  **keinen** erneuten Fokus-Grant von sich aus.
- `Bar.qml`s Surface wird einmal beim Bar-Start gemappt und lebt seither
  dauerhaft. Der Klick, der `bar.openPopup = "launcher"` setzt, wird von
  mango **verarbeitet, bevor** die QML-Property-Änderung zu einem neuen
  Commit führt — zum Zeitpunkt, den mangos Pointer-Handler prüft, steht
  `keyboard_interactive` noch auf `None`. Der öffnende Klick bekommt also nie
  Fokus, egal wie die Property gebunden ist.
- Der `SUPER+space`-Hotkey (`LauncherState`-Pulse über `mmsg`/`IpcHandler`,
  kein Pointer-Event beteiligt) kann **grundsätzlich nie** über den
  Pointer-Pfad fokussiert werden — es gibt keinen Klick, den mango dafür
  auswerten könnte.
- Fix: `bar/LauncherWindow.qml`, ein eigenes `PanelWindow` (eigene
  Layer-Shell-Surface), das `Bar.qml`s `Loader { active: bar.openPopup ===
  "launcher" }` bei jedem Öffnen frisch instanziiert und beim Schließen
  wieder zerstört — statt wie die anderen fünf Menüs dauerhaft als
  `PopupShell`-Item im Bar-Fenster zu leben. `WlrLayershell.keyboardFocus`
  steht dort fest auf `OnDemand`; eine frische Surface bekommt ihren
  Fokus-Grant über den `initial_commit`-Pfad, **unabhängig davon, ob** per
  Klick oder Hotkey geöffnet wurde. Positionierung ist einfache
  Rand-Margins (`margins.top`/`margins.left`) statt `PopupShell`s
  `mapToItem`-Ankerlogik, weil ein eigenständiges Fenster nicht relativ zu
  einem Item in einem *anderen* Fenster positionieren kann. Verlust dabei:
  kein Klick-daneben-Schließen mehr (das lief über `Bar.qml`s gemeinsamen
  `popupLayer`/`mask`, den ein separates Fenster nicht hat) und keine
  Grow-Animation beim Öffnen (nur noch Opacity-Fade auf dem Inhalt, weil ein
  `Window` kein `opacity` besitzt wie ein `Item`) — Escape oder erneuter
  Klick auf den Launcher-Button schließen weiterhin zuverlässig.
- **Zwei echte Bugs beim ersten Entwurf per Live-Test gefangen** (Bar
  tatsächlich neu gestartet mit `qs -p .../fisheye -n`, Log unter
  `/run/user/1000/quickshell/by-id/*/log.qslog` geprüft): `signal closed`
  kollidiert mit `Window`s eingebautem `closed`-Property-Change-Signal
  (`Duplicate signal name`, stiller Ladefehler) — umbenannt zu
  `closeRequested`. Und `opacity: 0` direkt auf dem `PanelWindow` scheitert
  mit `Cannot assign to non-existent property "opacity"` — `Window` hat
  keine `opacity`-Property, nur `Item`; Fade läuft jetzt auf einem
  Kind-`Item`, das den ganzen Inhalt umschließt. Nach beiden Fixes lädt die
  Config sauber (`Configuration Loaded`), ein `ipc call launcher open`/
  `close`-Zyklus lief ohne neue Log-Zeilen durch.
- **Nicht per echtem Tastendruck end-to-end testbar** in dieser Umgebung
  (kein `wtype`/`ydotool` verfügbar) — bitte einmal live gegenprüfen:
  SUPER+space **und** Klick auf den Launcher-Button, jeweils direkt tippen
  und Escape drücken, ohne vorher woanders hinzuklicken.

## Was funktioniert (Nachtrag: Wetter + Kalender im Uhr-Popup)

Nutzerauftrag: Klick auf die Uhr soll neben der schon vorhandenen Analoguhr
(Etappe 7) auch Wetter und einen Kalender zeigen. `menus/ClockMenu.qml`
bekam dafür einen Wetter- und einen Monatskalender-Block unter die
bestehende `AnalogClock`.

- **Wetter-/Geolocation-Logik 1:1 aus `bars/floating/center/
  CalendarWeatherPopup.qml` übernommen**, nicht neu erfunden — dort schon
  erprobt: `curl` gegen `http://ip-api.com/json/...` für die
  IP-Geolokalisierung (kein API-Key), dann Open-Meteo (`api.open-meteo.com`,
  ebenfalls kein Key) für aktuelles Wetter + 4-Tage-Vorschau, alle 25 Minuten
  neu abgefragt, letzter Stand bleibt bei Offline/Parse-Fehler einfach
  stehen statt einen Fehler zu zeigen. Läuft über `Quickshell.Io.Process` +
  `StdioCollector`, genau wie `MangoIpc.qml` es für `mmsg` schon tut — kein
  neues Muster für dieses Projekt.
- **Geokoordinaten-Cache neu in `Config.qml`** (`weatherLat`/`weatherLon`/
  `weatherLabel`, per `cacheAutoLocation()`), damit nicht bei jedem
  Bar-Neustart erneut gegen ip-api.com aufgelöst wird. `_writeDefaults()`
  ruft jetzt dieselbe `_save()`-Funktion wie der Cache-Schreibpfad, statt
  die Default-Werte zweimal im Code zu halten.
- **Kalender**: Montag-Start-Wochenraster wie beim floating-Vorbild, mit
  Vor-/Zurück-Monatsnavigation (Klick auf den Monatsnamen springt zurück auf
  den aktuellen Monat) und heute markiert. Eigenständig für fisheye
  geschrieben (kein `QtQuick.Layouts` wie im floating-Original — dieses
  Projekt verwendet durchgängig plain `Column`/`Row`, siehe
  `NetworkMenu.qml`/`PowerMenu.qml`), Beschriftungen auf Deutsch/Großschreibung
  passend zu den übrigen Menüs.
- **Styling bewusst nicht auf 7-/14-Segment umgestellt** — Wetterbeschreibung
  und Kalenderzahlen sind variable Fließtexte/Zahlen ohne festes
  Zeichen-Set, für die es in diesem Projekt schon einen Präzedenzfall gibt:
  `NetworkMenu.qml` und `PowerMenu.qml` nutzen für genau solche Labels auch
  plain `Text` mit `Theme.surfaceInk` + Opacity statt Segment-Widgets. Nur
  die Analoguhr bleibt segment-/font-frei, wie in den Konventionen für die
  eine dort dokumentierte Ausnahme vorgesehen.
- **Popup vergrößert** (`bar/Bar.qml`s `clockPopup` und `test/
  MenuTestScene.qml`s Pendant): 160×160 → 240×340, damit Uhr + Wetter +
  Kalender ohne Kürzung reinpassen. Inhalt sitzt in einer `Flickable`
  (Fallback, falls eine schmalere Bildschirmbreite die Höhe doch mal
  sprengt), wie es `NetworkMenu.qml`/`WeatherTab.qml` auch schon so machen.
- **Verifiziert per Live-Screenshot**, nicht nur warnungsfrei geladen: kurz
  `testMode` auf `true` gestellt, `test/MenuTestScene.qml`s Klick-Popup für
  den Uhr-Test automatisch geöffnet, `qs -p .` per `grim`-Screenshot
  festgehalten — Wetterdaten (16°C, teilweise bewölkt, 4-Tage-Vorschau) und
  Kalender (September 2026, 13. korrekt hervorgehoben) kamen live über
  echtes Internet/Open-Meteo rein, keine Platzhalterdaten. Danach `testMode`
  und die Test-Popup-Größe wieder zurückgesetzt, Zombie-Check nach dem
  Testlauf durchgeführt (siehe "Testen"-Abschnitt) — sauber.
- Kein manuelles Standort-Override (nur automatische IP-Geolokalisierung,
  wie `Settings.weatherMode === "auto"` es bei floating/quickbar als einen
  von zwei Modi kennt) — war nicht Teil des Auftrags, ließe sich aber nach
  demselben Muster nachrüsten, falls die IP-basierte Ortung mal daneben
  liegt.

## Was funktioniert (Nachtrag: Popup-Position drifted bei Network/Bluetooth/Volume)

Nutzermeldung nach obigem Nachtrag: "der Volumen-Slyder und WLAN öffnen
sich alle links und nicht unter ihren Knöpfen" — ein vorbestehender Bug,
unabhängig vom Wetter/Kalender-Feature, nur zufällig dabei aufgefallen.

- **Ursache, per Live-Debug-Readout im echten `Bar.qml` verifiziert** (nicht
  geraten): `PopupShell.qml`s `_anchorDep`-Trick las nur `anchorItem`s
  eigene lokale `x`/`y`/`width`/`height`, um `mapToItem()`s bekannten
  "one-time snapshot"-Bug (siehe `feedback_qml_maptoitem_non_reactive.md`)
  zu umgehen. Network/Bluetooth/Volume sitzen aber alle in `Bar.qml`s
  rechts-verankertem Status-`Row` (`anchors.right: parent.right`) — und in
  so einem Row hängt die *absolute* Bildschirmposition eines Elements nur
  von seiner eigenen Breite plus der Summe aller Breiten der Geschwister
  **danach** ab, nicht davor (mathematisch: bei Rechtsverankerung kürzt
  sich alles vor einem Element aus der Positionsformel komplett heraus).
  Wächst/schrumpft ein späteres Geschwister (Tray-Icon erscheint, Battery
  blendet sich ein/aus, Media-Titel taucht auf), verschiebt das den ganzen
  Row über sein `anchors.right`, ohne `anchorItem`s eigenes lokales `x` zu
  ändern — `_anchorDep` bekam das nie mit, der Anker blieb auf seiner
  allerersten (oft vor-Layout) Position eingefroren. `ClockModule`
  (`anchors.centerIn`, kein Row) und `PowerButton` (letztes Element im Row,
  nichts danach kann ihn verschieben) waren nie betroffen — deckt sich
  genau mit der Nutzermeldung.
- **Verifiziert durch einen temporären Debug-Text direkt in der laufenden
  Produktiv-Bar** (`bar.openPopup` kurz per `Component.onCompleted` auf
  `"volume"` erzwungen, da `wtype`/`ydotool` hier fehlen): der gecachte
  Anker lag über 100px neben einer frisch berechneten `mapToItem()`-Kontrolle
  — reproduzierbarer Beweis, kein Verdacht.
- **Fix**: `_anchorDep` + `mapToItem()` komplett ersetzt durch
  `_absoluteOffset()`, das für `anchorItem` und `overlay` je den eigenen
  Ahnen-Pfad bis zur Fenster-Wurzel abläuft und dabei nur echte
  QML-Properties (`.x`/`.y`) liest — das registriert automatisch eine
  Abhängigkeit auf *jede* Ahnen-Positionsänderung (inklusive des Row selbst),
  ganz ohne den ursprünglichen mapToItem-Snapshot-Bug. Betrifft nur
  `widgets/common/PopupShell.qml`, jedes Menü profitiert automatisch mit.
- **Nach dem Fix per selbem Debug-Readout gegengeprüft**: gecachter Anker
  und frische Kontrollmessung stimmen jetzt überein, Screenshot zeigt das
  Volume-Popup direkt unter dem echten Button statt am Bildschirmrand.
  Danach Debug-Text und Test-`Component.onCompleted` wieder entfernt,
  `qs -p .` lädt weiterhin warnungsfrei, kein Zombie-Prozess übrig.

## Wichtige Stolperfallen (bereits gefunden, in globalem Memory gespeichert)

Diese zwei haben beim Bauen von Etappe 1 tatsächlich zugeschlagen — beim
Weiterbauen unbedingt im Hinterkopf behalten:

1. **Singleton + Cross-Directory-Import**: `pragma Singleton` (Theme, Config)
   funktioniert nur bei Import aus dem eigenen Ordner oder einer reinen
   `".."`-Ahnenkette. Ein seitlicher Import (`import "../sibling"`) gibt
   still ein Objekt zurück, dessen Properties alle `undefined` sind — **ohne
   jede Fehlermeldung**. Deshalb liegen Theme.qml/Config.qml im
   `fisheye/`-Root statt in `config/`: so ist von jeder Datei in `bar/`,
   `menus/`, `widgets/*` aus `import "../.."` (o.ä., je nach Tiefe) eine
   reine Ahnenkette. Nicht-Singleton-Typen (BevelPanel, LcdSurface, spätere
   SevenSegment etc.) sind davon **nicht** betroffen — die dürfen ganz normal
   seitlich importiert werden.
2. **`Behavior on <Property>` + Property-Name wie ein Signal-Handler**: Ein
   Property namens `onSurface`/`onAccent` (Muster `/^on[A-Z]/`) mit
   `Behavior on onSurface {...}` **crasht Quickshell mit SIGSEGV, ganz ohne
   QML-Warnung**. Per Bisektion isoliert (einzelner `Behavior on onSurface`
   Block reicht zum Reproduzieren). Deshalb heißen die Rollen hier
   `surfaceInk`/`accentInk` statt der Material-typischen `onSurface`/
   `onAccent`-Schreibweise. Bei jeder neuen Theme-Property mit Behavior:
   Name gegen `/^on[A-Z]/` prüfen.
3. `Behavior on <readonly property>` ist (separat davon) ein normaler
   Compile-Error ("is a read-only property") — deshalb sind alle animierten
   Theme-Rollen normale `property`, nicht `readonly property`. Extern
   schreibt sie trotzdem niemand (Konvention, nicht erzwungen).
4. **`Repeater` akzeptiert nur `Item`-Delegates.** Ein `Repeater`, der
   `ShapePath`-Instanzen in einem `Shape` erzeugen sollte (statt sieben
   Segmente einzeln hinzuschreiben), scheiterte mit `Delegate must be of
   Item type` — zeichnet einfach nichts, kein Crash. Bei fester, kleiner
   Anzahl (wie den sieben Segmenten) die Elemente direkt/explizit
   hinschreiben statt Repeater zu benutzen.
5. **`PathLine` sieht die Properties seiner eigenen `ShapePath` nicht ohne
   `id`.** `ShapePath { property var pts: ...; PathLine { x: pts[0][0] } }`
   wirft `ReferenceError: pts is not defined` zur Laufzeit — der normale
   QML-Scope-Chain-Zugriff auf Parent-Properties funktioniert hier für
   Path-Elemente nicht. Fix: `ShapePath { id: seg; ... }` und in den
   Kindern `seg.pts[0][0]` statt `pts[0][0]`.
6. **Kurze Hexagon-Segmente mit fixem Chamfer werden zu Rauten statt
   Balken.** `FourteenSegment`s Mittelbalken (`g1`/`g2`) und Diagonalen
   (`h`/`i`/`j`/`k`/`l`/`m`) sind viel kürzer als die äußeren Balken
   (`a`-`f`) — mit dem gleichen festen `chamfer` wie bei den langen Balken
   frisst der Chamfer die ganze Segmentlänge auf, das Sechseck entartet zu
   einer Raute ohne erkennbare gerade Kante. Sichtbar als "Mittelbalken
   fehlt bei jeder Ziffer/jedem Buchstaben, auch wenn er laut Pattern an
   sein sollte" — aber `isLit()`/das Pattern selbst waren dabei die ganze
   Zeit korrekt (per Debug-Text mit `JSON.stringify(_lit)` verifiziert),
   nur die Geometrie hat den Unterschied unsichtbar gemacht. Fix: Chamfer
   in `_hexAt()` relativ zur eigenen Segmentlänge deckeln
   (`Math.min(root.chamfer, len * 0.3)`) statt einen globalen Wert zu
   benutzen.
7. **Ein wertquellen-Animator (`Animation on <Property>`) auf einer
   Property, die schon einen deklarativen Bindungsausdruck trägt, ersetzt
   diese Bindung dauerhaft**, sobald die Animation einmal einen Wert
   schreibt — nicht nur währenddessen. `WorkspacesModule`s Tag-Kachel hatte
   `color: active ? Theme.accent : "transparent"` **und** eine
   `SequentialAnimation on color` für den Urgent-Puls auf derselben
   Property; nach dem ersten Animationsdurchlauf war `color` fest auf den
   zuletzt geschriebenen Wert eingefroren und reagierte nie wieder auf
   `active`-Änderungen — verwandt mit, aber nicht identisch zu
   `feedback_qml_behavior_animator_freeze.md` (dort war die Kombination
   `Behavior` + von einem Animator getriebener Wert das Problem, hier ist
   es die Animation selbst, die direkt auf eine gebundene Property
   schreibt). Fix: den Puls als separates `Rectangle`-Overlay obendrauf
   animieren (dessen `opacity`, nicht `color`) statt die Basis-Property zu
   animieren, die den deklarativen Zustand trägt.
8. **Screenshot-Crops driften bei jedem `magick -crop`, wenn man das
   Ergebnis eines vorherigen Crops weiter zuschneidet** — ImageMagick
   behält die virtuelle Leinwand (Page-Geometrie) des Originalbilds bei,
   d. h. ein zweiter `-crop` auf ein bereits zugeschnittenes PNG rechnet
   Koordinaten relativ zur *ursprünglichen* Position, nicht zu (0,0) im
   neuen Bild — das erzeugte hier reihenweise falsch ausgerichtete Crops
   und sah kurzzeitig wie ein schwerer Rendering-Bug aus (Ziffern schienen
   alle identisch/falsch), war aber nur Verwechslung durch verschobene
   Koordinaten. Fix: nach jedem `-crop` sofort `+repage` anhängen, bevor
   das Ergebnis erneut zugeschnitten wird.
9. **`Item.mapToItem()` in einer Property-Bindung ist keine reaktive
   Quelle** — sie liefert nur einen Schnappschuss zum Zeitpunkt des
   Bindungs-Laufs und läuft nicht erneut, wenn sich die Geometrie des
   Zielitems später ändert (der interne Lesezugriff passiert in einem
   C++-Aufruf, den QMLs Abhängigkeits-Tracking nicht sieht). `PopupShell`s
   Popup-Positionierung fror dadurch beim allerersten Bindungslauf ein
   (alle Anker-Items noch bei Breite ~0) und aktualisierte sich nie wieder
   — in einer `PanelWindow` reproduzierbar, weil deren `width` erst nach
   dem asynchronen Wayland-Configure feststeht, in einer `FloatingWindow`
   dagegen unsichtbar, weil deren Layout schon vorher synchron fertig ist
   (deshalb unbemerkt seit Etappe 6). Fix: eine zusätzliche Property, die
   die relevante Geometrie direkt liest (echte, trackbare Property-Reads)
   und im `mapToItem`-Binding referenziert wird, rein um dessen
   Neuberechnung zu erzwingen. Details in Etappe 7 oben.
10. **`QtObject` hat kein Default-Property.** Ein nackter `Timer {}` (oder
    `PwObjectTracker {}` o.ä.) direkt als Kind-Element eines `QtObject`
    scheitert mit `Cannot assign to non-existent default property` — anders
    als `Item`, dessen Default-Property (`data`/`children`) so etwas klaglos
    aufnimmt. Passiert in `Boot.qml` (Etappe 9) beim ersten Entwurf des
    Selbsttest-Timers. Fix: als benannte Property zuweisen,
    `property Timer _wipeTimer: Timer {...}`, statt es als bloßes Kind
    hinzuschreiben.
11. **Ein eigenes Root-Singleton, das gleich heißt wie ein eingebauter
    Quickshell-Typ, wird von `import Quickshell` überschattet.** Das erste
    Design für den App-Launcher hieß `DesktopEntries.qml` — kollidiert mit
    Quickshells eingebautem `DesktopEntries`-Singleton. Sobald irgendeine
    Datei im Baum zusätzlich `import Quickshell` macht (hier:
    `LauncherMenu.qml`, wegen `Quickshell.iconPath`/`hasThemeIcon`), löst
    sich der Bezeichner `DesktopEntries` dort gegen den eingebauten Typ auf
    statt gegen das lokale `pragma Singleton`-File — `DesktopEntries.ready`
    lieferte `undefined` statt `false`, ganz ohne Fehlermeldung beim Start
    (nur eine späte `WARN scene: Unable to assign [undefined] to bool` beim
    ersten Binding-Auswerten). Fix: umbenannt zu `AppEntries.qml` — lokale
    Singletons nie so nennen, dass der Name mit einem Quickshell-Kerntyp
    kollidiert.
12. **Ein `PanelWindow` ohne `mask` nimmt über seine gesamte
    Fenstergeometrie Zeigereingaben entgegen, nicht nur dort, wo etwas
    sichtbar/interaktiv ist.** `bar/Bar.qml`s Fenster ist absichtlich höher
    als die sichtbare Leiste, damit Popups darunter Platz haben
    (`exclusiveZone` reserviert nur `Theme.barHeight`, `implicitHeight` ist
    `Theme.barHeight + popupMaxHeight`) — ohne `mask` verschluckte dieses
    unsichtbare, transparente Zusatzfenster **jeden Klick** in diesem Band
    über die volle Bildschirmbreite, egal ob ein Popup offen war oder nicht
    (bemerkt als "keine Klicks im oberen Bildschirmbereich möglich, z. B.
    keine Browser-Tabs öffnenbar"). Fix: `mask: Region { Region { item: ...
    } ... }`, eine `Region` pro tatsächlichem Klick-Ziel (Leiste, jedes
    `PopupShell`, der Klick-daneben-Fänger). Wichtiger Nebenpunkt dabei:
    `visible: false` auf einem `MouseArea` schrumpft dessen Geometrie
    **nicht** — eine `Region` liest die rohe `x/y/width/height` des Items,
    nicht seine Sichtbarkeit, also braucht so ein Klick-Fänger zusätzlich
    eine echte `height`-Bindung (`height: <Bedingung> ? parent.height : 0`),
    sonst bleibt der alte Bug trotz `mask` bestehen.
13. **`WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` heißt nicht "kein
    Autofokus", sondern "dieses Surface bekommt niemals eine einzige
    Taste".** Stand seit Etappe 1 fest auf `None` in `Bar.qml` — dadurch war
    nicht nur (der später gewünschte) Escape-Handler wirkungslos, sondern
    schon vorher jedes Tippen in `LauncherMenu`s Suchfeld oder
    `NetworkMenu`s PSK-Feld, komplett ohne Fehlermeldung (sieht im
    Screenshot völlig normal fokussiert aus, nimmt aber nie eine Taste an).
    `focus: true`/`forceActiveFocus()` in der QML-Szene ändern daran nichts,
    weil der Compositor die Taste gar nicht erst an dieses Fenster
    weiterreicht. Fix: `keyboardFocus` an den offenen Zustand binden statt
    fest verdrahten — `bar.openPopup !== "" ? WlrKeyboardFocus.OnDemand :
    WlrKeyboardFocus.None` (nicht `Exclusive`, das würde der ganzen Session
    die Tastatur wegnehmen, solange irgendein schmales Dropdown-Menü offen
    bleibt — angemessen eher für ein großes zentriertes Modal wie
    `quickdots/menu`s eigenes, das `Exclusive` tatsächlich richtig nutzt).
14. **`WlrKeyboardFocus.OnDemand` auf einer dauerhaften, wiederverwendeten
    Layer-Surface reicht nicht, um zuverlässig Fokus zu bekommen — nicht mal
    mit der offen-Zustand-Bindung aus Punkt 13.** Verifiziert im
    mango-Quellcode (`manage/layer.h`, `input/pointer.h`): `focuslayer()`
    feuert nur beim allerersten Commit eines Surfaces (`initial_commit`,
    einmalig) oder in mangos Pointer-Button-Handler, und dort nur, wenn
    `keyboard_interactive` **zum Zeitpunkt des Klicks bereits** `ON_DEMAND`
    ist — ein späterer Commit (ausgelöst durch eine QML-Property-Änderung
    danach) triggert keinen neuen Grant. Für eine dauerhaft gemappte Surface
    (wie `Bar.qml`s eigene) heißt das: der Klick, der `keyboardFocus` von
    `None` auf `OnDemand` umschaltet, kommt für sich selbst immer eine
    Runde zu spät, und ein rein IPC/Hotkey-ausgelöstes Öffnen (kein Klick
    beteiligt, siehe `LauncherState`) bekommt so **nie** Fokus. Betraf
    `LauncherMenu`s Suchfeld (Tippen ging trotz `forceActiveFocus()` nicht)
    und dessen Escape-Handler. Fix ist nicht auf der Property-Ebene lösbar
    (kein zusätzliches "Fokus jetzt bitte"-Signal für ein Layer-Surface, das
    schon existiert) — nur eine **frisch erzeugte** Surface bekommt den
    `initial_commit`-Grant zuverlässig, also `bar/LauncherWindow.qml`: ein
    per `Loader` bei jedem Öffnen neu instanziiertes eigenes `PanelWindow`
    statt eines `PopupShell`-Items im dauerhaften Bar-Fenster.

Weitere technische Hinweise stehen in den jeweiligen Abschnitten dieser
README und den Quellkommentaren.
`feedback_qml_maptoitem_non_reactive.md`,
`feedback_qml_qtobject_no_default_property.md`,
`feedback_qml_singleton_name_shadows_builtin.md` und
`feedback_quickshell_panelwindow_mask_input_region.md` und
`feedback_wlr_layershell_keyboard_focus_none.md`.

## System-Fakten (verifiziert, nicht geraten — Stand Etappe-1-Recherche)

- Compositor: **mango** 0.16.1 (nicht Hyprland/Niri). IPC über `mmsg`
  (`mmsg get/watch all-monitors`, `mmsg get/watch focusing-client`, `mmsg
  dispatch view,<idx>,<synctag>` / `viewcrossmon,<idx>,<monitor>`). Fertiges,
  funktionierendes Beispiel: `bars/klasic/MangoIpc.qml` — für Workspaces
  1:1 übernommen (`MangoIpc.qml` im fisheye-Root, siehe Etappe 4).
- Quickshell 0.3.0, hat nativ: `Quickshell.Networking` (WLAN/NetworkManager),
  `Quickshell.Bluetooth`, `Quickshell.Services.{Mpris,Pipewire,UPower,
  SystemTray,Notifications,Polkit,Greetd,Pam}`. Kein Grund für
  nmcli/bluetoothctl-Gefrickel — alles direkt über QML-Typen ansprechbar.
  API-Details bei Bedarf aus den `.qmltypes`-Dateien unter
  `/nix/store/*-quickshell-0.3.0/lib/qt-6/qml/Quickshell/**` ziehen, nicht
  aus dem Gedächtnis (die API ändert sich zwischen Versionen). In Etappe 5
  tatsächlich so verwendet für Volume/Netzwerk/Bluetooth/Akku/Media/Tray.
- **Dieser Rechner ist ein Desktop, kein Laptop**: kein Akku
  (`/sys/class/power_supply/` leer, kein `upower`-Binary), `upower.service`
  und `bluetooth.service` existieren in der NixOS-Config nicht
  (`systemctl status <name>` → "could not be found"), obwohl ein
  Bluetooth-Adapter (`hci0`) und eine Wi-Fi-Karte (`wlp9s0`) physisch da
  sind — nur eben ohne laufenden `bluetoothd`. Netzwerk läuft über
  **Ethernet** (`eno1`), Wi-Fi ist getrennt. Betrifft `BatteryModule`,
  `BluetoothModule`, `NetworkModule` (Etappe 5) — Details/Konsequenzen dort
  im "Was funktioniert"-Eintrag.
- Farbquelle: **pywal**, `~/.cache/wal/colors.json`, wird von `shellwall` bei
  Wallpaperwechsel neu geschrieben. matugen ist installiert, aber ohne
  Config — pywal ist die tatsächlich aktive Quelle.
- `Qt.color(str)`, `Qt.rgba()`, `Qt.lighter/darker/tint/alpha` sind reale,
  in `qqmlbuiltinfunctions_p.h` verifizierte Qt-Global-Funktionen.
- Kein `grim`/`wayshot` vorinstalliert, aber `nix --extra-experimental-
  features "nix-command flakes" shell nixpkgs#grim --command grim <datei>`
  holt es ad-hoc (kein Systemeingriff) — damit wurde Etappe 2 tatsächlich
  gescreenshottet, siehe "Screenshot machen" unten.
- **`~/.config/mango/config.conf` wird laufend von etwas außerhalb dieser
  Session neu geschrieben** (viele `.bak-<timestamp>`-Dateien über den
  ganzen Tag verteilt) und aktuell steht in dessen `exec-once`-Block bereits
  `qs -p .../bars/fisheye -n` statt `bars/fullshell` — d.h. das System des
  Nutzers ist schon so konfiguriert, dass es fisheye statt fullshell
  autostartet, unabhängig davon ob fisheye schon fertig ist. Ein
  Bar-Prozess, der grundlos verschwindet, muss kein Absturz sein — siehe
  `feedback: project_mango_config_live_reload.md`.

## Testen

```
cd ~/quickdots/bars/fisheye
qs -p .
```

Muss ohne jede Konsolen-Warnung starten (Warnungen = Fehler, nicht Rauschen —
Vorgabe aus dem Originalauftrag). Nach jedem Testlauf, besonders nach einem
Crash, prüfen ob ein Zombie-Prozess übrig bleibt:

```
ps aux | grep quickshell-wrapped
pkill -9 -f "\.quickshell-wrapped"   # nur falls einer hängt
```

(Ein gecrashter `qs`-Lauf hinterlässt manchmal einen `.quickshell-wrapped`-
Prozess bei 100% CPU, der nicht von `timeout` mitgekillt wird — das hat beim
Bisektions-Debugging von Stolperfalle 2 oben eine automatisierte Testreihe
lahmgelegt, weil die liegengebliebenen Prozesse das System an CPU
verhungern ließen. Bei automatisierten/wiederholten Testläufen also nach
jedem Lauf explizit aufräumen, nicht auf `timeout` allein verlassen.)

Es laufen parallel weitere echte Quickshell-Bars des Nutzers (`shellwall`,
`menu`) — die beim Testen von `fisheye` in Ruhe lassen, nicht anfassen/
killen. `bars/fullshell` lief zu Beginn dieser Etappe auch noch, ist aber
zwischenzeitlich von selbst (sauber per IPC, kein Crash) beendet worden —
vermutlich im Zuge der laufenden `mango`-Config-Neuschreibungen, nicht durch
etwas das dieser Session zurechenbar ist (Shell-IDs von fullshell/fisheye
sind nachweislich unterschiedlich). Siehe `project_mango_config_live_
reload.md` in memory.

### Screenshot machen

Kein `grim` im System — über `nix shell` ad-hoc holen:

```
qs -p . > /tmp/live.log 2>&1 &
QSPID=$!
sleep 2
nix --extra-experimental-features "nix-command flakes" shell nixpkgs#grim \
  --command grim /tmp/screenshot.png
kill $QSPID   # tötet ggf. nur den Wrapper, s.o. -- danach ps prüfen
sleep 0.5
ps aux | grep quickshell   # falls noch ein Prozess läuft: kill <pid>
```

`kill $QSPID` reicht nicht immer (der `qs`-Wrapper und der echte Prozess
können unterschiedliche PIDs haben) — nach jedem Screenshot-Testlauf mit
`ps aux | grep quickshell` prüfen, ob der Testprozess wirklich weg ist,
bevor man weitermacht.

## Konventionen, an die sich der Rest des Baus halten sollte

- Kein Hex-Wert, keine Dauer/Easing außerhalb von `Theme.qml`.
- Neue Theme-Property mit Behavior → sofort gegen `/^on[A-Z]/` prüfen (s.o.).
- Neue Datei in `bar/modules/`, `menus/`, `widgets/*`, die Theme/Config
  braucht → Import muss eine reine `".."`-Kette zum `fisheye/`-Root sein.
- `QtQuick.Shapes` für Ziffern/Icons, Canvas nur für den gebogenen
  Ringtext der Analoguhr (Ausnahme bereits gemacht: das statische
  Pixelraster in `LcdSurface.qml` ist Canvas, aber einmalig gerendert +
  `layer.enabled` gecacht, nicht live neu gezeichnet — das war eine bewusste
  Abwägung für "einmal rendern und cachen", keine Regel-Verletzung).
- Jede Etappe muss `qs -p .` warnungsfrei laden, bevor sie als fertig gilt.

## Ursprungs-Prompt

Der komplette, ursprüngliche Auftrag (deutsch, vom Nutzer) mit allen
Design-Details (7-/14-Segment-Zeichnung, Geistersegmente, Bevel-Logik,
Boot-Selbsttest, Analoguhr-Spezifikation, Etappenplan Punkt für Punkt) steht
in der Conversation, aus der dieses Projekt entstanden ist — nicht hier
dupliziert, um diese Datei nicht mit Redundanz aufzublähen. Bei Bedarf beim
Nutzer nachfragen oder die Session-History dieses Threads konsultieren, falls
verfügbar. Kurzfassung der Etappen (Original Abschnitt 10):

1. ~~Theme + Config + leere Bar auf allen Monitoren~~ ✅
2. ~~Segment-Widgets isoliert in Testszene~~ ✅ (FourteenSegment bewusst
   verschoben auf Etappe 3, siehe "Was fehlt")
3. ~~Digitaluhr in der Bar (Rolling Digits, blinkender Doppelpunkt)~~ ✅
4. ~~Workspaces + Fenstertitel~~ ✅
5. ~~Statusmodule rechts~~ ✅
6. ~~Popup-Infrastruktur + zwei Menüs~~ ✅
7. ~~Analoguhr im Uhr-Menü~~ ✅
8. ~~Restliche Menüs~~ ✅ (Network + Bluetooth, Nutzer-Entscheidung)
9. ~~Boot-Sequenz + Idle-Glanz + Performance-Messung~~ ✅ (LCD-Selbsttest-
   Wisch, periodischer Glanz-Sweep, Debug-Overlay, Nutzer-Entscheidungen)
