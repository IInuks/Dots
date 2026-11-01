# ricev2 — Skewed Topbar + Menüs (skwd-bar-Nachbau für mango)

Nachbau der Shell „skwd" von [liixini/skwd](https://github.com/liixini/skwd)
(MIT-Lizenz) nach den beiden Prompts in `prompt/`:
`claude-code-prompt-skwd-bar.md` (Bar) und `claude-code-prompt-skwd-menus.md`
(Dropdowns, Launcher, Switcher, Power-Menü, Notifications). Beide Prompts
sind generische Vorlagen mit **[ECKIGEN KLAMMERN]** zum Ausfüllen — dieses
README dokumentiert, wie sie ausgefüllt wurden, welche Widersprüche dabei
aufgetaucht sind, und in welchem Bauzustand `ricev2` gerade ist.

## Der Widerspruch, der den Anstoß für dieses README gab

Beide Prompts nennen als Compositor-Platzhalter **[niri / Hyprland /
Sway]** — dieses System läuft aber **mango** (siehe
`~/.config/mango/config.conf`, Prozess `mango` aktiv). Keiner der drei
genannten Compositors trifft zu; alle compositor-spezifischen Werte unten
sind daher nicht "einer der drei Vorschläge", sondern gegen das
tatsächliche System geprüft (siehe "Systemwerte").

## Ausgefüllte Platzhalter

Geprüft, nicht geraten — jeweils mit dem Befehl, der es belegt.

| Platzhalter | Prompt-Vorschlag | Tatsächlicher Wert | Beleg |
|---|---|---|---|
| Compositor | niri / Hyprland / Sway | **mango** | `pgrep mango`, `~/.config/mango/config.conf` |
| Hauptmonitor | z. B. DP-1 | **DP-4** (2560×1440@170) | `monitorrule=name:DP-4,...` in `config.conf` |
| WLAN-Interface | z. B. wlan0 | **wlp9s0**, über **nmcli** (NetworkManager) | `ip -o link show`; `iwctl` ist nicht installiert, `systemctl status NetworkManager` aktiv, `which nmcli` |
| Wetterstadt | z. B. Wiener Neustadt | **Wien** | Nutzerentscheidung (AskUserQuestion) |
| Bevorzugter Player | z. B. spotify | **keine Präferenz** | Nutzerentscheidung — kein playerctl/Spotify auf dem System installiert, Lyrics-Insel nimmt den zuletzt aktiven MPRIS-Player |
| Installationsort | `~/.config/quickshell/skewbar/`, Start `qs -c skewbar` | **`~/quickdots/bars/ricev2`**, Start `qs -p ~/quickdots/bars/ricev2` | Jeder andere Ordner unter `quickdots/bars/*` folgt dieser Konvention und hängt am `quickdots/menu`-Switcher (`adapters/*.json`) statt an `qs -c` |
| Terminal (Menüs-Prompt) | kitty | **kitty** (bestätigt installiert) | `nix profile`/`which kitty` |
| MEIN MATUGEN-OUTPUT | `~/.cache/skwd-wall/colors.json` | **`~/.cache/ricev2/colors.json`** (matugen, eigenes Template) | siehe "Farben" |

## Farben

Der Bar-Prompt will feste Material-You-Rollen (`primary`, `primaryContainer`,
`surfaceContainer`, `outline`, `shadow`, `inversePrimary`, ...) — das ist
näher an matugens eigenem Rollenschema (Material Color Utilities) als an
pywal, das jeder andere Bar-Build hier (`lumen`, `simple`, ...) über
`~/.cache/wal/colors.json` liest. matugen läuft auf diesem System bereits
für `bars/rice` und `bars/blobs`, deshalb bekommt `ricev2` ein eigenes
Template statt einer pywal-Fallback-Palette wie sonst üblich:

- `~/.config/matugen/templates/ricev2-colors.json` — Template, mappt
  `colors.<rolle>.default.hex` auf exakt die Schlüssel aus Prompt-Abschnitt
  7 (inkl. `primaryText` = `on_primary`, `surfaceText`/`backgroundText` =
  `on_surface`/`on_background`, ...).
- `~/.config/matugen/config.toml` — neuer `[templates.ricev2]`-Eintrag,
  Output nach `~/.cache/ricev2/colors.json`. Bestehende Einträge
  (`blobs-bar`, `rice-gtk3/4`) unverändert gelassen.
- `Colors.qml` liest diese Datei per `FileView { watchChanges: true }` und
  fällt, solange sie fehlt (matugen wurde für `ricev2` noch nicht
  ausgeführt), auf die **im Prompt selbst genannte Fallback-Palette**
  zurück (Abschnitt 7, wortwörtlich übernommen) — nicht auf pywal wie
  sonst in diesem Repo.
