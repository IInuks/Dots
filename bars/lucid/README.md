# lucid — Material 3 Expressive Pill-Bar für mango

Eigenständige Neuimplementierung, inspiriert vom Aussehen/Verhalten des
[Lucid](https://github.com/Sn3akyy1/lucid)-Rices (MIT-Lizenz) für Hyprland.
Kein Code von dort übernommen — Lucid ist fest an `Quickshell.Hyprland`
gebunden, das hier nirgends vorkommt. Alles unten ist neu geschrieben gegen
`mmsg` (mango) und `Quickshell.Wayland`.

**Scope:** die Bar + ihre aufklappenden Panels, plus (nachträglich, auf
expliziten Wunsch) ein App-Launcher unter SUPER+space. Ursprünglich als
"kein Launcher" ausgeschlossen (siehe "App-Launcher" unten für die
Begründung der Kursänderung) — weiterhin kein Dock, kein Lockscreen, kein
Emoji-Picker, kein Screenshot-Tool, keine separate Settings-App.

**Baufortschritt:** Alle sieben Stages fertig (Gerüst, Theme, Bar-Mechanik,
Clock komplett: Uhrzeit-Pille, Kalender, Wetter, Reminders+Toast; System
komplett: Lautstärke, Mikro, Helligkeit, Akku, RAM/CPU/Disk, volle WLAN- und
Bluetooth-Panels; Tray komplett: SNI-Liste mit echten App-Icons, Aktivieren
+ Kontextmenüs; Notifications komplett: Toasts, Verlauf, DND, Actions;
Media komplett: MPRIS-Steuerung + cava-Audiovisualizer; Tags komplett:
Tag-Raster + Fensterliste mit Fokus/Schließen). Jedes der sechs Module hat
jetzt echten Panel-Inhalt — siehe "Fahrplan" für die noch offenen
Politur-Punkte danach. Dazu (nachträglich): ein SUPER+space-App-Launcher,
siehe eigener Abschnitt "App-Launcher" unten.

## Kurzfassung

**Abhängigkeiten:** Quickshell ≥ 0.3.0, mango (`mmsg`), Pipewire/wireplumber,
NetworkManager (`nmcli`), `bluez` (`bluetoothctl`), `brightnessctl`,
`upower`, `cava`, `jq`, `matugen`, `pkgs.material-symbols` (Family "Material
Symbols Rounded"), `libnotify`. Alle über `flake.nix`s `homeManagerModules.
lucidbar` in `home.packages` gezogen — siehe "NixOS-Integration" unten für
den Haken dabei. `cava` läuft gegen Pipewire nativ (`method = pipewire`,
siehe Stage 6) — kein Pulseaudio/`pipewire-pulse` nötig, obwohl `cava`
selbst dafür historisch am bekanntesten ist.

**Start (Test/Debug):**
```
qs -p ~/quickdots/bars/lucid -n
```
Log/Fehler: `qs -p ~/quickdots/bars/lucid log`. Beenden über
`qs -p ~/quickdots/bars/lucid kill` (nicht `pkill` — ein
nicht exakt passendes Pattern lässt die alte Instanz laufen, dann meldet
der nächste Testlauf "already running").

## Struktur (Stand Stage 1)

```
shell.qml            Root: ein Bar pro Bildschirm (Variants über
                      Quickshell.screens)
Theme.qml              Singleton: Farben (matugen-adaptiv + 4 feste
                        Paletten), Radien, Motion-Tokens, Fontauflösung
Config.qml              Singleton: persistierte Wahl (Shape-Modus,
                         Palette, UI-Font, DND, Modul-Enable+Monitor) ->
                         ~/.config/lucidbar/config.json
MangoService.qml          Singleton: alle mmsg-Aufrufe, siehe eigener
                           Kommentarblock oben in der Datei für die real
                           geprüften Subcommands/JSON-Schemas. focusClient/
                           closeClient (Stage 7) nutzen `focusid`/
                           `killclient client,<id>` -- ersteres steht nicht
                           im mango-Wiki, gefunden durch Absuchen der
                           installierten Binary nach ihrer bind-Funktions-
                           Keyword-Tabelle, dann live gegengeprüft
Clock.qml                  Singleton: eine gemeinsame "now" (Timer,
                            1s) für Uhrzeit-Pille, Kalender, Reminder-
                            Fälligkeit
Reminders.qml                Singleton: persistierte Liste ->
                              ~/.config/lucidbar/reminders.json,
                              prüft alle 15s Fälligkeit gegen Clock.now,
                              feuert über ToastState
ToastState.qml                  Singleton: ein Toast auf einmal, von
                                 jedem Bar dargestellt (Stage 5
                                 Notifications nutzt denselben Mechanismus
                                 mit)
WeatherService.qml                Singleton: Open-Meteo (kein API-Key)
                                   statt wttr.in — Geocoding von
                                   Config.weatherLocation, dann
                                   current_weather, alle 15min neu.
                                   Live gegen die echten Endpunkte
                                   getestet (siehe unten)
BarRegistry.qml                     Singleton: outputName -> Bar-
                                     Instanz, damit IpcHandler auf den
                                     fokussierten Monitor routen kann
Bar/Bar.qml           Ein PanelWindow pro Bildschirm: drei Gruppen
                       (links Tags, Mitte Uhr+Media, rechts Tray+
                       Benachrichtigungen+System), `mask` hält leere
                       Flächen klick-durchlässig (Technik aus
                       bars/blobs/Bar.qml)
Bar/Pill.qml             Morph-Hülle jedes Moduls: Pille (voll gerundet)
                          <-> Panel (Rechteck mit Theme.radiusPanel),
                          Icon bleibt an seiner Ankerkante fixiert
                          (adaptiert aus bars/blobs/components/
                          MorphBlob.qml, gleicher Autor, keine
                          Lucid-Übernahme)
Bar/Icon.qml               Ein Glyph: Material Symbols Rounded, sonst
                            Unicode-Fallback, falls die Schrift fehlt
Bar/TextField.qml            Minimaler eigener Texteingabe-Rahmen (kein
                              QtQuick.Controls) — Reminder-Text jetzt,
                              WLAN-Passwort in Stage 3
Bar/Toast.qml                  Reminder-/Notification-Karte, blendet
                                über ToastState ein/aus
Panels/ClockPanel.qml    Clock-Panelinhalt: Kalender, Wetter, Reminders
                          in einem scrollbaren Flickable
Panels/CalendarGrid.qml    Kompakter Monatskalender, heute hervorgehoben
Panels/WeatherRow.qml       Aktuelle Bedingungen + Ort/Fehlerzustand
Panels/ReminderList.qml       Text+Uhrzeit-Eingabe, sortierte Liste,
                               löschbar, erledigte durchgestrichen
SystemService.qml     Singleton: CPU/RAM (/proc)-Polling + Disk (`df`) +
                       Helligkeit (`brightnessctl`) — die vier System-Werte
                       ohne eigenen Quickshell-Dienst (siehe Kommentarblock
                       oben in der Datei). Lautstärke/Mikro/Akku/WLAN/
                       Bluetooth laufen direkt über Quickshell.Services.
                       Pipewire/UPower/Quickshell.Networking/Quickshell.
                       Bluetooth, ohne eigenen Wrapper — selbe Quellen, die
                       bars/fisheye dafür schon nutzt und die hier erneut
                       gegen dieses System bestätigt wurden.
Panels/SystemPanel.qml    System-Panelinhalt: alle sechs Sections in einem
                           scrollbaren Flickable, gleiche Struktur wie
                           ClockPanel.qml
Panels/AudioSection.qml     Lautstärke + Mikro, je Icon (Mute-Toggle) +
                             Slider, via Pipewire.defaultAudioSink/
                             defaultAudioSource
Panels/BrightnessRow.qml     Helligkeits-Slider via SystemService,
                              versteckt sich ganz ohne Backlight-Gerät
Panels/BatteryRow.qml          Akku-Prozent + Ladezustand via UPower,
                                versteckt sich ganz ohne Akku (Desktop)
Panels/StatsRow.qml              CPU/RAM/Disk kompakt in einer Zeile,
                                  via SystemService
Panels/WifiSection.qml             Volles WLAN-Panel: Kabel-Status,
                                    WLAN-An/Aus, Netzwerkliste mit
                                    Passwort-Eingabe, via Quickshell.
                                    Networking
Panels/BluetoothSection.qml          Volles Bluetooth-Panel: Adapter-
                                      Toggle, Geräteliste mit Verbinden/
                                      Koppeln, via Quickshell.Bluetooth
Panels/TrayPanel.qml    Tray-Panelinhalt: eine Zeile pro SNI-Item, echtes
                         App-Icon statt Glyph, Linksklick aktiviert,
                         Rechtsklick öffnet das native Kontextmenü über
                         `modelData.display(hostWindow, x, y)` — braucht
                         dafür das echte PanelWindow (`bar`), nicht nur ein
                         beliebiges Item, deshalb als `hostWindow` von
                         `Bar/Bar.qml` durchgereicht
CavaService.qml           Singleton: wrappt `cava` (raw-ascii-Ausgabe,
                          `method = pipewire`) für den Media-Panel-
                          Visualizer. Schreibt einmalig eine generierte
                          Config nach ~/.cache/lucidbar/cava.conf (nicht
                          nutzereditierbar, anders als Config.qml), läuft
                          nur bei geöffnetem Media-Panel (refcounted via
                          acquire()/release())
Bar/CavaBars.qml            Reine Balkenreihe, liest CavaService.levels
Panels/MediaPanel.qml    Media-Panelinhalt: MPRIS-Cover/Titel/Künstler,
                          Zurück/Play-Pause/Vor, Fortschrittsbalken (lokal
                          zwischen echten MPRIS-Positions-Updates
                          interpoliert, siehe Kommentarblock in der Datei),
                          darunter CavaBars — Player und Visualizer sind
                          unabhängig voneinander sichtbar/aktiv
Panels/TagsPanel.qml     Tags-Panelinhalt: klickbares Raster aller
                          mango-Tags (aktiv/belegt/dringend eingefärbt,
                          Klick wechselt via MangoService.viewTag), darunter
                          die Fensterliste der gerade aktiven Tags — Klick
                          fokussiert (focusClient), das X-Icon schließt
                          gezielt (closeClient)
Bar/Slider.qml         Eigener Drag+Scroll-Slider (kein QtQuick.Controls),
                        `value` kommt vom Aufrufer (echte Quelle, z.B.
                        Pipewire audio.volume), Ziehen/Scrollen feuert nur
                        `moved` — kein Zwei-Wege-Binding gegen einen
                        Live-Dienst
Bar/Toggle.qml          Eigener An/Aus-Schalter, gleicher Stil
AppEntries.qml            Singleton (nachträglich, App-Launcher): scannt
                           .desktop-Dateien, siehe eigener Kommentarblock
                           für die Namensgebungs-Falle (nicht
                           "DesktopEntries.qml")
LauncherState.qml            Singleton (nachträglich): isOpen + screenName,
                              Brücke zwischen shell.qml's IpcHandler und dem
                              Loader für LauncherWindow.qml
LauncherWindow.qml              Eigenes Layer-Shell-Fenster (nachträglich):
                                 zentrierter Such-Popup, frisch erzeugt bei
                                 jedem Öffnen — siehe "App-Launcher" oben für
                                 den Grund
flake.nix             packages.default (QML-Tree als Derivation) +
                       homeManagerModules.lucidbar
```

## Entwurfsentscheidungen (Abweichungen vom ursprünglichen Auftrag)

- **Pille = die Panel-Surface selbst**, nicht Pille + separates Flyout.
  Jedes Modul ist eine einzelne, dauerhaft geladene `Pill`-Instanz, die
  zwischen Rest- und Offen-Größe morpht (Spring auf width/height, siehe
  `Bar/Pill.qml`) — technisch identisch zur bereits gebauten und
  getesteten `bars/blobs/components/MorphBlob.qml`, nur auf sechs Module
  statt drei erweitert. Alle sechs Pillen leben in **einem** gemeinsamen,
  überdimensionierten `PanelWindow` pro Bildschirm (`Theme.maxPanelHeight`
  hoch), dessen `mask` nur die tatsächlich sichtbaren Pillen/Panels
  klickbar macht — sonst würde jedes geöffnete Panel am Fensterrand
  abgeschnitten oder der leere Rest des Fensters Klicks vor darunter
  liegenden Fenstern abfangen (gleiche Falle, gleiche Lösung wie in
  `bars/blobs`).
- **Adaptive Palette ruft `matugen` selbst als Process auf**, liest aber
  **nicht** `~/.cache/quickshell/matugen.json` per FileView, wie ursprünglich
  skizziert. Grund: nichts auf diesem System erzeugt diese Datei, und
  `bars/klasic/Theme.qml` hat den realen `matugen --json hex`-Output schon
  gegen den tatsächlich installierten Binary (4.2.0) verifiziert — er ist
  `{"colors":{"<rolle>":{"dark":{"color":"#hex"}, ...}}}`, verschachtelt pro
  Rolle, **keine** flache Map, wie der ursprüngliche Auftrag annahm. Eine
  flache JSON-Datei hätte ich aus genau diesem verschachtelten Output selbst
  bauen müssen — ein Umweg ohne Nutzen gegenüber der schon bewährten
  Prozess-Variante aus `bars/klasic`. Übernommen wurde von dort auch: `
  --source-color-index 0` (empirisch besser als `--prefer saturation` auf
  echten Wallpapern dieses Systems) und `--mode dark` (erzwungen, kein
  Light-Mode in dieser Bar). Die Wallpaper-Pfad-Erkennung läuft weiterhin
  über `~/.cache/wal/colors.json` (von `wal`/shellwall bei jedem
  Wallpaper-Wechsel geschrieben, `.wallpaper`-Feld) — dieselbe Quelle, die
  auch `bars/klasic` und `bars/fisheye` schon nutzen.
- **Kein `programs.quickshell.configs`.** Dieses Home-Manager-Modul
  existiert in aktuellem nixpkgs/home-manager nicht (geprüft) — `flake.nix`
  legt die QML-Dateien stattdessen direkt über `home.file
  ".config/quickshell/lucidbar".source` ab, was `qs -c lucidbar` bzw. `qs`s
  eigene `<xdg dir>/quickshell/<name>/shell.qml`-Konvention nutzt.

## NixOS-Integration — was auf DIESEM System tatsächlich zutrifft

Dieser Rechner nutzt **kein Home-Manager** (`/etc/nixos/flake.nix` hat keine
`home-manager`-Eingabe, `configuration.nix` importiert kein HM-Modul,
`quickshell` selbst ist ein schlichtes `environment.systemPackages`-Paket).
`flake.nix`s `homeManagerModules.lucidbar` ist trotzdem so gebaut, wie im
Auftrag verlangt — funktioniert, sobald du Home-Manager einmal in dein
System einbindest — aber **aktiviert auf diesem Rechner aktuell nichts von
selbst**. Zwei Wege, keiner davon von mir ungefragt ausgeführt:

1. **Home-Manager nachrüsten** (größerer, eigenständiger Schritt: neuer
   Flake-Input, `home-manager.nixosModules.home-manager`-Import in
   `configuration.nix`, `home-manager.users.<username>.imports = [
   lucid.homeManagerModules.lucidbar ]`, `programs.lucidbar.enable = true;`).
2. **Ohne Home-Manager, analog zu allen anderen `bars/*` hier:**
   `environment.systemPackages` in `/etc/nixos/configuration.nix` um die
   oben gelistete Paketmenge ergänzen (viele — `quickshell`, `bluez`,
   `brightnessctl`, `upower`, `cava`, `matugen`, `material-symbols` — fehlen
   dort schon für andere Bars, siehe "Fehlende CLIs" unten) und die QML
   einfach dort lassen, wo sie ist (`qs -p ~/quickdots/bars/lucid`),
   wie jede andere Bar in diesem Repo auch.

Sag Bescheid, welcher Weg gewünscht ist — ich fasse `/etc/nixos` nicht ohne
ausdrückliche Aufforderung an.

**Fehlende CLIs (Stand heute):** `cava`, `jq`, `bluetoothctl` (`bluez`),
`brightnessctl`, `upower`, `material-symbols` fehlten auf diesem System und
wurden für den Bau testweise per `nix profile install` in dein Nix-Profil
gezogen (reversibel: `nix profile remove <name>`) — dieselben Pakete, die
`flake.nix` ohnehin für den Dauerbetrieb vorsieht, also kein verlorener
Aufwand, aber eine bewusste, von dir bestätigte Abweichung vom "nichts
außerhalb von ~/.config/lucidbar und ~/.cache/quickshell anfassen"-Grundsatz
des Auftrags (der bezieht sich auf Schreibziele der Bar selbst zur
Laufzeit, nicht auf einmalige Bau-/Test-Werkzeuge).

## mango-Anbindung

Siehe den ausführlichen Kommentarblock oben in `MangoService.qml` für alle
real geprüften `mmsg`-Subcommands und JSON-Schemas (gegen die echte laufende
Compositor-Instanz verifiziert, nicht nur gegen `--help`/Wiki). Eine
Abweichung zwischen MangoWC-Wiki und dem tatsächlich installierten Binary:
die Wiki-Seite `ipc` listet `get/watch all-layers`, das echte `mmsg --help`
und ein echter Aufruf kennen diesen Subcommand nicht (`{"error":"unknown
command"}`) — nirgends in diesem Bar-Code verwendet.

## App-Launcher

Nachträglich hinzugefügt, auf expliziten Wunsch — ursprünglich hatte diese
Bar "kein Launcher" im Scope, siehe die Begründung im "Scope"-Absatz oben.
Zwei neue Root-Dateien:

- `AppEntries.qml` (Singleton): scannt `.desktop`-Dateien über
  `XDG_DATA_DIRS` + `~/.local/share/applications` in einem einzigen
  `sh -c`-Prozess, verbatim übernommen aus `bars/quickbar/DesktopEntries.
  qml` (gleicher Autor, keine Änderungen an der Scan-/Parse-Logik nötig).
  **Bewusst nicht `DesktopEntries.qml` genannt** — Quickshell bringt einen
  eigenen eingebauten `DesktopEntries`-Typ mit, und jede Datei, die
  zusätzlich `import Quickshell` hat (wie `LauncherWindow.qml`, wegen
  `Quickshell.screens`), löst einen nackten `DesktopEntries`-Bezeichner
  dann **lautlos** auf den eingebauten Typ auf statt auf die eigene
  Singleton-Datei — kein Fehler, nur `.apps`/`.ready` für immer
  `undefined` (memory: `feedback_qml_singleton_name_shadows_builtin`).
  Genau das ist beim ersten Testlauf dieser Datei auch tatsächlich passiert
  (`TypeError: Cannot read property 'length' of undefined` im Log), erst
  danach umbenannt. `quickdots/menu` ist derselben Falle schon vorher
  begegnet und hat seine eigene Kopie deshalb `AppEntries.qml` genannt —
  hier aus genau demselben Grund übernommen.
- `LauncherWindow.qml` + `LauncherState.qml`: eigenes Layer-Shell-Fenster
  (`WlrLayer.Overlay`, unangeankert → zentriert auf dem Bildschirm),
  **frisch erzeugt bei jedem Öffnen** über einen `Loader` in `shell.qml`
  (`active: LauncherState.isOpen`), nicht als dauerhaft gemapptes Fenster
  mit umgeschaltetem `visible`. Grund: mango vergibt `WlrKeyboardFocus.
  OnDemand` nur beim allerersten Commit einer Surface oder bei einem
  Mausklick auf eine bereits als on-demand committete Surface (memory:
  `feedback_mango_ondemand_focus_requires_fresh_surface`) — SUPER+space
  ist ein Dispatch-Aufruf, kein Klick, kann also nie den zweiten Pfad
  auslösen. Nur ein wirklich neuer `initial_commit` bei jedem Öffnen
  funktioniert zuverlässig; exakt dieselbe Schlussfolgerung (und Lösung)
  wie in `bars/fisheye/bar/LauncherWindow.qml`.
- IPC-Target `launcher` (`toggle`/`open`/`close`) in `shell.qml`, gleiches
  Muster wie die anderen sechs, ruft aber `LauncherState` direkt statt
  `BarRegistry` (nur ein Launcher gleichzeitig nötig, kein Per-Bildschirm-
  Zustand wie bei den sechs Pillen).
- `~/quickdots/menu/adapters/lucid.json` neu angelegt (`hasLauncher: true`
  + `keybinds: ["bind=SUPER,space,spawn,qs -p .../bars/lucid ipc call
  launcher toggle"]`) — dasselbe Adapter-Schema, das `fisheye`/`chamaeleon`/
  `quickbar`/`lumen`/`claude`/`blobs`/`simple`/`simplecrab`/`kompass`/
  `shellbar` schon nutzen, damit `quickdots/menu`s globaler SUPER+space-
  Bind (aktuell `toggle-launcher.sh`, das ohne Adapter-Eintrag auf `menu`s
  generischen Fallback-Launcher zeigt) für diese Bar auf den eigenen
  Launcher umgeleitet wird. **Wichtig:** dieser Adapter-Eintrag allein
  ändert `~/.config/mango/config.conf` noch nicht — `menu/scripts/
  switch-bar.sh` schreibt den `keybinds`-Eintrag erst beim nächsten
  tatsächlichen Bar-Wechsel über die `menu`-UI in den verwalteten Config-
  Block. `config.conf` wurde hier bewusst nicht von Hand angefasst (gleiche
  Zurückhaltung wie beim Blur-Abschnitt oben) — einmal kurz über `menu`
  zu/von lucid wechseln (oder `switch-bar.sh` direkt aufrufen) reicht, um
  den SUPER+space-Bind zu aktivieren.

**Live getestet (echtes System, nicht nur strukturell):** `qs -p . -n` +
`qs ipc call launcher open`/`close` + `mmsg get last_open_surface`
bestätigten die `lucid-launcher`-Surface. Per `wlrctl keyboard type`
(echte virtuelle Tastatureingabe, kein simulierter QML-Event) bestätigt,
dass eine frisch erzeugte Surface tatsächlich Tastaturfokus bekommt — Text
erschien im Suchfeld. Echte Substring-Suche gegen echte installierte
`.desktop`-Daten bestätigt (Query `"ri"` → korrekt `Brave Origin` und
`Factorio Demo`, oberstes Ergebnis korrekt hervorgehoben).

**Ein Vorfall beim Live-Testen, transparent dokumentiert:** Bei einem
`wlrctl`-Testlauf ist der Tastaturfokus nach einem Enter-getriggerten
`launchSelected()` (das eine bereits laufende Single-Instance-App aktiviert
hat) offenbar auf deren Fenster gewandert, statt beim neu geöffneten
Launcher zu bleiben — nachfolgende Testeingaben landeten dadurch kurzzeitig
in einem echten Browser-Tab statt im Launcher. Sofort bemerkt und bereinigt
(Text wieder gelöscht, bevor irgendetwas abgeschickt wurde), bevor weiter
getestet wurde. Ob das ein mango-Fokus-Quirk speziell nach `launchSelected()`
ist oder ein Testartefakt von `wlrctl`s virtueller Tastatur, ist ungeklärt
— siehe "Bekannte Lücken".

## Blur hinter den Panels

Noch **nicht** in deine `~/.config/mango/config.conf` eingetragen (Auftrag:
nur dokumentieren, nicht ungefragt setzen). `blur`/`blur_layer` sind
**globale** Schalter (MangoWC-Wiki `effects`); `layerrule=...,noblur:1,
layer_name:<regex>` kann Blur nur pro Layer **ausschließen**, nicht
selektiv nur für `lucid-bar` **einschalten**. Für Blur hinter den
Lucid-Panels bräuchtest du:

```
blur=1
blur_layer=1
```

...plus, weil das dann auch die anderen aktuell laufenden Quickshell-Bars
(shellwall, blobball, menu, claude) trifft, pro Layer, den du NICHT
weichgezeichnet haben willst:

```
layerrule=noblur:1,layer_name:<namespace-dieser-bar>
```

`lucid-bar`s eigener Layer-Namespace ist `lucid-bar` (siehe `WlrLayershell.
namespace` in `Bar/Bar.qml`) — zur Bestätigung nach dem Start:
`mmsg get last_open_surface`.

## Fahrplan

- **Stage 1 (fertig):** Gerüst, `Theme.qml` (5 Paletten inkl. Live-Matugen),
  `Config.qml`, `MangoService.qml`, `flake.nix`, leere Bar mit sechs
  morphenden Pillen — lädt fehlerfrei, Fenster von mango als
  `lucid-bar`-Layer bestätigt (`mmsg get last_open_surface`).
- **Stage 2 (fertig):** Clock — Pille zeigt Live-Uhrzeit (`Clock.qml`,
  1s-Timer), Panel mit Monatskalender (heute hervorgehoben), Wetter
  (Open-Meteo, Geocoding + `current_weather`, End-to-End gegen die echten
  Endpunkte getestet: `Wien` → `24.4°C Bedeckt` korrekt geparst) und
  Remindern (Text+Uhrzeit, persistiert, feuert als Toast über
  `ToastState`, per Escape/Klick-außerhalb schließbar). IPC-Target
  `clock` (`toggle`/`open`/`close`) über `BarRegistry` verifiziert (`qs
  ipc call clock toggle`, kein Fehler im Log). `WlrKeyboardFocus` von
  `None` auf dauerhaft `OnDemand` umgestellt (siehe "Entwurfs-
  entscheidungen") — nötig für das Reminder-Textfeld.
  Standort für Wetter ist bewusst nicht vorbelegt (`Config.
  weatherLocation`, leer) — noch keine Einstellungs-UI dafür, bis dahin
  manuell in `~/.config/lucidbar/config.json` setzen.
- **Stage 3 (fertig):** System — Lautstärke+Mikro (Pipewire, je Slider +
  Mute-Toggle), Helligkeit (`brightnessctl`, versteckt sich ohne
  Backlight-Gerät), Akku (UPower, versteckt sich ohne Akku), RAM/CPU/Disk
  (kompakte Zeile), volles WLAN-Panel (Kabel-Status, An/Aus, Netzwerkliste,
  Passwort-Eingabe für unbekannte gesicherte Netze) und volles
  Bluetooth-Panel (Adapter-Toggle, Geräteliste mit Verbinden/Koppeln) —
  alles in einem gemeinsamen scrollbaren Panel (`Panels/SystemPanel.qml`),
  wie Clock. IPC-Target `system` (`toggle`/`open`/`close`) über
  `BarRegistry` ergänzt, gleiches Muster wie `clock`. Getestet via `qs -p .
  -n` + `qs ipc call system open`/`close` + Log-Kontrolle (keine
  QML-Fehler/TypeErrors) — auf diesem Desktop ohne echten Bluetooth-Dienst
  und ohne UPower (kein Akku) laufend getestet, beide Dienste degradieren
  dabei erwartungsgemäß auf "kein Adapter"/versteckte Zeile statt zu
  crashen (DBus-Warnungen im Log sind Umgebungslücken dieses Rechners, kein
  Bug — siehe bars/fisheye für dieselbe bereits dokumentierte Einschränkung).
  Nicht per echtem Mausklick/Scroll durchgetestet (kein Zugriff auf echte
  Maus/Tastatur in dieser Umgebung, wie schon bei Stage 2).
- **Stage 4 (fertig):** Tray — `Panels/TrayPanel.qml` listet `SystemTray.
  items` (Quickshell.Services.SystemTray) als scrollbare Zeilen, gleiches
  Grundmuster wie `ClockPanel`/`SystemPanel`. Echtes App-Icon (`modelData.
  icon`, asynchron geladen) statt Material-Glyph — ein Tray-Icon lässt sich
  nicht als Symbol neu zeichnen. Linksklick `activate()`, Rechtsklick (nur
  wenn `hasMenu`) öffnet das native Kontextmenü über `modelData.display
  (hostWindow, x, y)`. `hostWindow` ist das eigentliche `PanelWindow`
  (`bar` aus `Bar/Bar.qml`, als Property durchgereicht) — `display()`
  braucht ein echtes Quickshell-Window zum Verankern, kein beliebiges Item.
  Gleicher SystemTray.items+display()-Ansatz wie schon in `bars/claude/
  Bar/TrayRow.qml` und `bars/fisheye/bar/modules/TrayModule.qml` bewährt,
  hier nur in die aufklappende Panel-Konvention dieser Bar übersetzt statt
  einer dauerhaft sichtbaren Icon-Reihe (Pille selbst bleibt ein statisches
  Icon, wie Clock/System es bei ihrem Trigger-Icon auch halten — kein
  Live-Badge in der Pille, gleiche bewusste Zurückhaltung wie bei der
  System-Pille, siehe "Bekannte Lücken"). IPC-Target `tray` (`toggle`/
  `open`/`close`) über `BarRegistry` ergänzt, gleiches Muster wie `clock`/
  `system`. Getestet via `qs -p . -n` + `qs ipc call tray toggle`/`close` +
  Log-Kontrolle (keine QML-Fehler/TypeErrors, Panel öffnet/schließt sauber
  mit leerer Liste). Dieser Rechner hat aktuell **keinen einzigen
  laufenden SNI-Client** (kein nm-applet/blueman/pasystray o.ä.) — der
  Leerlauf-Zustand ("Keine Tray-Icons") ist damit real getestet, das
  Icon-Rendering, `activate()` und das native Kontextmenü über `display()`
  dagegen nur strukturell (gegen den gleichen, bereits in `bars/claude`
  und `bars/fisheye` verifizierten API-Aufruf), nicht gegen ein echtes
  SNI-Item auf diesem System.
- **Stage 5 (fertig):** Notifications — `NotificationState.qml` (neuer
  Singleton: Log, `unread`-Zähler, `_live`-Map für echtes `dismiss()`) plus
  ein `NotificationServer` (`Quickshell.Services.Notifications`) in
  `shell.qml`, das ihn füttert — gleicher Split (Server im shell.qml wegen
  App-Lifetime, Zustand im Singleton) wie schon in `bars/claude`,
  `bars/chamaeleon`, `bars/ksp` und `bars/floating`. Anders als dort: kein
  zweiter Toast-Mechanismus — eingehende Notifications zeigen sich über das
  bereits vorhandene `ToastState` aus Stage 2 (dessen eigener Kommentar
  kündigte das schon an), unterdrückt bei aktivem `Config.dnd` (das Feld
  existierte in `Config.qml` bereits vor dieser Stage, nur ungenutzt).
  `Panels/NotificationsPanel.qml` (gleiches Flickable+Column-Grundmuster
  wie `ClockPanel`/`SystemPanel`/`TrayPanel`) zeigt den Log neuste zuerst,
  je Karte App+Zeitstempel+Schließen-Icon, Titel, Body und — falls vom
  Client mitgeschickt — Action-Buttons (`modelData.actions[].invoke()`),
  außerdem einen `Nicht stören`-Schalter (`Toggle.qml`, gebunden an
  `Config.dnd`/`Config.setDnd`) und „Alle löschen". Öffnen des Panels ruft
  `NotificationState.markSeen()`, ein kleiner Punkt auf der Glocken-Pille
  (`Theme.critical`, wie das Muster in `bars/chamaeleon/Bar/Bar.qml`) zeigt
  `unread > 0` an. IPC-Target `notifications` (`toggle`/`open`/`close`)
  über `BarRegistry` ergänzt, gleiches Muster wie die anderen vier. Kein
  konkurrierender Notification-Daemon auf diesem Rechner (`mako`/`dunst`/
  `swaync`/`fnott` per `pgrep` geprüft, keiner lief) — Beanspruchung von
  `org.freedesktop.Notifications` war also sicher; per `busctl --user
  status org.freedesktop.Notifications` nach dem Start bestätigt, dass der
  eigene Quickshell-Prozess der Owner ist. End-to-End getestet: `qs -p . -n`
  + `notify-send` (einmal einfach, einmal mit zwei `--action`-Einträgen) +
  `qs ipc call notifications open`/`close`/`toggle` + Log-Kontrolle nach
  jedem Schritt (keine QML-Fehler/TypeErrors bei Empfang, Panel-Öffnen mit
  gefülltem und mit leerem Log, Action-Buttons-Rendering). `imageSupported`
  bewusst aus (`NotificationServer` in `shell.qml`) — Icon-Rendering ist
  wie schon bei Tray kein Teil dieser Stage. Nicht per echtem Mausklick
  getestet, genau wie bei den vorigen Stages: DND-Schalter-Klick,
  Action-Button-Klick und Karten-Schließen-Klick sind nur strukturell
  (Bindung/Repeater lädt fehlerfrei), nicht mit echter Maus verifiziert.
- **Stage 6 (fertig):** Media — `CavaService.qml` (neuer Singleton) wrappt
  `cava` in raw-ascii-Ausgabemodus für den Audiovisualizer, `Panels/
  MediaPanel.qml` zeigt darüber Cover/Titel/Künstler, Zurück/Play-Pause/
  Vor und einen Fortschrittsbalken über `Quickshell.Services.Mpris`
  (gleiches "spielender Player, sonst der erste"-Auswahlmuster wie
  `bars/fisheye/MediaModule.qml` und `bars/lumen/Media.qml`, keine
  Mehrfach-Player-Umschaltung). Player-Steuerung und Visualizer sind
  bewusst entkoppelt — der Visualizer zeigt das tatsächlich hörbare Audio
  unabhängig davon, ob überhaupt ein MPRIS-fähiger Player läuft (Spiele,
  Browser ohne MPRIS-Unterstützung).
  `cava` braucht eine echte Config-**Datei** (keine Inline-CLI-Flags für
  Input/Output), also schreibt `CavaService.qml` einmalig eine generierte
  nach `~/.cache/lucidbar/cava.conf` — nicht nutzereditierbar, anders als
  `Config.qml`s persistiertes `~/.config/lucidbar/config.json`. Läuft nur
  bei geöffnetem Media-Panel (refcounted `acquire()`/`release()`, von
  `MediaPanel.qml`s `active`-Property aus `Bar.qml`s `Pill.open`
  gegengeprüft) — anders als die immer laufenden Pipewire/UPower-Tracker
  im System-Panel ist das ein dauerhafter 60fps-Capture-Prozess, den es
  nicht wert ist, hinter einem geschlossenen Panel weiterlaufen zu lassen.
  **Input-Methode ist `pipewire` nativ, nicht `pulse`** — kein
  Pulseaudio/`pipewire-pulse`-Kompatibilitätslayer nötig, obwohl `cava`
  historisch dafür bekannt ist; live gegen das echte, installierte `cava`
  1.0.0 auf diesem System verifiziert: ein per `pw-play` abgespielter
  440Hz-Testton erzeugte über `qs -p . ipc call media open` + laufendem
  `cava`-Subprozess ein reales, plausibles Spektrum (Peak im erwarteten
  unteren Balken) im exakt geparsten Format (`0;2;100;7;5;4;` — Semikolon
  auch nach dem letzten Wert, ein `bars`-Wert muss bei Stereo-Eingabe
  gerade sein, daher `channels = mono` statt eine gerade Balkenzahl zu
  erzwingen). `qs -p . ipc call media open`/`toggle`/`close` + `ps aux`
  bestätigten außerdem den Prozess-Lebenszyklus: `cava` startet exakt beim
  Öffnen und stirbt exakt beim Schließen, keine Leiche danach. IPC-Target
  `media` über `BarRegistry` ergänzt, gleiches Muster wie die anderen
  fünf. Kein MPRIS-Player auf diesem Rechner aktuell aktiv — die
  Player-Steuerung selbst (Cover/Titel/Künstler, Buttons, Fortschritts-
  Interpolation) ist deshalb nur strukturell verifiziert (lädt fehlerfrei,
  "Kein Player aktiv"-Leerzustand real getestet), nicht gegen einen
  echten Player, siehe "Bekannte Lücken".
- **Stage 7 (fertig):** Tags — `Panels/TagsPanel.qml` zeigt ein klickbares
  Raster aller `MangoService.tagsFor(screenName)`-Tags (aktiv gefüllt,
  belegt schwach gefüllt, dringend rot umrandet — gleiches Datenschema wie
  in `bars/chamaeleon`/`bars/lumen` schon verifiziert), Klick auf ein Tag
  wechselt via `MangoService.viewTag` (schon seit Stage 1 vorbereitet).
  Darunter die Fensterliste der gerade aktiven Tags (mehrere gleichzeitig
  aktive Tags sind bei mango möglich, deshalb eine Vereinigung über
  `active_tags`, kein Gleichheitsvergleich); Klick auf ein Fenster
  fokussiert es, das X-Icon schließt gezielt nur dieses eine Fenster.
  Die Tags-Pille selbst zeigt jetzt (wie die Clock-Pille) einen kleinen
  Live-Wert neben dem Icon — die Nummer(n) des/der gerade aktiven Tags —
  statt der bisher rein statischen "workspaces"-Glyphe; einzige bewusste
  Abweichung von der sonstigen "Pille bleibt stumm, Panel zeigt alles"-
  Zurückhaltung dieser Bar, aus demselben Grund wie bei Clock: es gibt
  hier einen einzelnen, offensichtlich nützlichen Wert.
  Zwei mmsg-Dispatch-Funktionen für `MangoService.qml` ergänzt, beide echt
  gegen die laufende Compositor-Instanz verifiziert, nicht nur gegen
  `--help`: **`focusid,<id>`** steht nicht im mango-Wiki und wurde durch
  Absuchen der installierten `mango`-Binary nach ihrer bind-Funktions-
  Keyword-Tabelle gefunden (`../src/dispatch/bind.c`-Nachbarschaft im
  Rodata) — live bestätigt, dass es einen Klienten auf einem *gerade
  angezeigten* Tag tatsächlich fokussiert, bei einem nicht angezeigten Tag
  aber `{"success":true}` zurückgibt, ohne den Fokus wirklich zu bewegen
  (harmlos hier, da die Fensterliste per Konstruktion nur je aktive Tags
  zeigt). **`killclient client,<id>`** (mmsg --help's eigenes dokumentiertes
  `client,<id>`-Targeting, hier zum ersten Mal in dieser Bar genutzt) —
  live an einem eigens dafür gestarteten Wegwerf-`kitty`-Fenster
  verifiziert: schloss exakt dieses eine Fenster, ließ die zwei echten
  Fenster dieses Rechners unangetastet. IPC-Target `tags` über
  `BarRegistry` ergänzt, gleiches Muster wie die anderen sechs; `qs -p . -n`
  + `qs ipc call tags open`/`toggle`/`close` + `mmsg get
  last_open_surface` + Log-Kontrolle liefen fehlerfrei. Reale Tag-Daten
  dieses Rechners (`DP-4`, `tag_num: 9`, zwei echte Klienten auf Tag 1/2)
  bestätigten, dass Grid, Fensterliste und Live-Zahl auf der Pille mit
  echten Compositor-Daten übereinstimmen (nicht nur mit einem leeren
  Zustand) — die einzige Stage bisher, für die kein "leer/nicht
  installiert"-Vorbehalt in "Bekannte Lücken" nötig ist.
- **Danach:** IPC-Targets + Beispiel-Keybinds in dieser README, "notch"-
  Formvariante mit echten konkaven Flares (Stage 1 unterscheidet Insel/
  Notch bisher nur über Fensterrand-Marge, keine Shape-Geometrie),
  Theming-Abschnitt, Troubleshooting.

## Bekannte Lücken (Stand Stage 7)

- "notch"-Formmodus hat noch keine konkaven Flare-Kurven (QtQuick.Shapes) —
  bisher nur randbündig vs. schwebend über die Fenster-Marge.
- Kein Settings-Panel für `Config.weatherLocation` — muss weiterhin manuell
  in `config.json` gesetzt werden.
- Nicht per Mausklick im echten Compositor durchgetestet (kein Zugriff auf
  eine echte Maus/Tastatur in dieser Umgebung), nur `qs -p . -n` +
  `mmsg get last_open_surface` + `qs ipc call` + Log-Kontrolle nach jedem
  Schritt. Insbesondere ungetestet: Reminder-Textfeld-Fokus, WLAN-Passwort-
  Feld-Fokus, Slider-Drag/Scroll und Toggle-Klicks per echter Maus (OnDemand-
  Fokus-Logik ist die in `bars/lumen` bereits bestätigte, aber die konkrete
  Interaktion hier noch nicht live geklickt), Toast-Anzeige/Ausblenden
  visuell.
- Bluetooth- und Akku-Zweig nur strukturell verifiziert, nicht gegen echte
  Geräte/echten Akku: dieser Rechner hat weder einen laufenden
  `bluetooth.service` noch einen UPower-Akku (Desktop) — beide Dienste sind
  hier dauerhaft im "leer/kein Adapter"-Zustand, genau wie schon in
  `bars/fisheye` dokumentiert. Vor echtem Einsatz auf einem Laptop/mit
  Bluetooth-Adapter noch mal gegenprüfen.
- Kein Live-Wert in der System-Pille selbst (nur das Zahnrad-Icon, wie vor
  Stage 3) — bewusst keine Scope-Erweiterung über den Auftrag hinaus, ließe
  sich aber leicht ergänzen (siehe wie die Clock-Pille `Clock.formatTime`
  neben ihrem Icon zeigt).
- Tray-Panel nur mit leerer `SystemTray.items`-Liste getestet (dieser
  Rechner hat aktuell keinen laufenden SNI-Client) — Icon-Rendering,
  `activate()` und das native Kontextmenü über `display()` sind nur
  strukturell verifiziert (gleicher API-Aufruf wie in `bars/claude` und
  `bars/fisheye`), nicht gegen ein echtes Tray-Item. Vor echtem Einsatz
  z.B. mit laufendem `nm-applet`/`blueman-applet` noch mal gegenprüfen.
  Auch keine Live-Anzahl in der Tray-Pille selbst, gleiche bewusste
  Zurückhaltung wie beim Zahnrad-Icon der System-Pille.
- Notifications: kein Icon-Rendering (`imageSupported` im `NotificationServer`
  bewusst aus, siehe Stage-5-Eintrag oben) — nur App-Name/Titel/Body/Zeit.
  DND-Schalter, Action-Buttons und Karten-Schließen sind nur strukturell
  getestet (End-to-End via `notify-send`, aber ohne echten Mausklick auf den
  Schalter/Button selbst). Kein Urgency-basiertes Styling (Low/Normal/
  Critical werden gleich dargestellt) — bewusst nicht Teil des Stage-5-
  Auftrags (Toasts/History/DND/Actions), ließe sich aber leicht ergänzen.
- Media: kein MPRIS-Player auf diesem Rechner aktuell aktiv — Cover-Laden,
  Titel/Künstler-Anzeige, Zurück/Play-Pause/Vor-Buttons und die
  Fortschrittsbalken-Interpolation sind nur strukturell verifiziert (der
  "Kein Player aktiv"-Leerzustand dagegen real getestet), nicht gegen
  einen echten Player. Insbesondere ungetestet: ob `player.position =
  wert` (Scrubben im Fortschrittsbalken) beim tatsächlich installierten
  Player als Seek ankommt, und ob dessen `position` sich tatsächlich nur
  sporadisch statt jede Sekunde aktualisiert (Annahme, auf der die lokale
  Interpolation beruht — siehe Kommentarblock in `MediaPanel.qml`). Der
  cava-Visualizer selbst (Prozess-Lebenszyklus + reales Audiospektrum) ist
  dagegen live verifiziert, siehe Stage-6-Eintrag oben. Keine
  Mehrfach-Player-Umschaltung, bewusst nicht Teil des Auftrags (gleiches
  "spielender Player, sonst der erste"-Muster wie `bars/fisheye` und
  `bars/lumen`). Vor echtem Einsatz mit laufendem Player (Spotify, mpv,
  Browser-Tab, ...) noch mal gegenprüfen.
- Tags: `focusid`/`killclient client,<id>` selbst sind live gegen die
  echte Compositor-Instanz verifiziert (siehe Stage-7-Eintrag oben), aber
  nicht per echtem Mausklick auf eine Fensterzeile/das X-Icon in dieser
  Umgebung ausgelöst — nur direkt über `mmsg dispatch`. Kein
  Tag-Umbenennen, kein Layout-Umschalten pro Tag, kein Drag zwischen
  Monitoren — bewusst nicht Teil des Stage-7-Auftrags ("mango-Tags,
  Fensterliste per Tag"). Nur an einem Einzelmonitor-Setup getestet;
  `viewcrossmon` selbst ist zwar schon aus Stage 1 seit `bars/chamaeleon`/
  `bars/lumen` für Mehrmonitor-Fälle bekannt, aber nicht erneut eigens für
  diese Stage an einem zweiten Monitor gegengeprüft.
- App-Launcher: Tippen (frischer Fokus) und die Ergebnisliste/Suche sind
  live gegen echte `.desktop`-Daten verifiziert (siehe "App-Launcher"
  oben). Klick auf ein Ergebnis (statt Enter) ist nur strukturell verifiziert
  — derselbe `MouseArea.onClicked`-Aufruf wie `Keys.onReturnPressed`, aber
  nicht sauber isoliert per echtem Mausklick durchgetestet, nachdem ein
  Testlauf einen Fokus-Sprung auf eine andere App auslöste (siehe
  Vorfall-Absatz oben) und weiteres blindes Maus-/Tastatur-Simulieren auf
  einem echten, in Benutzung befindlichen Desktop danach bewusst gestoppt
  wurde, statt das Risiko einzugehen, erneut in eine fremde Anwendung zu
  tippen. Ob der beobachtete Fokus-Sprung ein echter mango-Quirk (Fokus
  wandert zur aktivierten Single-Instance-App statt beim neuen Launcher-
  Fenster zu bleiben) oder ein `wlrctl`-Testartefakt war, ist ungeklärt —
  vor Verlass auf "Enter startet zuverlässig die App und schließt sauber"
  im echten Alltag noch einmal mit echter Maus/Tastatur gegenprüfen. Keine
  Mehrfachauswahl, kein Fuzzy-Matching (nur Substring), keine Icons in der
  Ergebnisliste — bewusst nicht Teil des Auftrags, gleiche Reuse-Basis wie
  `bars/quickbar`s Original. `~/quickdots/menu/adapters/lucid.json` ist
  angelegt, aber der SUPER+space-Bind in `~/.config/mango/config.conf`
  zeigt erst nach dem nächsten Bar-Wechsel über `menu` tatsächlich auf
  `qs ipc call launcher toggle` (siehe "App-Launcher" oben) — bis dahin
  öffnet SUPER+space weiterhin `menu`s generischen Fallback-Launcher, der
  aber unabhängig davon ebenfalls funktioniert.
