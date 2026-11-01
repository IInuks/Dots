# quickdots menu

Ein schwebendes Quickshell-Menü für MangoWM im Stil eines
Installations-Assistenten (Calamares-Look), mit dem sich zwischen den
Bars in `~/quickdots/bars/` wechseln lässt. Läuft als eigene,
dauerhafte Quickshell-Instanz (im Hintergrund, unsichtbar) und wird per
Tastenkombination oder IPC ein-/ausgeblendet.

## Starten

```sh
qs -p ~/quickdots/menu -n
```

Läuft normalerweise dauerhaft im Hintergrund über den `exec-once`-Eintrag
im `# >>> quickdots >>>`-Block in `~/.config/mango/config.conf` (wird bei
jedem Bar-Wechsel automatisch mitverwaltet, siehe unten).

## Öffnen / Schließen

- Tastenkombination: **Strg + Super + Alt + Leertaste**
  (reine Modifier-Kombis ohne Taste unterstützt MangoWM nicht, siehe
  `bind=` in `config.conf`)
- IPC direkt:
  ```sh
  qs -p ~/quickdots/menu ipc call menu toggle
  qs -p ~/quickdots/menu ipc call menu open
  qs -p ~/quickdots/menu ipc call menu close
  ```
- Maus: Klick außerhalb des Panels schließt es, ebenso **Esc**

## Bedienung (Tabs)

Fenster 1100x620, zentriert: Titelleiste (ziehen = verschieben,
Doppelklick = maximieren; rechts Minimieren/Maximieren/Schließen),
Seiteninhalt, Statuszeile mit „Anwenden“/„Schließen“ und ganz unten die
Tab-Leiste mit sieben Tabs. Aktueller Tab = türkise Pille. Beim Öffnen ist
der zuletzt benutzte Tab aktiv (gemerkt in
`~/.local/state/quickshell/menu-last-tab`, auch über Neustarts; beim allerersten
Mal **Bars**), in „Bars“/„Launcher“ mit der aktiven Bar bzw. ihrem Launcher
ausgewählt. Ausnahme:
**Strg + rechte Umschalttaste** (`ipc call wizard blob`) öffnet direkt den
Tab **Blob**.

