# Faltwerk: eine Origami-Shell für mango

Alles ist aus Papier: Die Leiste besteht aus zickzack-gefalteten Papierstücken, jedes Menü faltet sich auf seine eigene Art auf, und der Launcher ist ein zweimal gefalteter Bogen. Gestartete Apps fliegen als Papierflieger davon. Sechs Papiersorten wechselt man über einen Farbfächer, die Leiste blättert dabei um: **Adaptiv** (aus dem Wallpaper), Washi, Kraft, Tusche, Blaupause und Sakura.

## Was drin ist

| Teil | Datei | Animation |
|---|---|---|
| **Leiste** | `bar/` | Drei Papierstücke falten sich beim Start nacheinander auf (Leporello). Jedes Modul liegt auf einer eigenen „Seite“ mit Knicklinie. Beim Papierwechsel blättern die Stücke kaskadierend um. |
| Kranich + „falten“ | `bar/LeftPiece.qml` | Öffnet den Launcher. Bei Hover hüpft der Kranich und schlägt mit den Flügeln. |
| Tags | `bar/TagTile.qml` | Origami-Quadrate. Ein aktiver Tag dreht sich auf seine farbige Rückseite, belegte Tags haben ein Eselsohr, dringende zappeln. Mausrad wechselt den Tag. |
| Banderole | `bar/Banner.qml` | Fenstertitel auf einem Papierband mit Schwalbenschwanz. Ändert sich der Titel, klappt das Band um. |
| Messwerk, Ton, Fächer, Zettel, Uhr, Orakel | `bar/RightPiece.qml` | Mini-Streifen für CPU/RAM/Temperatur. Lautstärke per Mausrad, Mittelklick schaltet stumm. Die Uhrziffern klappen jede Minute um. |
| **Kalender** | `menus/CalendarMenu.qml` | Abreißkalender als Leporello mit 3 Streifen. Tagesblatt mit Perforation, darunter der Monat mit KW. Pfeile oder Mausrad blättern die Seite um. |
| **Messwerk** | `menus/SystemMenu.qml` | Faltet sich seitlich auf (4 Streifen). Bleistiftskizze der CPU-Last; die Papierstreifen für CPU, RAM, Platte und Temperatur schieben sich gestaffelt hinein. |
| **Ton** | `menus/SoundMenu.qml` | Lasche (2 Streifen). Der Regler ist ein Fähnchen am Falz; die Ausgänge sind Karteireiter (`pactl`). |
| **Fächer** | `menus/PaperMenu.qml` | Die Papiersorten spreizen sich als Musterstreifen auf. Hover schiebt einen Streifen heraus, ein Klick wählt ihn. |
| Adaptiv | `core/Wallpaper.qml` | Liest alle 5 s `awww query`. Bei einem neuen Bild quantisiert `magick` es auf 12 Farben. Ein dunkles Wallpaper ergibt dunkles Papier, ein helles helles, jeweils in den Grundton getönt. Akzent ist die kräftigste Farbe, die Zweitfarbe die kräftigste mit anderem Farbton, und die App-Kärtchen bekommen die Wallpaperfarben. Wechselt das Wallpaper, blättert die Leiste in die neuen Farben um. |
| **Zettel** | `menus/NoteMenu.qml` | Angepinnter Notizzettel, klappt herunter und pendelt aus. Wird automatisch gespeichert. „abreißen“ lässt ihn fallen und hängt einen neuen hin. |
| **Himmel und Hölle** | `menus/PowerMenu.qml` | Das Papier-Orakel als Ausschalt-Menü. Vier Klappen falten sich nacheinander auf: Ruhe, Neustart, Aus, Abmelden. Erster Klick wählt, zweiter führt aus. |
| **Launcher** | `launcher/` | Zweimal gefalteter Bogen mit Kranich-Stempel auf der Rückseite. Erst klappt die untere, dann die rechte Hälfte in Perspektive auf. Die Apps sind Origami-Kärtchen, die gestaffelt aufklappen. Enter faltet die gewählte zum **Papierflieger**. |

## Bedienung

- **SUPER+Space**: Launcher. Tippen filtert, Pfeile/Tab wählen, Enter startet, Esc schließt. Ohne Suchtext stehen die meistgestarteten Apps vorn. `> befehl` führt einen Shell-Befehl aus.
- Klick auf ein Modul der Leiste öffnet sein Menü. Klick daneben oder **Esc** schließt es.
- IPC:
  ```sh
  qs -p ~/quickdots/bars/faltwerk ipc call launcher toggle
  qs -p ~/quickdots/bars/faltwerk ipc call faltwerk toggle calendar   # calendar|system|sound|paper|note|power|launcher
  qs -p ~/quickdots/bars/faltwerk ipc call faltwerk paper tusche      # adaptiv|washi|kraft|tusche|blaupause|sakura
  qs -p ~/quickdots/bars/faltwerk ipc call faltwerk close
  ```

## Aufbau

- `core/`: Singletons. `Paper` (Paletten), `Store` (merkt sich Papier, App-Starts und Zettel in `~/.local/state/quickdots/faltwerk.json`), `Mango` (`mmsg watch`), `Sys` (`/proc` und `pactl`), `Apps` (Suche), `Falt` (welches Menü wo offen ist).
- `fold/`: die Falt-Bausteine. `Fold.qml` schneidet beliebigen Inhalt in Streifen (ShaderEffectSource) und kippt sie abwechselnd per `Rotation` mit Perspektive. `Flap.qml` ist die 180°-Faltung mit Rückseite, verschachtelt ergibt sie die Kartenfaltung des Launchers. Dazu `Sheet` (Papier mit Korn) und `Crane`.
- `menus/Overlay.qml`: ein Vollbild-Overlay pro Bildschirm mit allen Menüs. Es ist per leerer Maske klickdurchlässig, solange nichts offen ist.

## Hinweise

- Ohne DBus und Pipewire-Bindings (die Session hat kein DBus; Quickshells Pipewire verbindet sich nicht neu, wenn qs zu früh startet): Ton läuft über `pactl subscribe`. Systemwerte kommen alle 3 s aus einem kurzen `sh`-Aufruf.
- Im Ruhezustand laufen keine Dauer-Animationen. Alles bewegt sich nur beim Öffnen, Hovern oder bei Änderungen.
- Kein `Behavior` in Singletons (crasht Quickshell 0.3.1). Deshalb läuft das Umblättern beim Papierwechsel über `Paper.pending` und die Animation in `bar/Bar.qml`.
- Der Launcher steht auch anderen Bars zur Verfügung: `menu/launchers/hosts/faltwerk.qml` („Gefalteter Bogen“ im Menü-Tab „Launcher“).
