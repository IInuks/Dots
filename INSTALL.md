# Quickdots installieren

`install.sh` erkennt die Linux-Distribution und verwendet deren Paketmanager
(Arch/pacman, Debian oder Ubuntu/apt, Fedora/dnf, openSUSE/zypper, Void/xbps,
Alpine/apk oder NixOS/Nix). Auf Bedrock Linux verwendet es den Arch-Stratum.
Je nach Paketmanager kann die Installation nach dem sudo-Passwort fragen.

Im Anschluss verknüpft das Skript `menu`, `shellwall` und `blobball` unter
`~/.config/quickshell`. Danach kannst du zwischen vollständiger Einrichtung,
nur Autostart oder Autostart plus Keybinds wählen. Eigene Wallpaper werden
nicht mitgeliefert; optional hinzugefügte Bilder in `wallpapers/` werden
kopiert.

```sh
cd ~/quickdots
./install.sh
```

MangoWM (`mango` und `mmsg`) muss bereits installiert sein. MangoWM selbst
wird nicht von diesem Skript installiert, weil es für viele Distributionen
separat gebaut oder aus zusätzlichen Repositories bezogen wird. Auf Debian,
Ubuntu, Fedora, openSUSE und Void installiert das Skript die dort verfügbaren
Hilfsprogramme und zeigt fehlende optionale Programme an. Quickshell,
`awww`/`swww`, matugen und pywal müssen dort gegebenenfalls separat installiert
werden; der Wallpaper-Switcher benötigt `awww`, während Farbthemen matugen
oder pywal nutzen.

Serverdaten werden zuletzt abgefragt und können übersprungen werden. Sie
werden lokal in `~/.local/state/quickshell/menu-server.json` gespeichert.