| Tab | Datei | Inhalt |
|---|---|---|
| Editor | `steps/CustomStep.qml` | Baukasten für eigene Bars (`tabs/CustomTab.qml`) |
| Bars | `steps/BarStep.qml` | links (25 %) Liste aller Bars, rechts (75 %) Name, große Vorschau, Beschreibung |
| Launcher | `steps/LauncherStep.qml` | links Liste aller Launcher, rechts Vorschau, Beschreibung und Zuweisung an Bars (siehe „Launcher mischen“) |
| Blob | `steps/BlobStep.qml` | Einstellungen des Desktop-Blobs (`../blobball`, ersetzt dessen altes eigenes Menü): links Live-Vorschau, Sichtbar, Starten/Test-Nachricht/Standard; rechts Aussehen + Verhalten. Wirkt sofort, kein „Anwenden“ (siehe „Blob“) |
| Widgets | `steps/WidgetsStep.qml` | Desktop-Widgets der Bar `salbei`, aufgebaut wie „Bars“/„Launcher“: links alle Widgets (Uhr, analoge Uhr, Kalender, Visualizer, Begrüßung, Musik, System, Wetter) mit eigenem An/Aus-Schalter in der Zeile, darunter „Akzentfarbe“ (fest oder aus dem Wallpaper, plus „Alle Widgets auf Standard“). Rechts Name + Beschreibung, eine Live-Vorschau auf dem echten Wallpaper (webp: salbeis Farbraster) und die Einstellungen des gewählten Widgets, je Widget außerdem „An Hintergrund anpassen“ (dunkle Schrift + kräftigerer Akzent auf hellem Wallpaper, gleiche Rechnung wie in salbei), „Glas-Karte“ und Position. „Verschieben“ (oder V, Doppelklick auf ein Widget) macht die Vorschau zum Editor: Widgets ziehen (rastet an Mitte und 2,5-%-Rändern ein, am rechten/unteren Rand gespeichert als 100 %), Pfeile 0,2 %, Shift 2 %, Tab nächstes Widget, Enter/Esc fertig; der Desktop folgt live. Leertaste schaltet das gewählte Widget an/aus. Wirkt sofort, kein „Anwenden“. `WidgetsStore.qml` (Widget-Liste + Einstellungs-Beschreibung, generisch gerendert) schreibt `~/.local/state/quickshell/salbei-widgets.json`, salbei (`services/WidgetSettings.qml`) liest die Datei live. Mit jeder anderen Bar laufen die Widgets eigenständig über `bars/salbei/widgets.qml` (nur salbeis Desktop-Ebene, ohne Bar), gestartet von `scripts/widgets-host.sh sync` beim Bar-Wechsel, beim Login und beim Öffnen des Menüs; mit salbei selbst wird der Host beendet. Direkt öffnen: `ipc call wizard widgets` |
| Blur | `steps/BlurStep.qml` | Mangos globaler Blur (Bar, Menüs, transparente Fenster): links Annäherungs-Vorschau auf dem aktuellen Wallpaper + „Standard“, rechts An/Aus, Layer-Blur, Radius, Durchgänge, Optimiert, Helligkeit/Kontrast/Sättigung/Rauschen. Wirkt sofort: `BlurStore.qml` ruft `scripts/set-blur.sh key=value …` auf (ersetzt die Zeile in `config.conf`, ein Backup pro Tag als `config.conf.bak-YYYYMMDD-blur`, dann `mmsg dispatch reload_config`). Mango begrenzt Helligkeit/Kontrast/Sättigung auf 0–1. Direkt öffnen: `ipc call wizard blur` |
| Server | `steps/ServerStep.qml` | Dashboard des Servers im Tailnet (Standard `PRIVATE_VALUE`, Fallback-IP `TAILSCALE_FALLBACK_IP`): links Name, Status, Kernel + Laufzeit, Ringe für CPU / RAM / Platte `/`, darunter Load, Temperatur, Swap, Netz ↓/↑; Knöpfe „Terminal“ (kitty mit ssh, Taste T), „Neu verbinden“ (R) und – wenn der Server keinen Login ohne Passwort erlaubt – „Schlüssel“ (ssh-copy-id). Rechts CPU-/RAM-Verlauf der letzten 3 min, alle Laufwerke, die 6 Prozesse mit der meisten CPU (Ø seit Prozessstart, `ps`) und „Verbindung“ (Host, Fallback-IP, Benutzer → `~/.local/state/quickshell/menu-server.json`). `ServerStore.qml` fragt alle 3 s per `bars/salbei/scripts/server.sh stats` ab (dasselbe Skript und derselbe ssh-Control-Socket wie salbeis Server-Seite), nur solange der Tab offen und das Menü sichtbar ist. Braucht laufendes Tailscale (`tailscript start`). Verlangt Tailscale SSH eine Browser-Bestätigung („check“-Modus), zeigt der Tab das an (Abfrage bricht nach 15 s ab): „Terminal“ öffnen und den Link anklicken, danach läuft die Abfrage über dessen Control-Socket. Direkt öffnen: `ipc call wizard server` |

- **Tastatur**: ←/→ = Tab wechseln (nicht in Textfeldern), ↑/↓
  (Home/End/Bild↑↓) = Bar in der Liste wählen, **Enter** = Anwenden,
  **Esc** = Schließen
- **Maus**: Klick auf einen Tab wechselt ihn, Klick auf einen Listeneintrag
  wählt, Doppelklick = Anwenden
- **Anwenden** startet `switch-bar.sh`; Fortschritt bzw. Ergebnis (bei
  Fehler mit der letzten Fehlerzeile) stehen links in der Statuszeile.
  Schließen während des Wechsels blendet nur aus, der Wechsel läuft weiter.
- **Vorschau**: liegt `bars/<name>/preview.png` (oder `.jpg`) vor, wird der
  echte Screenshot gezeigt. Sonst ein generiertes Mockup: aktuelles
  Wallpaper (`awww query`) + Leiste/Fenster in Farben, Deckkraft und Radius
  der Bar. Titel + Beschreibung kommen aus Überschrift und erstem Absatz
  von `bars/<name>/README.md` (`scripts/bar-info.py`).

