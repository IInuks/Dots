# blobball

Ein weicher, animierter Blob, der frei über deinem Desktop schwebt. Du kannst
ihn mit der Maus greifen und durch die Gegend werfen -- er prallt elastisch
an den Bildschirmrändern ab und kommt sauber zur Ruhe. Zwei Augen verfolgen
deine Maus -- unter dem wirbel-Compositor überall auf dem Bildschirm, sonst
nur in seiner Nähe; außerhalb davon schauen sie von selbst umher. Form, Größe, Physik und Farbe stellst du im Tab **Blob** des
quickdots-Menüs ein (`../menu`, siehe unten). blobball hat kein eigenes
Menü mehr.

Läuft als [Quickshell](https://quickshell.outfoxxed.me/)-Konfiguration auf
dem [mango](https://github.com/DreamMaoMao/mango)-Compositor (NixOS/Wayland).

## Benutzung

**Blob greifen & werfen**
Mit der Maus auf dem Blob klicken, halten, bewegen, loslassen -- er fliegt
mit der Wurfgeschwindigkeit weiter und prallt an den Bildschirmkanten ab.

**Steinschleuder (rechte Maustaste)**
Rechte Maustaste auf dem Blob gedrueckt halten -- er bleibt an Ort und Stelle
stehen (Anker) und laesst sich nur noch ziehen, nicht mehr frei bewegen. Beim
Ziehen streckt er sich sichtbar wie ein Gummiband in Zugrichtung (bis zu einem
Zug-Radius von 220px). Loslassen schiesst ihn in die dem Zug entgegengesetzte
Richtung ab -- je weiter gezogen, desto schneller der Schuss --, danach gilt
wieder die normale Wurf-/Abprallphysik.

**Einstellungen (quickdots-Menü, Tab „Blob“)**
Tastenkombination `Strg + rechte Umschalttaste` (Shift_R) öffnet das
quickdots-Menü direkt auf dem Tab „Blob“ (`qs -p ../menu ipc call wizard
blob`). Ist das Menü schon offen, wechselt sie nur auf diesen Tab. Jede
Änderung wird sofort nach `~/.local/state/quickshell/blob.json` geschrieben,
und blobball lädt die Datei live nach. Ein „Anwenden“ gibt es nicht. Solange
das Menü offen ist, blendet sich der Blob aus (beide liegen auf dem
Overlay-Layer; das Menü meldet das per `ipc call menu opened/closed`). Links
im Tab siehst du eine Live-Vorschau. Dazu kommen „Starten“ (falls blobball
nicht läuft), „Test-Nachricht“ und „Standard“ (setzt alles zurück).

**Optionen:**

| Regler | Wirkung |
|---|---|
| Sichtbar | Blob ein-/ausblenden |
| Form | Kreis, abgerundetes Quadrat, Squircle oder organische Blob-Form |
| Größe | 40--240 px, mit Live-Vorschau |
| Restitution (Abprall) | wie stark der Blob beim Aufprall abbremst (0 = klebt fest, 1 = prallt fast verlustfrei ab) |
| Schwerkraft | Blob fällt nach unten statt frei zu schweben |
| Wabbeligkeit | Staerke von Aufprall-Squash, Atem-Wobble und organischem Wabern (0 = starr, 1 = Standard, 2 = stark uebertrieben) |
| In Ecke fliegen, wenn inaktiv | Blob gleitet nach der Wartezeit selbststaendig in eine Bildschirmecke |
| Wartezeit bis Ecke | Sekunden Stillstand, bevor der Abflug ausgeloest wird (0--30s, 0 = quasi sofort) |
| Ecke (5 Icons) | welche Ecke angeflogen wird: automatisch die naechstgelegene, oder fest eine der vier Ecken |
| Sicherheitsabstand oben (Bars) | Freiraum am oberen Bildschirmrand, den der Blob beim Ruhen/Ziehen/Ecken-Anflug nicht mehr betritt (0--120px, Standard 44px = Hoehe der aktuell aktiven Bar) -- verhindert, dass er in den oberen Ecken unter eine dort sitzende Bar rutscht |
| Farbe | sechs Farben zum Durchklicken (manuelle Farbe, siehe "Adaptives Theme") |
| Adaptives Theme | faerbt den Blob (und die Nachrichten-Flaeche) statt in der oben gewaehlten Farbe live in der Akzentfarbe des aktuellen Wallpapers (`awww query` + ColorQuantizer, pywal nur als Rückfall) |
| Schrift (Auto/Schwarz/Weiß) | Schriftfarbe in der Nachrichten-Flaeche: "Auto" errechnet sie aus der Helligkeit des jeweiligen Hintergrunds, "Schwarz"/"Weiß" erzwingen eine feste Farbe -- noetig, weil ein adaptives Theme einen beliebig hellen oder dunklen Hintergrund ziehen kann |

Alle Einstellungen werden sofort gespeichert (in
`~/.local/state/quickshell/blob.json`) und beim nächsten Start wieder geladen.

**Nachricht anzeigen**
Der Blob kann per IPC eine Nachricht anzeigen -- er streckt sich dafuer an
Ort und Stelle zu einer abgerundeten Flaeche ("wird zur Nachricht") und zeigt
den Text darin, statt einer Sprechblase daneben. Nach einigen Sekunden
(laenger bei mehr Text) zieht er sich von selbst wieder zum normalen Blob
zusammen -- ohne dass man klicken muss:

```sh
qs -p ~/quickdots/blobball ipc call -- notify show "Dein Text hier"
qs -p ~/quickdots/blobball ipc call -- notify clear   # sofort ausblenden
```

> **Hinweis zum `--`:** Quickshells `ipc call` braucht das `--` vor
> Ziel/Funktion/Argumenten, sobald ein Funktionsargument mitgegeben wird --
> ohne `--` bricht das CLI11-Parsing mit "The following argument was not
> expected" ab (Version 0.3.0, getestet).

**Nachrichten-Verlauf & ungelesen-Zähler**
Jede per `notify show` angezeigte Nachricht landet zusätzlich in einem
Verlauf. Solange ungelesene Nachrichten da sind, zeigt der Blob oben rechts
ein kleines rotes Badge mit der Anzahl. Ist der Blob gerade selbständig in
eine Ecke geflogen (siehe "In Ecke fliegen, wenn inaktiv" im Tab „Blob“) und liegt
dort noch unbewegt, streckt ihn ein einfacher Klick darauf (ohne zu ziehen)
zur selben Flaeche wie oben -- diesmal aber mit dem ganzen Verlauf, und sie
bleibt offen, bis man erneut darauf tippt (kein Auto-Schliessen). Alle
Nachrichten gelten dabei sofort als gelesen, das Badge verschwindet. Ein
echter Wurf (Klicken + Ziehen) funktioniert an der Ecke weiterhin normal --
und solange sich der Blob bewegt, oeffnet ein Klick nichts.

Der Verlauf lässt sich auch ohne Klick in der Ecke ansteuern:

```sh
qs -p ~/quickdots/blobball ipc call -- messages open
qs -p ~/quickdots/blobball ipc call -- messages close
qs -p ~/quickdots/blobball ipc call -- messages toggle
```

Der Verlauf ist wie die Vorschau bewusst nur In-Memory (nicht auf Platte
gespeichert) -- ein Neustart von Quickshell leert ihn.

Im geoeffneten Verlauf sitzt oben rechts neben der Ueberschrift ein
"Löschen"-Knopf (nur sichtbar, wenn ueberhaupt Nachrichten da sind), der den
kompletten Verlauf leert (`Message.clearHistory()`). Die Nachrichten-Flaeche
selbst ist bewusst in `Settings.blobColor` eingefaerbt statt in einer
eigenen Menue-Farbe -- sie soll wie der verformte Blob selbst aussehen,
nicht wie ein Menue, das ihn ersetzt.

## Installation

**Schnelltest, ohne etwas zu installieren:**

```sh
nix develop ~/quickdots/blobball   # oder: nix-shell -p quickshell qt6.qtdeclarative
qs -p ~/quickdots/blobball -n
```

**Dauerhaft über Home-Manager:**

```nix
imports = [ ~/quickdots/blobball/home-manager-module.nix ];
```

Installiert `quickshell` und legt die Config nach
`~/.config/quickshell/blob/`. Läuft danach auch als `qs -c blob`.

**Autostart + Tastenkombination in mango:**
Ist bei dir bereits eingetragen in `~/.config/mango/config.conf`:

```conf
# Autostart
exec-once=qs -p ~/quickdots/blobball -n &

# Einstellungen: quickdots-Menü auf dem Tab "Blob"
bind=CTRL,Shift_R,spawn,qs -p ~/quickdots/menu ipc call wizard blob
```

Für eine andere Maschine/einen anderen Nutzer: Pfad anpassen, oder nach
Home-Manager-Deploy `-p ~/quickdots/blobball` durch `-c blob`
ersetzen (Config wird dann über den Namen statt über den Pfad gefunden).

> **Hinweis zu `CTRL,Shift_R`:** Eine Tastenkombination, bei der die "Taste"
> selbst ein Modifier ist (hier: die rechte Umschalttaste), wird nicht von
> jedem Compositor gleich zuverlässig erkannt. Sollte der Hotkey bei dir
> nicht auslösen, in der `bind=`-Zeile oben stattdessen
> `CTRL+SHIFT,space` verwenden -- das ist der getestete Fallback.

## Für Entwickler

### Dateistruktur

```
shell.qml                ShellRoot, IpcHandler ("menu" = opened/closed vom quickdots-Menü, "notify", "messages")
Settings.qml              Singleton: liest blob.json (FileView/JsonAdapter, watchChanges -> live), geschrieben wird sie von menu/BlobStore.qml
Message.qml                Singleton: transienter Nachrichten-Zustand + -Verlauf/Ungelesen-Zaehler fuer die "notify"-IPC (nicht persistiert)
Theme.qml                   Singleton: Akzentfarbe aus dem aktuellen Wallpaper (awww + ColorQuantizer, schreibt ~/.cache/blobball/accent fuers Menue) fuers adaptive Blob-Theme + textColorFor()-Helfer
BlobWindow.qml             Layer-Shell-Fenster, Input-Maske, Drag-MouseArea (inkl. Klick-vs-Wurf-Erkennung an der Ecke), FrameAnimation-Ticker, Ungelesen-Badge, Nachrichten-Flaeche (der Blob verformt sich in-place, kein eigenes Fenster)
Blob.qml                   Darstellung: 4 Formen + alle Animationen (inkl. Wabbeligkeits-Skalierung)
Physics.qml                Reine Integration/Kollision/Wurfgeschwindigkeit/Ecken-Anflug/Steinschleuder (kein Fenster-Wissen)
flake.nix                   devShell mit quickshell + qt6-Tooling
home-manager-module.nix     installiert quickshell, legt Config nach ~/.config/quickshell/blob/
```

### Bewusste Entscheidungen

- **Einstellungen leben im quickdots-Menü, nicht mehr in blobball.**
  Früher hatte blobball ein eigenes kleines Menüfenster (`Menu/`). Seit
  2026-10-05 ist das ein Tab im quickdots-Menü (`menu/steps/BlobStep.qml`,
  `menu/BlobStore.qml`). Die beiden Prozesse teilen sich nur `blob.json`:
  Das Menü schreibt sie als Einziger, blobball beobachtet sie
  (`watchChanges`) und lädt sie neu. Die Vorschau im Tab nutzt dieselbe
  `Blob.qml` (Symlink `menu/components/Blob.qml`), sie sieht also exakt
  aus wie der echte Blob. Das alte Menü liegt noch in
  `../blobball.bak-2026-10-05/Menu/`.
- **Sicherheitsabstand oben ist ein fester, im Menü einstellbarer Wert
  (`Settings.barMargin`), keine automatische Bar-Erkennung.** `BlobWindow`
  setzt `WlrLayershell.exclusionMode: ExclusionMode.Ignore` und spannt
  bewusst den ganzen Bildschirm auf (siehe "Ein Blob, ein Bildschirm"
  unten) -- er kennt die `exclusiveZone` anderer Layer-Shell-Clients
  (z.B. der Bar aus `bars/claude`, aktuell 44px hoch, volle Breite) also
  grundsätzlich nicht. Ein direkter Import von deren `Metrics`-Singleton
  wäre zudem ein sideways-Import zwischen Geschwister-Verzeichnissen
  (`blobball` → `bars/claude`, kein reiner `..`-Elternketten-Pfad) und
  würde nach `feedback_quickshell_singleton_cross_dir_import` alle
  Properties nur still auf `undefined` auflösen, ganz ohne Fehler. Deshalb
  ein einfacher, manuell im Menü nachziehbarer Wert (Standard = aktuelle
  Bar-Höhe) statt einer fragilen Cross-Dir-Abhängigkeit -- wirkt auf
  Ruheposition, Ziehen und Ecken-Anflug gleichermaßen (`Physics.qml`,
  `topMargin`).
- **Schriftfarbe (Auto/Schwarz/Weiß) ist ein manueller Override, kein
  reines Auto-Kontrast-System.** "Auto" errechnet Schwarz/Weiß aus der
  Helligkeit des jeweiligen Hintergrunds (`Theme.textColorFor`); ein
  aktiviertes adaptives Theme kann aber einen beliebig hellen oder
  dunklen Hintergrund aus dem Wallpaper ziehen, auf dem die automatische Wahl
  nicht immer der Geschmack ist -- deshalb bleibt eine feste Übersteuerung
  wählbar.
- **Ein Blob, ein Bildschirm.** `BlobWindow` bindet sich an
  `Quickshell.screens[0]` statt per `Variants` eine Instanz pro Monitor zu
  erzeugen. Eine Wayland-Layer-Shell-Surface kann ohnehin nicht über mehrere
  Outputs hinweg existieren; mehrere Instanzen würden aus "einem" Blob
  mehrere unabhängige Bälle machen. Welcher Bildschirm das ist, lässt sich
  in `BlobWindow.qml` (`screen:`-Zeile) ändern.
- **Input-Maske für eckige/organische Formen ist eine Annäherung.**
  Wayland-Layer-Shell-Regionen kennen nur Rechteck oder Ellipse
  (`RegionShape`-Enum in Quickshells eigenen `.qmltypes`). Kreis bekommt eine
  echte Ellipsen-Maske; die anderen drei Formen bekommen ein abgerundetes
  Rechteck mit passendem Rundungsradius (`BlobWindow.qml`, `_maskRadius`).
  Optisch minimal ungenauer an den Rändern der organischen Form, praktisch
  nicht spürbar.
- **"Morphing" zwischen Formen = Crossfade + Pop, kein Pfad-Morphing.**
  Kreis/Quadrat sind `Rectangle`s, Squircle/organisch sind `Shape`s mit
  generiertem `PathSvg`. Eine punktgenaue Interpolation zwischen so
  unterschiedlichen Geometrien bräuchte einen eigenen Geometrie-Interpolator;
  stattdessen blendet `Blob.qml` zwischen vier vorgefertigten Varianten über
  und spielt einen kurzen Einzieh-Federn-"Pop" ab (`_shapePop`).
- **Augen sind eine bewusste Ausnahme vom ursprünglichen "keine Gesichter"-
  Nicht-Ziel.** Auf expliziten Wunsch nachträglich hinzugefügt; alle anderen
  Nicht-Ziele (kein Füttern, kein Spielen etc.) gelten unveraendert weiter.
- **Augen-Tracking nur in einer Erkennungszone um den Blob, nicht
  bildschirmweit.** Eine Wayland-Layer-Shell-Surface bekommt Pointer-Events
  (auch reine Bewegung ohne Klick) nur innerhalb ihrer eigenen Input-Region --
  es gibt kein "nur Hover, Klicks durchlassen". Eine bildschirmweite
  Input-Region wuerde also *jeden* Klick auf dem Desktop schlucken, solange
  der Blob laeuft. Deshalb ist die Input-Region (`BlobWindow.qml`,
  `eyeZone`/`_eyeDetectRadius`) nur maessig groesser als der Blob selbst
  (Blob-Radius + 170px) -- die Augen reagieren schon, bevor die Maus den Blob
  beruehrt, aber nur in einem begrenzten Umkreis. Als Nebeneffekt gilt dieser
  ganze Umkreis jetzt auch als Greiffläche zum Wegwerfen (nicht nur die
  sichtbare Blob-Form), was das Greifen eher erleichtert als stoert. Ausserhalb
  der Zone schauen die Augen von selbst zufaellig umher (`Blob.qml`,
  `_lookX`/`_lookY`-Idle-Timer) statt starr geradeaus zu stehen.
  **Ausnahme wirbel:** Laeuft blobball unter dem eigenen Compositor wirbel,
  liest `BlobWindow.qml` (`_globalPointer`) die globale Zeigerposition aus
  `wirbel pos loop xy 1` und die Augen folgen dem Cursor bildschirmweit, ohne
  die Input-Region zu vergroessern. Fehlt wirbel (z.B. unter mango), endet der
  Prozess sofort, alle 5s gibt es einen neuen Versuch, und es bleibt beim
  Verhalten mit Erkennungszone.
- **Kein eigener `org.freedesktop.Notifications`-Server.** Fuer "der Blob
  zeigt eine Nachricht" waere ein echter Notification-Server
  (`Quickshell.Services.Notifications`) die naheliegende Wahl gewesen -- der
  D-Bus-Name ist auf diesem System aber bereits von einer anderen laufenden
  Quickshell-Instanz belegt (`bars/claude`, per `busctl --user list`
  verifiziert). Ein zweiter Bewerber wuerde entweder den Namen nicht bekommen
  oder dem bestehenden System-Notification-Weg in die Quere kommen. Deshalb
  zeigt der Blob Nachrichten stattdessen ueber eine eigene IPC-Funktion
  (`notify show <text>`, siehe `Message.qml`) -- eine externe Stelle (Skript,
  Keybind, oder ein Hook in der bestehenden Notifications-Bar) muss die
  gezielt aufrufen.
- **Ecken-Anflug ist ein eigenes Ease-out, keine Wiederverwendung der
  Wurf-Physik.** Ein mit `Physics.step()`s elastischer Kollision "geworfener"
  Blob (Restitution < 1) landet nicht zuverlaessig exakt in einer Ecke --
  er wuerde mehrfach abprallen und irgendwo dazwischen zur Ruhe kommen.
  `flyToCorner()`/`stepToCorner()` bewegen `posX`/`posY` deshalb direkt per
  Exponential-Ease-Out auf die naechstgelegene Ecke zu, unabhaengig von
  Restitution/Schwerkraft/Luftwiderstand (`Physics.qml`).
- **Steinschleuder nutzt dieselbe `MouseArea` wie Greifen/Werfen, nur mit
  `acceptedButtons: Qt.LeftButton | Qt.RightButton` und Verzweigung nach
  `mouse.button`.** Eine zweite, ueberlappende MouseArea fuer Rechtsklick
  haette mit der bestehenden um Events konkurriert. Da die rechte Taste jetzt
  explizit akzeptiert wird, synthetisiert Qt beim Loslassen kein
  Kontextmenue-Event mehr -- relevant, weil genau das (`maybeSynthesizeContextMenuEvent`)
  in einer anderen Quickshell-Instanz (`bars/claude`) bereits einmal einen
  Qt-Bug ausgeloest hat (siehe Abschnitt "Was automatisiert getestet wurde").
  Anker/Zug/Abschuss leben komplett in `Physics.qml`
  (`beginSlingshot`/`updateSlingshot`/`endSlingshot`) als reine Zahlen, der
  Gummiband-Stretch (`Blob.qml`, `pullX`/`pullY`) ist rein optisch und
  unabhaengig davon.

### Entwickeln

Nach Änderung an einer **bestehenden** Datei reicht Hot-Reload. Nach einer
**neuen** Datei muss der Prozess komplett neu gestartet werden (`kill <pid>`
+ neu starten) -- Quickshell 0.3.0 übernimmt neue Dateien in einem laufenden
Config-Verzeichnis nicht zuverlässig ins Rendering (lädt fehlerfrei, zeigt
aber nichts).

### Was automatisiert getestet wurde (und wie)

Diese Umgebung hat kein Tool, das einen echten Maus-Drag (Press-Halten-Move-
Release) oder einen rohen Tastendruck wie Escape/Shift_R simulieren kann
(`wlrctl pointer click` ist atomar, `wlrctl keyboard type` tippt nur
druckbare Zeichenketten). Getestet wurde deshalb:

- Layer-Shell-Fenster erscheint, ist transparent, lässt Klicks außerhalb des
  Blobs durch (Screenshot-Vergleich).
- Physik: Wurf + Abprall + sauberes Zur-Ruhe-Kommen, mit und ohne Schwerkraft
  (per Debug-Startgeschwindigkeit ausgelöst, per Screenshot-Serie verifiziert,
  danach wieder entfernt -- kein Debug-Code im Endstand).
- Alle vier Formen rendern korrekt, keine QML-Fehler/Warnungen im Log.
- Augen: rendern korrekt auf allen vier Formen, Pupillen sind sichtbar aus
  der Mitte verschoben wenn die Maus in der Naehe ist (Screenshot-Vergleich).
  Das exakte Verfolgen der Mausrichtung in Echtzeit liess sich nicht
  zuverlaessig automatisiert verifizieren, weil in dieser Session ein
  Vollbild-Spiel mit Pointer-Lock im Vordergrund lief -- `wlrctl pointer
  move` schickt nur relative Bewegungen, die von einer Pointer-Constraint
  ueberschrieben/verworfen werden koennen. Die deklarative Bindung selbst
  (`mouseArea.mouseX/mouseY` relativ zur Zonenmitte, geclamped auf -1..1) ist
  einfacher Standard-Qt-Quick-Code ohne exotische Fallstricke.
- Menü öffnen/schließen/toggle über IPC (`qs ipc call menu ...`).
- Klick außerhalb des Menüs schließt es (per `wlrctl pointer move` + `click`
  auf eine Position außerhalb der Karte verifiziert).
- Nachricht per `notify show`-IPC: Sprechblase erscheint mit Text, Blob
  verformt sich (Screenshot direkt nach dem Call). Menü zeigt die drei neuen
  Regler (Wabbeligkeit, In-Ecke-fliegen-Toggle, Wartezeit-Slider) mit
  korrekt geladenen Werten aus einer bereits bestehenden, die neuen Felder
  noch nicht enthaltenden Settings-Datei.
- Ecken-Anflug: Blob startet zentriert, `idleToCornerEnabled` + kurze
  `idleToCornerDelay` per Settings-Datei gesetzt, Prozess neu gestartet --
  Screenshot direkt nach dem Start (noch zentriert) vs. nach der Wartezeit
  (in der Ecke, mit Landungs-Squash) verglichen.

**Nicht automatisiert verifiziert:**
- Echtes Ziehen des Blobs mit gehaltener Maustaste.
- Escape schließt das Menü.
- Der `CTRL,Shift_R`-Hotkey selbst.
- Ein echter Klick auf die neuen Menü-Regler selbst (Toggle/Slider) --
  `wlrctl pointer move` sendet nur relative Bewegungen, ein Klick auf eine
  absolute Position im Menü liess sich damit nicht zuverlaessig treffen
  (siehe Kommentar oben zum Augen-Tracking-Test). Die Werte wurden
  stattdessen direkt in `blob.json` gesetzt und ihre Wirkung ueber echtes
  Prozessverhalten verifiziert -- die Regler selbst nutzen exakt dieselben
  `ToggleRow`/`SliderRow`-Komponenten wie die laengst funktionierenden
  Restitution/Schwerkraft-Regler.
- Ein echter Klick auf den neuen "Löschen"-Knopf im Nachrichten-Verlauf --
  gleiche `wlrctl`-Einschraenkung wie bei den Menü-Reglern oben. Visuell per
  Screenshot verifiziert (Blob-farbene Flaeche statt grauem Menue-Look,
  Knopf an richtiger Position, nur sichtbar wenn Verlauf nicht leer ist);
  `Message.clearHistory()` selbst ist trivialer Code (`history = []`,
  `unreadCount = 0`), analog zum bereits laufenden `clear()`.

(Alle drei Punkte wurden inzwischen von dir selbst im laufenden Betrieb
bestätigt -- die gespeicherten Einstellungen zeigen bereits eine geänderte
Form/Restitution.)

Beim Testen ist außerdem einmal *bars/claude* (eine andere, unabhängige
Quickshell-Instanz auf diesem System) durch einen `wlrctl pointer click` in
deren Dock-Ecke abgestürzt (Qt-Bug in `maybeSynthesizeContextMenuEvent`,
unabhängig von blobball -- blobballs eigener Prozess lief währenddessen
weiter).

## Nicht-Ziele

Kein Füttern, kein Spielen, keine Haustier-Interaktionen, keine Systemleiste,
keine Widgets außer Blob + Menü + Physik. (Die Augen waren ursprünglich unter
"keine Gesichter" ausgeschlossen -- das wurde bewusst revidiert, siehe
"Bewusste Entscheidungen".)
