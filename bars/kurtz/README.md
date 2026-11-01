# kurtz: eine Kurzgesagt-Shell für mango

Entstanden aus dem Auftrag „überrasch mich mit einer Quickshell-Shell im
Kurzgesagt-Stil: viele Menüs, Animationen, Customization“, nach einem
ausführlichen Style-Guide (flache Vektorformen, weiches 3D nur aus
Farbschichten, optimistischer Nachthimmel). Der Name ist ein Wortspiel mit
*kurz*gesagt.

Der Style-Guide war für Hyprland/Niri/Sway geschrieben. Umgesetzt ist die
Shell für **mango** (Tags über `mmsg`), wie alle Nachbar-Bars hier.

![Leiste](docs/bar.png)

## Was drin ist

| Teil | Wo | Was es macht |
|---|---|---|
| **Leiste** | `modules/bar/` | Schwebende Kapsel (oder drei „Inseln“), Nachthimmel-Verlauf mit Sternen + Filmkorn. Links Heimat-Planet (Launcher), Tag-Planeten, Fenstertitel · Mitte Uhr mit Sonne/Mond · Rechts Medien, CPU/RAM/Temp-Ringe, Tray, Lautstärke, Netz, Glocke, Studio, Power |
| **Launcher** | `modules/launcher/` | Zentrierte Karte, Such-Pill, Treffer lernen aus deinen Starts, Buchstaben-Planeten als Icon-Ersatz, `=` macht daraus einen Taschenrechner |
| **Ereignishorizont** | `modules/launcher/OrbitLauncher.qml` | Alternativer Launcher (`launcherStyle: orbit`): schwarzes Loch in der Bildschirmmitte, die Apps kreisen als Planeten auf drei gekippten Bahnen darum (innen die besten Treffer, innen schneller). Jeder Tastendruck zieht die nicht passenden Apps spiralförmig ins Loch, der Rest gleitet auf neue Plätze. Starten verschluckt alles |
| **Kontrollzentrum** | `popups/ControlCenter.qml` | Begrüßung nach Tageszeit, 4 Schnellschalter, Lautstärke + Mikro, Ausgabegerät, Mini-Player |
| **Studio** | `popups/Studio.qml` | Die Customization-Zentrale, 4 Tabs (Farben, Leiste, Kosmos, Bewegung), alles live |
| **Kalender** | `popups/CalendarPopup.qml` | „Tagesbogen“: die Sonne wandert von 06 bis 20 Uhr über den Horizont (nachts der Mond), darunter der Monat |
| **System** | `popups/SystemPopup.qml` | Große Ringe, CPU/RAM-Verlauf als Sparkline (80 s), Balken pro Kern, Uptime/Last/Speicher |
| **Medien** | `popups/MediaPopup.qml` | Rundes Cover mit gepunktetem Orbit, der sich beim Abspielen dreht, Seek, Transport, Player-Wahl |
| **Mitteilungen** | `popups/NotifCenter.qml` | Verlauf, Nicht-stören, alle löschen |
| **Toasts** | `modules/notifications/` | Gleiten mit Overshoot rein, Urgency-Orb, Auto-Dismiss-Ring (pausiert bei Hover) |
| **OSD** | `modules/osd/` | Lautstärke-Kapsel, springt bei jeder Änderung hoch |
| **Session** | `modules/session/` | Vollbild-Sternenhimmel, großer Ringplanet, Ring-Buttons. **Gedrückt halten** zum Bestätigen (der Ring füllt sich) |

| | | |
|---|---|---|
| ![](docs/control.png) | ![](docs/studio.png) | ![](docs/calendar.png) |
| ![](docs/system.png) | ![](docs/notifications.png) | ![](docs/media.png) |

![Launcher](docs/launcher.png)
![Session](docs/session.png)
![Toasts + OSD](docs/toasts-osd.png)
![Inseln-Modus mit Sonnensystem-Tags](docs/bar-inseln.png)

### Kleine Überraschungen