IPC (zusätzlich zu `menu` oben):
```sh
qs -p ~/quickdots/menu ipc call wizard toggle
qs -p ~/quickdots/menu ipc call wizard tab 0           # 0 = Editor, 1 = Bars, 2 = Launcher, 3 = Blob
qs -p ~/quickdots/menu ipc call wizard blob            # öffnen bzw. wechseln auf Tab „Blob“ (Strg + Shift_R)
qs -p ~/quickdots/menu ipc call wizard select polarlicht
qs -p ~/quickdots/menu ipc call wizard launcher kurtz   # Launcher im Tab „Launcher“ wählen
qs -p ~/quickdots/menu ipc call wizard apply            # gewählte Bar anwenden (bzw. Launcher der aktiven Bar zuweisen)
qs -p ~/quickdots/menu ipc call wizard next             # / back (Tab) / close
```

## Blob (Tab „Blob“)

Der Blob (`../blobball`) läuft weiter als eigene Quickshell-Instanz. Nur
seine Einstellungen liegen jetzt hier. `BlobStore.qml` ist der einzige
Schreiber von `~/.local/state/quickshell/blob.json`: Jede Änderung wird
nach 60 ms gesammelt geschrieben (ein Slider-Zug erzeugt also nicht
Dutzende Schreibvorgänge), und blobball lädt die Datei per `watchChanges`
live nach. Beim Öffnen und Schließen des Menüs ruft `BlobStore`
`qs -p ../blobball ipc call menu opened|closed` auf, und der Blob blendet
sich so lange aus. Sonst läge er zufällig über oder unter dem Menüfenster,
weil beide auf dem Overlay-Layer liegen. Die Vorschau nutzt dieselbe
`Blob.qml` wie der echte Blob (`components/Blob.qml` ist ein Symlink nach
`../../blobball/Blob.qml`).

## Design anpassen

Alle Farben, Schriftgrößen, Abstände, Radien und Animationsdauern stehen in
`Theme.qml` (Singleton). Hintergrund `#1a1d21`, Panels `#212529`, Akzent
Türkis `#00c8c8` (aktiver Tab, Rahmen, Primär-Button), Listenauswahl
Blau `#3daee9`. Der Wizard nutzt bewusst dieses feste Theme, nicht die
Live-Farben der aktiven Bar -- die bekommt weiterhin nur die App-Suche
(`ThemeAdapter`, siehe „Theme“ unten). Keine `Behavior` in `Theme.qml`
einbauen (crasht Quickshell 0.3.1 in Singletons).

## App-Suche (SUPER+Space)

Eigenständiges zweites Popup (nicht Teil des Wizards oben) für Bars ohne
eigenen App-Launcher -- Tippen filtert `.desktop`-Einträge live, Pfeiltasten
+ Enter (oder Klick) startet, Esc/Klick daneben schließt. Farben/Deckkraft
kommen über dasselbe `ThemeAdapter` wie die Bars-Karte, passen also immer
zur aktiven Bar.

- Tastenkombination: **Super + Leertaste**
- IPC direkt:
  ```sh
  qs -p ~/quickdots/menu ipc call launcher toggle
  qs -p ~/quickdots/menu ipc call launcher open
  qs -p ~/quickdots/menu ipc call launcher close
  ```

`SearchState.qml` öffnet das Popup nur, wenn die App-Suche der Launcher
der aktiven Bar ist: Standard für Bars ohne eigenen Launcher
(`adapters/<barname>.json`: `"hasLauncher": false`) oder im Tab „Launcher“
zugewiesen. Sonst ist der Aufruf ein No-op, und SUPER+Space ist ohnehin an
einen anderen Launcher gebunden (siehe „Launcher mischen“).

## Launcher mischen (Tab „Launcher“)

Jede Bar kann einen beliebigen App-Launcher bekommen: ihren eigenen, die
App-Suche des Menüs oder den Launcher **einer anderen Bar**. Die Zuweisung
bleibt bestehen, bis sie geändert wird. Wird eine Bar gewählt (Tab „Bars“
oder beim Login), kommt ihr zugewiesener Launcher automatisch mit.

