# lumen — komplette Rice für mango

Keine durchgehende Bar-Leiste, kein separates Menü-Fenster. Die ganze Rice
ist **ein einziges schwebendes Fenster** oben mittig ("Notch"), das sich
zwischen vier Formen VERFORMT:

- **Pille** (Ruhezustand): nur die Uhrzeit
- **Settings-Karte** (Hover/Klick): Tags/Musik, Audio (Lautstärke +
  Mikrofon), System (Nicht stören + WLAN), Schnellzugriff (Suchen/
  Wallpaper/Screenshot), Energie (Sperren/Logout/Reboot/Shutdown)
- **Suche**: Fuzzy-App-Launcher, direkt in derselben Surface
- **Wallpaper**: Thumbnail-Grid, färbt bei jedem Wechsel automatisch per
  pywal um

Dieselbe Fenster-Surface animiert einfach zwischen den vier Zielgrößen —
kein zweites Fenster, keine Lücke. Ein `TopGapReserve` hält getilte Fenster
unterhalb der Pille, damit nichts direkt darunter/dahinter überlappt.

Der Ordner hieß ursprünglich `überaschung` (Platzhaltername).

## Kurzfassung

**Abhängigkeiten:**
- Quickshell ≥ 0.3.0
- mango (liefert `mmsg` für Tag-Status/-Wechsel und Fokus-Infos)
- Pipewire/wireplumber (Lautstärke + Mikrofon)
- `awww`/`awww-daemon` (Nixpkgs-Nachfolger von `swww`, CLI identisch) für
  den Wallpaper-Switcher — Daemon muss laufen (i. d. R. bereits per
  Autostart aktiv, siehe `~/quickdots/shellwall`)
- `wal` (pywal) für die adaptive Einfärbung
- ein laufender MPRIS-Player ist optional
- Wallpaper-Ordner: `~/Pictures/Walpapers` (Tippfehler im Ordnernamen ist
  Absicht — konsistent mit `~/quickdots/shellwall/Config.qml`)
- `nmcli` (NetworkManager) für den WLAN-Schalter
- `flameshot` für den Screenshot-Button (einziges auf diesem System
  installierte Screenshot-Tool — kein grim/hyprshot/spectacle vorhanden)

**Start (Test/Debug, ohne Bar-Switcher):**
```
qs -p ~/quickdots/bars/lumen -n
```

**Als aktive Bar registrieren** (empfohlener Weg):
```
~/quickdots/menu/scripts/switch-bar.sh lumen
```
Adapter: `quickdots/menu/adapters/lumen.json`.

**Fallback ohne Bar-Switcher:**
```
qs -p ~/quickdots/bars/lumen ipc call launcher toggle
qs -p ~/quickdots/bars/lumen ipc call wallpaper toggle
```

## Struktur

```
shell.qml                       Root: Notch pro Bildschirm, geteilter menuOpen/menuSubview-Zustand, IpcHandler, Klick-weg-Catcher
Colors.qml                       Singleton: pywal-adaptive Farben + Font
Settings.qml                      Singleton: Notch-/Such-/Wallpaper-Geometrie, Kommandos
MangoIpc.qml                       Singleton: mmsg-IPC (Tags, Monitore, Fokus)
Apps.qml                            Singleton: Fuzzy-Suche + Nutzungshäufigkeit
Wallpaper.qml                        Singleton: scannt Walpapers/, wendet awww + wal an
Modules/Notch/Notch.qml               Das eine Fenster: Pille <-> Settings <-> Suche <-> Wallpaper
Modules/Notch/TopGapReserve.qml         Reserviert oben eine Zone, damit getilte Fenster nicht überlappen
Modules/Notch/Workspaces.qml              Tags 1..6 + aktiver Fenstertitel (Settings-Kopfzeile)
Modules/Notch/Clock.qml                     Uhr, format/pointSize überschreibbar (Pille + Kopfzeile)
Modules/Notch/Media.qml                       MPRIS, blendet sich ohne Player weg
Modules/Notch/SearchField.qml                   Suchfeld (Subview "search")
Modules/Notch/AppList.qml                         App-Liste (Subview "search")
Modules/Notch/WallpaperTile.qml                     Eine Thumbnail-Kachel (Subview "wallpaper")
```

`Colors.qml`/`Settings.qml`/`MangoIpc.qml`/`Apps.qml`/`Wallpaper.qml` liegen
bewusst im Wurzelverzeichnis: ein `pragma Singleton` löst in dieser
Quickshell-Version nur über denselben Ordner oder eine reine
`".."`-Elternkette zuverlässig auf. Module erreichen sie per
`import "../.."`.

## Entwurfsentscheidungen

- **Kein linkes/rechtes Anchor.** `Notch.qml` ankert nur `top: true`;
  wlr-layer-shell zentriert eine so verankerte Surface automatisch
  horizontal — Technik bestätigt aus `bars/floating/IslandBase.qml`
  (dortiger Kommentar: *beide* Anchors setzen würde die Surface stattdessen
  auf volle Bildschirmbreite strecken, nicht zentrieren).