- Die Tags sind **Planeten**. Der aktive bekommt einen Saturn-Ring und
  springt mit Overshoot auf. Leere Tags sind **schwarze Löcher** mit
  rotierender Akkretionsscheibe und gelinstem Lichtbogen (oder, im Studio
  wählbar, Staubkörner bzw. ganz ausgeblendet). Im Studio färbt
  „Sonnensystem“ jeden Tag in einer eigenen Planetenfarbe.
- Den Heimat-Planeten (Launcher) umkreist ein kleines **schwarzes Loch**, mal hinter, mal vor ihm. Fährst du mit der Maus drüber, kommt noch ein kleiner gelber Mond dazu.
- Im Schnitt alle 30 s (einstellbar) zieht eine **Sternschnuppe** über Popups und Launcher.
- Die Uhr-Sonne wechselt mit der Tageszeit: Morgenrot orange, tagsüber
  gelb, abends orange, nachts ein Mond mit zwei Sternchen.
- Die Glocke wackelt bei neuen Mitteilungen.
- Der Launcher lernt: Häufig gestartete Apps rutschen nach oben (Zähler in
  `~/.local/state/quickshell/by-shell/<id>/launches.json`).
- Der Session-Planet nimmt die Farbe der gewählten Aktion an und glüht
  heller, während der Ring sich füllt.

## Starten

```sh
# Test (läuft neben der aktiven Bar, -n = nur eine Instanz)
qs -p ~/quickdots/bars/kurtz -n

# beenden
qs -p ~/quickdots/bars/kurtz kill

# als aktive Bar über den Bar-Switcher
~/quickdots/menu/scripts/switch-bar.sh kurtz
```

Adapter für den Switcher: `quickdots/menu/adapters/kurtz.json` mit diesen Keybinds:

| Taste | Aktion |
|---|---|
| `SUPER+Space` | Launcher |
| `SUPER+Escape` | Session-Menü |
| `CTRL+SUPER+C` | Kontrollzentrum |
| `CTRL+SUPER+S` | Studio |
| `CTRL+SUPER+N` | Mitteilungen |

## IPC

```sh
K=~/quickdots/bars/kurtz
qs -p $K ipc call panel toggle <id>     # launcher control studio calendar system media notifications session
qs -p $K ipc call panel close
qs -p $K ipc call launcher toggle
qs -p $K ipc call session toggle
qs -p $K ipc call config set accent magenta     # jede Config-Option, Typen werden geparst
qs -p $K ipc call config toggle grain
qs -p $K ipc call config reset
qs -p $K ipc call theme regen                 # Wallpaper-Farben neu einlesen
qs -p $K ipc call theme wallpaper             # welches Bild gerade gilt
qs -p $K ipc call notify demo "Titel" "Text" 1  # Test-Mitteilung ohne DBus (0 low, 1 normal, 2 kritisch)
qs -p $K ipc call notify dnd
qs -p $K ipc call debug shot bar@DP-4 /tmp/bar.png   # Item als PNG (siehe `debug items`)
```

## Customization

### Adaptives Theme

`sky` und/oder `accent` auf `wallpaper` (im Studio: letzte Kachel bzw.
letzter Planet) holt die Farben aus dem aktuellen Hintergrundbild.
Das ist der Standard. Wechselst du das Bild mit **shellwall**, zieht kurtz
sofort nach: `Wallpaper.qml` überwacht die Dateien, die shellwalls
matugen-/pywal-Lauf neu schreibt (`~/.cache/ricev2/colors.json`,
`~/.cache/wal/colors.json`), fragt dann `awww query` nach dem Bild und
lässt `matugen` darauf laufen (~0,2 s). Anders gesetzte Wallpaper fängt
eine Abfrage alle 10 s ab. Von dessen Material-Paletten werden nur die
**Farbtöne** übernommen: Himmel und Flächen bekommen die gewohnten dunklen
Helligkeitsstufen, leicht Richtung Blauviolett gezogen (warme Bilder
ergeben einen Abendhimmel statt Braun). Der Akzent wird auf volle
Kurzgesagt-Leuchtkraft gebracht, `accent2` kommt aus der Tertiärfarbe.
Ohne `awww`/`matugen` bleibt es bei `nebula`/`cyan`, das Studio zeigt den
Grund an. Die Statusfarben (ok/warn/crit) bleiben fest.


