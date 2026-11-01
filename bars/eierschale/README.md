# eierschale: eine Überraschungsei-Shell für mango

Entstanden aus „überrasch mich mit einer kompletten Quickshell-Shell mit
vielen Animationen, Menüs, einer Bar und adaptivem Theme“. Der Ordner hieß
erst `ueberaschung`. Der Name ist ein Wortspiel: eine Quick*shell*-Shell,
die aussieht wie eine *Eierschale*.

Alles dreht sich ums Ei: Tags sind Eier, der Launcher ist ein Nest, die
Schalter haben Ei-Knubbel, heute im Kalender ist ein Ei, und in der Mitte
der Leiste liegt ein echtes Überraschungsei mit Sammelfiguren.

## Adaptives Theme

Die Farben kommen aus dem **aktuellen Wallpaper**:

1. `Wall.qml` fragt alle 5 s `awww query` nach dem Bildpfad (awww hat keine
   Events). Nur wenn sich der Pfad ändert, passiert etwas.
2. Quickshells `ColorQuantizer` zieht 16 Farbkandidaten aus dem Bild.
3. `Theme.qml` leitet ab: **Akzent** = buntester Kandidat (auf lesbare
   Helligkeit gezogen), **Akzent 2** = der Kandidat mit dem größten
   Farbtonabstand, **Grund** = Farbton der dunkelsten Farbe, sehr dunkel.
4. Jede Farbe gleitet in 0,9 s über. Ein neues Wallpaper färbt also die
   ganze Shell sanft um.

In der **Werkbank** lässt sich der Akzent aus den Wallpaper-Kandidaten
wählen, oder man nimmt ein festes Preset (Schoko, Ostern, Mitternacht,
Minze). Die aufgelöste Palette landet zusätzlich in
`~/.local/state/eierschale/palette.json`. Daraus färbt sich auch das
quickdots-Menü mit (`menu/adapters/live/EierschaleLive.qml`).

## Was drin ist

| Teil | Datei | Was es macht |
|---|---|---|
| **Leiste** | `Bar.qml` | Schwebende Kapsel (oder bündig), schlüpft beim Start mit Überschwingen von oben herein. Links Nest (Launcher), Tag-Eier, Fenstertitel · Mitte Uhr, Überraschungsei · Rechts CPU/RAM-Ringe, Lautstärke (Rad = lauter/leiser, Mitte = stumm), Werkbank, Power |
| **Tag-Eier** | `TagEggs.qml` | Leer = Umriss, belegt = gefüllt, aktiv = schlüpft zur Pille mit Nummer. Mausrad wechselt Tags |
| **Nest** (Launcher) | `Launcher.qml` | Suche mit Lerneffekt (oft Gestartetes rutscht hoch), Treffer purzeln gestaffelt rein, `=` rechnet (`=2^10`, `=19,5*3`) |
| **Schaltzentrale** | `ControlCenter.qml` | Begrüßung, Lautstärke, Mikro, Ausgabegerät, 4 Schnellschalter, aktuelle Palette |
| **Kalender** | `CalendarPopup.qml` | Großer Tageskopf, KW, Tag x von 365; Monat gleitet beim Blättern (Pfeile/Mausrad), Klick auf den Titel = heute |
| **System** | `SystemPopup.qml` | Große Ringe, Verlauf der letzten Minute, Balken pro Kern, Uptime/Last |
| **Überraschungsei** | `EggPopup.qml`, `ToyView.qml`, `Eggs.qml` | Siehe unten |
| **Werkbank** | `Studio.qml` | Farbquelle, Akzent, Schweben, Rundung, Deckkraft, Sekunden, Animationstempo (Aus/Flott/Normal/Gemütlich), Ei-Wackeln, Abdunkeln. Alles live und gespeichert |
| **Session** | `Session.qml` | Vollbild, großes Ei. Abmelden, Ruhezustand, Neustart, Ausschalten, **gedrückt halten** zum Bestätigen: Ring füllt sich, das Ei bekommt Risse |
| **OSD** | `Osd.qml` | Lautstärke/Mikro unten mittig, auch bei Änderungen per Tasten/`wpctl` |

### Das Überraschungsei

