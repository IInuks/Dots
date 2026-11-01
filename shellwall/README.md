# shellwall

Wallpaper-Selector als Quickshell-Widget für MangoWM (wlroots/dwl) mit
`awww` als Wallpaper-Backend. Optik/Interaktion (Stand 2026-09-22) ist 1:1
vom App-Launcher aus `quickdots/bars/ricev2` (Menüs-Prompt Abschnitt 2,
Slice-Modus) übernommen — siehe "Design" unten.

## Struktur

```
shellwall/
├── shell.qml                     # Root: App-Zustand, Ordner-Scan, awww-Aufruf, IPC-Handler
├── Config.qml                    # alle konfigurierbaren Werte (Ordner, Wallpaper-Backend, Slice-Geometrie, Farben)
├── Components/
│   ├── CoverflowOverlay.qml      # Vollflächiges Overlay: Dimmer, zentrierte Karte, Tastatursteuerung
│   ├── SearchBar.qml             # Such-Pill oben (Icon + Suchfeld + Caret + Hinweistext)
│   └── WallpaperSlice.qml        # Einzelnes schräges Wallpaper-Slice (Schatten/Maske/Rand/Namensschild)
└── README.md
```

## Design

Ursprünglich ein PathView-Coverflow (gebogener Pfad, Y-Rotation der
Randelemente). Auf Wunsch umgebaut auf exakt dasselbe Slice-Gerüst wie
`quickdots/bars/ricev2`s App-Launcher: eine horizontale Reihe schräger,
sich überlappender Parallelogramme, das ausgewählte klappt breiter auf
(`sliceWidth` 135px → `sliceExpandedWidth` 924px, `Behavior` 350ms
OutCubic), mit Schatten-Canvas, `MultiEffect`-Maskierung auf die Schräge,
Rand (3px ausgewählt / 1px Hover / 1px sonst) und einem Namensschild-Pill
(Dateiname + per `identify` aufgelöste Auflösung). Oben eine Such-Pill wie
`ricev2`s `FilterBar.qml`, aber ohne dessen Filter-Buttons (All/Apps/
Games/Steam) — für Wallpaper gibt es keine vergleichbaren Kategorien;
stattdessen filtert das Suchfeld live nach Dateiname.

`sliceExpandedWidth:sliceHeight` (924:520) trifft zufällig fast exakt
16:9 — passt für Wallpaper-Vorschauen (echte Fotos in dem Seitenverhältnis)
sogar besser als für den App-Launcher, den das Maß ursprünglich zeigt.

Bekannte, von `ricev2` übernommene Einschränkung: die Klickfläche folgt
nicht exakt der Schräge (`containmentMask` mit einem `contains(point)`-
QtObject wird von dieser Qt-Version zur Laufzeit abgelehnt), bleibt also
rechteckig — die toten Ecken (`sliceSkew` 35px) sind meist vom
höher-`z`-liegenden Nachbar-Slice überdeckt (Overlap `sliceSpacing`
-22px).

Getestet: `qs -p . -n -d` (`Configuration Loaded`, keine QML-Fehler/
Warnungen), Overlay per `qs -p . ipc call coverflow toggle` geöffnet und
per `flameshot full` visuell geprüft — Slices, Namensschild inkl.
Auflösung, Such-Pill und Dimmer rendern wie erwartet. Danach wieder
geschlossen. Keine simulierte Tastatur-/Mauseingabe nötig (memory:
feedback_live_input_sim_desktop_risk) — Navigation/Aktivierung nur gegen
den Code geprüft, nicht interaktiv geklickt/getippt.

## Voraussetzungen

- Quickshell ≥ 0.3.0
- ImageMagick (`identify`) — wird nur zur Anzeige der Bildauflösung genutzt
- **`awww`** (Wallpaper-Backend). Auf diesem System per
  `environment.systemPackages = [ pkgs.swww ]` in `/etc/nixos/configuration.nix`
  installiert — **Hinweis:** das nixpkgs-Paket heißt weiterhin `pkgs.swww`
  (mit Deprecation-Warnung beim Rebuild), installiert aber tatsächlich die
  Binaries `awww` / `awww-daemon`. Der Upstream-Projektname wurde von `swww`
  zu `awww` geändert; die CLI ist 1:1 identisch geblieben (`img`, `--transition-type`,
  `--transition-fps`, …).

## Konfiguration

Alle anpassbaren Werte liegen gebündelt in `Config.qml`:

- `wallpaperDir` — Wallpaper-Ordner. **Achtung:** Der Default zeigt auf
  `~/Pictures/Walpapers` (Tippfehler), weil genau dieser Ordner mit 31 Bildern
  auf deinem System tatsächlich existiert (`~/Pictures/Wallpapers` gibt es
  nicht). Passe den Pfad an, falls du den Ordner umbenennst.
- `extensions` — erlaubte Dateiendungen (Default: jpg, jpeg, png, webp)
- `wallpaperBinary` — Name des Backend-Binaries (Default: `awww`)
- `transitionType` / `transitionFps` — Übergabewerte für `awww img`
- Slice-Geometrie (1:1 aus `ricev2/Style.qml`): `sliceWidth`,
  `sliceExpandedWidth`, `sliceHeight`, `sliceSkew`, `sliceSpacing`,
  `sliceVisibleCount`
- Animation: `animFast`/`animNormal`/`animEnter`/`animMedium`/
  `animExpand`/`anim300`/`anim400`
- Optik: `overlayBackgroundColor`, `surfaceContainer`, `primary`,
  `tertiary`, `textColor`, `thumbSourceWidth`/`Height` (Decode-Auflösung
  der Thumbnails)

## Steuerung

- `←` / `→` — durch die Wallpaper blättern
- Tippen — filtert live nach Dateiname (Suchfeld oben, `Backspace` löscht)
- `Enter` — fokussiertes Wallpaper anwenden (setzt es per `awww img` und
  schließt das Overlay)
- `Escape` — schließen ohne Änderung
- Maus: Klick auf ein Slice wählt es aus, Klick auf das bereits
  ausgewählte wendet es an (wie `ricev2`s `SliceDelegate.qml`)

## Installation & Test

Direkt aus diesem Ordner heraus starten (kein Kopieren nach
`~/.config/quickshell` nötig):

```sh
qs -p ~/shellwall -n
```

Overlay manuell togglen (z. B. zum Testen, ohne Mango-Keybind):

```sh
qs -p ~/shellwall ipc call coverflow toggle
```

## Einbindung in MangoWM

Bereits in `~/.config/mango/config.conf` eingetragen:

```conf
# Autostart
exec-once=qs -p ~/shellwall -n &
exec-once=awww-daemon

# Keybind: Overlay per IPC togglen statt bei jedem Tastendruck neu zu starten
bind=CTRL+SUPER,space,spawn,qs -p ~/shellwall ipc call coverflow toggle
```

Der Bind ersetzt den vorherigen `quickwall`-Picker-Bind auf derselben
Tastenkombination (`Super+Strg+Leertaste`).

**Warum IPC statt Neustart pro Tastendruck:** shellwall läuft als ein
dauerhafter Quickshell-Prozess im Hintergrund (per `exec-once`, unsichtbar
solange das Overlay geschlossen ist). Der Keybind ruft nur `qs ipc call` auf,
was lediglich ein IPC-Signal an den bereits laufenden Prozess schickt. Ein
kompletter `qs`-Neustart bei jedem Tastendruck wäre spürbar langsamer (QML-
Engine-Start, erneutes Ordner-Scannen) und würde den State (aktuelles
Wallpaper, Auflösungs-Cache) verlieren.

**Wichtig — `exec-once` läuft nur beim Compositor-Start:** Im Gegensatz zu
`bind`-Änderungen greift `exec-once` **nicht** durch `reload_config`
(`Super+R`). Nach Änderungen an den `exec-once`-Zeilen musst du dich aus- und
wieder einloggen (oder Mango komplett neu starten), damit `shellwall` und
`awww-daemon` automatisch hochkommen. Reine `bind=`-Änderungen reichen mit
`Super+R`.

**Konflikt mit `quickwall` (behoben, 2026-08-27):** `exec-once=qs -c
quickwall` rendered den Hintergrund über eine eigene Layer-Shell-Surface
(`Background.qml`, Layer `Background`) und setzte ihn über `pywal`, nicht über
`awww`. Da `shellwall` zusätzlich per `awww` einen Hintergrund setzte,
konkurrierten zwei Mechanismen um denselben Layer, wodurch Wallpaper-Wechsel
über shellwall unsichtbar blieben (obwohl `awww img` laut Log erfolgreich
lief). Fix: `exec-once=qs -c quickwall` wurde aus `~/.config/mango/config.conf`
entfernt — nur noch `shellwall`/`awww` steuert den Hintergrund.