- **Bedienung**: links den Launcher wählen (↑/↓, Suche). **Enter** bzw.
  „Anwenden“ weist ihn der aktiven Bar zu (sofort wirksam). Unten rechts
  steht pro Bar ein Chip: gefüllt heißt, die Bar nutzt diesen Launcher
  („Standard“ heißt, es ist ihr eigener bzw. die App-Suche ohne Zuweisung).
  Ein Klick auf einen Chip weist den Launcher dieser Bar zu, ein erneuter
  Klick setzt sie auf den Standard zurück. „Ausprobieren“ schließt das
  Menü und öffnet den echten Launcher, ohne etwas zuzuweisen.
- **Speicher**: `~/.local/state/quickdots/launchers.json`
  (`{"assignments": {"<bar>": "<launcher>"}}`, ohne Eintrag = Standard).
  Launcher-IDs: `appsearch` oder ein Bar-Name.
- **Fremde Launcher ohne ihre Bar**: `launchers/hosts/<bar>.qml` ist je
  Bar eine abgespeckte `shell.qml`, die nur den Launcher startet, mit
  IPC-Target `launcher` (`toggle`/`open`/`close`). `scripts/launcher-host.sh`
  kopiert sie nach `bars/<bar>/.quickdots-launcher.qml` (sie muss neben den
  Dateien der Bar liegen, damit deren Typen und Singletons gefunden werden)
  und setzt dabei `//@ pragma ShellId <md5 von bars/<bar>/shell.qml>`. So
  liest der Launcher dieselben Einstellungen und dasselbe Theme wie die
  Bar selbst. Die Kopie wird bei jedem Start neu erzeugt; die Quelle bleibt
  immer `launchers/hosts/`.
- **Keybind**: `scripts/launchers.py keybinds <bar>` nimmt die Keybinds aus
  `adapters/<bar>.json`, wirft bei fremdem Launcher bzw. App-Suche deren
  `bind=SUPER,space,…` raus und hängt den passenden an
  (`qs -p bars/<x>/.quickdots-launcher.qml ipc call launcher toggle` bzw.
  `toggle-launcher.sh`).
- **Ablauf**: `scripts/set-launcher.sh <bar> <launcher|default>` speichert
  die Zuweisung. Ist `<bar>` aktiv, folgen `launcher-host.sh sync`
  (richtigen Host starten, andere beenden, nur per exakter PID) und
  `mango-block.sh <bar>` (Config-Block + Reload). `switch-bar.sh` macht
  dasselbe bei jedem Bar-Wechsel. Der Config-Block enthält zusätzlich
  `exec-once=…/launcher-host.sh sync`, damit der Host nach dem Login läuft.
- **Neuen Launcher hinzufügen**: `launchers/hosts/<bar>.qml` anlegen (eine
  der vorhandenen als Vorlage: Fenster-Launcher wie `simple.qml`/`lucid.qml`,
  Overlay-Launcher wie `kurtz.qml`/`eierschale.qml`, in die Bar eingebaute
  wie `quickbar.qml`/`blobs.qml` als eigene Karte) und Titel und
  Beschreibung in `launchers/info.json` eintragen. Er erscheint dann von
  selbst in der Liste.
- **Grenzen**: Der Launcher-Knopf *in* einer Bar öffnet weiterhin deren
  eigenen Launcher; umgelenkt wird nur SUPER+Space. Launcher, die sonst
  aus der Bar herauswachsen (fisheye, blobs, quickbar, lumen, shellbar,
  fullshell), erscheinen ohne ihre Bar mittig als Karte. Ein Host läuft
  mit der Shell-ID seiner Bar, kann also nie gleichzeitig mit ihr laufen.
  Das passiert auch nicht: eine Bar „leiht“ sich nie ihren eigenen
  Launcher, und `switch-bar.sh` beendet alle Hosts, bevor es eine Bar
  startet.

## Testen