Alles über das **Studio** (Palette-Knopf in der Leiste) oder direkt in
`config.json` in diesem Ordner. Die Datei wird überwacht, Handänderungen
greifen sofort, ein Neustart ist nie nötig. Fehlt sie oder fehlen einzelne
Schlüssel, schreibt die Shell die Defaults hinein.

| Schlüssel | Default | Bedeutung |
|---|---|---|
| `sky` | `wallpaper` | Hintergrund: `nebula` `deepsea` `sunset` `aurora` `void` `wallpaper` |
| `accent` | `wallpaper` | `cyan` `blue` `purple` `magenta` `orange` `yellow` `red` `green` `wallpaper` |
| `glow` | `0.65` | Stärke aller Glows (0–1) |
| `grain` | `true` | 4,5 % Filmkorn auf großen Flächen |
| `stars` / `starCount` | `true` / `36` | Sternenfeld |
| `twinkle` | `true` | Sterne flackern (Popups, Launcher, Session) |
| `barTwinkle` | `false` | Funkeln + Sonnenpuls auch in der Leiste (kostet CPU, s. u.) |
| `nebula` | `true` | Weiche Farbwolken hinter Leiste und Karten |
| `shootingStars` / `cometEvery` | `true` / `30` | Sternschnuppen, mittlerer Abstand in s |
| `planetRings` | `true` | Saturn-Ring um aktive Orbs |
| `planetStyle` | `planet` | `planet` oder `blackhole`: Akzent-Bälle, aktiver Tag und Heimat-Planet als schwarze Löcher in der Akzentfarbe |
| `planetScale` | `1.0` | Größe der Tag-Planeten |
| `tagPalette` | `accent` | `accent` oder `planets` (jeder Tag eigene Farbe) |
| `emptyTags` | `blackhole` | Leere Tags: `blackhole` `dust` `hidden` |
| `launcherHole` | `orbit` | Schwarzes Loch am Heimat-Planeten: `orbit` `beside` `off` |
| `launcherStyle` | `list` | `list` (Karte) oder `orbit` (Ereignishorizont), auch im Studio unter Bewegung → Popups |
| `blackHoleColor` | `warm` | Scheibe: `warm` `accent` `violet` `ice` |
| `blackHoleSpin` / `blackHoleSpeed` | `true` / `1.0` | Rotation der Scheibe (Leiste zeichnet dann laufend neu) |
| `barPosition` | `top` | `top` / `bottom` (Popups, Caret und Toasts drehen mit) |
| `barStyle` | `capsule` | `capsule` / `islands` |
| `barHeight` / `barMargin` / `barAlpha` | `46` / `10` / `0.92` | Geometrie |
| `radiusScale` / `fontScale` | `1.0` | Rundung / Schriftgröße |
| `showLauncher` `showTitle` `showMedia` `showStats` `showTray` | `true` | Module ein/aus |
| `showClockOrb` / `showDate` | `true` | Sonne/Mond und Datum in der Uhr |
| `clock24` / `showSeconds` | `true` / `false` | Uhr |
| `locale` | `de_DE` | Tag-/Monatsnamen |
| `animations` | `true` | Aus = alle Dauern 0, keine Ambient-Effekte |
| `animSpeed` | `1.0` | Multiplikator auf alle Dauern (>1 ruhiger) |
| `tagSwitch` | `comet` | Tag-Wechsel in der Leiste: `comet` (Komet fliegt zum neuen Tag, Schockring beim Einschlag) oder `off`, auch im Studio unter Bewegung |
| `popupDim` | `0.22` | Abdunkeln hinter Popups (Launcher: ×2,3) |
| `osd` | `true` | Lautstärke-Kapsel |
| `toastSide` | `right` | Mitteilungen `left` / `right` |
| `dnd` | `false` | Nicht stören (kritische Mitteilungen kommen trotzdem) |
| `toastTimeout` | `6` | Sekunden |

