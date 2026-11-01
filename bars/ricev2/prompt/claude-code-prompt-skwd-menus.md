# Claude Code Prompt: Skewed Menüs (Dropdowns, Launcher, Switcher, Power-Menü, Benachrichtigungen)

> Kopiere alles unterhalb der Linie in Claude Code. Dieser Prompt baut auf dem Bar-Prompt auf (`claude-code-prompt-skwd-bar.md`). Nutze dieselben `Colors.qml`, `Style.qml` und `Config.qml`. Passe die Werte in **[ECKIGEN KLAMMERN]** an.

---

Du baust mir mit **Quickshell (QML, Qt6)** die Menüs zu meiner Skewed-Topbar. Vorbild ist die Shell „skwd“ von liixini (https://github.com/liixini/skwd, MIT-Lizenz), genauer `skwd-bar/qml/bar/dropdowns`, `skwd-launch`, `skwd-switch`, `skwd-power` und `skwd-notification`. Halte dich exakt an die Zahlen unten. Wenn etwas unklar ist, klone das Repo und lies die entsprechende Datei nach, statt zu raten.

## Mein Setup

- Compositor: **[niri / Hyprland / Sway]**, Hauptmonitor: **[DP-1]**, Terminal: **[kitty]**
- Alles liegt in `~/.config/quickshell/skewbar/` neben der Bar. Launcher, Switcher und Power-Menü sollen **separat per IPC** umschaltbar sein.

## 0. Gemeinsame Grundregeln

- **Farben:** Material-You-Rollen aus `Colors.qml` (primary, tertiary, secondary, surface, surfaceContainer, surfaceVariant, outline, primaryText, backgroundText, surfaceText …). Niemals hart codierte Farben, außer da, wo unten ausdrücklich `rgba(…)` steht.
- **Fonts:** Text in **Roboto Condensed**, Bar-Icons in **Symbols Nerd Font**, große Menü-Icons und Filter in **Material Design Icons**.
- **Designsprache:** Parallelogramme und Trapeze mit schrägen Kanten, Überschriften in GROSSBUCHSTABEN, halbtransparente Flächen, keine Unschärfe.
- **Animationszeiten** (in `Style.qml` ergänzen): veryFast 100, fast 150, normal 200, enter 250, medium 300, expand 350, slow 400 ms.
- **Vollbild-Overlays** (Launcher, Switcher, Power-Menü): `PanelWindow` mit allen vier Ankern, `color: "transparent"`, `exclusionMode: ExclusionMode.Ignore`, Keyboard-Focus `Exclusive`, solange offen. Darunter liegt ein Dimmer: Rechteck `rgba(0,0,0, X)`, Opacity 0↔1 in 300 ms. Ein Klick auf den Dimmer schließt, `Esc` schließt ebenfalls.

---

## 1. Dropdown-Menüs der Bar

Alle Dropdowns haben dieses gemeinsame Gerüst:

- Breite 320 px (`contentWidth`), Innenbreite 320 − 24.
- Hintergrund `surface` @ **0.88**. Einzige Ausnahme ist das Benachrichtigungszentrum mit **0.92**.
- Radius: 0 im classic-Stil. Im pill-Stil 16, dabei obere Ecken 0.
- Die Höhe animiert von 0 auf Inhaltshöhe + 24 in **320 ms** mit BezierSpline `[0.05, 0.7, 0.1, 1.0, 1.0, 1.0]`.
- Unten sitzt eine **2 px Linie in primary**, deren Breite beim Öffnen in 300 ms (OutCubic) von 0 auf voll wächst. Das gilt nur im classic-Stil.
- Der Inhalt ist unten verankert (Margins 12 seitlich, 12 unten). Er wird erst sichtbar, wenn die Höhe über 50 % liegt: Opacity 0→1 und Translate y −15→0, beides 200 ms OutCubic.
- Abschnittsköpfe: GROSSBUCHSTABEN, **14 px DemiBold, primary**.
- Zeilen: Icon 12 px Nerd Font in primary (14 px breit, zentriert), Name 12 px Medium in backgroundText (120 px breit, Elide), Wert 12 px Medium in tertiary (32 px breit, rechtsbündig). Abstand in der Zeile 12 px.

### 1.1 Lautstärke

- Abschnitt „OUTPUT“: alle PipeWire-Sinks. Das Standardgerät bekommt das Icon U+F057E, alle anderen U+F0580. Ein Klick auf eine Zeile macht das Gerät zum Standard (`Pipewire.preferredDefaultAudioSink`).
- Abschnitt „INPUT“ (topPadding 8): alle Quellen. Standard U+F036C, andere U+F036D.
- Unter jeder Zeile liegt ein eigener **Slider**:
  - Höhe 14 px, Spur 4 px hoch, Radius 2, Farbe primary @ 0.18.
  - Füllung in primary.
  - Knopf 10×10 px, rund, primary, 1 px Rand in surface @ 0.85. Bei Hover oder Drag skaliert er auf 1.25 (120 ms OutCubic).
  - Die Klickfläche ist 6 px größer als der Slider. Während des Ziehens wird ein lokaler Wert angezeigt, damit nichts springt.

### 1.2 WLAN

- Kopf „WIFI“. Darunter die verbundene Zeile: Icon U+F0928, SSID in primary, Signal in tertiary (28 px breit).
- Trennlinie 1 px in primary @ 0.2.
- Unterüberschrift „AVAILABLE“ in 10 px tertiary. Während des Scans steht dort „Scanning...“ in 11 px tertiary.
- Netzwerkzeilen: Signal-Icon 12 px in tertiary, SSID 12 px in backgroundText, Signal/Sicherheit 11 px in tertiary. Bekannte Netze bekommen U+F0E1E in primary @ 0.7.
- **Passwort-Panel** (klappt beim Klick auf ein gesichertes Netz auf; Höhe = Inhalt × Opacity, 180 ms):
  - Rahmen: Radius 4, Farbe surfaceContainer @ 0.6, 1 px Rand in primary @ 0.45.
  - Label mit Schlüssel-Icon U+F0306 in 11 px primary.
  - Eingabefeld: 24 px hoch, Radius 3, Farbe surface @ 0.8, Rand primary @ 0.6. Platzhalter „Password“ in surfaceText @ 0.35.
  - **Signature-Detail:** Statt Punkten zeigt das Feld für jedes getippte Zeichen eine Form aus der Folge `⬢ ◆ ▲ ● ■ ⬟ ★` (11 px). Die Farben rotieren durch primary, tertiary, secondary. Jede neue Form ploppt auf: Scale 0.4→1.15 in 90 ms, dann →1.0 in 110 ms. Dahinter ein eigener Cursor, 1×12 px in primary. Das echte `TextInput` ist unsichtbar (`echoMode NoEcho`).
  - Buttons: 20 px hoch, Radius 3, Text 10 px. „CANCEL“ in outline mit Rand outline @ 0.4. „CONNECT“ in primary mit Text in surface.
  - Solange das Panel offen ist, holt sich die Bar exklusiven Tastaturfokus.
- Verbinden über `iwctl station [wlan0] connect <ssid>` mit Passphrase.

### 1.3 Bluetooth

Kopf „BLUETOOTH DEVICES“. Pro verbundenem Gerät eine Zeile mit Icon U+F00AF in primary, Name in backgroundText (120 px) und Akku in tertiary. Abstand 12, Spalten-spacing 10.

### 1.4 Kalender (öffnet sich über die Uhr)

- Kopfzeile 18 px hoch: links Pfeil U+F004D, rechts U+F0054, beide 14 px primary. In der Mitte `MMMM yyyy` in GROSSBUCHSTABEN, 14 px, primary.
- Beim Monatswechsel gleitet der Inhalt ±90 px zur Seite und blendet aus (180 ms). Dann gleitet der neue Monat von der anderen Seite herein.
- Wochentagszeile: 28 px breite Zellen, 11 px, primary @ 0.6, Woche beginnt am Montag.
- Tagesraster: 7 Spalten × 6 Zeilen, **Zellen 28×28 px, Abstand 2 px**. **Jede Zelle ist ein kleines Parallelogramm** (Schräge 4 px), gezeichnet per Canvas:
  - normal: Füllung surface @ 0.3, Rand primary @ 0.3 (1 px)
  - Hover: Füllung primary @ 0.15
  - heute: Füllung primary @ 0.3, Rand primary 1.5 px, Zahl in primary und **Bold**
  - Zahl sonst 12 px Medium in backgroundText
  - optionaler Termin-Punkt: 3×3 px, tertiary, 3 px über der Unterkante

### 1.5 Wetter

- Kopf: Pfeile wie beim Kalender (bei nur einer Stadt primary @ 0.25), Stadtname in GROSSBUCHSTABEN 13 px primary. Mit den Pfeilen wechselt man die Stadt, mit derselben Slide-Animation wie beim Kalender.
- „Jetzt“-Block: Wetter-Icon **40 px** in primary, Temperatur **30 px** in backgroundText, Beschreibung 12 px @ 0.75.
- Vorhersage: gleich breite Tageskarten nebeneinander (spacing 4), je **124 px hoch, Radius 8**. Die heutige Karte hat primary @ 0.12 als Füllung und 1 px Rand primary @ 0.35, alle anderen sind transparent.
- Karteninhalt (Margins 4, spacing 1):
  - Tag 10 px Medium
  - Icon 20 px primary
  - Höchstwert 11 px DemiBold
  - Tiefstwert 10 px tertiary @ 0.7
  - Regen (U+F058E + Menge, ab 0.1) und Wind (U+F059D + Wert), 11 px tertiary @ 0.85
- Datenquelle: **[wttr.in / Open-Meteo]**.

### 1.6 Benachrichtigungszentrum

- Kopf: „NOTIFICATIONS“ 14 px primary, daneben die Anzahl in 11 px tertiary @ 0.6. Rechts der Button „CLEAR ALL“: 22 px hoch, Radius 4, Text 10 px primary.
- Leerzustand: „No notifications yet this session.“ in 12 px tertiary @ 0.55.
- Einträge (ListView, spacing 6):
  - Karte mit Radius 6, surfaceContainer @ 0.55, Rand outline @ 0.15, Höhe Inhalt + 14
  - App-Name in GROSSBUCHSTABEN 10 px primary, Uhrzeit in tertiary @ 0.55, darunter Summary und Body
  - Jeder Eintrag lässt sich einzeln wegklicken. Der Verlauf liegt in `$XDG_RUNTIME_DIR/skwd/notifications.json`, weggeklickte Einträge in `notifications-dismissed.json`.

---

## 2. App-Launcher (Modus „slice“)

Das Herzstück: eine horizontale Reihe **schräger, überlappender Streifen**. Das ausgewählte Element klappt breit auf.

**Fenster:** `WlrLayer.Overlay`, Namespace `app-launcher-parallel`, Dimmer `rgba(0,0,0,0.5)`. Die Karte blendet in **400 ms OutCubic** ein.

**Maße (per Config änderbar):**

| Wert | Standard |
|---|---|
| sliceWidth (zu) | **135** |
| expandedWidth (ausgewählt) | **924** |
| sliceHeight | **520** |
| skewOffset | **35** |
| sliceSpacing | **−22** (Streifen überlappen) |
| visibleCount | **12** |
| roundCorners / cornerRadius | aus / 16 |

- ListView-Breite = expandedWidth + (visibleCount − 1) × (sliceWidth + spacing). Header und Footer sind je (Breite − expandedWidth)/2 breit, damit das ausgewählte Element **immer mittig** steht.
- Die Liste beginnt 50 + 15 px unter der Kartenoberkante, unten bleiben 20 px Abstand.

**Filterleiste oben:**

- Pille, 10 px unter der Oberkante, Breite Inhalt + 30, Höhe Inhalt + 14, Radius = Höhe/2, Farbe surfaceContainer @ 0.85. Abstand zwischen den Elementen 16.
- Filter-Buttons (spacing 4): je 32×24 px, Radius 4, Icon 14 px Material Design Icons.
  - Alle U+F0136, Apps U+F003B, Games U+F0297, Steam U+F04D3
  - ausgewählt: Füllung primary, Icon primaryText
  - Hover: surfaceVariant @ 0.5 und 1 px Rand primary @ 0.4
  - sonst transparent mit tertiary Icon
  - Farbwechsel 100 ms, Tooltip nach 500 ms
- Danach ein Trenner 1×20 px in primary @ 0.3, Such-Icon U+F0349 in 18 px tertiary und ein Suchfeld: 200 px breit, 14 px Medium, weiß, Platzhalter in primaryText @ 0.4. Rechts ein Hinweistext in 11 px primaryText @ 0.5.
- Während der App-Cache aufgebaut wird: Fortschrittsbalken 300×4 px, Radius 2, Spur `rgba(1,1,1,0.1)`, Füllung primary, Text 12 px tertiary mit letterSpacing 0.5.

**Ein Streifen (SliceDelegate):**

- **Form:** Parallelogramm. Oben links bei x = 35, oben rechts bei w, unten rechts bei w − 35, unten links bei 0. Die Kanten lehnen sich also nach rechts. Mit Eckenradius werden die Ecken per `PathQuad` gerundet.
- Bild und Farbfläche werden mit **MultiEffect-Maske** auf diese Form beschnitten (`maskThresholdMin 0.3`, `maskSpreadAtMin 0.3`). Auch die Klickfläche folgt exakt der Schräge (`containmentMask`).
- **Inhalt:**
  - Hintergrundbild der App (Splash oder Steam-Artwork) mit PreserveAspectCrop
  - sonst das App-Icon zentriert (Pad), bei Steam gecroppt
  - sonst ein Glyph in 48 px primary @ 0.7 auf surfaceVariant @ 0.8
- **Abdunkelung:** Schwarz @ 0.4, bei Hover 0.15, ausgewählt 0 (200 ms).
- **Rand:** ausgewählt 3 px primary, Hover 1 px primary (halbtransparent), sonst 1 px `rgba(0,0,0,0.6)`.
- **Schatten:** schwarze Kopie der Form dahinter. Ausgewählt 4/10 px versetzt mit Opacity 0.5, sonst 2/5 px mit 0.3 (200 ms).
- **Breite:** ausgewählt 924, sonst 135, animiert **350 ms OutCubic**.
- **z-Reihenfolge:** ausgewählt 100, Hover 90, sonst 50 − Abstand zum ausgewählten Index.
- **Rand-Fade:** Streifen werden zum Rand hin transparent. Voll sichtbar bis zu einem normierten Abstand von max. 0.6 vom Zentrum, danach linear bis 1.2 auf 0.
- **Namensschild** (bei Auswahl oder Hover, 16 px über dem unteren Rand, zentriert): 22 px hoch, Radius 11, `rgba(0,0,0,0.75)`, Rand primary @ 0.4. Name in GROSSBUCHSTABEN, 11 px Bold, letterSpacing 0.5, tertiary. Einblenden in 150 ms.
- **Interaktion:**
  - Mausbewegung über einen Streifen wählt ihn aus, aber erst bei mehr als 2 px Bewegung, damit ein ruhender Cursor die Tastaturnavigation nicht stört.
  - Klick auf einen ausgewählten Streifen startet die App, auf einen anderen wählt ihn aus.
  - ←/→ und Mausrad blättern, Enter startet, Esc schließt. Tippen landet immer im Suchfeld.
- **Listen-Übergänge:** neue Elemente Opacity 0→1 und Scale 0.85→1 (250 ms). Entfernte Elemente Opacity →0 (200 ms InCubic). Verschieben x/y in 300 ms.

**Alternative Modi (optional, per Config `displayMode`):**

- **hex:** Waben mit Radius 140, 3 Zeilen × 7 Spalten, Abstand 6 px. Die Spalten folgen einem Bogen (Intensität 1.2). Übergänge wie oben mit Scale 0.9→1.
- **grid:** 6 × 3 Kacheln à 300×169 px, Radius 6, Abstand 8, Farbe surfaceContainer @ 0.85. Bei Hover 2 px Rand in primary, Abdunkelung 0.4 → 0.15. Name 10 px Bold weiß.

---

## 3. Fenster-Switcher (Alt+Tab)

**Fenster:** Overlay, Namespace `window-switcher-parallel`, Dimmer 0.5, Einblenden 400 ms. Kartenbreite 1600, Höhe = sliceHeight + 40.

**Modus „slice“** verwendet dieselben Maße wie der Launcher (135 / 924 / 520 / Schräge 35 / spacing −22 / 12 sichtbar), mit diesen Unterschieden:

- **Hintergrund:** vertikaler Verlauf von surfaceContainer nach surface statt Bild, Abdunkelung 0.4 → 0 bei Auswahl.
- **Icon:** App-Icon 96 px, 20 px über der Mitte. Bei Glyph-Fallback ausgewählt in primary, sonst tertiary @ 0.5 (200 ms).
- **Schatten:** Canvas mit drei gestapelten schwarzen Parallelogrammen, Versatz ×1 / ×0.6 / ×1.4 und Alpha ×0.5 / ×0.3 / ×0.2. Basisversatz ausgewählt 4/10 mit Alpha 0.6, sonst 2/5 mit 0.4.
- **Rand:** ausgewählt 3 px primary, sonst 1 px schwarz @ 0.6.
- **Badges** (je `rgba(0,0,0,0.75)`, 1 px Rand primary @ 0.4, 9 px Bold, letterSpacing 0.5):
  - oben links, 10 px unter der Oberkante, eingerückt um Schräge + 6: „FOCUSED“ als Pille, 20 px hoch, Radius 10, in primary mit primaryText, nur beim fokussierten Fenster
  - unten rechts: „WS 3“ (16 px hoch, Radius 4, tertiary)
  - unten links: „FLOAT“ bei schwebenden Fenstern
- **Namensschild** (nur ausgewählt, 40 px über dem unteren Rand): Radius 6, `rgba(0,0,0,0.75)`, Rand primary @ 0.5. App-Name in GROSSBUCHSTABEN 13 px Bold primary, darunter der Fenstertitel in 11 px weiß @ 0.6 (max. 60 Zeichen, dann „…“).
- **Rand-Fade** über 1.5 × sliceWidth, 200 ms OutQuad.
- Ohne Fenster: „NO WINDOWS“, 18 px Bold, letterSpacing 2, outline.
- **Steuerung:** `open` öffnet und springt direkt zum zweiten Fenster, `next`/`prev` blättern, `confirm` fokussiert, `cancel` schließt ohne Auswahl, `close` beendet das ausgewählte Fenster. Die Fensterliste kommt von **[niri msg -j windows / hyprctl clients -j]**.

**Modus „wheel“ (optional):**

- Ring mit Außenradius 320 und Innenradius 90, Start bei −90° (oben). Jedes Fenster ist ein Ringsegment mit 4° Lücke, gefüllt mit surfaceContainer @ 0.85 und 1 px Kontur schwarz @ 0.45.
- Das ausgewählte Segment liegt als Overlay darüber: primary @ 0.85 mit 2 px Rand primary, einblenden in 220 ms.
- Icons 80 px auf dem Mittelradius (0.85 Opacity, ausgewählt 1.0). Fokussierte Fenster bekommen einen 8 px Punkt in primary oben rechts.
- **Nabe in der Mitte:** Kreis (2 × Innenradius − 8), surface @ 0.96, 2 px Rand primary. Darin der App-Name (14 px Bold primary), eine Linie (60 % Breite, primary @ 0.4) und der Titel (10 px weiß @ 0.7).
- Die Auswahl folgt dem Winkel der Maus.

**Modus „grid“ (optional):** 5 × 4 Zellen à 240×170 px, Abstand 14, Icon 64 px, Radius 10.

---

## 4. Power-Menü

- **Fenster:** auf **allen** Monitoren (`Variants`), Namespace `powermenu`, `WlrLayer.Top`. Dimmer **0.45** und darunter eine fast unsichtbare Fläche `rgba(0,0,0,0.01)`, die Klicks abfängt. Die Karte ist nur auf dem Hauptmonitor sichtbar und erscheint 50 ms nach dem Öffnen.
- **Karte** 1200×380 px, zentriert. Die Optionen stehen in einer Reihe mit **spacing 80**.
- **Jede Option:** 220×320 px. Spalte (spacing 24) aus:
  - riesigem Icon **216 px** (Symbols Nerd Font) mit weichem Schatten (MultiEffect: `rgba(0,0,0,0.5)`, Blur 0.8, y-Versatz 2)
  - Label **24 px Bold**
- **Farben:** ausgewählt in primary, sonst tertiary (150 ms). Bei Hover skaliert das Icon auf 1.1 (150 ms OutCubic). Hover wählt auch aus.
- **Standard-Optionen:**
  - Lock U+F033E → `loginctl lock-session`
  - Logout U+F0343 → Compositor beenden (**[niri msg action quit / hyprctl dispatch exit]**)
  - Reboot U+F0709 → `systemctl reboot`
  - Poweroff U+F0425 → `systemctl poweroff`
  - Alle Optionen sind per Config überschreibbar (Label, Icon, eigener Befehl, `enabled`).
- **Tastatur:** ←/→ wählt, Enter führt aus, Esc schließt. Beim Öffnen ist immer die erste Option ausgewählt.

---

## 5. Benachrichtigungs-Popups (eigener Notification-Daemon)

- Quickshell `NotificationServer` mit Actions. Popups in einem eigenen `PanelWindow` oben rechts (per Config auch links), `WlrLayer.Overlay`, Namespace `skwd-notifications`, ohne Tastaturfokus.
- **Maße:** Breite **320**, Abstand 16 zum Rand, 12 nach oben, Karten-spacing 8, **max. 4 sichtbar**, Standard-Ablauf **5000 ms**. Das Timeout der Notification hat Vorrang. Bei Hover pausiert der Timer.
- **Kartenform:** Trapez mit **Schräge 28**, derselben wie die Bar. Rechts angedockt: (0,0) → (w−28,0) → (w,h) → (28,h). Links angedockt gespiegelt. Füllung surface @ **0.92**.
- **Signature-Detail:** Beim Erscheinen **zeichnet sich ein 2 px primary-Rand um die Form**. Der Strich läuft über den Umfang von 0 auf 100 % (600 ms OutCubic, `lineCap round`), gezeichnet per Canvas segmentweise über die vier Kanten.
- **Einblenden:** Opacity 0→1 und Slide x ±40→0, beides 350 ms OutCubic.
- **Schließen:**
  1. Opacity →0 und Slide →±40 (250 ms InCubic)
  2. danach Höhe →0 (180 ms InOutCubic), damit die übrigen Karten nachrutschen
  3. dann `dismiss()`
- **Inhalt** (seitlich um Schräge + 4 eingerückt, Margins 10, spacing 4):
  - Kopfzeile (spacing 6): App-Name 12 px Medium in primary, „·“ in outline, Summary 12 px Medium in tertiary (Elide), rechts „✕“ 12 px in outline, bei Hover primary
  - Body: 12 px in surfaceVariantText, max. 3 Zeilen
  - Action-Buttons: Pillen, 22 px hoch, Radius 11, Text 11 px Medium. Normal secondaryContainer @ 0.5 mit tertiary Text, bei Hover primary mit onPrimary-Text.
- Ein Klick auf die Karte schließt sie.
- Jede Notification wird zusätzlich in `$XDG_RUNTIME_DIR/skwd/notifications.json` geschrieben (Felder: ts, appName, summary, body, timeText; max. 200 Einträge), damit das Benachrichtigungszentrum der Bar sie anzeigen kann.

---

## 6. IPC & Keybinds

Stelle für jede Komponente einen `IpcHandler` bereit:

- `launcher toggle`
- `switch open|next|prev|confirm|cancel|close`
- `power toggle`

Liefere mir die fertigen Keybinds für meinen Compositor, z. B. für niri:

- `Mod+Space` → Launcher
- `Mod+Escape` → Power-Menü
- `Alt+Tab` / `Alt+Shift+Tab` → Switcher open/prev
- `Alt+Return` → confirm
- `Alt+Escape` → cancel
- `Alt+C` → close

## Vorgehen

1. Plan und Dateiliste zeigen, dann in dieser Reihenfolge bauen: Dropdown-Gerüst und Lautstärke → restliche Dropdowns → Benachrichtigungen → Power-Menü → Launcher → Switcher.
2. Nach jedem Schritt `qs -c skewbar` starten, das Log auf QML-Fehler prüfen, beheben und mich per Screenshot vergleichen lassen.
3. Keine Werte „verschönern“. Die Zahlen oben sind gewollt. Wenn eine Quickshell-API anders heißt als erwartet, lies die Doku bzw. den skwd-Quellcode nach.
