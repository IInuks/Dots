# Claude Code Prompt: Skewed Top-Bar (nach dem Vorbild von liixini/skwd → skwd-bar)

> Kopiere alles unterhalb der Linie in Claude Code. Passe vorher die Werte in **[ECKIGEN KLAMMERN]** an.

---

Du baust mir eine Wayland-Topbar mit **Quickshell (QML, Qt6)**. Ziel ist ein möglichst exakter Nachbau der Bar „skwd-bar" aus https://github.com/liixini/skwd (MIT-Lizenz). Halte dich pixelgenau an die folgende Spezifikation. Wenn du unsicher bist, klone das Repo und lies `skwd-bar/qml/bar/TopBar.qml`, `skwd-bar/qml/bar/lyrics/LyricsIsland.qml` und `skwd-bar/qml/bar/dropdowns/*.qml` als Referenz, statt zu raten.

## Mein Setup

- Compositor: **[niri / Hyprland / Sway …]**
- Hauptmonitor (Output-Name): **[z. B. DP-1]**
- WLAN-Interface: **[z. B. wlan0]** (Status über `iwctl`)
- Wetterstadt: **[z. B. Wiener Neustadt]**
- Bevorzugter Player: **[spotify]**
- Installationsort: `~/.config/quickshell/skewbar/` (Start mit `qs -c skewbar`)

## Abhängigkeiten

quickshell, qt6-declarative, qt6-multimedia, qt6-imageformats, cava, iwd, brightnessctl, upower, pipewire, matugen (optional), Fonts: **Roboto + Roboto Condensed + Roboto Mono**, **Symbols Nerd Font** (`ttf-nerd-fonts-symbols`), **Material Design Icons** (`ttf-material-design-icons-extended`). Prüfe, was fehlt, und sag mir die Installationsbefehle, statt sie ungefragt auszuführen.

## Dateistruktur

```
shell.qml
qml/Style.qml        (Singleton: Fonts, Größen, Radien, Spacing, Animationszeiten)
qml/Colors.qml       (Farben, live aus JSON geladen)
qml/Config.qml       (Singleton: liest config.json)
qml/bar/BarShell.qml
qml/bar/TopBar.qml
qml/bar/lyrics/LyricsIsland.qml + LyricsIslandService.qml
qml/bar/dropdowns/{Volume,WiFi,Bluetooth,Calendar,Weather,Brightness,NotificationCenter}Dropdown.qml, DropdownTail.qml
qml/services/{SystemStats,Weather,Wifi,Lyrics,Wm,Ipc}Service.qml
ext/cava/cava-bar.conf
config.json
```

## 1. Fenster

- `PanelWindow`, `WlrLayershell.namespace: "topbar"`, auf dem Monitor aus der Config (Fallback `Quickshell.screens[0]`).
- `anchors { top; left; right }`, `color: "transparent"`.
- **Barhöhe: 32 px.**
- `exclusiveZone = barVisible ? 32 + topMargin : 0`.
- `implicitHeight` = Barhöhe + höchstes offenes Dropdown + (Visualizer-Höhe, wenn Musik läuft).
- **Input-Mask** (`mask: Region`): nur Bar-Streifen, Visualizer-Streifen und die Dropdown-Bereiche links/rechts sind klickbar – alles andere klickt durch.
- Keyboard-Focus `OnDemand`, nur während ein WLAN-Passwort eingegeben wird `Exclusive`. `Esc` schließt alle Dropdowns.

## 2. Die Form: drei schräge Inseln („classic", Standard)

Es gibt **keine durchgehende Bar**. Stattdessen drei separate, bündig an der oberen Bildschirmkante klebende Inseln mit **diagonalen Kanten**. Zentrale Konstante: **`diagSlant = 28` px** (horizontaler Versatz über 32 px Höhe).

Füllung aller Inseln: **Farbe `surface` mit Alpha 0.88**. **Kein Rand, kein Radius, kein Schatten, kein Blur.** Gezeichnet per `Canvas` (2D-Context), bei Farbwechsel `requestPaint()`.