Farben, Radien, Abstände, Dauern und Schriften stehen alle in **`Theme.qml`**.
Die Komponenten enthalten keine hartcodierten Werte.

## Stil-System

**Palette** (`Theme.qml`):

- Himmel (Verlauf oben nach unten): `#0B0F2F` → `#14164A` → `#2B1B6B` (nebula), mit 0,92–0,97 Alpha
- Flächen: `#1B1E5A`, raised `#262A73`, hover `#313690`, sunken `#12143F`
- Akzente: Cyan `#38BDF8` · Blau `#3B82F6` · Lila `#A855F7` · Magenta `#E879F9` · Orange `#FB923C` · Gelb `#FACC15` · Rot `#F43F5E` · Grün `#34D399`
- Text `#F5F3FF`, gedämpft `#94A3B8`. Nie reines Schwarz oder Weiß.
- Semantik: Akzent = aktiv, Gelb/Orange = Warnung/Energie, Rot = kritisch, Grün = ok, Lila = Medien

**Lichtquelle: immer oben links.** Das Herzstück ist `components/Orb.qml`:

```
Ebene 0  Glow       Radialverlauf dahinter (optional)
Ebene 1  Schatten   ganze Scheibe, dunkler + Richtung Blau/Violett verschoben
Ebene 2  Basis      kleinere Scheibe, innen tangential oben links:
                    von Ebene 1 bleibt nur eine scharfe Sichel unten rechts
Ebene 3  Highlight  heller Kapsel-Fleck + Punkt oben links
Ebene 4  Rim        dünner heller Bogen auf der Schattenseite
Ebene 5  Ring       optionaler Planetenring, hintere Hälfte hinter, vordere vor dem Körper
```

Die Ebenen liegen geometrisch ineinander. Masken oder `clip` sind deshalb
nicht nötig. Schatten-, Highlight- und Rim-Töne leitet `Theme.shadeOf`,
`highlightOf` und `rimOf` aus der Grundfarbe ab. So schattiert jeder Orb in der
Shell gleich: Tags, Knöpfe, Slider-Knöpfe, Toggle, Urgency-Punkte, die
Sonne, der Session-Planet.

**Tiefe:** `Backdrop.qml` stapelt weichen Schatten, diagonalen Nachtverlauf und
einen maskierten Deko-Layer (Nebelglows, Sterne, Korn) übereinander. Darüber
liegen Pills und Karten, ganz vorne Icons und Text. Positionen der Sterne
kommen aus einem Hash (Index + Seed), der Himmel sieht also nach jedem Reload
gleich aus.

**Bewegung:** 180/260/320 ms OutCubic, „Pop“ mit OutBack. Hover skaliert auf
1,04, Druck auf 0,96, Slider- und Planetenknöpfe quetschen sich beim Drücken
(Squash & Stretch). Popups blenden ein, gleiten 10 px und skalieren von 0,96.

**Schrift:** Poppins → Montserrat → Sofia Pro → Inter → **Adwaita Sans**
(installiert, Inter-basiert) → Noto Sans. Qt kennt keine CSS-Fallback-Liste,
deshalb wählt `Theme._pick()` einmal die erste installierte Schrift. Icons
sind gefüllte Material-Design-Glyphen aus der installierten JetBrainsMono
Nerd Font Propo (`Glyphs.qml`). Alle Codepoints wurden gegen die Charset-Tabelle
der Schrift geprüft. Wer Poppins installiert (`ttf-poppins` im Arch-Stratum),
bekommt sie automatisch.

## Struktur

