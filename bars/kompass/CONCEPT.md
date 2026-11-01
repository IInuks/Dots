# Konzept — kompass

> Ersetzt bei diesem Projekt den sonst vom Nutzer stammenden "Ursprungs-Prompt":
> der Auftrag war "überrasch mich mit einer Quickshell-Bar". Alles Folgende ist
> Claudes eigener Entwurf, im selben Detailgrad dokumentiert wie die Prompts der
> anderen Bars (siehe z. B. `bars/blobs/quickshell-bar-prompt-v2.md`), damit
> spätere Sessions hier genauso anknüpfen können wie bei einem nutzereigenen
> Auftrag.

## Leitidee

Eine Quickshell-Leiste für MangoWM im Look eines **analogen Messgeräte-Panels**
— Zeigerinstrumente, Drehknöpfe, geriffeltes Messing/Metall, Nietenreihen an
den Kanten, kleine Kontrolllämpchen. Kein Pixel Schrift-Digitalanzeige (das ist
`fisheye`s LCD-Terrain), keine morphenden Formen (das ist `blobs`' Terrain).
Alles hier bewegt sich wie ein physisches Instrument: Zeiger drehen sich,
Trommeln rotieren, Schalter kippen.

Drei Module in der Ruheleiste, von links nach rechts:

1. **Kompassrose** — zeigt den aktiven Mango-Tag als Peilung. Eine feststehende
   Rose mit Gradmarkierungen, eine Nadel dreht sich auf die Position des
   aktiven Tags. Klick auf eine Tag-Position springt dorthin (`viewcrossmon`).
2. **Zeit-Trommel** — Stunden/Minuten als zwei kleine Walzen wie ein
   mechanisches Zählwerk (Za­poznaj-Zähler/Kilometerzähler-Optik), Ziffern
   rollen beim Wechsel statt zu springen.
3. **Temperatur-Zeigerinstrument** — CPU-Temperatur als klassisches
   Rundinstrument mit Skala, Zeiger schlägt aus wie ein Thermometer/Manometer.
   Grün/Amber/Rot-Zonen auf der Skala selbst sichtbar (nicht nur Zeigerfarbe).

Perspektivisch (siehe Etappenplan) bekommen weitere Module eigene
Zeigerinstrumente: RAM als zweites Manometer, Netzwerk als Signalstärke-
Zeiger, Lautstärke als Drehknopf-Popup mit echten Kippschaltern für Mute.

## Stack & Umgebung (geprüft)

- Quickshell 0.3.0 (Nixpkgs), MangoWM (dwl-basiert) — Status ausschließlich
  über `mmsg`, kein Hyprland-IPC.
- `mmsg`-Kommandos, die es in dieser Version tatsächlich gibt (per `mmsg
  --help` geprüft, **nicht** die `-g -t`/`-w -t`-Form aus älteren Bar-
  Prompts): `get/watch all-monitors`, `get/watch focusing-client`,
  `dispatch view,<mask>,<synctag>`, `dispatch viewcrossmon,<mask>,<monitor>`.
  `MangoIpc.qml` ist 1:1 aus `bars/fisheye` übernommen (dort bereits gegen
  genau diese mmsg-Version verifiziert), nicht neu erfunden.
- Sensoren: `k10temp` liefert `Tctl` (CPU), `amdgpu` liefert `edge` (GPU) —
  `Cpu.qml` ist 1:1 aus `bars/blobs` übernommen (dort bereits gegen diese
  hwmon-Belegung verifiziert).
- Palette: `~/.cache/wal/colors.json` (pywal/shellwall), live per `FileView`
  — `Theme.qml` folgt demselben Muster wie `bars/fisheye/Theme.qml`
  (HSL-Ableitung, `Behavior`-Crossfade pro Rolle, keine `on[A-Z]`-Properties
  wegen des bekannten Segfault-Bugs — siehe dortiger Kommentar).
- Kein `matugen`-Template nötig (anders als `blobs`) — pywal reicht für
  dieses Farbschema, es gibt hier keinen Wallpaper-Grid-Anspruch.
- `awww` ist der aktuelle Name des Wallpaper-Daemons (Upstream-Rename von
  `swww`), falls ein späteres Modul das Wallpaper wechseln soll.

## Geometrie

- `PanelWindow`, `anchors.top`, `exclusiveZone` = Ruhehöhe der Leiste (44px),
  volle Bildschirmbreite, transparenter Fensterhintergrund.
- Panel selbst: horizontal zentrierter Messing-Streifen, Höhe 44px, Breite
  wächst mit Inhalt, `radius` 10px, sichtbare Nietenreihe oben/unten (kleine
  Kreise mit Bevel-Licht/Schatten aus `Theme.bevelLight`/`bevelDark`).
- Drei Module mit 1px eingelassener Trennlinie (`Theme.bevelDark`) dazwischen,
  kein Abstand — wirkt wie ein durchgehendes Panel, nicht wie separate
  Widgets.
- Popups (spätere Etappe) klappen wie ein Instrumenten-Klarsichtdeckel nach
  unten auf: kein Morph der Ruheform, sondern ein eigenes Panel darunter, das
  an der Oberkante des jeweiligen Moduls andockt.

## Module im Detail

### Kompassrose (links, ~70×36 im Kreis)

- `Shape`/`ShapePath` mit `PathAngleArc` für den äußeren Ring (analog zu
  `fisheye`s Temperaturring-Technik), Gradmarkierungen alle 30°, N/O/S/W
  beschriftet (bzw. bei diesem Bar besser: Tag-Nummern 1–9 an den
  entsprechenden Positionen, gleichmäßig über 360° verteilt).
- Nadel: schmales `Rectangle` oder `Shape`-Dreieck, `transform: Rotation`,
  Zielwinkel = `(aktiverTag - 1) / 9 * 360`. Kürzester Drehweg beim Wechsel
  (Winkel-Delta auf ±180° normalisieren, bevor die `Behavior`/Animation den
  Zielwert bekommt — sonst dreht die Nadel bei 9→1 einmal ganz herum statt
  den kurzen Weg zu nehmen).
- Klick auf eine Tag-Position: `MangoIpc.viewTag(screenName, index)`.
- Datenquelle: `MangoIpc.activeTagsFor(screenName)` (Stream läuft bereits,
  kein eigenes Polling nötig).

### Zeit-Trommel (Mitte, feste Breite)

- Vier Ziffern-Walzen (HH:MM), jede eine `Column` mit Ziffern 0–9
  übereinander, sichtbarer Ausschnitt per `clip: true` auf Zifferhöhe, `y`
  animiert (`Behavior on y`, `Easing.OutBack`, ~260ms) beim Ziffernwechsel —
  wirkt wie eine rollende Zählwerk-Walze, nicht wie ein Fade.
- Doppelpunkt blinkt sanft (Opacity-Loop, ~1s) wie ein mechanisches Relais,
  nicht hart an/aus.
- Minütlich aktualisiert, auf volle Minute synchronisiert.

### Temperatur-Zeigerinstrument (rechts, ~70×36 im Kreis)

- Skala 30–95°C über 270° Sweep (−135° bis +135°, unten 90° Lücke — klassische
  Rundinstrument-Optik, nicht `fisheye`s 240°/120°-Ring).
- Skalenfarbe selbst dreigeteilt: grün (30–65°C), amber (65–80°C), rot
  (80–95°C) als drei `PathAngleArc`-Segmente hinter den Tick-Marks, nicht nur
  Zeigerfarbe.
- Zeiger dünn, rot, mit kleiner Nabe in der Mitte (`Rectangle radius: width/2`).
- Datenquelle: `Cpu.qml` (1:1 aus `blobs` übernommen), `Behavior on angle`
  ~400ms.

## Popups (spätere Etappen, noch nicht spezifiziert im Detail)

Analog zu den bereits gebauten Bars: Audio (Pipewire, Kippschalter für Mute,
Drehregler für Lautstärke), Netzwerk/Bluetooth, Power-Menü, App-Launcher
(`Quickshell.DesktopEntries`, `SUPER+space`, `IpcHandler target: "launcher"`
wie bei `fisheye`/`blobs`). Aufklappen als eigenes Panel unter dem jeweiligen
Modul, nicht als Morph. Details werden verfeinert, wenn diese Etappe
ansteht — kein Grund, das jetzt schon festzunageln.

## Qualitätsanforderungen

- Läuft mit `qs -p ~/quickdots/bars/kompass` ohne Warnungen.
- Kein hartcodierter Hex-Wert außerhalb `Theme.qml`.
- Kein Shell-Prozess im Polling-Loop (Sensoren über `FileView`, Tags/Fokus
  über die laufenden `mmsg watch`-Streams).
- Nadel-/Zeiger-Rotationen nehmen immer den kürzesten Drehweg.
- Root-level Singletons (`Theme.qml`, `MangoIpc.qml`, `Cpu.qml`, `BarState.
  qml`) — siehe `fisheye`-README zur Cross-Dir-Import-Falle bei
  pragma-Singletons.

## Etappenplan

1. **Theme.qml** — Palette + Messing-/Instrumenten-Rollen (Nietenlicht/
   -schatten, Zifferblattfarbe, Nadelfarbe, Skalenzonen). ✅ diese Session
2. **Bar-Grundgerüst** — `PanelWindow`, Messingpanel mit Nietenreihe, drei
   Modul-Slots, Start läuft ohne Warnungen. ✅ diese Session
3. **Kompassrose live** — `MangoIpc.qml` eingebunden, Nadel zeigt echten
   aktiven Tag, Klick wechselt Tag. ✅ diese Session
4. **Temperatur-Zeigerinstrument live** — `Cpu.qml` eingebunden, Zeiger
   schlägt echte CPU-Temperatur aus, Farbzonen sichtbar. ✅ diese Session
5. **Zeit-Trommel** — rollende Ziffernwalzen statt Platzhaltertext.
6. **Audio-Popup** — Kippschalter/Drehregler, Pipewire-Anbindung.
7. **Netzwerk/Bluetooth-Popup**.
8. **Power-Popup**.
9. **App-Launcher** ✅ vorgezogen (zweite Session) — eigenes
   `LauncherWindow.qml` (Loader-erzeugt, `WlrKeyboardFocus.OnDemand`, nach
   dem in `bars/fisheye` verifizierten Muster statt dem unverifizierten aus
   `bars/blobs`), Uhr-Modul wächst + schiebt Kompass/Gauge auseinander,
   `AppEntries.qml`/`LauncherState.qml` aus `bars/fisheye` übernommen. Noch
   offen: Adapter-Eintrag in `quickdots/menu/adapters/kompass.json` +
   scharfgeschaltete Mango-Keybind-Zeile (siehe README "Mango-Keybind" für
   den Grund, warum das noch nicht automatisch eingetragen wurde).

Stand nach dieser Session: Etappen 1–4 stehen (Kompassrose + Temperatur
live, Zeit noch als einfacher Text-Platzhalter statt Trommel), plus der
App-Launcher aus Etappe 9 vorgezogen — siehe README.