```sh
# Menü manuell starten (ohne mango-Neustart)
qs -p ~/quickdots/menu -n

# Öffnen
qs -p ~/quickdots/menu ipc call menu toggle

# Wechsel-Logik isoliert testen (ohne UI)
./scripts/switch-bar.sh shellbar
./scripts/switch-bar.sh quickbar

# laufende Instanzen prüfen
qs list --all
```

Nach einem Wechsel sollte `~/.local/state/quickdots/active-bar` den neuen
Namen enthalten, `qs list --all` nur noch die neue Bar zeigen (alte PID
beendet), und der `# >>> quickdots >>>`-Block in
`~/.config/mango/config.conf` die neue Bar + ihre Keybinds enthalten.

## Wie ein Bar-Wechsel abläuft

(Launcher-Host, Config-Block und Keybinds: siehe auch „Launcher mischen“.)

`scripts/switch-bar.sh <barname>` (aufgerufen von `SwitchState.qml`):

1. **Alte Bar beenden** — PID der aktiven Bar-Instanz über
   `qs list --all --json` (Config-Pfad-Match) ermitteln, gezielt per
   `qs kill --pid <PID>` beenden. Nie `pkill quickshell` — das Menü ist
   selbst eine Quickshell-Instanz und wird nie getroffen, da nur Pfade
   unter `bars/` als Ziel infrage kommen.
2. **Neue Bar starten** — laufende Launcher-Hosts beenden, dann
   `qs -p bars/<name> -n &` (das `-n` macht Re-Runs für die bereits aktive
   Bar ungefährlich/idempotent). `~/.local/state/quickdots/active-bar` wird
   auf den neuen Namen gesetzt, danach startet `launcher-host.sh sync` den
   Launcher, der dieser Bar zugewiesen ist (falls er von einer anderen Bar
   kommt), und `widgets-host.sh sync` salbeis Desktop-Widgets (außer die
   neue Bar ist salbei selbst).
3. **Config angepasst** (`scripts/mango-block.sh`) — der Block zwischen `# >>> quickdots >>>` und
   `# <<< quickdots <<<` in `~/.config/mango/config.conf` wird neu
   geschrieben (vorher wird ein Backup `config.conf.bak-<timestamp>`
   angelegt). Der Rest der Datei bleibt unberührt.
4. **Keybinds aktualisiert** — bar-spezifische Keybinds aus
   `adapters/<name>.json` (`keybinds`-Array, SUPER+Space je nach
   zugewiesenem Launcher umgebogen) werden mit in den Block geschrieben,
   danach `mmsg dispatch reload_config` — lädt MangoWM ohne
   Neustart neu.

Jede der vier Zeilen wird vom Skript auf stdout ausgegeben; `SwitchState.qml`
liest das und hakt die Statusliste im Menü live ab.

## Theme

Farben (surface/foreground/accent) kommen **live** von der jeweiligen Bar
selbst — `adapters/live/<Bar>Live.qml` liest schreibgeschützt genau die
Zustandsdatei(en), die diese Bar auch selbst benutzt, und bildet exakt
deren Farblogik nach (Dark/Light/Adaptive-Modus, Presets, Custom-Farben,
statische Theme-Dateien), ohne die Bar-Dateien selbst zu importieren oder
zu verändern:

| Bar | Quelle | Nachgebildete Logik |
|---|---|---|
| `quickbar` | `~/.local/state/quickbar/settings.json` | Dark/Light-Palette, Adaptive via ImageMagick-Farbextraktion aus `wallpaperPath` |
| `shellbar` | `~/.local/state/quickshell/by-shell/<hash>/theme.json` (Pfad wird zur Laufzeit per `Qt.md5(".../shellbar/shell.qml")` berechnet, nicht hartkodiert) | mono/monoInvert/adaptive-Presets, Custom-Farben |
| `klasic` | `~/.local/state/klasic/settings.json` + `bars/klasic/themes/*.json` | Theme-Datei nach `themeId`, Adaptive via matugen |
| `custom-<slug>` | `~/.local/state/quickdots/custom-bars/<slug>.json` (`theme.mode`) + live `~/.cache/wal/colors.json` für `"adaptive"` | siehe "Eigene Bars" unten |

