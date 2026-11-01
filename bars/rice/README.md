# rice — komplette Wayland-Desktop-Shell für mango

Antwort auf den vollständigen Shell-Auftrag in `originalPromt` (Bar +
Menüs + adaptives Theming + Wallpaper-Switcher, ohne Home-Manager). Der
Auftrag selbst lässt fast jeden konkreten Wert offen (`[XX px]`,
`[oben/unten]`, Farben, Modul-Liste, ...) und delegiert die Wahl explizit
("überrasch mich") — dieses README dokumentiert, welche Werte gewählt
wurden und warum, plus alles, was der Auftrag unter "Anforderungen an die
Antwort" verlangt (Pakete, volle Configs, Autostart, Keybinds, Re-Trigger-
Erklärung).

**Baufortschritt:** Stage 1 fertig und via `qs -p . -n` sauber ladend
getestet (kein QML-Fehler, keine Warnung außer dem erwarteten
bluez-DBus-Hinweis, siehe "Bekannte Lücken"): Bar, adaptive Theming-Pipeline
(inkl. GTK-Templates, echt gegen matugen getestet), Wallpaper-Switcher,
Control-Center (Toggle-Kacheln + Slider), Power-Menü. Noch nicht gebaut:
Kalender/Notification-Center/Media-Player-Vollansicht, Qt-Theming (siehe
"System-Theming" — Template steht, aber deaktiviert, da qt6ct auf diesem
System noch nicht installiert ist), Live-Interaktionstest per Maus
(bewusst nicht selbst durchgeführt, siehe "Testen").

## Der ausgefüllte Auftrag

**BAR** — oben, volle Breite (kein Floating-Abstand), Höhe 46px,
Eckenradius **0** (flush mit der Bildschirmkante — bewusst kein weiterer
Pill/Insel/Notch wie praktisch jede andere Bar unter `bars/*`, siehe
"Warum diese Form"). Ursprünglich unten gebaut, auf Nutzerwunsch
(2026-09-21) nach oben verschoben — siehe `Bar/Bar.qml`s Kopf-Kommentar für
die genaue Änderung (Anker-Kante, welche Seite die Haarlinie bekommt, und
die Auto-Hide-Richtung wurden alle mitgespiegelt). Hintergrund: adaptive
`Theme.surface`-Farbe bei 92% Deckhraft, kein Blur, 1px Haarlinie unten in
`Theme.border` statt Rand + Schatten. Innenabstand 14px horizontal, 10-12px
zwischen Modulen. Font
JetBrainsMono Nerd Font, Icons Material Symbols Rounded (beide bereits auf
diesem System installiert, siehe "Nix-Pakete").

- **Links:** Launcher-Icon (öffnet das gemeinsame `quickdots/menu`, kein
  eigener Launcher — siehe "Warum kein eigener Launcher"), Workspaces als
  **Segment-Ticks** (dünne vertikale Balken statt Punkte/Zahlen/Pills —
  aktiv am höchsten + akzentfarben, belegt mittelhoch + textMuted, leer
  am kürzesten + kaum sichtbar), aktiver Fenstertitel (elided).
- **Mitte:** Uhrzeit (HH:MM, 1s-Takt) über Datum (klein, textMuted).
- **Rechts:** Tray (echte SNI-Icons), kompakter Media-Widget (Play/Pause +
  Titel, nur sichtbar wenn ein MPRIS-Player existiert), Lautstärke
  (Icon+%), Netzwerk (Kabel/WLAN/Aus), Bluetooth, Power.
- **Hover:** Workspace-Ticks skalieren 1.3× und wechseln weich die Höhe;
  Icon-Module haben eine vergrößerte Klickfläche (`anchors.margins: -6`),
  keine Hover-Pille (die Bar selbst ist schon die "Pille").

