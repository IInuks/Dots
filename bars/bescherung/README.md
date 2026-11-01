# Bescherung

Jede Anzeige in der Leiste ist ein eingepacktes Geschenk mit Papier, Band,
Schleife und Anhänger. Nach dem Login packt sich die Leiste selbst aus (die
„Bescherung“): Die Papierhälften fliegen zur Seite, es regnet Konfetti, und
darunter liegt der Inhalt auf Seidenpapier. Popups springen wie ein
Springteufel auf einer Feder aus ihrem Geschenk und federn nach.

In der Mitte liegt jeden Tag ein neues **Tagesgeschenk**. Es bleibt
verpackt, bis du es selbst aufmachst. Drin ist ein Fakt, eine Mini-Mission,
ein Kompliment oder eine Frage des Tages. Um Mitternacht liegt ein neues da,
und die Leiste zählt mit, wie viele du schon gesammelt hast.

Design und Code sind komplett neu geschrieben, ohne Vorlage aus den
anderen Bars.

## Bedienung

| Wo | Was |
| --- | --- |
| verpacktes Geschenk | Hover: wackelt · Klick: auspacken |
| ausgepacktes Geschenk | Rechtsklick: wieder einpacken |
| Kugeln (Tags) | Klick: Tag wechseln · Mausrad: blättern |
| Lautstärke | Klick: stumm · Mausrad: ±5 % |
| Geschenk ganz links | Wundertüte (App-Launcher) |
| Geschenk ganz rechts | Power-Karte (jeder Knopf will zweimal gedrückt werden) |
| Päckchen in der Mitte | Tagesgeschenk |

**Wundertüte:** tippen zum Suchen, ↑/↓ oder Ctrl+J/K zum Wählen, Enter
startet die App, Esc schließt. **Tab = Glücksgriff:** Die Auswahl rattert
zufällig durch die Liste und bleibt irgendwo stehen. Gestartet wird erst
mit Enter.

## Starten

```
qs -p ~/quickdots/bars/bescherung
```

Oder über das quickdots-Menü auf „bescherung“ wechseln. Die Keybinds
dafür stehen in `quickdots/menu/adapters/bescherung.json`:

- SUPER+Space: Wundertüte
- SUPER+Escape: Power-Karte
- CTRL+SUPER+G: Tagesgeschenk

## IPC

```
qs -p <bar> ipc call bescherung launcher
qs -p <bar> ipc call bescherung power
qs -p <bar> ipc call bescherung tagesgeschenk   # öffnet das heutige Geschenk
qs -p <bar> ipc call bescherung nochmal         # alles einpacken, neu auspacken
qs -p <bar> ipc call bescherung zukleben        # heutiges Geschenk wieder zu
qs -p <bar> ipc call bescherung shot <name> <datei.png>   # Debug (bar-<Ausgang>, popup)
```

## Einstellungen

Alles in `Config.qml`, zum Beispiel `bescherungOnStart` (auf `false`
startet die Leiste ausgepackt), Tempo der Bescherung, Anzahl der
Konfetti-Schnipsel, Tag-Anzahl und Power-Kommandos. Farben und Papiermuster
stehen in `Theme.qml`, der Inhalt der Tagesgeschenke in `pool.js`.

## Technisches

- Ohne laufende Animationen im Ruhezustand: Das Papier wird nur bei
  Größenänderung neu gezeichnet. Konfetti und Federn laufen nur kurz nach
  einem Klick.
- Das Bar-Fenster ist 120 px höher als die reservierte Zone, damit Konfetti
  nach unten fallen kann. Klicks zählen nur im oberen Streifen (`mask`).
- Die Lautstärke läuft über `wpctl` und `pactl subscribe` statt über
  Quickshell.Services.Pipewire. So erholt sich die Bar, auch wenn sie beim
  Login vor PipeWire startet.
- Kein MPRIS, Tray oder Benachrichtigungen, weil die mango-Session keinen
  DBus-Session-Bus hat.
- Power-Aktionen nutzen `loginctl` (elogind). Sperren fehlt, weil kein
  Lockscreen installiert ist.
- Zustand des Tagesgeschenks: `tagesgeschenk.json` im Quickshell-State-
  Ordner dieser Config.