- **Update (Stage 2, 21.09.):** `~/.cache/ricev2/colors.json` existiert
  inzwischen (`primary #8ccff0`, `surface #0f1417`, ...) — ein normaler
  `matugen image ...`-Lauf (nicht von mir ausgelöst, siehe unten) hat das
  `ricev2`-Template mitgeschrieben, seit es in `config.toml` registriert
  ist. `ricev2` läuft also nicht mehr auf der Fallback-Palette, sondern auf
  echten, vom aktuellen Wallpaper abgeleiteten Farben — im Stage-2-
  Screenshot-Test (`flameshot full`, siehe README-Abschnitt „Testen")
  sichtbar bestätigt (kühles Blau/Lila statt des warmen Fallback-Rot/Braun
  aus Abschnitt 7). Ich habe matugen selbst weiterhin nicht manuell
  ausgelöst — Grund s. u. gilt unverändert, falls `colors.json` mal fehlt
  oder veraltet.
- Ursprünglich habe ich matugen bewusst NICHT selbst laufen lassen, um
  `colors.json` zu erzeugen: `matugen image <pfad>` würde laut
  `config.toml` (`[config.wallpaper] set = true`) auch `awww img ...`
  ausführen und **alle** registrierten Templates neu schreiben, inklusive
  des aktiven GTK3/GTK4-Themes von `bars/rice` — ein Seiteneffekt auf die
  laufende Session, den ich nicht ungefragt auslösen wollte. Diese
  Zurückhaltung gilt weiter: falls `colors.json` künftig wieder fehlt,
  bitte wie bisher auf den nächsten normalen `matugen image ...`-Aufruf
  warten statt ihn hier auszulösen.
- Jede Farbe hat `Behavior … ColorAnimation { 180ms, InOutQuad }`, aktiv
  erst ab dem zweiten `_settle()` (siehe Prompt: „erst nach dem ersten
  Laden aktiv") — der allererste Werteschritt (Fallback → erste geladene
  Palette bzw. Fallback → Fallback beim allerersten Start) passiert ohne
  Animation, sonst würde die Bar beim Start sichtbar von Schwarz einfaden.

## Fonts

Geprüft per `fc-match "<Familie>:charset=<Codepoint>"` statt angenommen:

- **Symbols Nerd Font** und **Material Design Icons** sind beide **nicht
  installiert** — aber jeder `U+F0xxx`-Codepoint, den beide Prompts
  benutzen (z. B. `U+F0EE0`, `U+F08AE`, `U+F04AE`), ist ein `nf-md-*`-Slot:
  Nerd Fonts patcht das komplette Material-Design-Icons-Set an exakt diese
  Codepoints in **jede** gepatchte Font. **JetBrainsMono Nerd Font** ist
  auf diesem System bereits installiert (jeder andere Bar-Build hier nutzt
  sie) und deckt alle getesteten Codepoints ab (`fc-match` bestätigt
  Treffer in genau dieser Familie, kein Fallback auf eine andere Font). →
  `Style.iconFont` und `Style.menuIconFont` zeigen beide auf
  „JetBrainsMono Nerd Font" statt auf zwei nicht vorhandene Fonts.
- **Roboto Condensed** / **Roboto Mono** sind **nicht installiert**
  (`fc-match "Roboto Condensed"` fällt auf DejaVu Sans zurück) und wurden
  **nicht** ersetzt — `Style.textFont`/`Style.monoFont` bleiben wörtlich
  auf den Spec-Namen stehen. Qt fällt bis zur Installation lautlos auf
  einen Systemfont zurück; sobald die Fonts installiert sind, greift der
  richtige Font ohne Codeänderung.
- **Installationsbefehl** (nicht ausgeführt, wie vom Prompt verlangt):
  ```
  nix profile install nixpkgs#roboto nixpkgs#roboto-mono
  ```
  bzw. deklarativ in `/etc/nixos/configuration.nix` unter
  `environment.systemPackages` (gleiches Muster wie `bars/rice`s
  `material-symbols`-Ergänzung, siehe dessen README).

## WLAN-Backend

Prompt-Vorlage geht von `iwctl` (iwd) aus. Auf diesem System läuft
**NetworkManager** (`systemctl status NetworkManager` aktiv), `iwctl` ist
nicht installiert, `nmcli` schon. Der WLAN-Dropdown (Menüs-Prompt 1.2)
wird daher gegen `nmcli device wifi list` / `nmcli device wifi connect
<ssid> password <pw>` gebaut statt gegen `iwctl station ... connect`.

## Bauzustand

**Stage 1 — Fenster, Inselformen, Farben, Uhr** (Bar-Prompt „Vorgehen"
Schritt 2): **fertig**, headless getestet via
`qs -p ~/quickdots/bars/ricev2 -n` — `Configuration Loaded`,
keine QML-Fehler/Warnungen im Log. Enthält:

- `shell.qml`, `Style.qml`, `Colors.qml`, `Config.qml` (Singletons)
- `Bar/BarShell.qml` — `PanelWindow`, `WlrLayershell.namespace: "topbar"`,
  Monitor `DP-4` (Fallback `Quickshell.screens[0]`), Höhe 32px,
  `exclusiveZone`, `topMargin: -1` (classic), Input-`mask` auf die drei
  Inseln beschränkt, `bar toggle|show|hide`-IPC mit Zustand in
  `~/.cache/ricev2/bar-state`.
- `Bar/Island.qml` — die drei schrägen Trapez-Formen (links/rechts/Mitte)
  aus Prompt-Abschnitt 2, per Canvas, `diagSlant = 28`, Füllung `surface`
  @ 0.88, kein Rand/Radius/Schatten.
- `Bar/TopBar.qml` — ordnet die drei Inseln an; linke/rechte Inselbreite
  folgt live der Inhaltsbreite (`+28+24`), mittlere Insel fix 699px breit,
  aber **Breite (nicht nur Opacity) fällt auf 0**, solange sie unsichtbar
  ist — sonst bliebe ein 699px unsichtbarer Klick-Totbereich in der
  `mask` stehen (siehe Speicher-Notiz zu `PanelWindow`-Masken:
  `visible` allein schrumpft die Region nicht).
- `Bar/widgets/ClockWidget.qml` — `HH` in `primary`, `:mm` in `tertiary`,
  13px DemiBold, spacing 0, keine Sekunden. Noch ohne Klick/Kalender.

**Stage 2 — restliche Bar-Widgets** (Bar-Prompt Abschnitt 4): **fertig**,
headless getestet via `qs -p . -n` — `Configuration Loaded`, keine
QML-Fehler/Warnungen im Log (nur die beiden erwarteten DBus-Warnungen unten).
Enthält:

- `SystemService.qml`, `WeatherService.qml` (neue Root-Singletons) — CPU
  (`/proc/stat`-Delta), CPU-Temp (k10temp-hwmon, per Name aufgelöst statt
  `hwmonN` fest zu verdrahten — Nummerierung ist nicht reboot-stabil),
  GPU (`nvidia-smi`, 20% / 45°C beim Testlauf bestätigt), RAM
  (`/proc/meminfo`), Helligkeit (`brightnessctl`, wie zuvor in
  `bars/lucid/SystemService.qml` bewährt) — Polling getrennt nach Prompt-
  Vorgabe (Systemwerte 2s, Helligkeit 5s, Wetter 10min). Wetter über
  Open-Meteo (Geocoding + Forecast, kein API-Key), `Config.weatherCity`.
- `Bar/widgets/{Cpu,Gpu,Memory,Weather,Bluetooth,Wifi,Brightness,Battery,
  Volume,Notifications}Widget.qml` — je ein `Row{spacing:4}` aus
  14px-Icon (`primary`) + 12px-Medium-Wert (`tertiary`), exakt nach
  Abschnitt 4. Bluetooth/WLAN/Batterie über Quickshells native Services
  (`Quickshell.Bluetooth`, `Quickshell.Networking`,
  `Quickshell.Services.UPower`/`.Pipewire`) statt eigener Shell-Polls —
  dieselben APIs, die `bars/lucid` dafür schon verwendet. Icon-Codepoints
  sind `\u{FXXXX}`-Escapes (oberhalb der BMP, gleiche Syntax wie
  `bars/blobs/components/ClockBlob.qml`).
- `Bar/widgets/WidgetSlot.qml` — der Loader-Wrapper aus Abschnitt 4
  („Ein-/Ausblend-Animation" 180ms OutCubic, „Mouseover-Modus"): lädt die
  Widget-Datei per `Config.widgetsLeft`/`widgetsRight`-Eintrag, blendet
  über `implicitWidth`/`opacity` weich ein/aus. Ein Widget signalisiert
  „keine Daten" (wifi/bluetooth/brightness/battery, siehe Prompt) über eine
  eigene `readonly property bool available`.
- `Bar/TopBar.qml` — `leftContent`/`rightContent` sind jetzt `Repeater`
  über `Config.widgetsLeft`/`widgetsRight` statt fest verdrahteter Kinder;
  je ein `HoverHandler` pro Insel für den Mouseover-Modus.
- **Klick/Dropdown-Verhalten bewusst nicht gebaut**: keins der neuen
  Widgets hat Cursor/`MouseArea`, obwohl der Prompt cpu/weather/bluetooth/
  wifi/brightness/volume/notifications als klickbar listet — dieselbe
  Zurückstellung, die `ClockWidget.qml` schon in Stage 1 für sich selbst
  gewählt hat („Klick ... ist Stage 3"). Ein Cursor ohne Wirkung wäre eine
  Halbfertig-Implementierung; kommt mit dem Dropdown-Gerüst in Stage 3.
  Einzige Ausnahme: Helligkeits-Mausrad (±5%) ist echte, dropdown-
  unabhängige Funktionalität und daher schon verdrahtet.
- **Zwei Annahmen, wo der Prompt keine exakten Werte nennt**:
  - Akku-Icons: 7 (entladend) bzw. 8 (ladend) Codepoints aus der Tabelle,
    aber keine Prozent-Grenzwerte — gleichmäßig über 0–100% verteilt
    (~14,3 bzw. 12,5 Punkte pro Stufe), in der vom Prompt vorgegebenen
    Low-zu-High-Reihenfolge.
  - Wetter-Icons: Der Prompt nennt zehn Kategorien (Gewitter, Schneesturm,
    Schnee, Graupel, Starkregen, Regen, Nebel, teils bewölkt, bewölkt,
    sonnig/klar), keine vollständige WMO-Code-Tabelle — Open-Meteos
    `weathercode`-Werte sind nach Schwere auf diese zehn gemappt (siehe
    `WeatherService.qml`).
- **Notifications-Widget ist ein Platzhalter**: zeigt lokal `count: 0`,
  da der eigene Notification-Daemon erst Stage 5 ist. Wird dann auf eine
  echte geteilte Quelle umgestellt.
- **WLAN-Backend-Planänderung**: README hatte ursprünglich `nmcli` als
  Backend für den WLAN-Dropdown vorgesehen (siehe "WLAN-Backend" unten).
  Für das Widget wird stattdessen `Quickshell.Networking` verwendet — ein
  natives, event-getriebenes Service-Modul (kein Polling nötig), das laut
  `bars/lucid/Panels/WifiSection.qml` auf diesem System bereits
  funktioniert und ohnehin über NetworkManager läuft. **Stage 3 sollte den
  WLAN-Dropdown ebenfalls darüber bauen statt `nmcli` per `Process` zu
  shellen** — mit `.connect()`/`.connectWithPsk()`/`.disconnect()` deckt
  der Service den Login-Flow bereits ab.
- Getestet: nur der Bluetooth-Adapter (`org.bluez` DBus-Objekt-Manager
  scheitert) und UPower (`org.freedesktop.UPower` nicht aktivierbar) sind
  auf diesem System nicht erreichbar — beide Warnungen sind erwartet
  (kein Akku im Desktop, siehe „Bauzustand" unten) und werden von den
  jeweiligen Widgets über ihr `available`/`isPresent`-Gating sauber
  abgefangen, keine harten Fehler.

**Stage 3 — Dropdown-Menüs** (Menüs-Prompt Abschnitt 1): **fertig**, headless
getestet via `qs -p . -n` (`Configuration Loaded`, keine QML-Fehler/
Warnungen außer den beiden erwarteten bluez/UPower-DBus-Meldungen) und per
`flameshot full` visuell gegen jedes einzelne Dropdown geprüft (dazu
`DropdownState.open`'s Default kurzzeitig testweise auf den jeweiligen
Dropdown-Namen gesetzt statt live zu klicken — echte Klick-Simulation auf
diesem System hätte Fokus in eine laufende App abdriften können, siehe
Speicher-Notiz zu Live-Input-Risiko). Enthält:

- `DropdownState.qml` (neues Root-Singleton) — welches Dropdown offen ist
  (`""` = keins; genau eins gleichzeitig) plus `keyboardWanted` fürs
  WLAN-Passwortfeld (siehe unten).
- `NotificationState.qml` (neues Root-Singleton) — Datenquelle fürs
  Benachrichtigungszentrum, liest/schreibt `$XDG_RUNTIME_DIR/skwd/
  notifications.json` + `notifications-dismissed.json` exakt wie im
  Menüs-Prompt (Abschnitt 1.6/5) spezifiziert. Der eigene Popup-Daemon
  (Bar-Prompt Abschnitt 5) ist erst Stage 5 — bis dahin ist `log` normalerweise
  leer, aber die UI liest bereits die echte (künftig geteilte) Quelle statt
  eines Stubs.
- `Bar/menus/Dropdown.qml` — das gemeinsame Gerüst aus Menüs-Prompt
  Abschnitt 0/1: 320px Breite, Höhe animiert 0→Inhalt+24 in 320ms per
  `Easing.BezierSpline` (`Style.dropdownBezier`, schon in Stage 1 vorbereitet),
  untere 2px-Linie in primary wächst 0→voll in 300ms OutCubic, Inhalt blendet
  erst nach >50% Öffnung ein (Opacity + Translate −15→0, 200ms OutCubic).
  Hintergrund `surface` @ 0.88, beim Benachrichtigungszentrum @ 0.92
  (`Style.notificationAlpha`).
- `Bar/menus/{MenuRow,VolumeSlider,PasswordField,CalendarCell}.qml` —
  gemeinsame Bausteine für mehrere Dropdowns (Icon+Name+Wert-Zeile,
  PipeWire-Lautstärkeregler, WLAN-Passwortfeld, Kalender-Parallelogrammzelle).
- `Bar/menus/{Volume,Wifi,Bluetooth,Calendar,Weather,Notifications}Dropdown.qml`
  — je ein Dropdown-Inhalt, geladen über `TopBar.qml`'s
  `_dropdownFiles`-Lookup + `Loader`. Alle sechs öffnen sich unter der
  rechten Insel (jedes auslösende Widget sitzt dort), weshalb sie sich einen
  einzigen Anker teilen: `Dropdown` sitzt in `TopBar.qml`,
  `anchors.top: rightIsland.bottom` / `anchors.right: rightIsland.right`.
- Volume (1.1): OUTPUT/INPUT-Abschnitte über `Pipewire.nodes` gefiltert nach
  `isSink` bzw. der `AudioSource`-Typ-Flag (PwNode hat auf dieser
  Quickshell-Version **kein** `isSource` — gegen `quickshell-network.qmltypes`
  geprüft, nicht angenommen; ein im Repo gefundenes Gegenbeispiel
  (`bars/floating/right/AudioPopup.qml`) nutzt `n.isSource`, das auf diesem
  System vermutlich nie ausgewertet wurde). Klick auf eine Zeile setzt
  `Pipewire.preferredDefaultAudioSink/Source`, der Slider darunter ist ein
  eigenes `VolumeSlider.qml` nach Abschnitt 1.1 (14px Spur, 10px Knopf,
  1.25× Hover/Drag-Scale, lokaler Wert während des Ziehens).
- WLAN (1.2): über `Quickshell.Networking`, wie schon `WifiWidget.qml`
  (Stage 2) — nicht über `nmcli`. **Scanning-Anzeige ist eine Annäherung**:
  `WifiDevice` hat ein schreibbares `scannerEnabled`, aber kein
  „Scan fertig"-Signal/-Property (gegen die qmltypes geprüft) — „Scanning..."
  wird deshalb für ein festes 2,5s-Fenster nach dem Öffnen angezeigt, nicht
  über ein echtes Scan-Ende-Event. Passwort-Panel exakt nach Abschnitt 1.2
  (rotierende Glyphen-Sequenz `⬢ ◆ ▲ ● ■ ⬟ ★`, Pop-in-Animation, blinkender
  Cursor, verstecktes `TextInput` mit `NoEcho`) — verbindet über
  `WifiNetwork.connectWithPsk()`, nicht `iwctl`.
- Bluetooth (1.3), Kalender (1.4, öffnet über die Uhr), Wetter (1.5),
  Notification-Center (1.6) wie im Prompt spezifiziert. `WeatherService.qml`
  wurde für die Vorhersage-Karten um `dailyForecast` erweitert (Open-Meteo
  `daily=weathercode,temperature_2m_max,temperature_2m_min,
  precipitation_sum,windspeed_10m_max`) — vorher gab's dort nur den
  aktuellen Wert. Die Stadt-Wechsel-Pfeile sind dauerhaft im
  „bei nur einer Stadt"-deaktivierten Zustand (primary @ 0.25), weil
  `Config` nur eine `weatherCity` kennt.
- **Nicht gebaut: eine Helligkeits-Dropdown.** Der Menüs-Prompt spezifiziert
  in Abschnitt 1 nur sechs Dropdowns (1.1–1.6: Lautstärke/WLAN/Bluetooth/
  Kalender/Wetter/Notifications) — Helligkeit ist dort keins davon, obwohl
  README's ursprüngliche Stage-3-Ankündigung sie mitgelistet hatte. Das
  Mausrad-±5%-Verhalten aus Stage 2 bleibt die einzige Interaktion.
- **Bekanntes Verhalten, keine Regression:** WLAN/Bluetooth-Dropdown lassen
  sich nur öffnen, wenn ihr Bar-Widget überhaupt sichtbar ist — und das ist
  laut Stage 2 nur der Fall, wenn schon ein Netzwerk verbunden bzw. ein
  Gerät mit Akkudaten verbunden ist (siehe Stage 2 oben, „ausgeblendet ohne
  Daten"). Ein Rechner ohne aktive WLAN-Verbindung kann also nicht über die
  Bar nach neuen Netzwerken suchen. So spezifiziert es der Prompt (Sichtbar-
  keitsregel kam aus dem Bar-Prompt Abschnitt 4, nicht aus dem Menüs-
  Prompt) — nicht in Stage 3 relitigiert, aber hier festgehalten, falls das
  später als Bug gemeldet wird.
- **Kein Außerhalb-Klick schließt / kein Dimmer für Bar-Dropdowns.** Menüs-
  Prompt Abschnitt 0 spezifiziert einen Dimmer + Außenklick-schließt nur für
  die Vollbild-Overlays (Launcher/Switcher/Power-Menü, Stufen 6–8), nicht
  für die Bar-Dropdowns aus Abschnitt 1. Ein offenes Dropdown schließt daher
  nur durch erneuten Klick auf sein eigenes Widget oder durch Öffnen eines
  anderen Dropdowns (das dann nahtlos, ohne Schließen+Neuöffnen,
  überblendet).
- **Bekanntes Risiko, ungetestet:** Das WLAN-Passwortfeld schaltet
  `WlrLayershell.keyboardFocus` auf der Bar-eigenen, dauerhaft laufenden
  PanelWindow-Surface von `OnDemand` auf `Exclusive` um
  (`DropdownState.keyboardWanted`). Laut Speicher-Notiz zu mangos
  OnDemand-Fokusvergabe gewährt mango echten Tastaturfokus nur bei
  `initial_commit` einer Surface oder einem bereits-als-OnDemand-
  committeten Klick — ob das Umschalten auf einer wiederverwendeten,
  langlebigen Surface tatsächlich Fokus gewinnt, ist auf diesem System
  **nicht verifiziert** (echte Tastatureingabe-Tests hätten Live-Input-
  Simulation gegen die echte Session gebraucht, siehe Speicher-Notiz zum
  Risiko davon). Falls das Passwortfeld in der Praxis keinen Fokus bekommt,
  ist der dokumentierte Fix ein eigenes, per `Loader` bei jedem Öffnen neu
  erzeugtes Popup-Fenster statt der wiederverwendeten Bar-Surface (gleiches
  Muster wie in der Speicher-Notiz empfohlen).
- Mausinteraktion, die echte Texteingabe/Drag bräuchte (Passwortfeld tippen,
  Lautstärke-Slider ziehen), wurde aus demselben Live-Input-Risiko-Grund
  nur gegen den Code gelesen, nicht interaktiv geklickt — die sechs
  Dropdown-*Inhalte* selbst (Layout, Farben, Live-Daten) wurden aber alle
  einzeln per erzwungenem `DropdownState.open`-Default + Screenshot
  verifiziert (Lautstärke mit echten PipeWire-Geräten inkl. Slider-Füllung,
  Kalender mit echtem Monatsraster + Parallelogrammzellen, Wetter mit
  echter 7-Tage-Vorhersage von Open-Meteo, Bluetooth/WLAN/Notifications im
  spezifizierten Leerzustand dieses Systems).

**Stage 4 — Mittlere Insel: Lyrics + Karaoke-Effekt + cava-Visualizer**
(Bar-Prompt Abschnitt 6): **fertig**, headless getestet via `qs -p . -n`
(`Configuration Loaded`, keine QML-Fehler/Warnungen außer den beiden
erwarteten bluez/UPower-Meldungen) und per `flameshot full` visuell
geprüft — sowohl im Ruhezustand (keine Insel sichtbar, kein `cava`-Prozess
laufend) als auch mit einer echten, per `pw-play` erzeugten Testtonspur
plus einem testweise eingesetzten `player`-Objekt (siehe unten). Enthält:

- `LyricsService.qml`, `CavaService.qml` (neue Root-Singletons).
- `Bar/lyrics/LyricsIsland.qml` — der komplette Inselinhalt (Trapezform
  wiederverwendet über `Island { variant: "middle" }`, Interpret/Titel
  links/rechts, synchronisierte Lyric-Zeile mit Karaoke-Clip-Reveal,
  Hover-Transportsteuerung, zwei Wave-Visualizer-Canvas).
- `TopBar.qml`s `middleIsland`-Wrapper lädt `LyricsIsland` jetzt direkt
  (statt der Stage-1/2/3-Platzhalter-`Island`) und wächst um
  `Style.vizHeight` (14px), solange `LyricsService.playing` wahr ist —
  `BarShell.qml` braucht dafür keine Änderung, weil dessen Maske schon
  vorher per `Region { item: topBar.middleIslandItem }` an genau dieses
  Item gebunden war (siehe Stage-1-Notiz zu `PanelWindow`-Masken).
  `TopBar.implicitHeight` ist jetzt `Math.max(barHeight + dropdown.height,
  middleIsland.height)` statt der alten Summe, weil beide Erweiterungen
  vom selben `y=0`-Ursprung aus nach unten wachsen, nicht addiert werden
  müssen.
- **Lyrics-Quelle bewusst NICHT wie im echten skwd-bar**: Der Prompt
  verweist bei Unsicherheit auf das echte Referenz-Repo
  (github.com/liixini/skwd) — dort geklont und gelesen (nicht geraten):
  `skwd-bar/qml/services/LyricsService.qml` redet über einen Unix-Socket
  mit einem separaten Rust-Daemon (`skwd-daemon`, eigenes Repo
  github.com/liixini/skwd-daemon), der wiederum drei Anbieter probiert
  (Musixmatch über eine inoffizielle, reverse-engineerte Token-API zuerst,
  dann lrclib.net, dann einen internen Netease-Music-Endpunkt — siehe
  `crates/daemon/src/lyrics/providers.rs` im Daemon-Repo). `ricev2` hat an
  keiner Stelle einen eigenen Daemon (jede andere Stage redet direkt aus
  QML mit ihrer Datenquelle, z. B. `WeatherService.qml` → Open-Meteo), und
  Musixmatchs Token-Verfahren ist eine inoffizielle, nicht zum
  Nachbau vorgesehene private API. `LyricsService.qml` implementiert daher
  nur den lrclib.net-Pfad (öffentliche, kostenlose, für genau diesen
  Zweck gedachte API, kein Key nötig — `GET /api/get`, bei Fehlschlag
  `GET /api/search` als Fallback) — das ist ohnehin schon der Fallback,
  den auch der echte Daemon nach Musixmatch nimmt.
- LRC-Parsing (normale Zeilen-Zeitstempel **und** „enhanced" LRC mit
  eingebetteten Wort-Zeitstempeln `<mm:ss.xx>`) sowie die
  Drift-korrigierte Sync-Schleife (`_launchSync`/`_estimatedTrackMs`,
  alle 5s neu verankert, Timer alle 33ms) sind ein direkter Nachbau von
  `skwd-daemon/crates/daemon/src/lyrics/parse.rs` bzw.
  `skwd-bar/qml/bar/lyrics/LyricsIslandService.qml`s `launchSync()` —
  beides Mechanik, die keiner der beiden Prompts selbst spezifiziert,
  daher gegen die echte Referenz gebaut statt geraten (wie vom Bar-Prompt
  selbst verlangt: „Wenn du unsicher bist, klone das Repo ...").
- **Karaoke-Effekt bewusst vereinfacht gegenüber dem echten skwd-bar**:
  Der Bar-Prompt selbst verlangt nur eine einzige Clip-Breite = `progress`
  (0..1) über die ganze Zeile — kein wortweises Hervorheben. Word-Level-
  Fortschritt wird trotzdem berechnet (zeichenweise gewichtet über
  `charStart`/`charEnd`), aber nur als Quelle für denselben einen
  `progress`-Wert; ohne Wort-Zeitstempel (der lrclib-Normalfall) fällt es
  linear auf `(pos - line.start) / (line.end - line.start)` zurück —
  beide Pfade münden in genau der einen Clip-Reveal-Text-Kopie, die der
  Prompt beschreibt.
- **Nur das „wave"-Visualizer-Theme gebaut**: Der Prompt nennt neun
  weitere Themes explizit als optional („wenn du Zeit hast") — das echte
  skwd-bar hat sie alle (bars/neon/pulse/vu/spectrogram/stardust/liquid/
  ripple/zigzag/metaballs/comet/aurora/aurora-responsive/blocks/dots/
  line/wave, umschaltbar über `Config.visualizerTheme`), aber das wäre
  weit über die Prompt-Vorgabe hinaus gebaut — nicht umgesetzt, um keine
  Halbfertig-Konfigurationsoberfläche (Theme-Auswahl ohne UI dafür) zu
  hinterlassen, die der Prompt nirgends verlangt.
- **`cava.conf` mit explizitem `[input]`-Abschnitt**: Der Prompt nennt nur
  `bars`/`framerate`/`method`/`data_format`/`ascii_max_range` (`[general]`+
  `[output]`), keinen `[input]`-Block — genau wie die echte
  `skwd-bar/ext/cava/cava-bar.conf` (geprüft, nicht geraten). Trotzdem
  ergänzt um `method = pipewire, source = auto`, weil dieses System ohne
  PulseAudio-kompatible Auto-Erkennung sonst stumm bliebe — dasselbe,
  bereits auf diesem System verifizierte Muster wie
  `bars/lucid/CavaService.qml`. Live gegen den echten `cava`-Prozess
  getestet: `~/.cache/ricev2/cava.conf` wird beim ersten Start erzeugt,
  `cava -p ...` läuft, solange die Insel sichtbar ist, und beendet sich
  automatisch wieder, sobald `LyricsService.playing` auf `false` wechselt
  (per Testlauf verifiziert: kein `cava`-Prozess im Ruhezustand).
- **Testmethode ohne Live-Input-Simulation**: Da auf diesem System kein
  MPRIS-Player tatsächlich spielt (siehe „Bevorzugter Player" oben) und
  echtes Klicken/Tippen laut Speicher-Notiz zum Live-Input-Risiko
  vermieden werden soll, wurde für den Screenshot-Test statt echter
  Bedienung nur `LyricsService.player` kurzzeitig auf ein Test-Objekt
  (fixer Titel „Rick Astley – Never Gonna Give You Up", `position: 15`)
  gesetzt und wieder zurückgesetzt — kein `wlrctl`/`ydotool`, keine
  Fokus-Interaktion mit einer laufenden App. Der so ausgelöste, komplett
  reale `lrclib.net`-Abruf fand tatsächlich passende, synchronisierte
  Lyrics und rendertere sie inkl. Karaoke-Clip in Primärfarbe korrekt
  (Pixel-Sampling bestätigt exakt `Colors.primary` `#8ccff0` im
  aufgedeckten Bereich). Für den Visualizer wurde zusätzlich eine per
  Python erzeugte WAV-Testspur über `pw-play` abgespielt (kein
  GUI-Fenster, keine Fokus-Interaktion) — der Wave-Effekt war im
  Screenshot über der Insel sichtbar; ob die Trapezform des unteren
  (unter der Bar hängenden) Canvas exakt stimmt, wurde zusätzlich per
  Debug-Fill (`ctx.fillRect` in Rot, danach wieder entfernt) verifiziert,
  weil die echten, transparenten `primary`/`tertiary`-Farbtöne gegen den
  aktuellen (dunklen) Wallpaper zu kontrastarm für ein eindeutiges
  Standbild-Urteil waren.
- Mausinteraktion (Hover zeigt Transportsteuerung, Klick auf
  Zurück/Play-Pause/Weiter) wurde aus demselben Live-Input-Risiko-Grund
  nur gegen den Code gelesen, nicht interaktiv geklickt.

**Stage 5 — eigener Notification-Daemon (Popups)** (Menüs-Prompt Abschnitt 5):
**fertig**, headless getestet via `qs -p . -n` (`Configuration Loaded`, keine
QML-Fehler/Warnungen außer den beiden erwarteten bluez/UPower-Meldungen)
und **live gegen echte Desktop-Notifications** geprüft: `notify-send -a
"Mail" "Neue Nachricht" "..." -A "reply=Reply" -A "dismiss=Dismiss"` plus
eine zweite `notify-send`-Notification kurz danach, dann `flameshot full`
— beide Karten gestapelt sichtbar (siehe Screenshot-Crop), danach erneut
nach 6s geprüft: beide automatisch verschwunden (5000ms-Standard-Ablauf).
Kein `wlrctl`/`ydotool` nötig für diesen Test — `notify-send` selbst
triggert den kompletten Pfad ohne Fokus-Risiko (Speicher-Notiz zu
Live-Input-Risiko bleibt dadurch unberührt). Enthält:

- `PopupState.qml` (neues Root-Singleton) — die Warteschlange der
  aktuell/als nächstes sichtbaren Toasts (`push`/`remove`); nur die
  ersten `Style.popupMaxVisible` (4) werden gerendert, der Rest wartet,
  bis eine Karte durch Timeout/Klick verschwindet.
- `Bar/notifications/PopupHost.qml` — besitzt den `NotificationServer`
  (muss App-Lebensdauer haben, daher nicht im Singleton selbst, gleiche
  Begründung wie `bars/claude/shell.qml`s `NotifyHub`-Aufteilung) und ein
  eigenes kleines `PanelWindow` (`WlrLayer.Overlay`, Namespace
  `skwd-notifications`, `WlrKeyboardFocus.None`), nur mit `anchors.top`
  + `anchors.right` (bzw. `.left`, siehe `Config.notificationPopupSide`)
  verankert und inhaltsgroß (`implicitWidth`/`implicitHeight` aus dem
  Stack) — dadurch reicht `visible: PopupState.queue.length > 0` allein
  schon aus, kein Mask-Workaround nötig (anders als `BarShell`, das
  größer als sein klickbares Innenleben ist).
- `Bar/notifications/PopupCard.qml` — eine Karte: Trapezform exakt nach
  Spec (`(0,0)→(w−28,0)→(w,h)→(28,h)`, rechts angedockt; links gespiegelt
  über eine eigene `_points()`-Funktion, nicht `Bar/Island.qml`
  wiederverwendet — die Popup-Form ist ein echtes Parallelogramm mit
  Schräge auf **beiden** Seiten, `Island.qml`s Formen haben nur eine
  schräge und eine gerade Kante), Füllung `surface` @ 0.92. Signature-
  Detail (2px-`primary`-Umriss, der sich in 600ms `OutCubic` über den
  Umfang aufbaut) per zweitem Canvas, das den Umfang in die vier
  Kantenlängen zerlegt und je nach `progress`-Budget voll/teilweise/gar
  nicht zeichnet. Ein-/Ausblenden (Opacity+Slide ±40, 350/250ms), danach
  Höhe→0 (180ms) bevor `notif.dismiss()` + `PopupState.remove()` — exakt
  die dreistufige Schließsequenz aus der Spec.
- Hover pausiert den Auto-Timer (eigener 100ms-Tick statt `Timer.interval`
  neu zu starten, damit die **verbleibende** Zeit erhalten bleibt statt
  bei jedem Hover-Ende wieder bei 5000ms zu beginnen — die Spec sagt nur
  „pausiert", nicht „setzt zurück").
- Action-Buttons (`notif.actions`, je `.text`/`.invoke()`) als Pillen
  nach Spec (secondaryContainer @ 0.5/tertiary normal, primary/primaryText
  bei Hover). Eigene `MouseArea` pro Button/✕ sitzt im Baum nach der
  kartenweiten Schließen-`MouseArea` und fängt ihre Klicks daher zuerst ab.
- Jede Notification landet zusätzlich in `NotificationState.record()`
  (neue Funktion, ergänzt die bisher nur lesende Seite aus Stage 3) →
  `$XDG_RUNTIME_DIR/skwd/notifications.json`, max. 200 Einträge, wie von
  der Spec verlangt — im Livetest inklusive einer echten `flameshot`-
  eigenen Notification bestätigt (das Benachrichtigungszentrum aus Stage 3
  zeigt jetzt also echte Historie statt des Leerzustands).
- `Config.notificationPopupSide` (neu, Default `"right"`) deckt die von
  der Spec genannte Links-Alternative ab.
- Property `leftSide` statt `onLeft` genannt (sowohl in `PopupCard.qml`
  als auch `PopupHost.qml`) — ein Property, das wie ein `on<Signal>`-
  Handler aussieht, ist laut Speicher-Notiz zu genau dieser Namensklasse
  (`Behavior on onSurface` etc.) ein bekannter QML-Stolperstein; hier zwar
  keine `Behavior on`-Nutzung betroffen, aber vorsorglich vermieden.
- **Nicht gebaut:** `hasActionIcons`/Bild-Notifications (`imageSupported:
  false`) — die Spec-Karte selbst hat keinen App-Icon-Platz vorgesehen,
  nur Text + Actions.

**Stage 6 — Power-Menü** (Menüs-Prompt Abschnitt 4): **fertig**, headless
getestet via `qs -p . -n` (`Configuration Loaded`, keine QML-Fehler/
Warnungen außer den beiden erwarteten bluez/UPower-Meldungen) und per
`flameshot full` visuell geprüft (`PowerMenuState.open`'s Default
kurzzeitig testweise auf `true` gesetzt statt live zu klicken, wieder
zurückgesetzt — selbe Methode wie Stage 3, memory zu Live-Input-Risiko).
Enthält:

- `PowerMenuState.qml` (neues Root-Singleton) — offen/geschlossen plus
  `selectedIndex` (Tastatur/Hover). `show()` setzt `selectedIndex` immer
  auf 0 zurück (Spec: „Beim Öffnen ist immer die erste Option
  ausgewählt").
- `Bar/power/PowerMenu.qml` — `Variants` über `Quickshell.screens` (Spec:
  „auf allen Monitoren"), pro Monitor ein `PanelWindow` mit allen vier
  Ankern. Dimmer + Klick-Abfang-Fläche laufen über dieselbe volldeckende
  `MouseArea`/Rectangle-Kombination auf jedem Monitor; die eigentliche
  1200×380px-Karte sowie der exklusive Tastaturfokus leben aber nur auf
  der `isMain`-Instanz (`Config.monitorName`, mit
  `Quickshell.screens[0]`-Fallback — dasselbe Muster wie `BarShell.qml`/
  `PopupHost.qml`). `IpcHandler` liefert `power toggle` (Spec-Abschnitt 6).
- `Bar/power/PowerOption.qml` — 220×320px-Spalte aus 216px-Icon (Nerd-Font-
  Glyph, `MultiEffect`-Weichschatten `rgba(0,0,0,0.5)`, Blur 0.8, y+2) und
  24px-Bold-Label. Farbe primary (ausgewählt) / tertiary (sonst), 150ms;
  Hover skaliert das Icon auf 1.1 und wählt zugleich aus (Spec: „Hover
  wählt auch aus").
- **Kommandos an dieses System angepasst** (geprüft, nicht geraten —
  dieselbe Abweichung, die jeder andere Bar-Build hier schon dokumentiert
  hat, z. B. `bars/fisheye/README.md`, `bars/simple/README.md`): Lock ist
  `swaylock` statt `loginctl lock-session` (auf diesem System läuft kein
  `swayidle`/logind-Lock-Handler, der das DBus-„Lock"-Signal überhaupt
  abgreift — `loginctl lock-session` allein wäre ein stiller No-op, siehe
  `systemctl status swayidle` → „could not be found"). Logout ist `mmsg
  dispatch quit` statt `niri msg action quit` — mangos eigenes IPC-Tool
  (`mmsg`, bestätigt durch `bind=SUPER,m,quit` in
  `~/.config/mango/config.conf` und durch `bars/rice/MangoService.qml`s
  bereits verifizierte `logout()`-Funktion). Reboot/Poweroff sind
  `systemctl reboot`/`poweroff` wie im Prompt. Alle vier liegen in
  `Config.powerOptions` (Label/Icon/Befehl/`enabled`, wie von der Spec
  verlangt „per Config überschreibbar").
- **Layer-Wahl gegen das System geprüft statt blind übernommen**: Die
  Spec verlangt `WlrLayer.Top`. Ein erster Testlauf zeigte scheinbar gar
  nichts auf dem Bildschirm (nur das laufende Terminalfenster) — das
  lag aber **nicht** an der Layer-Wahl, sondern an einem eigenen Bug: die
  Karte blendete über einen `Connections { onOpenChanged }`-Handler ein,
  der bei einem bereits beim Erstellen `true`en Wert (mein Test-Default)
  nie feuert (memory: feedback_qml_binding_fires_on_init — dieselbe Falle
  spiegelverkehrt: kein Wertwechsel, kein Signal). Ein Debug-Rechteck in
  Vollfarbe bewies, dass das Fenster auf `WlrLayer.Top` +
  `exclusiveZone: 0` korrekt über dem Terminal rendert; der 45%-Dimmer
  war die ganze Zeit da, nur auf einem bereits dunklen Terminal-Hintergrund
  im Screenshot kaum zu erkennen. Behoben durch ein deklaratives
  `State`/`Transition`-Paar statt der Connections-Krücke; danach zeigte
  ein sauberer Screenshot Karte + alle vier Optionen korrekt über einem
  echten Fenster (YouTube im Browser auf einem anderen Tag). **Ergebnis:
  `WlrLayer.Top` bleibt wie in der Spec** — keine Abweichung nötig, siehe
  Screenshot-Test.
- Mausklick auf eine Option sowie Tastatur (←/→/Enter/Esc) wurden aus dem
  bekannten Live-Input-Risiko-Grund nur gegen den Code gelesen, nicht
  interaktiv geklickt/getippt.
- **Nicht verifizierbar auf diesem System**: nur ein Monitor (DP-4)
  angeschlossen, daher konnte das „Dimmer auf jedem Monitor, Karte nur
  auf dem Hauptmonitor"-Verhalten nicht an einem echten zweiten Bildschirm
  bestätigt werden — nur gegen den Code (`win.isMain`-Gate) geprüft.

**Stage 7 — App-Launcher, Slice-Modus** (Menüs-Prompt Abschnitt 2): **fertig**,
headless getestet via `qs -p . -n` (`Configuration Loaded`, keine QML-Fehler
— nur die erwarteten bluez/UPower-Meldungen plus zwei harmlose Laufzeit-
Warnungen, siehe unten) und per `flameshot full` visuell geprüft
(`LauncherState.open`'s Default kurzzeitig testweise auf `true` gesetzt,
wieder zurückgesetzt — dieselbe Methode wie Stage 3/6, memory zu Live-
Input-Risiko; der Screenshot fiel dabei auf einen laufenden Spiel-Client
des Nutzers, es wurde aber ausschließlich fotografiert, kein Klick/keine
Taste gesendet). Enthält:

- `AppIndex.qml` (neues Root-Singleton) — wrapped Quickshells eigenes
  `DesktopEntries`-Singleton (Muster wie `bars/ksp/AppIndex.qml`, nicht
  `bars/quickbar/DesktopEntries.qml`s Hand-Parsing) statt selbst
  `.desktop`-Dateien zu scannen — daher kein Async-Scan-Schritt: `ready`
  ist hier immer `true`.
- **„Games"/„Steam"-Filter sind Neuland in diesem Repo** — keine andere
  Bar hier hat sie. Gegen echte `.desktop`-Dateien auf diesem System
  geprüft statt geraten: Steam-installierte Spiele (z. B.
  `~/.local/share/applications/"Kerbal Space Program.desktop"`) tragen
  `Categories=Game;` und `Exec=steam steam://rungameid/<appid>` — beide
  Filter (`isGame`/`isSteam`+`steamAppId`) lesen genau das.
- **Steam-Artwork verifiziert vorhanden**: `~/.local/share/Steam/appcache/
  librarycache/<appid>/library_600x900.jpg` existiert auf diesem System
  (z. B. für Kerbal Space Program) und wird als Slice-Hintergrundbild
  genutzt (spec: „Splash oder Steam-Artwork"), `PreserveAspectCrop`. Kein
  Existenz-Check vorab nötig — `Image.status !== Ready` fällt einfach auf
  die Icon-Ebene zurück (im Screenshot bei zwei Spielen ohne
  heruntergeladenes Artwork live beobachtet: `Cannot open:
  .../library_600x900.jpg`, sauber auf Icon zurückgefallen).
- Icon-Fallback über `Quickshell.Widgets.IconImage` +
  `Quickshell.iconPath(icon, "application-x-executable")` (72px, „Pad"/
  zentriert — Größe ist ein Judgment Call, die Spec nennt hier keine Zahl,
  anders als beim 48px-Glyph). Glyph-Fallback (letzte Stufe) ist der erste
  Buchstabe des App-Namens — die Spec nennt nur Größe/Farbe fürs Glyph,
  keinen Inhalt.
- **Parallelogramm-Maskierung**: ein Content-`Item` (Bild + Icon/Glyph-
  Fläche + Abdunkelung) wird als Einheit per `MultiEffect`
  (`maskSource`/`maskThresholdMin 0.3`/`maskSpreadAtMin 0.3`, exakt die
  Spec-Werte) auf die Parallelogramm-Form beschnitten. Das maskierte
  `Item` steht mit `visible: false` da — dokumentiertes QtQuick.Effects-
  Verhalten, dass `source`/`maskSource` ein unsichtbares Item trotzdem als
  Textur greifen, sodass außerhalb der Form nichts durchscheint.
  Eckenradius (Spec-Default „aus") **nicht gebaut** — derselbe „Default
  ausliefern, Optional-Extra zurückstellen"-Schnitt wie beim `pill`-
  Bar-Stil und den Launcher-Modi hex/grid unten.
- **Klickfläche folgt NICHT exakt der Schräge** — Spec verlangt ein
  `containmentMask`, das über ein `QtObject` mit `contains(point)`
  versucht wurde; diese Qt-Version lehnt es zur Laufzeit ab (`Object set
  as mask does not have an invokable contains method, ignoring it`), also
  bleibt die rechteckige `MouseArea`-Standardfläche. Die toten Ecken sind
  je `sliceSkew` (35px) groß und meist vom höher-`z`-liegenden
  Nachbar-Slice überdeckt (Overlap `sliceSpacing` −22px) — kleine, keine
  sichtbare Abweichung.
- Namensschild, Rand, Schatten, Abdunkelung, Breite/Z-Order und Rand-Fade
  (normierter Abstand zum Viewport-Zentrum, reaktiv über `ListView.view.
  contentX`) exakt nach Spec-Zahlen umgesetzt.
- Such-Feld **hand-gezeichnet** statt echtes `TextInput` (Text +
  blinkender Caret) — dieselbe Begründung wie `PasswordField.qml`s
  eigener Caret: die Spec will, dass ←/→ immer die Slices durchblättern
  und jede sonstige Taste immer im Suchfeld landet, unabhängig vom
  aktuellen Fokus. Mit echtem `TextInput`-Fokus würde ←/→ den Text-Cursor
  bewegen statt die Auswahl; stattdessen hält ein `Keys.onPressed` auf der
  Fensterebene alles fest und schreibt getippten Text direkt in
  `LauncherState.searchText`.
- Filterleiste: 4 Filter-Buttons (All/Apps/Games/Steam, MDI-Codepunkte wie
  spezifiziert), Trenner, Such-Icon+Feld, Tastatur-Hinweistext (Inhalt
  „← → select · Enter launch · Esc close" — die Spec gibt hier keinen
  Wortlaut vor, nur dass da einer stehen soll), Tooltip nach 500ms Hover,
  Fortschrittsbalken für den App-Cache-Aufbau (bleibt auf diesem System
  praktisch immer unsichtbar, da `AppIndex.ready` schon beim Start `true`
  ist — dieselbe „gebaut, Bedingung hier nie wahr"-Form wie das fehlende
  Bluetooth/Akku in Stage 2).
- `IpcHandler` liefert `launcher toggle` (Spec-Abschnitt 6). Kein
  Compositor-Keybind verdrahtet — dieselbe Lücke wie beim Power-Menü,
  siehe „Noch nicht gebaut" unten (Adapter-System).

**Stage 8 — Fenster-Switcher (Alt+Tab), Slice-Modus** (Menüs-Prompt Abschnitt
3): **fertig**, headless getestet via `qs -p . -n` (`Configuration Loaded`,
keine neuen QML-Fehler) und per echtem IPC-Roundtrip visuell geprüft: Bar in
`-d` gestartet, `qs -p . ipc call switch open` aufgerufen (liest nur, löst
kein `focusid`/`killclient` aus) und mit `flameshot full` fotografiert —
danach `switch cancel` und Prozess beendet, dieselbe Methode wie Stage 3/6/7
(memory zu Live-Input-Risiko: nur Screenshot, keine simulierte Taste/Klick).
Der Screenshot zeigt die Karte korrekt über dem Desktop (Dimmer, Trapezform,
Rand, Icon, Nameplate „KITTY"/Fenstertitel, Badges „FOCUSED" und „WS 1")
für das einzige zu dem Zeitpunkt offene Fenster — `mmsg get all-clients`
direkt danach bestätigt: auf diesem System lief in diesem Moment
tatsächlich nur ein Fenster, kein Rendering-Fehler. Enthält:

- **Fensterliste statt niri/Hyprland-Platzhalter**: `mmsg get all-clients`
  (einmaliger Snapshot beim Öffnen, `StdioCollector`-Idiom wie
  `SystemService.qml`s Sensor-Probes — **kein** `mmsg watch all-clients`
  wie `bars/quickbar/MangoState.qml`, damit die Auswahl nicht mitten in der
  Bedienung durch ein fremdes Fenster-Event neu sortiert wird). Gegen
  mangos eigenen Source geprüft statt geraten (`/nix/store/.../src/
  dispatch/bind_define.h`, `src/ipc/ipc.h`): `focusid` und `killclient`
  lesen beide `arg->tc`, das die IPC aus einem `client,<id>`-Token befüllt
  — also `mmsg dispatch focusid client,<id>` zum Fokussieren (springt dabei
  auch über Tags/Monitor, siehe `client_active()` in `mango.c`) und
  `mmsg dispatch killclient client,<id>` zum Schließen. Beide Aufrufe sind
  exakt die, die `bars/quickbar/MangoState.qml` auf diesem System schon
  produktiv nutzt (`focusClient()`), also kein Neuland, nur wiederverwendet.
- **Scratchpad-Fenster werden herausgefiltert** (`is_scratchpad`/
  `is_namedscratchpad`) — dieselbe „ausgeblendet ohne Daten"-Logik wie bei
  fehlender Hardware in Abschnitt 4. Minimierte Fenster bleiben in der
  Liste: `focusid` holt sie über mangos eigene `client_active()` beim
  Auswählen automatisch wieder sichtbar.
- **„open springt direkt zum zweiten Fenster"**: die geholte Liste wird so
  rotiert, dass das fokussierte Fenster an Index 0 steht, dann startet
  `selectedIndex` bei 1 (oder 0, wenn nur ein Fenster offen ist).
- **Icon-Auflösung über den rohen `appid`** statt über `AppIndex`/
  Desktop-Entries wie der Launcher: `Quickshell.hasThemeIcon(appid)` +
  `Quickshell.iconPath(appid)`, exakt das Muster, das
  `bars/quickbar/WindowList.qml` auf diesem System bereits für Fenster-Chips
  nutzt (Fenster-Daten haben nur `appid`/`title`, keinen Desktop-Entry-Bezug
  wie Launcher-Einträge). Für das Nameschild versucht `_appName()`
  zusätzlich einen Best-Effort-Abgleich des `appid` gegen eine installierte
  `.desktop`-ID (auf diesem System exakt für `kitty`/`discord` getroffen)
  und fällt sonst auf den rohen `appid` zurück — Spec nennt hierfür keine
  Auflösungsmethode.
- **Karte fest 1600px breit** (Spec), anders als beim Launcher, dessen Karte
  einfach seine eigene volle Listenbreite ist — hier per `clip: true` auf
  einer inneren `ListView`, die weiterhin dieselbe Header/Footer-Spacer-
  Formel wie der Launcher nutzt, damit das ausgewählte Slice trotzdem
  mittig bleibt.
- **Rand-Fade als Judgment Call**: Spec nennt nur eine Distanz (1,5 ×
  sliceWidth) plus eine geeaste Dauer (200ms OutQuad), kein Start-/End-Paar
  wie beim Launcher. Umgesetzt als „ab dem sichtbaren Kartenrand (800px vom
  Zentrum) linear über die nächsten 1,5 × sliceWidth ausblenden" — die
  einzige Lesart, die für eine tatsächlich geclippte, schmalere-als-ihr-
  Inhalt Karte funktional Sinn ergibt (der Launcher braucht das nicht,
  seine Karte ist so breit wie sein Inhalt).
- **Schatten**: drei gestapelte Parallelogramm-Canvases (Versatz ×1/×0.6/
  ×1.4, Alpha ×0.5/×0.3/×0.2 auf einer von der Auswahl abhängigen Basis),
  anders als der Launcher mit nur einer Schatten-Kopie.
- **Badges**: FOCUSED (primary-Pille, nur eigener Style laut Spec statt der
  generischen `rgba(0,0,0,0.75)`-Badge-Optik), WS N (`tags[0]`, Füllung
  tertiary — Textfarbe `surface`, da Colors.qml keine `tertiaryText`-Rolle
  hat, Judgment Call), FLOAT (generischer Badge-Style, 10px-Einrückung statt
  Schräge-basiert, da unten links die Parallelogrammkante schon bei x=0
  liegt — Spec nennt hier keine Zahl).
- **Kein Maus-Hover-Select/Mausrad** wie beim Launcher: Spec section 3s
  „Steuerung" listet dafür anders als section 2 keine Mausregeln, nur
  Klick zum Auswählen/Bestätigen wurde ergänzt.
- Dieselbe `containmentMask`-Einschränkung wie `SliceDelegate.qml` (diese
  Qt-Version lehnt ein `QtObject` mit `contains()` als Maske ab) — die
  Klickfläche bleibt rechteckig.
- `IpcHandler` liefert `switch open|next|prev|confirm|cancel|close` (Spec-
  Abschnitt 6). Kein Compositor-Keybind verdrahtet — dieselbe Lücke wie bei
  Launcher/Power-Menü (Adapter-System, siehe unten).
- **Nicht verifizierbar auf diesem System**: Mehrfenster-Layout (Karte mit
  mehreren Slices, Rand-Fade in Aktion, Übergang zwischen Fenstern über
  `next`/`prev`) nur gegen den Code geprüft — zum Testzeitpunkt lief auf
  diesem System nur ein einziges Fenster (siehe oben), daher zeigte der
  Screenshot zwangsläufig nur den Ein-Fenster-Fall (Fokus- und
  Auswahl-Badge auf derselben Karte). `hex`/`wheel`/`grid`-Moden derselben
  Overlay-Familie sind ohnehin optional und nicht gebaut, siehe unten.

**Nachtrag (22.09.) — Settings-Menü (Workspace-Stil) + Mittelinsel folgt
Workspace-Breite**: außerhalb der beiden Original-Prompts, auf Nutzerwunsch.
Headless getestet via `qs -p . -n` (`Configuration Loaded`, keine neuen
QML-Fehler/Warnungen) und per `flameshot full` visuell geprüft, sowohl fürs
Dropdown (`DropdownState.open`'s Default kurzzeitig auf `"settings"`
gesetzt, wieder zurückgesetzt — dieselbe Methode wie Stage 3/6/7/8) als
auch für zwei der vier Workspace-Stile live in der laufenden Bar
(`~/.config/ricev2/config.json`s `workspaceStyle` kurzzeitig auf `"bars"`
gesetzt, wieder auf den Default `"dots"` zurückgesetzt — kein Klick/keine
Taste simuliert, nur der Bar-Prozess neu gestartet, memory zu
Live-Input-Risiko bleibt dadurch unberührt). Enthält:

- `Config.workspaceStyle` (neu, persistiert, Default `"dots"`) — welchen
  Look `Bar/lyrics/WorkspacePips.qml` (Mittelinsel im Ruhezustand) zeichnet:
  `"dots"` (Original-Look aus Stage 4, unverändert), `"numbers"` (Zahl
  immer sichtbar statt nur beim aktiven Tag), `"roman"` (römische
  Ziffern), `"bars"` (Mini-Equalizer-Balken, passend zum cava-
  Visualizer-Thema derselben Insel — die "überrasch mich"-Option). Alle
  vier teilen sich Highlight-Capsule/Hover/Klick/Scroll-Mechanik, nur die
  Pip-Geometrie selbst wechselt per `root.style`-Verzweigung.
- `Bar/menus/SettingsDropdown.qml` (neuer Dropdown-Inhalt) + neues gear-
  Icon-Widget `Bar/widgets/SettingsWidget.qml` (Codepoint `\u{F0493}`,
  `nf-md-cog`) in `Config.widgetsRight`, vor `clock` — einziger Trigger für
  den neuen Dropdown, öffnet wie alle anderen unter der rechten Insel
  (`DropdownState.toggle("settings")`). Jede der vier Optionen zeigt eine
  echte 3-Pip-Live-Vorschau (`Bar/menus/WorkspaceStylePreview.qml`, eigene
  Datei statt in `SettingsDropdown.qml` inline, weil dieselbe Geometrie
  auch für die Auswahl-Häkchen-Zeile gebraucht wird) statt nur eines
  Namens — "Punkte" vs. "Balken" sagt blind nichts.
  - **Stolperstein**: `WorkspaceStylePreview.qml`s `Repeater`-Delegate
    griff zuerst auf ein rohes `index` in einem verschachtelten `Text`
    zu (`ReferenceError: index is not defined` im Log) — Repeaters
    injizierte `index`/`modelData` sind nur auf dem Delegate-Root direkt
    sichtbar, nicht in dessen Kindern, es sei denn, man deklariert sie
    explizit als `required property` auf dem Root und greift qualifiziert
    zu (`cell.index`) — exakt das Muster, das `WorkspacePips.qml` für
    `modelData` schon vorher benutzt hatte (`pip.modelData.index`, nie
    bares `modelData`). Übersehen, weil dort nie ein bares `index`
    gebraucht wurde; hier nachgezogen.
  - Bestehende `~/.config/ricev2/config.json` von vor diesem Nachtrag
    kannte weder `settings` in `widgetsRight` noch `workspaceStyle`
    überhaupt — `JsonAdapter` füllt fehlende Schlüssel zwar aus den
    Code-Defaults, aber nur für Schlüssel, die in der Datei komplett
    fehlen, **nicht** für ein bereits vorhandenes `widgetsRight`-Array,
    dem nur ein Eintrag fehlt (das Array selbst gilt als "vorhanden", wird
    also 1:1 aus der Datei übernommen). Deshalb wurde die bestehende Datei
    dieses Nutzers direkt um `"settings"` (vor `"clock"`) und
    `"workspaceStyle": "dots"` ergänzt statt sich auf den Code-Default zu
    verlassen — sonst wäre das neue Zahnrad-Icon erst nach einem Löschen/
    Neuschreiben der Config sichtbar geworden.
- **Mittelinsel-Breite folgt jetzt der Workspace-Insel** (zweiter Teil des
  Nutzerwunschs: "die mittlere bar sollte so lang wie die workspaces sein
  und erst wachsen wenn etwas spielt"). Bisher war die Mittelinsel im
  Ruhezustand bereits permanent sichtbar (Stage 4), aber fest
  `Style.middleIslandWidth` (699px) breit, unabhängig von der tatsächlichen
  Pip-Reihenbreite. Jetzt besitzt `LyricsIsland.qml` ein `idleWidth`
  (`workspacePips.implicitWidth + (Style.diagSlant + 16) * 2` — dieselbe
  Slant-Padding-Formel wie links/rechts, nur symmetrisch, weil die
  Mittelinsel auf beiden Seiten schräg ist, nicht nur einer), und
  `TopBar.qml`s `middleIsland`-Wrapper switcht selbst zwischen `idleWidth`
  und `Style.middleIslandWidth` (`LyricsService.playing`, z. B. ein
  laufender YouTube-Tab über MPRIS) — mit eigenem `Behavior on width`
  (300ms OutCubic), exakt dieselbe Aufteilung, die für `height` schon
  bestand (Wrapper animiert, `LyricsIsland.qml` spiegelt per reiner
  Bindung `width: parent.width` nach unten, keine zweite, gegenläufige
  Animation). `Bar/Island.qml`s Canvas repaintet bei jeder
  `onWidthChanged` bereits reaktiv (dieselbe Mechanik, die links/rechts
  seit Stage 1 ihre variable Breite trägt), daher keine Änderung dort
  nötig; `BarShell.qml`s Input-Mask (`Region { item:
  topBar.middleIslandItem }`) folgt der animierten Wrapper-Geometrie
  ebenfalls automatisch.

**Nachtrag (22.09., zweiter Teil) — Esc schließt jetzt auch die sechs Bar-
Dropdowns + das neue Settings-Menü**: Launcher/Switcher/Power-Menü hatten
Esc schon immer (eigene, während offen exklusiv-fokussierte Fenster,
`Keys.onEscapePressed` in `Launcher.qml`/`Switcher.qml`/`PowerMenu.qml`) —
die sieben von `BarShell.qml`s einer, dauerhaften `PanelWindow` geteilten
Dropdowns (Volume/Wifi/Bluetooth/Calendar/Weather/Notifications/Settings)
dagegen nicht (Stage 3 hatte das bewusst offen gelassen, siehe „Kein
Außerhalb-Klick schließt" oben). Nur headless getestet (`qs -p . -n`,
`Configuration Loaded`, keine neuen Fehler) — ein echter Esc-Tastendruck
wurde nicht simuliert (memory zu Live-Input-Risiko), nur der Fokus-
Mechanismus selbst gegen den Code verifiziert:

- `BarShell.qml`s `WlrLayershell.keyboardFocus` ist jetzt `Exclusive`,
  solange irgendein Dropdown offen ist (`DropdownState.open !== ""`), nicht
  mehr nur während des WLAN-Passwortfelds (`keyboardWanted`) — sonst wäre
  Esc auf `OnDemand` vom unverifizierten mango-Fokusverhalten abhängig
  (memory: feedback_mango_ondemand_focus_requires_fresh_surface).
- `TopBar.qml`s neuer `dropdownEscCatcher`-Item (`focus: DropdownState.open
  !== "" && !DropdownState.keyboardWanted`, `Keys.onEscapePressed:
  DropdownState.close()`) sitzt neben dem `Dropdown`-Loader.
  **Stolperstein**: `Bar/menus/PasswordField.qml` reißt sich den Fokus per
  `hiddenInput.forceActiveFocus()` (imperativ), sobald es aufklappt — das
  löscht laut Qt-Quick-Fokusmechanik die deklarative `focus`-Bindung des
  vorherigen Fokus-Inhabers (wird zu einem toten `false`-Literal). Ohne
  Gegenmaßnahme hätte Esc nach einem abgebrochenen Passwort-Versuch nicht
  mehr funktioniert, bis der Dropdown einmal neu geöffnet wird. Behoben
  durch einen `Connections`-Handler auf `DropdownState.keyboardWantedChanged`,
  der `dropdownEscCatcher.forceActiveFocus()` genauso imperativ zurückholt,
  sobald `keyboardWanted` wieder `false` wird — verlässt sich nicht auf die
  (kaputte) Bindung.
- Notification-Toasts (`Bar/notifications/PopupHost.qml`) bewusst nicht
  angefasst — das sind Popups mit eigenem Timeout/Hover-Pause, keine
  „Menüs" im Sinne der Frage, und ihr Fenster läuft ohnehin auf
  `WlrKeyboardFocus.None`.

## Launcher-Modi `hex`/`grid` (22.09., nach Stage 8)

Menüs-Prompt Abschnitt 2, „Alternative Modi" — bis hierhin bewusst
zurückgestellt (siehe „Noch nicht gebaut" unten), jetzt gebaut:
`Config.launcherDisplayMode` (`"slice"` Default | `"hex"` | `"grid"`),
umschaltbar über eine neue Einstellungsdropdown-Sektion
(`Bar/menus/SettingsDropdown.qml`, „LAUNCHER-ANSICHT") oder direkt in
`~/.config/ricev2/config.json`.

- **`grid`** (`Bar/launcher/GridDelegate.qml`): folgt dem Spec-Text
  wörtlich — 6×3 Kacheln à 300×169px, Radius 6, Abstand 8,
  `surfaceContainer@0.85`, Hover 2px Rand primary, Abdunkelung
  0.4→0.15, Name 10px Bold weiß. Läuft über eine echte `GridView`
  (`interactive: false`, Auswahl steuert `positionViewAtIndex`) — mehr
  Apps als die drei sichtbaren Zeilen scrollen einfach weiter, dieselbe
  Idee wie `visibleCount` beim Slice-Modus. Zwei Lücken, die der Spec-Text
  selbst offen lässt, wurden judgment-call gefüllt: ein eigener
  „ausgewählt"-Zustand (3px Rand + Abdunkelung 0, analog zu Slice/Hex,
  da Tastatur-Navigation sonst unsichtbar bliebe) und ein
  Legibility-Scrim hinter dem Namen (der Spec-Text nennt nur die
  Textfarbe, kein Backing).
- **`hex`** (`Bar/launcher/HexDelegate.qml`): Waben mit Radius 140,
  7 Spalten sichtbar, Zeilen-major befüllt (Index = Zeile × 7 + Spalte).
  Der Spec-Satz „Spalten folgen einem Bogen (Intensität 1.2)" nennt
  keine Basis-Einheit, die die Intensität multipliziert — 40px gewählt
  (`Style.hexArcBaseUnit`), macht auf diesem 1440px-hohen Monitor einen
  spürbaren, aber nicht zu großen Bogen (Amplitude 1.2×40=48px, siehe
  `Style.hexArcOffset()`). Da QtQuick keine eingebaute gestaffelte
  Honeycomb-View kennt, positioniert sich jedes `HexDelegate` selbst aus
  seinem `index` heraus in einer `Flickable`+`Repeater` statt in einer
  `ListView`/`GridView` — das kostet die von `ListView`/`GridView`
  eingebauten add/remove/move-Übergänge; nur die „neues Element"-Hälfte
  (Opacity/Scale 0.9→1 beim Erscheinen, wie Spec-Text „Übergänge wie oben
  mit Scale 0.9→1" verlangt) ist per `Component.onCompleted` nachgebaut,
  ein aus dem gefilterten Set fallendes Element verschwindet einfach ohne
  Fade-out. Dokumentierte Lücke, kein Versehen — analog zur bereits
  bestehenden `containmentMask`-Einschränkung in `SliceDelegate.qml`.
  Inhalt (Bild/Icon/Glyph, Abdunkelung, Rand, Namensschild) übernimmt
  bewusst das „Ein Streifen"-Muster von `SliceDelegate.qml`, da der
  Alternative-Modi-Absatz nur Form/Geometrie neu definiert.
- Getestet headless (`qs -p . -n`, keine QML-Fehler in beiden neuen
  Dateien) und live per `flameshot` in allen drei Modi (Config-Datei
  editiert, Prozess neu gestartet — neue `.qml`-Dateien lädt ein
  laufender Prozess laut `feedback_quickshell_new_file_hotreload_invisible`
  ohnehin nicht per Hot-Reload nach). Tastatur-/Mausnavigation
  (Pfeiltasten hoch/runter = `Style.gridCols`/`hexCols` Schritte, Mausrad
  entsprechend) wurde wie in jedem anderen Bar-Build hier nur gelesen,
  nicht live gedrückt — dasselbe Live-Input-Risiko wie bei jeder
  Tastatur-/Maus-Interaktion in diesem Projekt (memory:
  `feedback_live_input_sim_desktop_risk`).
- `roundCorners`/Eckenradius (Slice-Modus) weiterhin nicht gebaut (siehe
  `SliceDelegate.qml`s eigener Kommentar) — betrifft nur `slice`, nicht
  die beiden neuen Modi.

## System-Monitor-Dropdown (22.09., Nutzerwunsch)

Nutzer bat direkt: „ein System-Monitor, der sich öffnet, wenn man auf die
linke Seite/Bar drückt". Kein Teil von einem der beiden Original-Prompts
— die dort spezifizierte Klick-Spalte für cpu/gpu/memory ist knapp
(„schließt offenes Dropdown" für cpu, „–" für gpu/memory, siehe
Bar-Prompt Abschnitt 4), und keines der beiden Prompts kennt ein
Dropdown, das vom linken statt vom rechten Inselcluster aus öffnet.
Umgesetzt:

- **Klickfläche**: eine `MouseArea`, die die ganze linke Insel abdeckt
  (`Bar/TopBar.qml`s `leftIsland`), nicht nur ein einzelnes Widget — der
  Nutzer sagte „linke Seite/Bar", nicht „das CPU-Widget". Kollidiert mit
  nichts: keines der drei linken Widgets (`CpuWidget`/`GpuWidget`/
  `MemoryWidget`) hatte je eine eigene `MouseArea` (ihr Klick war laut
  ihren eigenen Kommentaren nie verdrahtet).
- **Positionierung**: flush-links unter der linken Insel. Der Bar-Prompt
  selbst nennt genau diese Position bereits (Abschnitt 1: „linke Seite
  bündig links"), aber bis jetzt gab's nichts Linkes zum Andocken — jedes
  bestehende Dropdown hängt am rechten Inselcluster. `Bar/TopBar.qml`
  bekommt dafür einen zweiten `Dropdown{}`-Host (`leftDropdown`, analog
  zum bestehenden `dropdown`), `DropdownState.open` bleibt der einzige
  Wahrheitsspeicher (weiterhin nur eins gleichzeitig offen — ein Klick auf
  ein rechtes Widget schließt den Monitor automatisch mit und umgekehrt).
  Der bestehende rechte `Dropdown`-Host bekam dafür eine Bedingung
  (`root._rightDropdownOpen`), die `"sysmonitor"` ausdrücklich ausschließt
  — sonst wäre er beim Öffnen des Monitors leer mitaufgeklappt.
- **`Bar/BarShell.qml`s Input-Mask** um `topBar.leftDropdownItem` erweitert
  — sonst exakt die schon zweimal in diesem Projekt aufgetretene Falle
  (memory: `feedback_quickshell_panelwindow_mask_input_region`): ein
  zweiter `Dropdown`-Host, von dem die Maske nichts weiß, rendert
  korrekt, ist aber unklickbar, weil alles außerhalb der gelisteten
  Regionen durchklickt.
- **Inhalt** (`Bar/menus/SysMonitorDropdown.qml`): mehr Detail als die drei
  kompakten Widgets zeigen können, nicht dieselben drei Zahlen in einer
  größeren Box — CPU (Gesamt-% + Mini-Balken pro Kern), GPU (%, Temp,
  VRAM belegt/gesamt, nur sichtbar wenn `SystemService.gpuAvailable`),
  Arbeitsspeicher (GiB belegt/gesamt), Fußzeile mit Uptime + Load Average.
  `SystemService.qml` liefert diese Zusatzwerte über denselben
  bestehenden ~2s-Timer (kein separates Polling) — pro-Kern-Prozente aus
  `/proc/stat`s `cpuN`-Zeilen (eigene idle/total-Historie pro Kern,
  gleiche Differenz-Rechnung wie beim Gesamtwert), GiB-Werte aus
  `/proc/meminfo`, VRAM aus einer erweiterten `nvidia-smi`-Abfrage
  (`memory.used,memory.total` zusätzlich zu `utilization.gpu,
  temperature.gpu`), Load Average aus `/proc/loadavg`, Uptime aus
  `/proc/uptime`.
- Zwei Layout-Entscheidungen, die kein Prompt vorgibt: ein eigenes
  `WideRow`-Inline-Component statt `MenuRow` für die GiB-Zeilen (`MenuRow`s
  Wertspalte ist fest 32px, für „48%"-Werte gedacht, zu schmal für
  „8.0 / 16.0 GiB"), und `MeterBar.qml` als reiner Lese-Balken (gleiche
  Optik wie `VolumeSlider.qml`, aber ohne dessen Drag-Handle).
- Getestet headless (`qs -p . -n`, keine QML-Fehler) und live per
  `flameshot` — echtes Klicken auf die linke Insel wurde NICHT simuliert:
  `wlrctl pointer move` kennt laut `blobball/README.md` nur relative
  Bewegung, keine absolute Position, und ein blinder Bewegungs-Vorlauf zu
  einer geschätzten Koordinate ist genau das verkettete blinde Input, vor
  dem `feedback_live_input_sim_desktop_risk` warnt. Stattdessen ein
  temporärer `IpcHandler { target: "debug" }` in `TopBar.qml`, der direkt
  `DropdownState.open` setzt — echte IPC wie beim Launcher/Switcher-Test,
  kein simulierter Mausklick, danach wieder entfernt (siehe Git-Historie).
  Das Dropdown selbst öffnete korrekt und zeigte plausible Live-Werte
  (z. B. „Belegt 2.8 / 30.5 GiB", „Uptime 43m · Load 0.27 0.45 0.25").
  Der eigentliche Mausklick auf die Insel bleibt ungetestet — dieselbe
  Grenze wie bei jeder anderen Klick-/Tastatur-Interaktion in diesem
  Projekt.

**Noch nicht gebaut** (Reihenfolge wie in den Prompts' „Vorgehen"-Abschnitten):

- Switcher-Modi `wheel`/`grid` (Alternative zu `slice`) — bewusst
  zurückgestellt, siehe Stage 8 oben.
- `pill`-Bar-Stil (Alternative zu classic) — bewusst zurückgestellt, bis
  classic vollständig steht.
- **`adapters/ricev2.json` jetzt angelegt und vollständig** (`hasLauncher:
  true`, alle sechs Keybinds aus Spec-Abschnitt 6: Launcher, Power-Menü,
  Switcher open/prev/confirm/cancel/close). Auslöser war ein gemeldeter
  Bug: `SUPER+Space` öffnete bisher `quickdots/menu`s generischen
  Such-Popup statt ricev2s eigenem Launcher, weil ohne eigenen Adapter
  `switch-bar.sh` den Fallback-Bind aus `toggle-launcher.sh` einträgt
  (siehe `menu/scripts/switch-bar.sh`s `HAS_LAUNCHER`-Logik).
  - `Alt+Tab` (Switcher) und `Alt+Return` (confirm) kollidierten mit
    bereits vorhandenen, vom Nutzer aktiv genutzten mango-Binds
    (`ALT,Tab,togglejump` — natives Fenster-Overview; `Alt,Return,spawn,
    kitty` — Terminal-Shortcut, `SUPER+Return` bleibt als Backup). mangos
    `keybinding()` nimmt beim Tastendruck nur den *ersten* Treffer im
    Array und bricht ab (`src/input/keyboard.h`, Kommentar „only match
    the first keybind") — ein später im Prompts-Adapter angehängter Bind
    auf derselben Kombination hätte also nie gefeuert. Nutzer explizit
    gefragt (AskUserQuestion) und auf „überschreiben" entschieden: beide
    nativen Zeilen in `~/.config/mango/config.conf` auskommentiert (nicht
    gelöscht, mit Datumskommentar), vorher ein manuelles Backup
    (`config.conf.bak-manual-<timestamp>`) gezogen, zusätzlich zu
    `switch-bar.sh`s eigenem automatischen Backup bei jedem Lauf.
  - **`Switcher.qml`s `open`-IPC-Handler musste dafür ergänzt werden**:
    da mango bei gehaltenem Alt und mehrfachem Tab-Tippen jedes Mal
    denselben `switch open`-Aufruf schickt (kein „erster Druck" vs.
    „Wiederholung"-Unterschied auf Compositor-Seite), würde ein reines
    „immer neu holen + auf Index 1 springen" bei jedem Tab-Tipp die
    Auswahl zurücksetzen statt weiterzublättern. `_open()` prüft jetzt
    `SwitcherState.open` zuerst und ruft bei bereits offenem Overlay
    stattdessen `moveBy(1)` auf — erst dadurch verhält sich Alt+Tab wie
    echtes Alt-Tab-Cycling. Spec-Abschnitt 6 selbst spezifiziert dieses
    Verhalten nicht explizit (paart nur „Alt+Tab → open"), das ist also
    ein Judgment Call, kein Zahlenwert aus der Spec.
  - Per `switch-bar.sh ricev2` angewendet (backupt `config.conf`, schreibt
    den `# >>> quickdots >>>`-Block neu, `mmsg dispatch reload_config`)
    und per echten IPC-Aufrufen + `flameshot` bestätigt: Launcher-,
    Power-Menü- und Switcher-Overlay öffnen alle korrekt (Power-Menü
    testweise nur geöffnet/wieder `cancel`t, nie eine echte Option
    ausgeführt). Die eigentlichen Tastenkombinationen selbst (Alt+Tab
    gehalten, Alt+Return, ...) wurden nicht real gedrückt getestet —
    dasselbe Live-Input-Risiko wie bei jeder anderen Maus-/Tastatur-
    Interaktion in diesem Projekt, nur der IPC-Pfad dahinter ist
    verifiziert.

## Testen — bisherige Grenzen

Wie bei den anderen Bar-Builds in diesem Repo (`rice`, `lumen`, ...) lief
zunächst nur der **headless Component-Load-Test** (`qs -p . -n`, Log auf
QML-Fehler geprüft) — für Stage 2 bestätigt: `Configuration Loaded`, keine
QML-Fehler (nur die erwarteten bluez/UPower-DBus-Warnungen, siehe oben).

`grim`/`slurp`/`wayshot` fehlen auf diesem System weiterhin — **aber
`flameshot` ist installiert und funktioniert** (`flameshot full -p <pfad>`,
kein `grim`-Ersatz, sondern XDG-Desktop-Portal-basiert über
`xdg-desktop-portal-wlr`, das hier bereits läuft). Kein Passwort-/
Consent-Dialog, kein manueller Klick nötig — läuft nicht-interaktiv durch.
Damit ist der vom Bar-Prompt für genau diesen Zwischenstand ausdrücklich
gewünschte Screenshot-Vergleich („Fenster, Inselformen, Farben, Uhr ...
mich per Screenshot vergleichen lassen") jetzt möglich und für Stage 2
durchgeführt:

- Beide Inseln rendern als eigene, durch echte Transparenz getrennte
  Trapeze (kein durchgehender Strich) — schräge Kante links an der linken
  Insel rechts, rechts an der rechten Insel links, wie in Abschnitt 2
  spezifiziert.
- Alle Stage-2-Widgets zeigen plausible Live-Werte im Format „Icon
  Wert": links `cpu 3% 50°`, `gpu 7% 45°`, `memory 11%`; rechts `weather
  18°`, `brightness 0%`, `volume 20%`, `notifications 0`, `clock 17:34`.
- `bluetooth`, `wifi` und `battery` fehlen in der gerenderten Bar komplett
  (kein Leerstand, keine 0%) — korrekt: kein Bluetooth-Adapter, keine
  verbundene WLAN-Netzwerk-Property und kein Laptop-Akku auf diesem
  System, das „ausgeblendet ohne Daten"-Verhalten aus Abschnitt 4 greift.
- Die Bar-Fläche selbst ist die echte matugen-Palette (`primary #8ccff0`
  hellblau, `surface #0f1417` dunkel), nicht mehr die Fallback-Palette —
  siehe „Farben" oben.

Mausinteraktion (Scroll-Helligkeit, Hover-Modus) wurde weiterhin nicht
interaktiv getestet (Flameshot macht nur Standbilder, keine
Eingabesimulation) — nur der Code gegen die Prompt-Vorgabe gelesen.

## Ursprungs-Prompts

Siehe `prompt/claude-code-prompt-skwd-bar.md` und
`prompt/claude-code-prompt-skwd-menus.md` — unverändert wie vom Nutzer
abgelegt, dienen als Referenz-Spec für jede Stage oben.