**MENÜS/PANELS** — Control-Center (Profilzeile → Toggle-Kacheln WLAN/
Bluetooth/DND → Slider Lautstärke/Helligkeit → "Wallpaper wechseln"-Zeile),
Wallpaper-Switcher (Vorschau-Grid), Power-Menü (Sperren/Abmelden/Neu
starten/Herunterfahren). Öffnen: Klick auf das jeweilige Bar-Modul oder
Keybind (siehe "Keybinds"). Erscheinen als abgerundete Karte direkt
**unterhalb** der (jetzt oben sitzenden) Bar (nicht als eigenes Popup-
Fenster pro Pille wie `bars/lucid`) — klappt runter/rein, 220ms OutCubic,
mit Klick-außerhalb-schließt-Scrim (Code/Dateinamen heißen weiterhin
"PanelSheet"/"Bottom-Sheet-Chrome" — das UI-Muster, nicht mehr wörtlich die
Kante, an der es andockt). Radius rundum, `Theme.surface`-Hintergrund,
1px Rand.
Kalender/Notification-Center/Media-Player fehlen noch als eigene Panels
(Stage 2).

**THEMING** — adaptive Material-You-Palette aus dem aktuellen Wallpaper via
`matugen`, angewendet auf Bar+Panels (QML-Singleton `Theme.qml`) UND auf
GTK3/GTK4/libadwaita (`@define-color` in `~/.config/gtk-{3,4}.0/gtk.css`,
siehe "System-Theming"). Automatischer Hell/Dunkel-Wechsel: 07:00-19:00
hell, sonst dunkel (`Config.themeMode = "auto"`, umschaltbar auf
`"light"`/`"dark"`) — beide Zweige kommen aus **einem** matugen-Aufruf
(siehe "Re-Trigger der Farbgenerierung").

**WALLPAPER-SWITCHER** — Grid über `~/Pictures/Walpapers` (bestehender,
absichtlich beibehaltener Tippfehler-Ordnername, siehe `Wallpaper.qml`),
5 Spalten, Thumbnail-Radius 12px, aktives Bild mit Akzent-Ring + Häkchen
markiert. Klick setzt das Wallpaper über `awww` (swww-Nachfolger, siehe
"Nix-Pakete") mit Fade-Übergang (`--transition-type simple`) und stößt
danach automatisch Farbgenerierung an. Nur statische Bilder (jpg/jpeg/png/
webp), kein Video/mpvpaper/Online-Anbindung. Zufalls-Button (🔀) und
optionaler Timer (`Config.slideshowEnabled`, Intervall in Minuten,
Default 30min/aus) beide vorhanden.

## Architektur

```
Config.qml          Singleton: persistierte Wahl (Theme-Modus, Wallpaper-
                     Ordner, Slideshow, Auto-Hide, DND) -> ~/.config/
                     ricebar/config.json
Theme.qml            Singleton: adaptive Palette (matugen, beide Zweige
                      dark+light aus einem Aufruf), Hell/Dunkel-Auswahl,
                      Font-Auflösung
Clock.qml             Singleton: eine gemeinsame "now" (1s-Takt)
Wallpaper.qml           Singleton: scannt Config.wallpaperDir, apply()
                         via awww+wal+Theme.regenerateAdaptive()
Brightness.qml            Singleton: brightnessctl-Wrapper, blendet sich
                           selbst aus wenn kein Backlight-Gerät existiert
MangoService.qml            Singleton: alle mmsg-Aufrufe (Workspaces,
                             Fokus-Titel, Power-Aktionen)
PanelState.qml                Singleton: welches Bottom-Sheet offen ist
PanelSheet.qml                 Gemeinsame Bottom-Sheet-Chrome (Scrim +
                                Slide-Panel), von jedem Panels/*.qml als
                                Root-Typ verwendet
shell.qml                       Root: Variants (Bar pro Screen) + die
                                 drei Panel-Singletons + IpcHandler
Bar/Bar.qml                      Die Bottom-Bar selbst
Bar/WorkspacePips.qml             Segment-Tick-Workspace-Anzeige
Bar/TrayCompact.qml                SNI-Tray-Icons
Bar/MediaCompact.qml                Kompaktes MPRIS-Widget
Bar/Icon.qml                         Material-Symbols-Glyphe + Fallback
Panels/ControlCenter.qml              Toggle-Kacheln + Slider
Panels/WallpaperSwitcher.qml           Vorschau-Grid
Panels/PowerMenu.qml                    Sperren/Abmelden/Neustart/Aus
```