Klick aufs Ei in der Leiste, dann aufs große Ei: es zittert, die Folie
geht ab, ein Riss läuft herum, die Schale springt auf, die gelbe Kapsel
hüpft raus und klappt auf, und mit einem Funkenregen erscheint eine Figur.
**Leertaste/Enter** öffnet das nächste Ei.

Zehn Figuren, jede zum Spielen:

| Nr. | Figur | Seltenheit | Spielen |
|---|---|---|---|
| 1 | Würfel | normal | würfeln |
| 2 | Glücksmünze | normal | werfen, Kopf oder Zahl |
| 3 | Glückskeks | normal | Spruch ziehen |
| 4 | Orakelkugel | normal | schütteln, Ja/Nein-Antwort |
| 5 | Luftpolsterfolie | normal | 24 Blasen ploppen |
| 6 | Farbe des Tages | selten | jeden Tag eine; Klick kopiert den Hexwert |
| 7 | Mondphase | selten | echte Mondphase von heute |
| 8 | Sanduhr | selten | 1/5/10/25-min-Wecker; läuft weiter, Ring ums Leisten-Ei, klingelt (Ei zittert) |
| 9 | Jahresuhr | selten | Fortschritt von Jahr/Monat/Woche/Tag |
| 10 | Goldenes Ei | sehr selten (3 %) | glänzt |

Das Sammelregal unten zeigt, was du schon hast. Gefundene Figuren kann man
jederzeit wieder anklicken. Die Sammlung wird gespeichert.

## Bedienung / IPC

```sh
S=~/quickdots/bars/eierschale
qs -p $S -n                                  # starten
qs -p $S ipc call launcher toggle            # Nest
qs -p $S ipc call session toggle             # Session
qs -p $S ipc call egg crack                  # Menü auf + sofort ein Ei knacken
qs -p $S ipc call panel toggle <launcher|control|calendar|system|egg|studio|session>
qs -p $S ipc call theme refresh              # Wallpaper sofort neu einlesen
qs -p $S ipc call theme mode <wallpaper|schoko|ostern|mitternacht|minze>
qs -p $S ipc call debug shot <name@DP-4> /tmp/x.png   # Element als PNG (kein grim hier)
```

Esc schließt jedes Menü, Klick daneben auch. Über das quickdots-Menü
werden diese Tasten gebunden (`menu/adapters/eierschale.json`):

| Taste | Aktion |
|---|---|
| Super + Leertaste | Nest |
| Super + Esc | Session |
| Strg + Super + E | Ei knacken |
| Strg + Super + C | Schaltzentrale |
| Strg + Super + S | Werkbank |

## Hinweise

- **Leistung** (165 Hz!): Im Leerlauf läuft keine Dauer-Animation. Alle
  Eier sind Canvas-Zeichnungen, die nur bei Änderungen neu malen. Das
  Leisten-Ei wackelt alle 45 s kurz (abschaltbar), die Menü-Ebene existiert
  nur, solange ein Menü offen ist.
- **Ohne DBus** (siehe mango-Session) gibt es kein Tray, kein MPRIS und
  keine Benachrichtigungen, deshalb hat die Shell diese Teile gar nicht erst.
  Die Sanduhr ruft trotzdem `notify-send` auf, falls es mal geht.
- **Sperren** fehlt absichtlich: es ist kein Locker installiert.
- Ohne Wallpaper (awww nicht gestartet) gilt das Preset „Schoko“.

## Dateien

```
shell.qml          Wurzel: Leisten, Overlays, OSD, IPC
Theme.qml          Palette (Wallpaper-Ableitung, Presets), Maße, Tempo
Wall.qml           awww-Pfad + ColorQuantizer
Settings.qml       gespeicherte Einstellungen (JsonAdapter)
Mango.qml          mmsg-Streams (Tags, Fenstertitel)
Stats.qml Audio.qml Apps.qml Eggs.qml Ui.qml Icons.qml Shots.qml
Bar.qml TagEggs.qml BarClock.qml SurpriseEgg.qml MiniRing.qml
Overlay.qml PopupCard.qml Launcher.qml ControlCenter.qml CalendarPopup.qml
SystemPopup.qml EggPopup.qml ToyView.qml Studio.qml Session.qml Osd.qml
EggShape.qml Knopf.qml Schieber.qml Schalter.qml Ring.qml Kurve.qml Icon.qml Label.qml
```