- **Fenstergröße = Inhalt.** `implicitWidth`/`implicitHeight` folgen direkt
  der aktuellen Form (Pille/Settings/Suche/Wallpaper) — kein
  `mask`-Workaround nötig, weil die Surface nie größer ist als das sichtbar
  Gezeichnete.
- **Jede Subview hat eine feste eigene Breite/Höhe** (Settings.
  notchExpandedWidth/searchWidth/searchHeight/wallpaperWidth/
  wallpaperHeight), nicht `parent.width`. Würde ihr Inhalt live der
  wachsenden Karten-Größe folgen, bräche jede Zeile während der
  260ms-Verform-Animation laufend neu um. Stattdessen bleibt jede Subview
  in ihrer eigenen Zielgröße fest und wird von der noch wachsenden Karte
  (`clip: true`) einfach zunehmend freigelegt — genau DAS ist der
  "Verform"-Effekt: eine Surface animiert zwischen mehreren Zielformen,
  der Inhalt selbst bricht dabei nie um.
- **Zwei verschiedene "offen"-Zustände**: reine Hover-Vorschau
  (`notch.hovering`, nur die Settings-Karte, schließt automatisch nach
  350ms Hover-Exit) vs. "angepinnt" (`appRoot.menuOpen`, Suche/Wallpaper,
  ausgelöst durch Klick auf einen Schnellzugriff-Chip oder per IPC/
  SUPER+Space) — angepinnt schließt NICHT durch Hover-Exit, sonst würde
  Mausbewegung beim Tippen versehentlich die Suche zuklappen. Schließen
  dort nur über Escape, den ×-Button in der Subview-Kopfzeile, oder einen
  Klick außerhalb (gemeinsamer Catcher in `shell.qml`, gleiche
  `mask`-Techik wie `bars/floating/shell.qml`: togglet zwischen `null` und
  leerer `Region`, bleibt bei geschlossenem Menü komplett klick-durchlässig).
- **`WlrKeyboardFocus.OnDemand` von Anfang an, nie umgeschaltet.** Die
  Suche lebt jetzt IN derselben, nie neu erzeugten Notch-Surface (kein
  separates LazyLoader-Fenster mehr) — mango gewährt einer Layer-Surface
  Keyboard-Fokus aber nur bei ihrem allerersten Commit oder einem Klick auf
  eine bereits-als-OnDemand-committete Surface, nie beim nachträglichen
  Umschalten einer bestehenden Surface (siehe
  [[feedback_mango_ondemand_focus_requires_fresh_surface]]). Deshalb ist
  OnDemand hier von Beginn an fest gesetzt statt bedarfsweise umgeschaltet;
  ein Klick auf den "Suchen"-Chip zählt als genau der "Klick auf
  bereits-OnDemand"-Fall und gewährt Fokus zuverlässig. Nebenwirkung: jeder
  Klick auf den Notch holt sich kurz den Tastaturfokus, auch in der reinen
  Settings-Ansicht (siehe "Bekannte Lücken").
- **Escape schließt jede Subview**, nicht nur die Suche. Die Suche fängt
  Escape schon direkt im Suchfeld ab (`SearchField.qml`, bubbelt gar nicht
  erst hoch); für Settings/Wallpaper sitzt zusätzlich ein
  `Keys.onEscapePressed` auf der Karte selbst (`focus: notch.expanded`) —
  angepinnt (Suche/Wallpaper) schließt komplett, reine Hover-Vorschau
  (Settings) klappt nur ein. Greift nur, wenn die Surface echten
  Wayland-Tastaturfokus hat (siehe OnDemand-Punkt oben) — reines Hovern
  ohne vorherigen Klick liefert Escape möglicherweise gar nicht hier an,
  dann schließt stattdessen die normale Maus-weg-Verzögerung.
- **`appRoot` statt `shellRoot`** als Name für die durchgereichte Referenz
  auf die äußere `ShellRoot` — siehe
  [[feedback_qml_child_property_shadows_outer_id]]: ein gleichnamiges
  Property auf dem Kind-Objekt schattiert die äußere id lautlos auf
  `undefined`.
- **`TopGapReserve.qml`** reserviert oben `Settings.notchTopReserveZone`
  (marginTop + collapsedHeight + 6px) per `exclusiveZone` auf einer
  eigenen, unsichtbaren `WlrLayer.Bottom`-Surface (Technik aus
  `bars/floating/TopGapReserve.qml`). `Notch.qml`s eigenes `margins.top`
  rechnet die dadurch entstehende Verschiebung wieder heraus
  (`notchMarginTop - notchTopReserveZone` — mango stapelt gleich-kantige
  Layer-Shell-Surfaces, indem es jede um die exclusiveZone der jeweils
  anderen nach unten schiebt).