```
shell.qml              Root: Bar + Overlay pro Bildschirm (Variants),
                       NotificationServer, alle IpcHandler
Config.qml             Singleton: config.json (FileView, überwacht, eigenes Sync)
Theme.qml              Singleton: Farben, Himmel, Shading-Funktionen, Radien,
                       Abstände, Dauern, Schriften, Locale
Glyphs.qml             Singleton: Nerd-Font-Codepoints mit Namen
assets/noise.png       128x128 Rauschtextur (deterministisch erzeugt)
components/            Orb, BlackHole, Glow, Ring, StarField, Backdrop, Pill, IconBadge,
                       Slider, Toggle, Chip, Tile, SettingRow, SectionTitle,
                       SkyOrb, CoverArt, Sparkline, NotifCard, KLabel, KIcon
services/              Tags (mango), Stats (/proc,/sys), Sound (Pipewire),
                       Player (MPRIS), Net (NetworkManager + sysfs-Fallback),
                       Notifs, Apps (Suche + Launch-Zähler), Popups, Session,
                       Shots (Debug-Screenshots)
modules/bar/           Bar, Section, LauncherButton, Workspaces, WindowTitle,
                       ClockPill, MediaPill, StatsPill, TrayPill, StatusCluster
modules/popups/        Overlay (Fenster), PopupCard (Rahmen + Caret + Motion)
                       und die sechs Popup-Inhalte
modules/launcher/  modules/session/  modules/notifications/  modules/osd/
docs/                  Screenshots
```

`qmldir`: Der Style-Guide verlangt eine eigene `qmldir` für den Theme-Singleton.
Quickshell erzeugt pro Verzeichnis selbst eine, aus `pragma Singleton`.
Einen Import aus einem Unterordner (`import "../services"`) habe ich vorab
getestet. Eine handgeschriebene `qmldir` würde mit dieser Erzeugung kollidieren
und bringt nichts, deshalb gibt es keine.

## Befunde zu diesem System (wichtig)

Beim Testen aufgefallen, gilt für **alle** Bars in quickdots, nicht nur kurtz:

1. **Keine DBus-Session in der mango-Umgebung.** `DBUS_SESSION_BUS_ADDRESS` ist
   nicht gesetzt und `/run/user/1000/bus` existiert nicht. Die laufende ricev2
   loggt dieselben Warnungen. Folge: **MPRIS (Medien), System-Tray und der
   Notification-Server funktionieren in keiner Bar.** kurtz blendet Medien und
   Tray dann einfach aus und zeigt im Medien-Popup „Stille im All“.
   Lösung: mango über `dbus-run-session mango` starten (bzw. im Login-Skript
   die Session-Bus-Adresse exportieren). Ich habe das bewusst nicht geändert,
   weil es den Session-Start betrifft.
2. **NetworkManager läuft nicht** (`nmcli: NetworkManager is not running`).
   `Quickshell.Networking` hat damit kein Backend. `services/Net.qml` fällt
   dann auf `/sys/class/net/*/operstate` zurück (alle 10 s, nur solange NM
   fehlt) und zeigt „Ethernet“ oder „WLAN“ an. Den WLAN-Schalter gibt es nur mit NM.
3. **Kein Backlight, kein Akku** (Desktop). Beides ist bewusst weggelassen, statt
   leere Widgets zu zeigen.
4. Power-Aktionen nutzen `strat void loginctl …` (elogind-fähig), mit
   Fallback auf normales `loginctl`. Abmelden ist `mmsg dispatch quit`.

## Performance

Gemessen mit `/proc/<pid>/stat` im Leerlauf: **~0,25 % CPU**. Die ricev2 liegt bei ~0,1 %.

- Dein Monitor läuft mit ~165 Hz. Jede laufende Animation rendert das
  Fenster mit 165 fps. Die Ringe in der Leiste tweenten anfangs alle 2 s für
  640 ms, das ergab ~3,5 % CPU. Deshalb springen die Mini-Ringe jetzt direkt
  (`animated: false`). Die großen Ringe im System-Popup animieren weiter.
- In der Leiste ist Ambient-Bewegung (Funkeln, Sonnenpuls) standardmäßig aus
  (`barTwinkle`). Popups, Launcher und Session funkeln, solange sie offen sind.