- **Linke Insel:** Punkte (0,0) → (w,0) → (w−28, h) → (0,h). Die rechte Kante läuft also von oben rechts schräg nach innen-unten.
  Breite = Inhaltsbreite + 28 + 24. Inhalt: `Row`, `leftMargin 12`, **spacing 8**, vertikal zentriert.
- **Rechte Insel:** gespiegelt: (0,0) → (w,0) → (w,h) → (28,h). Linke Kante läuft schräg nach innen-unten.
  Breite = Inhaltsbreite + 28 + 24. Inhalt: `Row`, `rightMargin 12`, **spacing 14**.
- **Mittlere Insel (Lyrics/Musik):** feste **Breite 699 px**, horizontal zentriert, umgedrehtes Trapez: (0,0) → (w,0) → (w−28,h) → (28,h). Oben breit, unten schmal.
- In classic-Stil wird die Bar um 1 px nach oben geschoben (`topMargin = -1`), damit keine Lücke zur Kante bleibt.
- Die Inselbreiten ändern sich live mit dem Inhalt (siehe Widget-Animation).

### Alternativer Stil „pill" (per Config `bar.style: "pill"`)

- Seitenabstand 12 px, oberer Abstand 8 px.
- Eine durchgehende Pille über die volle Breite: `radius = height/2`, Farbe `surface` @ 0.88.
- Schatten: zweites Rechteck dahinter, `rgba(0,0,0,0.18)`, 4 px nach unten, 2 px breiter auf jeder Seite, gleicher Radius.
- Canvas-Trapeze werden ausgeblendet; Inhalts-Margins links/rechts = 32/2 + 4 = 20 px.

## 3. Typografie & Farben der Widgets

- Textfont: **Roboto Condensed**. Icons: **Symbols Nerd Font**. Mediensteuerung: **Material Design Icons**.
- Jedes Widget = `Row` mit **spacing 4**: Icon **14 px in `primary`**, Wert **12 px, Font.Medium, in `tertiary`**.
- Style-Skala zum Anlegen: fontTiny 9, Caption 11, Body 12, BodyLarge 13, Subtitle 14, Title 16, TitleLarge 18, Headline 24; Radien 2/4/8/12/16/20/40; Spacing 2/4/8/12/16/20; Animationen 150/200/300/400 ms; opacityDim 0.35, Muted 0.5, Subtle 0.6.

## 4. Widgets (IDs, Icons als Nerd-Font-Codepoints)

Standard-Layout: **links** `["cpu", "gpu", "memory"]`, **rechts** `["weather", "bluetooth", "wifi", "brightness", "battery", "volume", "notifications", "clock"]`. Beides per Config änderbar; zusätzlich pro Widget `icon`, `label`, `disabled`, `mouseover` überschreibbar.

| ID | Icon | Anzeige | Klick |
|---|---|---|---|
| cpu | U+F0EE0 | `42%` + `58°` (Auslastung + Temp) | schließt offenes Dropdown |
| gpu | U+F08AE | `%` + `°` | – |
| memory | U+F035B | `%` | – |
| qsmem (optional) | U+F0AF3 | RAM von quickshell+Daemon, `MB`/`x.x GB` | Dropdown mit Prozessliste |
| weather | je nach Beschreibung: Gewitter F067E, Schneesturm F0F36, Schnee F0598, Graupel F067F, Starkregen F0596, Regen F0597, Nebel F0591, teilweise bewölkt F0595, bewölkt F0590, sonnig/klar F0599 | Temperatur | Wetter-Dropdown |
| bluetooth | U+F00AF | Akku des ersten verbundenen Geräts; ausgeblendet ohne Daten | BT-Dropdown |
| wifi | Signal <25 F091F, <50 F0922, <75 F0925, sonst F0928 | SSID | WLAN-Dropdown |
| brightness | <25 F00DE, <50 F00DF, <75 F00DD, sonst F00E0 | `%` | Mausrad ±5 % via brightnessctl; Klick Dropdown |
| battery | 7 Stufen F008E, F007B, F007D, F007F, F0081, F0082, F0079; laden 8 Stufen F089C, F0086, F0087, F0088, F089D, F0089, F008B, F0085 | `%` | – |
| volume | 0 → F0581, <0.33 F057F, <0.66 F0580, sonst F057E; Icon fix 16 px breit, zentriert; Text min. 28 px breit | `%` | Lautstärke-Dropdown |
| notifications | U+F009A | Anzahl | Benachrichtigungs-Dropdown |
| clock | – | `HH` in **primary**, `:` und `mm` in **tertiary**, alle **13 px DemiBold**, spacing 0, keine Sekunden | Kalender-Dropdown |