`ThemeAdapter.qml` lädt immer den `BarTheme` der aktuell aktiven Bar
(`BarsModel.activeBar`) — ändert sich die aktive Bar (Statusdatei) oder
das Theme/Preset/Wallpaper der aktiven Bar selbst, passt sich das
Menü-Theme sofort an (`watchChanges` auf allen gelesenen Dateien). Jeder
Listeneintrag und jede Vorschau im Wizard lädt zusätzlich **ihren eigenen**
`BarTheme { barName: ... }`, damit Farbfeld und Mockup die Farben der
jeweiligen Bar zeigen, nicht die der aktiven.

`adapters/<barname>.json` liefert nur noch `barOpacity`/`radius`/
`keybinds` (strukturell, kein Farb-Theme) sowie den Farb-Fallback für
Bars ohne eigenen Live-Reader (`adapters/_default.json`, falls auch die
`<barname>.json` fehlt). Neue Bars bekommen automatisch den generischen
Fallback, bis ein `adapters/live/<Bar>Live.qml` für sie geschrieben wird.

## Neuen Tab hinzufügen

1. Neue QML-Datei in `steps/` anlegen, z. B. `steps/KeybindsStep.qml`
   (Wurzel ein `FocusScope`, siehe `steps/CustomStep.qml` als Vorlage;
   `import ".."` für die Singletons, `import "../components"` für
   `Panel`, `StepHeader`, `WizardButton` usw.).
2. In `Wizard.qml` einen Eintrag in `tabs` einfügen:
   ```qml
   { id: "keybinds", label: "Keybinds", icon: "\uf11c", file: "KeybindsStep.qml" }
   ```
   Tab-Leiste, Titel, ←/→ und Seitenwechsel passen sich automatisch an.

## Eigene Bars (Tab „Editor“)

Baukasten für eigene Bars aus Modulen (`menu/custom/*.qml`, Engine in
`lib/custombar/`) — Zonen links/mitte/rechts, Stil "Leiste" oder "Inseln".
Speichern legt `bars/custom-<slug>/` an und lässt die Bar danach wie jede
andere in der Liste des Tabs „Bars“ erscheinen (siehe Tabelle oben).

- **Workspaces-Modul-Gruppierung**: `groupSize`-Einstellung (1/3/5/9) am
  Modul. `1` = wie bisher, ein Slot pro belegtem/aktivem Tag. `>1` zeigt
  stattdessen nur einen einzelnen Range-Chip für die Gruppe, die den
  aktuell aktiven Tag enthält (z. B. `"1-3"` bei `groupSize: 3`) —
  Klick/Scroll wechselt zur nächsten/vorherigen Gruppe (`WorkspacesModule.qml`).
- **Adaptives Theme folgt live dem aktiven Wallpaper**: `theme.mode ===
  "adaptive"` liest `~/.cache/wal/colors.json` live (`WalTheme.qml`,
  gleiche Quelle/Feldbelegung wie `bars/shellbar/Theme.qml`), kein manueller
  Wallpaper-Pfad mehr nötig. `shellwall` ruft bei jedem Wallpaper-Wechsel
  `wal -i <pfad> -n -q` auf (siehe `shellwall/shell.qml`, `runPywal`), diese
  Datei ist also immer aktuell. Gilt sowohl für die laufende Bar
  (`CustomBarRoot.qml`) als auch für die Editor-Vorschau (`BarPreview.qml`)
  und die Vorschau im Tab „Bars“ (`adapters/live/CustomLive.qml`).
- **Form/Größe pro Insel** (nur Stil "Inseln"): `adapter.islands.<zone>` =
  `{ shape, height, padding, dx, dy }`, einzeln für links/mitte/rechts.
  `shape` ist `"rounded"|"pill"|"square"`, `height`/`padding` per Slider
  (`IslandStyleEditor.qml`, unterhalb der Vorschau im Editor, nur sichtbar
  bei Stil "Inseln").