**Multi-Monitor-Vereinfachung (Stage 1):** die Bar läuft per `Variants`
auf jedem Screen, aber die drei Panels sind **einzelne, globale** Instanzen,
fest an `Quickshell.screens[0]` (den ersten/primären Screen) angebunden —
öffnet man ein Panel von einer Bar auf einem anderen Screen, erscheint es
trotzdem auf Screen 0. Für ein Einzelmonitor-System (aktueller Stand laut
Systemwissen) ohne Auswirkung; ein per-Screen-Panel-Registry (wie
`bars/lucid/BarRegistry.qml`) wäre der Fix, falls das je zum Problem wird.

## Nix-Pakete

Alles unten Aufgeführte läuft **heute bereits** auf diesem System (Prüfung
per `which`/`fc-list` vor dem Bau, nicht angenommen) — nichts davon muss
neu installiert werden, um `rice` sofort zu testen. Eine Lücke zwischen
"läuft jetzt" (ad-hoc via `nix profile install`, wie der Nerd Font laut
Systemwissen schon mal gefixt wurde) und "steht deklarativ in
`configuration.nix`" gibt es bei genau einem Paket, `material-symbols`
(Material-Symbols-Font — aktuell nur im Nutzerprofil, siehe
`fc-list | grep -i "material symbols"`).

`environment.systemPackages`-Ergänzung in `/etc/nixos/configuration.nix`
(bereits vorhandene Einträge wie `quickshell`, `matugen`, `pkgs.swww`
— liefert trotz altem Namen das aktuelle `awww`-Binary —, `swaylock`,
`nerd-fonts.jetbrains-mono` NICHT erneut aufgeführt):

```nix
environment.systemPackages = with pkgs; [
  # ... bestehende Einträge unverändert ...
  material-symbols        # Icon-Font, aktuell nur ad-hoc im Nutzerprofil
];
```

Alles andere, was `rice` per `Process`/`execDetached` aufruft, ist bereits
System- oder Nutzerprofil-Paket auf dieser Maschine: `wal` (pywal),
`brightnessctl`, `hostname`, `jq` (nur falls künftige Stages es brauchen,
aktuell ungenutzt), NetworkManager (`nmcli`, via
`networking.networkmanager.enable = true`), `bluez`/`bluetoothctl`,
`wireplumber`/`pipewire` (Lautstärke läuft über Quickshell's natives
`Quickshell.Services.Pipewire`, kein `wpctl`-Aufruf nötig), `mmsg` (Teil
von mango selbst), `systemctl`/`loginctl` (systemd).

## Autostart