- Ansonsten identische Lösungen wie `bars/simple` für bekannte Fallstricke:
  `onAccent` → `accentInk`, Icons als `"\uXXXX"`-Escapes, `mmsg` statt
  Hyprland-IPC.

## Bekannte Lücken

- Mehrfach aktive Tags pro Monitor werden nur als "irgendein aktiver Tag hat
  diese Nummer" angezeigt (wie in `simple`).
- Kein `brightnessctl`/`bluetoothctl`/`wlsunset` auf diesem System
  installiert — deshalb bewusst keine Helligkeits-/Bluetooth-/Nachtlicht-
  Regler, die sonst nur lautlos fehlschlagen würden.
- SUPER+Space (IPC, kein echter Mausklick auf die Surface) öffnet die Suche
  zuverlässig sichtbar, aber ob mango dabei auch tatsächlichen
  Tastaturfokus vergibt, ist ungetestet — die dokumentierte Fokus-Regel
  verlangt einen Klick auf die Surface selbst; ein rein extern (IPC)
  ausgelöstes Öffnen könnte diesen Fall verfehlen. Falls Tippen nach
  SUPER+Space nicht ankommt: einmal ins Suchfeld klicken sollte es zuverlässig
  gewinnen (das ist der getestete "Klick auf bereits-OnDemand"-Fall).
- `dwm-minimalism-and-nature-v0-iygcamw2kiph1.webp` im Wallpaper-Ordner
  liefert `Unsupported image format` beim Dekodieren (fehlendes
  WebP-Codec-Plugin) — Kachel bleibt leer, alle anderen Wallpaper sind
  unbetroffen.
- Hover-Öffnen/Schließen, die Mikrofon-/WLAN-/Screenshot-Zeilen sowie das
  tatsächliche Verformen zwischen den vier Formen wurden nicht headless per
  echtem Mausklick getestet — Component-Load, IPC-Toggle (Suche + Wallpaper)
  und Pipewire/MPRIS-Bindings wurden verifiziert (kein QML-Fehler,
  `Configuration Loaded`, laufender Prozess über mehrere Sekunden stabil).

## Ursprungs-Prompt

"Kompletten Quickshell-Rice machen mit Bar, Menüs, App-Starter,
Wallpaper-Switcher, überrasch mich einfach, danach den aktuellen Ordner
passend umbenennen."

**Runde 1**: Erste Fassung war strukturell eine Kopie von `bars/simple`
(nur umgefärbt) — Feedback: "sieht genau aus wie simple bar, ich will etwas
Neues und Kreatives". Per `AskUserQuestion` drei echte
Strukturalternativen zur Wahl gestellt (Notch/Insel, vertikale
Seitenleiste, radiales HUD); Nutzer wählte Notch/Insel. Komplett neu gebaut
auf Basis der in `bars/floating` bereits gelösten Technik für schwebende,
nur-oben-verankerte, sich selbst größenanimierende Layer-Shell-Fenster.
Ordner von `überaschung` auf `lumen` umbenannt.

**Runde 2**: Design gut, aber Launcher/Wallpaper starteten nicht aus dem
Menü (Ursache: `shellRoot`-Namenskollision, siehe
[[feedback_qml_child_property_shadows_outer_id]]), Karte überlappte
Fenster ohne Gap (→ `TopGapReserve.qml`), Menü sollte größer/origineller
mit mehr Einstellungen sein (→ 420px, vier beschriftete Sektionen,
Mikrofon/WLAN/Screenshot ergänzt).

**Runde 3**: "App-Launcher und Wallpaper sollen Teil der Bar sein, keine
eigenen schwebenden Menüs." Aus screenzentrierten Vollbild-Overlays wurden
top-verankerte, direkt unter der Pille hängende eigene Fenster in
gleicher Optik.

**Runde 4** (diese): "Die Bar sollte sich verformen und so zum Menü werden,
nicht ein eigenes Menü mit Gap." Auch "top-verankert direkt darunter" war
dem Nutzer noch zu sehr "eigenes Fenster". Launcher/WallpaperPicker als
separate Fenster komplett aufgelöst — Suche und Wallpaper-Grid leben jetzt
als Subviews IN der Notch-Surface selbst, die zwischen allen vier Formen
animiert. Dafür `WlrKeyboardFocus` von `None` auf dauerhaft `OnDemand`
umgestellt (siehe "Entwurfsentscheidungen"), da die Suche jetzt keine
eigene, frisch erzeugte Surface mehr hat, auf der das sonst übliche
LazyLoader-Fresh-Surface-Muster greifen würde.

**Runde 5**: "Alle Menüs sollen sich mit Escape schließen lassen." Bisher
fing nur das Suchfeld Escape ab. Globales `Keys.onEscapePressed` auf der
Karte selbst ergänzt (`focus: notch.expanded`), das je nach Zustand
entweder das angepinnte Menü schließt oder nur die Hover-Vorschau einklappt.