- **Anordnung**: `dx`/`dy` werden nicht über Formularfelder gesetzt, sondern
  per Drag direkt in der Editor-Vorschau (`BarPreview.qml`) — jede Insel
  dort ist verschiebbar, die Position wird beim Loslassen in die Config
  geschrieben. `IslandStyleEditor.qml` bietet nur einen
  "Position zurücksetzen"-Link (setzt `dx`/`dy` auf 0). Die laufende Bar
  liest `dx`/`dy` nur, schreibt nie selbst in die Config.

## Dateien

| Datei | Rolle |
|---|---|
| `shell.qml` | `ShellRoot`, Wizard-Fenster (1100x620, verschieb-/skalier-/maximierbar, StackView mit Slide/Fade) + App-Suche-Popup (480x420), IPC-Handler `menu`, `wizard` (inkl. `blob`), `launcher`, je ein Klick-außerhalb-schließt-Catcher |
| `Wizard.qml` | Singleton: Tab-Liste, `currentTab`, `goTo()`/`nextTab()`/`prevTab()`, gewählte Bar, `apply()` |
| `Theme.qml` | Singleton: alle Farben/Schriften/Abstände/Dauern des Wizards |
| `BarInfo.qml` | Singleton: Titel/Beschreibung/Screenshot pro Bar (`scripts/bar-info.py`) + aktuelles Wallpaper |
| `steps/*.qml` | Je ein Tab (siehe Tabelle „Bedienung“) |
| `components/*.qml` | `TitleBar`, `MenuTabs` (Tab-Leiste), `WizardButton`, `BarMockup` (große Vorschau), `LauncherMockup` (Launcher-Vorschau über der aktiven Bar), `Panel`, `InfoChip`, `StepHeader`, `Icon`, `Spinner`, `ToggleRow`/`SliderRow` (Tab „Blob“), `Blob` (Symlink auf blobball) |
| `tabs/CustomTab.qml` | Inhalt des Tabs „Editor“ (Übersicht/Editor) |
| `MenuState.qml` | Singleton: Sichtbarkeit des Wizard-Fensters |
| `SearchState.qml` | Singleton: Sichtbarkeit des App-Suche-Popups, No-op, wenn die aktive Bar einen anderen Launcher nutzt (`forceOpen()` für „Ausprobieren“) |
| `BlobStore.qml` | Singleton: liest/schreibt `blob.json` für den Tab „Blob“, prüft, ob blobball läuft (`pgrep`), Starten, Test-Nachricht, meldet Menü offen/zu an blobball |
| `LauncherStore.qml` | Singleton: Launcher-Liste, Standard und Zuweisung pro Bar (`scripts/launchers.py info`), Zuweisen über `set-launcher.sh` mit Fortschritt, „Ausprobieren“ |
| `launchers/hosts/<bar>.qml` | Pro Bar: startet nur deren Launcher, ohne Bar (siehe „Launcher mischen“) |
| `launchers/info.json` | Titel + Beschreibung pro Launcher für den Tab „Launcher“ |
| `AppSearch.qml` | Inhalt des App-Suche-Popups: Suchfeld, gefilterte `ListView`, Tastatur+Maus |
| `AppEntries.qml` | Singleton: scannt `.desktop`-Dateien für die App-Suche (menu-lokale Kopie von `bars/quickbar/DesktopEntries.qml`s Logik; bewusst anders benannt, da Quickshell selbst schon ein eingebautes `DesktopEntries`-Singleton mitbringt) |
| `BarTheme.qml` | Theme für eine beliebige Bar: Farben live über `adapters/live/<Bar>Live.qml` (falls vorhanden), sonst/für Opacity+Radius+Keybinds+hasLauncher `adapters/<barname>.json` (+ Fallback) |
| `adapters/live/*.qml` | Pro Bar: liest deren echte Zustandsdatei(en) schreibgeschützt und bildet ihre Farblogik 1:1 nach |
| `ThemeAdapter.qml` | Singleton: `BarTheme`, fest an `BarsModel.activeBar` gebunden — das Menü-weite Theme |
| `BarsModel.qml` | Singleton: scannt `bars/`, liest/überwacht `active-bar`-Statusdatei |
| `SwitchState.qml` | Singleton: startet `switch-bar.sh`, parst Fortschrittszeilen, sammelt stdout/stderr (Fortschritt/Fehler in der Statuszeile) |
| `adapters/*.json` | Repräsentative Theme-Werte + Keybinds + `hasLauncher` pro Bar |
| `scripts/switch-bar.sh` | Kernlogik des Bar-Wechsels (siehe oben) |
| `scripts/bar-info.py` | Liest Überschrift + ersten Absatz jeder `bars/<name>/README.md` und optionale `preview.png` als JSON |
| `scripts/launchers.py` | Launcher-Zuweisungen: `info` (JSON fürs Menü), `resolve`, `keybinds`, `set` |
| `scripts/set-launcher.sh` | Launcher einer Bar zuweisen; bei aktiver Bar sofort wirksam |
| `scripts/launcher-host.sh` | Launcher-Hosts erzeugen/starten/beenden (`sync`, `start`, `run`, `stop`) |
| `scripts/widgets-host.sh` | salbeis Desktop-Widgets ohne salbei starten/beenden (`sync`, `stop`) |
| `scripts/try-launcher.sh` | „Ausprobieren“: Launcher öffnen, ohne ihn zuzuweisen |
| `scripts/mango-block.sh` | Schreibt den quickdots-Block in `config.conf` + Reload (von `switch-bar.sh` und `set-launcher.sh` genutzt) |
| `scripts/toggle-launcher.sh` | Ruft `menu ipc call launcher toggle` — Ziel des SUPER+Space-Binds |