Sonderfarben Akku-Icon: lädt → `rgba(0.4, 0.95, 0.6)`, unter 15 % → `rgba(0.95, 0.5, 0.4)`, sonst `primary`.

Klickbare Widgets haben `Qt.PointingHandCursor`. Widgets ohne Daten (kein WLAN, kein BT-Akku, keine Helligkeit, kein Akku) werden **gar nicht** angezeigt.

### Ein-/Ausblend-Animation der Widgets

Jedes Widget steckt in einem `Loader` mit `clip: true`. Sichtbar → `width = implicitWidth, opacity 1`; versteckt → `width 0, opacity 0`. Beides animiert **180 ms, Easing.OutCubic**. Dadurch wachsen/schrumpfen die schrägen Inseln weich.

### Mouseover-Modus

Widgets mit `mouseover: true` erscheinen nur, solange die jeweilige Seite gehovert wird oder ein Dropdown offen ist (`HoverHandler` über einer unsichtbaren Zone in voller möglicher Inselbreite, damit das Aufklappen kein Flackern erzeugt).

## 5. Dropdowns

- Mindestbreite **320 px**, Farbe `surface` @ 0.88.
- classic: Radius 0. pill: Radius 16, aber obere Ecken 0.
- Höhe animiert: **320 ms, BezierSpline [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]** (schnell raus, weich auslaufen).
- **Besonderheit classic:** Das Dropdown wächst von der oberen Bildschirmkante aus und **schiebt die Insel der jeweiligen Seite nach unten** – die Insel sitzt also auf der Unterkante des Dropdowns. In pill erscheint es unter der Pille.
- Unten eine **2 px Linie in `primary`**, deren Breite beim Öffnen von 0 auf voll animiert (300 ms OutCubic). Nur im classic-Stil.
- Inhalt: an der Seite ausgerichtet, Margins 12, unten 12, spacing 10. Er blendet erst ein, wenn die Höhe >50 % erreicht: Opacity 0→1 und Translate y −15→0, jeweils 200 ms OutCubic.
- Abschnittsüberschriften in Großbuchstaben („OUTPUT", „INPUT" …), 14 px DemiBold, `primary`.
- Position: linke Seite bündig links. Rechte Seite horizontal unter dem geklickten Widget zentriert, an den Rändern geklemmt.
- **DropdownTail:** Ein Streifen gleicher Farbe und Höhe verbindet das Dropdown mit dem Bildschirmrand seiner Seite (Überlappung = Radius), inklusive der 2 px primary-Linie. So wirkt es, als würde die Bar nach unten ausfließen.
- Nochmal auf dasselbe Widget klicken schließt es; ein anderes öffnet stattdessen dessen Dropdown.
- Inhalte: Lautstärke (alle PipeWire-Sinks mit Slider, Standardgerät wählbar), WLAN (Netzliste via iwctl, Passwortfeld), Bluetooth (verbundene Geräte + Akku), Kalender (Monatsansicht), Wetter (aktuell + Vorhersage), Helligkeit (Slider), Benachrichtigungen (Verlauf, einzeln wegklicken, „alle löschen").

## 6. Mittlere Insel: Lyrics + Visualizer

- Nur sichtbar, wenn ein MPRIS-Player spielt (bevorzugt der konfigurierte Player). Opacity 0↔1 in 200 ms OutCubic.
- **Links:** Interpret in GROSSBUCHSTABEN, 12 px DemiBold, `primary`, max 120 px, Elide. Abstand zum Rand 28 + 10.
- **Rechts:** Titel in GROSSBUCHSTABEN, gleich formatiert, rechtsbündig. Ein führendes „Interpret - " wird entfernt.
- **Mitte:** aktuelle synchronisierte Lyric-Zeile, 12 px Medium **kursiv**, `tertiary`, zentriert, einzeilig. Breite = 699 − 2·28 − 16 − 240.
  - **Karaoke-Effekt:** Eine exakte Kopie in `primary` liegt darüber und wird per Clip-Rechteck von links nach rechts über `contentWidth × Fortschritt` aufgedeckt.
  - Zeilenwechsel: alte Zeile gleitet ~20 px weg und blendet aus (250 ms), neue gleitet ein (300 ms), OutCubic.
  - Ohne Lyrics: Statustext in tertiary @ 60 %, verblasst nach einer Weile (600 ms).
- **Hover:** Lyrics blenden aus (180 ms), zentriert erscheinen Zurück / Play-Pause / Weiter (Material Design Icons U+F04AE, U+F03E4 bzw. U+F040A, U+F04AD), Größen 18/22/18 px, spacing 16. Farbe tertiary @ 0.85 (Play @ 0.95), bei Hover `primary` (120 ms). Klickfläche je 6 px größer.
- **Audio-Visualizer (cava):** `bars = 14`, `framerate = 30`, `method = raw`, `data_format = ascii`, `ascii_max_range = 100`. Glättung: `display += (neu − display) × 0.45`. Die Werte werden an den Rändern aufgefüllt: `[0, erster·0.1, erster·0.35, …werte…, letzter·0.35, letzter·0.1, 0]`.
  - Zwei Canvas, je **14 px** hoch: einer **in** der unteren Zone der Insel (Ausschlag nach oben, auf die Trapezform geclippt), einer **unter** der Insel (Ausschlag nach unten, ragt unter die Bar – deshalb wächst das Fenster um 14 px).
  - Standard-Theme „wave": Kurve mit `quadraticCurveTo` durch die Mittelpunkte, Füllung als linearer Verlauf `primary` Alpha 0.25 → 0.08 (bei 60 %) → 0, Kontur `tertiary` Alpha 0.2, 1 px.
  - Weitere Themes wenn du Zeit hast: bars (Abstand 2 px, Radius ≤3, primary 0.3→0.05), line, neon, vu, spectrogram, aurora (28 px hoch) usw.

## 7. Farben (Material You, live vom Wallpaper)

Lies `~/.cache/skwd-wall/colors.json` (bzw. **[MEIN MATUGEN-OUTPUT]**) mit `FileView { watchChanges: true }`. Schlüssel und Fallback-Werte:

primary #ffb4ab · primaryText #690005 · primaryContainer #b12723 · secondary #ffb4ab · secondaryContainer #792f29 · tertiary #8bceff · tertiaryContainer #006390 · background/surface #1d100e · surfaceText #f7ddd9 · surfaceVariant #5a413e · surfaceContainer #2c1f1d · error #ffb4ab · outline #a98986 · shadow #000000 · inversePrimary #b32824

Jede Farbe hat `Behavior … ColorAnimation { 180 ms, InOutQuad }` (erst nach dem ersten Laden aktiv). Alle Canvas zeichnen bei Farbänderung neu.

## 8. Verhalten

- Ein-/Ausblenden der ganzen Bar: sie gleitet um −(32 + topMargin) nach oben, **150 ms OutQuad**, `exclusiveZone` geht auf 0. Zustand wird in `~/.cache/skewbar/bar-state` gespeichert und beim Start wiederhergestellt.
- IPC: `qs -c skewbar ipc call bar toggle|show|hide` (Quickshell `IpcHandler`). Keybind-Beispiel für meinen Compositor mitliefern.
- Polling: WLAN alle 10 s, Wetter alle 10 min, Helligkeit alle 5 s, Systemwerte ~2 s.
- Optional: Akku-Benachrichtigungen per `notify-send` bei konfigurierbaren Schwellen.

## Vorgehen

1. Zuerst Plan + Dateiliste zeigen, dann bauen.
2. Mit Fenster, Inselformen, Farben und Uhr anfangen und mich per Screenshot vergleichen lassen, bevor du Dropdowns und Visualizer baust.
3. Nach jedem Schritt `qs -c skewbar` starten, Log auf QML-Fehler prüfen und beheben.
4. Keine Werte „verschönern" – die Zahlen oben sind gewollt.
