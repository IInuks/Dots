# Polarlicht

Eine komplette Quickshell-Shell für mango, deren Farben dem Wallpaper folgen.

```sh
qs -p ~/quickdots/bars/polarlicht -n
```

## Leiste
- **Links:** App-Starter · Tags mit gleitender Markierung (Klick = wechseln, Scrollen = nächster belegter Tag) · Fensterliste (Rechtsklick = Layout wechseln)
- **Mitte:** Uhr und Datum. Beim Überfahren fährt der Fenstertitel aus, ein laufender Timer wird eingeblendet, ein Klick öffnet den Kalender.
- **Rechts:** CPU/RAM → System · Lautstärke (Scrollen, Mittelklick = stumm) → Kontrollzentrum · Tastaturlayout · Hintergründe · Power

## Menüs
| Menü | Inhalt |
|---|---|
| Starter | Suche, `=` rechnet (`=2^10*3`), `>` führt Befehle aus |
| Kalender | große Uhr, Tages- und Jahresfortschritt, Monatsansicht, Timer (5/15/25/50 min) |
| Kontrollzentrum | Lautstärke, Ausgabegerät, Mikrofon, Wach bleiben, Sekunden, Übersicht, Lücken, Hell/Dunkel/Auto, Tonal/Lebhaft/Mono, Animationen Weich/Flott/Aus, Akzentfarbe aus dem Wallpaper |
| System | CPU- und RAM-Verlauf, Temperaturen, Festplatte, Laufzeit, Top-Prozesse |
| Fenster | alle Fenster, Klick = fokussieren, Mittelklick/× = schließen |
| Hintergründe | Galerie aus `~/Pictures/Walpapers`, Zufall; die Farben blenden weich um |
| Power | gedrückt halten zum Bestätigen: Shell neu, Abmelden, Bereitschaft, Neustart, Aus |

Esc oder ein Klick daneben schließt ein Menü. Die Lautstärke und das Tastaturlayout zeigen ein OSD unten.

## IPC / Tastenkürzel
```sh
qs -p ~/quickdots/bars/polarlicht ipc call polarlicht toggle launcher   # calendar control system windows walls power
qs -p ~/quickdots/bars/polarlicht ipc call polarlicht mode dark          # auto | dark | light
```
Beispiel für `~/.config/mango/config.conf`:
```
bind=SUPER,space,spawn,qs -p ~/quickdots/bars/polarlicht ipc call polarlicht toggle launcher
```

Die Einstellungen stehen in `~/.local/state/quickshell/by-shell/<id>/settings.json`.
Es gibt keine Dauer-Animationen, nur Übergänge (schont die CPU bei 165 Hz).
Die Shell braucht kein DBus: Audio läuft direkt über Pipewire, Fenster über wlr-foreign-toplevel.