## Bekannte Grenzen

- Farb-Theme ist live, aber nur für Bars mit eigenem
  `adapters/live/<Bar>Live.qml` (aktuell quickbar/shellbar/klasic). Eine
  neue Bar ohne eigenen Live-Reader zeigt die statischen Werte aus
  `adapters/<barname>.json` bzw. `_default.json`.
- shellbars Live-Pfad hängt von Quickshells `statePath`-Hashing
  (`md5(<shellDir>/shell.qml)`) ab — verschiebt/benennt sich
  `bars/shellbar/` selbst um, wird der Hash automatisch neu berechnet
  (kein hartkodierter Pfad), zeigt aber währenddessen kurz auf eine
  nicht mehr existente/alte Datei, bis shellbar einmal mit dem neuen Pfad
  gestartet wurde und seinerseits neu speichert.
- `qs list --all` aktualisiert sich nach einem `qs kill` mit minimaler
  Verzögerung (Prozess ist sofort tot, die Instanzregistrierung braucht
  bis zu ~1s). Rein kosmetisch, betrifft nur manuelles Debugging mit
  `qs list`, nicht die eigentliche Wechsel-Logik.
- **Jedes Feld in `adapters/<barname>.json` muss explizit gesetzt sein**,
  auch wenn der Wert dem Default entspricht (z. B. `"hasLauncher": false`).
  Quickshells `JsonAdapter` überschreibt beim Nachladen einer neuen Datei
  nur die Keys, die darin tatsächlich vorkommen -- fehlt ein Key, bleibt
  der zuletzt geladene Wert (von der vorherigen Bar!) einfach stehen. Bug
  dieser Art schon einmal passiert: `floating`/`klasic`/`_default` hatten
  anfangs kein `hasLauncher`, wodurch die App-Suche nach einem Wechsel
  weg von `quickbar`/`shellbar` fälschlich zugesperrt blieb.
- **Quickshell-0.3.1-Crash beim Zerstören von `BarTheme`**: wird ein Objekt
  mit `BarTheme` zerstört, während dessen `FileView`/`JsonAdapter` noch
  lädt, segfaultet Quickshell (`QJSEngine::create`). Deshalb hält die Liste
  im Tab „Bars“ alle Einträge am Leben (`cacheBuffer`) und `BarsModel`
  ersetzt `barNames` nur bei echter Änderung.
- **Verzeichnisse müssen von `shell.qml` aus importiert sein**: Quickshell
  registriert nur Typen aus Ordnern, die über `import` erreichbar sind.
  `steps/` und `tabs/` werden per URL geladen, stehen aber trotzdem als
  `import` in `shell.qml`, sonst findet `tabs/CustomTab.qml` die Typen in
  `custom/` nicht.