- Popup-Inhalte liegen in `Loader`s und existieren nur, solange die Karte
  sichtbar ist. Alle Stern-Animationen stoppen, wenn ihr Feld unsichtbar ist.
- Der Fenstertitel blendet nur beim App-Wechsel über, nicht bei jeder
  Titeländerung. Terminals mit Spinner im Titel (z. B. Claude Code) ändern ihn
  sonst mehrmals pro Sekunde.
- `MultiEffect` nur für die abgerundete Maske des Deko-Layers (1× pro Karte bzw.
  Leiste) und für runde Cover. Glows sind reine Radialverläufe ohne Blur-Pass.

## Getestet / nicht getestet

Getestet mit `qs -p . -d` + IPC auf DP-4 (2560×1440):

- Laden ohne QML-Warnungen, auch nach dem Öffnen aller Popups
- Jedes Popup per Screenshot-Hook geprüft (`debug shot`), inklusive aller vier Studio-Tabs
- Kapsel- und Inseln-Modus, Leiste oben/unten, Akzent-/Himmel-/Tag-Palette-Wechsel live, `config reset`
- Toasts (normal + kritisch) per `notify demo`, OSD durch `wpctl set-volume`

Nicht getestet (fehlender DBus-Bus bzw. keine echte Maus- oder Tastatureingabe
im Test):

- Echte Mitteilungen über DBus, Aktionen-Buttons
- MPRIS-Player, Tray-Menüs
- Tippen im Launcher, Hover-Effekte, Session-Halten mit der Maus, Tastatur-Navigation

Bewusst weggelassen: ein **Lockscreen**. Ohne installierten Locker müsste
er über `WlSessionLock` + PAM laufen. Ein Fehler darin sperrt dich aus, und
ohne echte Passworteingabe ließ sich das hier nicht sicher testen. Guter
Kandidat für eine nächste Runde.

## Bekannte Fallen (für künftige Sessions)

- Singleton-Namen wie `Palette`, `Colors`, `Layout` kollidieren still mit
  Qt-Builtins (siehe bars/claude/README.md). Deshalb heißen die Text-Komponenten
  `KLabel`/`KIcon` statt `Label`/`Icon`, und `Sound` hat das Signal `bumped`
  statt `changed`.
- `ShapePath` hat kein `parent`. In Inline-Komponenten auf die `Shape`-`id`
  verweisen (siehe Planetenring in `Orb.qml`).
- Quickshell lädt bei jeder Dateiänderung neu. Screenshots direkt nach einem
  Edit zeigen oft noch den alten Stand, also ein paar Sekunden warten.
- `qs -p . -n` beendet sich sofort, wenn schon eine Instanz läuft. Mit
  `qs -p . list` prüfen und mit `qs -p . kill` beenden.
- **mango verschiebt zu hohe Layer-Surfaces.** Ist ein `PanelWindow` höher als
  seine `exclusiveZone`, schiebt mango es um die Differenz Richtung Bildschirmrand.
  Die Leiste war dadurch oben abgeschnitten. Deshalb gilt in `Bar.qml`:
  Fensterhöhe = exclusiveZone, ohne Extra-Platz für den Schatten.
- **Config-Watcher und eigene Schreibvorgänge.** `config.json` wird überwacht.
  Ein Reload, den das eigene Speichern auslöst, konnte einen gerade geklickten
  Wert zurücksetzen (Sterne ließen sich nicht mehr ausschalten).
  Die erste Lösung (1,5 s nach dem eigenen Schreiben alles ignorieren)
  verschluckte dafür fremde Änderungen in diesem Fenster endgültig, bis zum
  Neustart. Jetzt: jede Änderung wird geladen, eigene Schreibvorgänge werden
  am exakten Text erkannt, und im Studio geänderte, noch nicht gespeicherte
  Schlüssel gewinnen gegen die Datei.
- Echte Bildschirmfotos ohne grim: eine Mini-Shell mit `ScreencopyView` +
  `grabToImage` (so wurde der Leisten-Versatz gefunden).