In `/etc/nixos/mango-config.conf` (nicht automatisch von diesem Build
verändert — nur dokumentiert, siehe "Warum config.conf nicht angefasst
wurde"):

```
exec-once=qs -p ~/quickdots/bars/rice -n &
```

Aktuell ist `quickbar` die per `exec-once` gestartete Bar (Zeile 4 der
echten Config) — `quickbar` sitzt ebenfalls oben, `rice` seit dem Umzug
(siehe "BAR") also jetzt auf **derselben** Kante. `rice` NICHT parallel per
`exec-once` starten, solange `quickbar` noch aktiv ist: beide würden dann
gleichzeitig oben `exclusiveZone` reservieren (addiert sich, keine echte
Kollision, aber unschön gestapelt) und `quickdots/menu`s Bar-Switcher
(`scripts/switch-bar.sh`) geht ohnehin von "genau eine aktive Bar" aus.
Umschalten also über den Switcher (`qs -p ~/quickdots/menu ipc
call menu toggle` → Tab "Bars" → `rice` auswählen), nicht durch manuelles
Ergänzen einer zweiten `exec-once`-Zeile.

## Keybinds

`quickdots/menu/adapters/rice.json` ist bereits angelegt (Farb-Fallback +
`hasLauncher: false`, damit der globale SUPER+Space-Bind beim Aktivieren
automatisch auf das gemeinsame `quickdots/menu` zeigt, exakt wie bei jeder
anderen Bar ohne eigenen Launcher). Die dort hinterlegten Panel-Keybinds
werden erst **wirksam, wenn `rice` über den Switcher aktiviert wird**
(`switch-bar.sh` schreibt sie dann in `config.conf` und lädt mango neu):

```
bind=SUPER,c,spawn,qs -p ~/quickdots/bars/rice ipc call controlcenter toggle
bind=CTRL+SUPER,w,spawn,qs -p ~/quickdots/bars/rice ipc call wallpapers toggle
bind=CTRL+SUPER,p,spawn,qs -p ~/quickdots/bars/rice ipc call power toggle
```

Geprüft: keine Kollision mit den bestehenden Binds in `mango-config.conf`
(`SUPER,w` ist dort `killclient` — andere Modifier-Kombination als
`CTRL+SUPER,w`, kein Konflikt).

## System-Theming

**GTK (fertig, echt getestet):** `~/.config/matugen/config.toml` hat zwei
neue `[templates.rice-gtk3]`/`[templates.rice-gtk4]`-Einträge (die
bestehende `[templates.blobs-bar]` unverändert gelassen), die
`matugen/templates/gtk-rice.css` nach `~/.config/gtk-3.0/gtk.css` bzw.
`~/.config/gtk-4.0/gtk.css` rendern — `@define-color`-Tokens für sowohl
libadwaita (`accent_color`, `window_bg_color`, `card_bg_color`, ...) als
auch GTK3-Legacy-Namen (`theme_bg_color`, `theme_selected_bg_color`, ...).
Einmal live gegen ein echtes Wallpaper durchgerendert und geprüft (Ausgabe
mit korrekten Hex-Werten, siehe Git-freie Historie dieser Session) —
beide Zieldateien existierten vorher nicht, es wurde also nichts
überschrieben.

**Qt (dokumentiert, nicht aktiv):** `qt6ct`/`qt5ct` sind auf diesem System
nicht installiert (geprüft) und `QT_QPA_PLATFORMTHEME` ist nirgends
gesetzt — Qt-Apps liefen also schon vor `rice` ungethemt. Das
qt6ct-Farbschema-Dateiformat (`[ColorScheme]` mit ~20 kommagetrennten
QPalette-Rollen pro Zustand) ist fehleranfällig genug, um es nicht
blind gegen ein System zu schreiben, auf dem es niemand konsumiert und
niemand verifizieren kann. Zum Aktivieren:

```nix
environment.systemPackages = with pkgs; [
  # ...
  libsForQt5.qt5ct  # oder qt6ct, je nach Qt-Version der Apps
];
environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qt5ct";
```

Danach in `~/.config/matugen/config.toml` einen `[templates.rice-qt]`-
Eintrag ergänzen (`input_path` = ein neues `matugen/templates/qt-rice.conf`
im `[ColorScheme]`-Format, `output_path` = `~/.config/qt5ct/colors/
rice.conf`) und den Pfad in `~/.config/qt5ct/qt5ct.conf` unter
`color_scheme_path` eintragen — beides erst sinnvoll, sobald qt6ct/qt5ct
tatsächlich installiert ist und getestet werden kann.

**Terminal (bereits vorhanden, nicht neu gebaut):** kitty liest
`~/.cache/wal/sequences` bereits über `~/.bashrc` (Systemwissen) — jeder
`Wallpaper.apply()`-Aufruf ruft `wal -i <pfad> -n -q` mit auf, hält das
also automatisch synchron. Kein rice-spezifischer Code nötig.

## Re-Trigger der Farbgenerierung

Zwei unabhängige Auslöser, beide landen in `Theme.regenerateAdaptive()`:

1. **Wallpaper-Wechsel** (`Wallpaper.apply(path)` — Klick im Switcher,
   Zufalls-Button, oder der Slideshow-Timer): setzt `Theme.wallpaperPath`,
   das über `onWallpaperPathChanged`-Analogon (hier: der Aufrufer ruft
   `regenerateAdaptive(path)` direkt) einen frischen `matugen image <pfad>
   --mode <hell|dunkel, je nach aktuellem Theme.isLight> --json hex`-Lauf
   startet. Dieser eine Aufruf liefert per JSON-Ausgabe BEIDE Zweige
   (dark+light) für die QML-Farben UND rendert nebenbei (matugens eigener
   `[config.wallpaper]`/`[templates.*]`-Mechanismus in `config.toml`) die
   GTK-Dateien auf Basis des `--mode`-Zweigs neu.
2. **Hell/Dunkel-Flip ohne Wallpaper-Wechsel** (`Config.themeMode ===
   "auto"` überquert 07:00 oder 19:00): `Theme.onIsLightChanged` ruft
   `regenerateAdaptive()` erneut mit dem zuletzt bekannten Wallpaper-Pfad
   auf, diesmal mit dem jeweils anderen `--mode` — hält die GTK-Dateien
   auch bei einem reinen Zeit-Flip synchron, nicht nur bei echtem
   Wallpaper-Wechsel.

`wal -i <pfad> -n -q` läuft separat und unconditional bei jedem
`Wallpaper.apply()` (nicht bei einem reinen Hell/Dunkel-Flip — pywal hat
kein Hell/Dunkel-Konzept, nur ein Wallpaper-Konzept).

## Warum diese Form

Diese Session hat vor dem Bau alle ~17 bestehenden Einträge unter
`quickdots/bars/*` gesichtet (siehe Memory
`feedback_creative_rice_means_new_structure`: "kreativ" heißt strukturell
anders, nicht nur andere Farben auf demselben Skelett). Fast jede davon
ist eine schwebende Pille/Insel/Notch mit Dropdown-Popups
(`lucid`, `lumen`, `floating`, `blobs`, `claude`, ...) oder eine
kantenkonfigurierbare vertikale Bar (`shellbar`). Keine davon: eine
flush-an-der-Kante sitzende, IMMER volle-Breite Bar mit Bottom-Sheet-Panels
statt Dropdowns UND — der eigentliche neue Teil — einer Theming-Pipeline,
die tatsächlich über die eigene Bar hinaus wirkt (GTK/Qt/Terminal), was
keine der bisherigen Bars je versucht hat (alle vorherigen matugen-
Aufrufe in diesem Projekt, auch die "vollen DE"-Builds wie `chamaeleon`,
färben ausschließlich ihre eigene QML ein).

## Warum kein eigener Launcher

`quickdots/menu` ist der von praktisch jeder Bar ohne `hasLauncher: true`
gemeinsam genutzte App-Launcher (Memory: `project_quickdots_bar_switcher`)
— ein zweiter, eigener Fuzzy-Such-Launcher hier hätte reine Duplikation
ohne Mehrwert bedeutet. `adapters/rice.json` lässt `hasLauncher` daher
weg (= `false`), das Launcher-Icon links in der Bar spawnt direkt
`qs -p .../menu ipc call menu toggle`.

## Warum config.conf nicht angefasst wurde

Root-eigene, live von mango eingelesene System-Datei mit hohem
Blast-Radius (ein falscher `bind=`/`exec-once` bricht im schlimmsten Fall
Keybinds oder den Autostart der aktuell laufenden Session) — dieselbe
Zurückhaltung, die schon `bars/lucid` für sich gewählt hat ("nudge, not
an automatic config.conf edit"). Autostart- und Keybind-Zeilen stehen oben
vollständig zum Copy-Paste bereit; das tatsächliche Aktivieren läuft
regulär über `quickdots/menu`s Bar-Switcher, der genau dafür gebaut wurde.

## Testen

```sh
qs -p ~/quickdots/bars/rice -n     # Start (Test/Debug)
qs -p ~/quickdots/bars/rice log    # Live-Log
qs -p ~/quickdots/bars/rice kill   # Beenden (nicht pkill)
```

Bereits durchgeführt in dieser Session: sauberer Start ohne QML-Fehler
(inkl. Fix eines echten `QQuickItem::polish()`-Loops in `Bar.qml`s
Lautstärke-Cluster — eine `MouseArea`, deren `width` an
`parent.implicitWidth` hing, während sie selbst Teil der `Row` war, die
`implicitWidth` daraus berechnet; behoben durch ein umschließendes `Item`,
dessen Breite nur vom Geschwister-`Row` abhängt) und ein Fix für zwei
`Row`-in-`Row`-Anker-Verstöße (`left`/`right`/`fill` sind auf direkten
`Row`-Kindern nicht erlaubt — `WorkspacePips.qml`s Scroll-`MouseArea` und
`WallpaperSwitcher.qml`s Kopfzeile wurden dafür jeweils auf ein `Item`
als Root/Container umgestellt). **Nicht durchgeführt:** echte
Maus-Interaktion (Klicks auf Panels, Wallpaper-Wechsel-Klick, Hover) —
bewusst, siehe Memory `feedback_live_input_sim_desktop_risk` (echte
Eingaben auf der laufenden Session können Fokus verschieben; ein reiner
Lade-Test ohne Klicks birgt dieses Risiko nicht). Eine echte
`matugen image`-Testausführung während des Baus hat kurz unabsichtlich
das echte Live-Wallpaper geändert (`[config.wallpaper] set = true` in
`config.toml` löst das als Nebeneffekt JEDES `matugen image`-Aufrufs aus,
nicht nur aus der QML heraus) — sofort bemerkt und auf den vorherigen
Stand (`wallhaven-9oxjvd_2560x1440.png`) zurückgesetzt; seither wird
matugen in dieser Session nicht mehr direkt manuell aufgerufen.

## Bekannte Lücken / Fahrplan

- **Kalender, Notification-Center, volle Media-Player-Ansicht** — im
  Auftrag als Beispiel-Panels genannt, hier noch nicht gebaut (Stage 2).
- **Qt-Theming** — Template-Ansatz dokumentiert, aber deaktiviert bis
  qt6ct/qt5ct installiert ist (siehe "System-Theming").
- **Multi-Monitor-Panels** — Panels fest an `Quickshell.screens[0]`, siehe
  "Architektur".
- **Tray-Kontextmenü** — nur Linksklick/Activate, kein Rechtsklick-Menü
  (bräuchte ein `hostWindow`, siehe `Bar/TrayCompact.qml`-Kommentar).
- **`Config.autoHideBar`** — implementiert (Content transformiert sich
  per Y-Offset, `exclusiveZone` bleibt konstant reserviert, kein
  Reveal-aus-Nullgröße-Problem), Default `false`, ungetestet gegen echtes
  Hover (siehe "Testen").
- **de_AT-Wochentagsnamen** — `Clock.dateText` nutzt
  `toLocaleDateString(Qt.locale("de_AT"), "ddd, d. MMM")`; funktioniert
  laut Qt-Doku, aber nicht live gegen dieses Quickshell/Qt-Build
  gegengeprüft (nur der App-Start insgesamt war fehlerfrei, nicht jeder
  einzelne Text-Wert visuell).
