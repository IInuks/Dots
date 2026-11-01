# drop: eine Wassertropfen-Shell für mango

Oben am Bildschirmrand liegt ein dünner Wasserfilm, von dem die Module als
Perlen herabhängen. Die Perlen werden selbst zu ihren Menüs: erst streckt
sich die Perle nach unten zu einer Zunge, dann fließt sie mit
Gelee-Überschwingen seitlich zur Karte aus. Oben bleibt sie über ihre
Kehle mit der Decke verbunden, unten geht sie über weiche Kehlen in die
Karte über, ein Stück Wasser von der Decke bis zum Menü. Der aktive Tag
fließt als Tropfen von Tag zu Tag, CPU, RAM und Lautstärke sind Pegel in
kleinen Tropfen, und zum Abmelden wird der Bildschirm geflutet. Die Farben
kommen live aus dem Wallpaper.

## Was drin ist

| Teil | Datei | Was es macht |
|---|---|---|
| **Leiste** | `Bar.qml`, `Bead.qml` | Wasserfilm + hängende Perlen mit Meniskus-Kehle. Überfahren = die Perle wird schwerer und federt nach, Klick = Wellenring. Rinnt beim Start elastisch von oben herein. Links Quelle (Launcher), Tag-Tropfen, Fenstertitel · Mitte Uhr · Rechts Pegel CPU/RAM, Lautstärke (Rad = lauter/leiser, Mitte = stumm), Labor, Power |
| **Tag-Tropfen** | `TagDrops.qml` | Leer = Ring, belegt = kleiner Tropfen, aktiv = großer Tropfen mit Nummer. Beim Wechsel fließt er hinüber: Kopf voraus, der Schwanz zieht als Metaball-Kette nach und saugt unterwegs die kleinen Tropfen an. Mausrad wechselt Tags |
| **Perlen-Menüs** | `Drip.qml` | Rahmen aller Menüs: die Perle streckt sich zur Zunge und fließt zur Karte aus (Stiel + Kehlen, `L.bloom`), beim Schließen rückwärts (die Perle saugt die Karte wieder auf). Auch per Tastenkürzel geöffnet wächst das Menü aus seiner Perle. Ohne Leiste (Launcher-Host) wächst die Karte aus einem runden Tropfen |
| **Quelle** (Launcher) | `Launcher.qml` | Suche mit Lerneffekt, Treffer perlen gestaffelt herab, Auswahl fließt als Pfütze unter die Zeile, `=` rechnet (`=2^10`, `=19,5*3`) |
| **Klang** | `ControlCenter.qml` | Großer Pegel-Tropfen (Klick = stumm), Lautstärke, Mikro, Ausgabegerät |
| **Kalender** | `CalendarPopup.qml` | Tageskopf mit KW und Tag x von 365, heute ist ein Tropfen. Pfeile/Mausrad blättern, Klick auf den Monat = heute |
| **Pegelstand** | `SystemPopup.qml` | CPU und RAM als große, gefüllte Tropfen (schwappen bei jeder Messung), Pegelverlauf der letzten Minute, ein Röhrchen pro Kern, Uptime/Last |
| **Labor** | `Studio.qml` | Wasserfarbe (Wallpaper oder Tiefsee/Lagune/Regen/Tinte), Akzent aus den Wallpaper-Farben, Zähigkeit (Animationstempo: Starr/Wasser/Normal/Honig), Deckkraft, Wasserfilm, Wellenringe, Sekunden, Abdunkeln |
| **Flut** (Session) | `Session.qml` | Wasser steigt von unten in den Bildschirm, es regnet, die Aktionen schwimmen als Blasen auf den Wellen. **Gedrückt halten** zum Bestätigen: die Blase läuft voll |
| **Anordnen** | `Arrange.qml`, `Arranger.qml` | Perlen frei verschieben (siehe unten) |
| **OSD** | `Osd.qml` | Lautstärke/Mikro unten mittig als Tropfen, der bei jeder Änderung schwappt |

## Perlen anordnen

Labor → **Anordnen** (oder eine Perle kurz gedrückt halten). Die Perlen
bekommen einen Akzentrand und lassen sich mit der Maus ziehen. Lässt man
eine nah an (≤ 22 px) oder auf einer anderen los, schnappt sie an und
beide **verschmelzen zu einer Perle**: gerade Innenkanten, eine
gemeinsame Rundung außen, und beim Überfahren hängt die ganze Gruppe
zusammen tiefer. Herausziehen trennt sie wieder.

Auch die **Bildschirmkanten** sind Wände: nah an (oder ganz an) die
linke/rechte Kante gezogen, klebt die Perle ohne Abstand an der Wand und
verbindet sich mit ihr. Die Außenkante wird gerade, unten kriecht das
Wasser als kleine Kehle die Wand hinab. Hängt dort schon eine Gruppe,
schiebt sich die neue Perle an die Wand und verschmilzt mit ihr.

Unter der Leiste hängt dabei ein Tropfen mit:

| Knopf | Wirkung |
|---|---|
| Zurücksetzen | ungespeicherte Änderungen verwerfen (zurück zur gespeicherten Anordnung) |
| Löschen | gespeicherte Anordnung löschen, zurück zum Standard |
| Speichern | aktuelle Anordnung speichern (überlebt Neustarts) |
| Fertig | Modus beenden (Esc geht auch) |

Eine Gruppe merkt sich ihre Lage relativ zwischen linkem und rechtem
Rand (`pos` 0..1) bzw. ihre Wand (`wall` `l`/`r`), d. h. was rechts klebt, bleibt rechts, was mittig ist,
bleibt mittig, auch wenn Titel oder Uhr breiter werden. Gespeichert wird in
`drop.json` unter `layout`.

## Adaptives Theme

Wie in eierschale: `Wall.qml` fragt alle 5 s `awww query`, Quickshells
`ColorQuantizer` zieht 16 Farben aus dem Bild, `Theme.qml` macht daraus
Akzent (bunteste Farbe), Akzent 2 (größter Farbtonabstand) und die Tiefe
(dunkelste Farbe, sehr dunkel). Ein Farbwechsel gleitet in 0,9 s über.

Qt kann hier kein webp (qt6-imageformats fehlt). Solche Wallpaper wandelt
`Wall.qml` einmal per `magick` in ein kleines PNG unter `~/.cache/drop/` um.

Die aufgelöste Palette landet in `~/.local/state/drop/palette.json`, daraus
färbt sich das quickdots-Menü mit (`menu/adapters/live/DropLive.qml`).

## Bedienung / IPC

```sh
S=~/quickdots/bars/drop
qs -p $S -n                                   # starten
qs -p $S ipc call launcher toggle             # Quelle
qs -p $S ipc call session toggle              # Flut
qs -p $S ipc call panel toggle <launcher|control|calendar|system|studio|session>
qs -p $S ipc call theme refresh               # Wallpaper sofort neu einlesen
qs -p $S ipc call theme mode <wallpaper|tiefsee|lagune|regen|tinte>
qs -p $S ipc call layout <edit|done|save|revert|remove|dump>
qs -p $S ipc call debug pop system 2328 150   # Menü aus einer Perle bei x=2328, Breite 150
qs -p $S ipc call debug move vol 30           # Perle ziehen und mit linker Kante bei x=30 loslassen
```

Esc oder ein Klick daneben schließt jedes Menü. Über das quickdots-Menü
werden diese Tasten gebunden (`menu/adapters/drop.json`):

| Taste | Aktion |
|---|---|
| Super + Leertaste | Quelle |
| Super + Esc | Flut |
| Strg + Super + C | Klang |
| Strg + Super + S | Labor |

## Hinweise

- **Leistung** (165 Hz): Im Leerlauf läuft keine Dauer-Animation. Alle
  Flüssig-Formen sind kleine Canvas-Zeichnungen, die nur bei Änderungen neu
  malen (Hover, Tag-Wechsel, neue Messwerte). Regen und Wellen gibt es nur,
  solange die Flut offen ist, und die Wellen werden einmal gemalt und dann
  nur verschoben.
- **Deckkraft**: Film, Perlen, Stiel und Karte liegen jeweils in einer
  gemeinsamen Ebene, damit Überlappungen nicht dunkler werden.
- **Ohne DBus** (siehe mango-Session) gibt es kein Tray, kein MPRIS und
  keine Benachrichtigungen, deshalb fehlen diese Teile.
- **PipeWire**: Startet die Shell vor PipeWire, bleibt die Lautstärke tot
  (Quickshell versucht es nicht erneut). Der `exec-once` sollte wie bei
  kurtz auf `$XDG_RUNTIME_DIR/pipewire-0` warten.
- **Testen neben einer anderen Bar**: `DROP_TEST=1 qs -p $S -n` legt die
  Leiste auf die Overlay-Ebene, über die laufende Bar.
- Ohne Wallpaper (awww nicht gestartet) gilt das Preset „Tiefsee“.

## Dateien

```
shell.qml          Wurzel: Leisten, Overlays, OSD, IPC
Liquid.js          Geometrie: Perle (+ Verschmelzen/Wand), Tropfen, Metaball-Brücke, Blüte (Perle -> Menü), Welle
Theme.qml          Palette (Wallpaper, Presets, Überblenden), Maße, Tempo
Wall.qml           awww-Pfad (+ webp -> png) + ColorQuantizer
Settings.qml       gespeicherte Einstellungen (JsonAdapter)
Mango.qml          mmsg-Streams (Tags, Fenstertitel)
Arrange.qml        Anordnung der Perlen (live / gespeichert / Standard)
Arranger.qml       Knopf-Tropfen im Anordnen-Modus
Stats.qml Audio.qml Apps.qml Ui.qml Icons.qml Shots.qml
Bar.qml Bead.qml TagDrops.qml Droplet.qml
Overlay.qml Drip.qml Launcher.qml ControlCenter.qml CalendarPopup.qml
SystemPopup.qml Studio.qml Session.qml Osd.qml
Pegel.qml Schalter.qml Chip.qml Heading.qml Icon.qml Label.qml
```
