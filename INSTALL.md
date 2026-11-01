# Quickdots installieren

`install.sh` erkennt die Linux-Distribution und verwendet deren Paketmanager
(Arch/pacman, Debian oder Ubuntu/apt, Fedora/dnf, openSUSE/zypper, Void/xbps,
Alpine/apk oder NixOS/Nix). Auf Bedrock Linux verwendet es den Arch-Stratum.
Je nach Paketmanager kann die Installation nach dem sudo-Passwort fragen.

Im Anschluss legt das Skript die Quickshell-State-Ordner an, verknüpft
`menu`, `shellwall` und `blobball` unter `~/.config/quickshell`, kopiert die
mitgelieferten Bilder nach `~/Pictures/Walpapers` (bestehende lokale Bilder
bleiben erhalten) und ergänzt den Quickdots-Block in
`~/.config/mango/config.conf`. Die Bar `simple` wird als Start-Bar gesetzt;
die Auswahl kann danach im Quickdots-Menü geändert werden.

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

Die gebündelten Bilder stammen aus der lokalen Wallpaper-Sammlung des
Maintainers. Vor einer Weiterverteilung bitte die jeweiligen Nutzungsrechte
und Lizenzbedingungen der Bildquellen beachten.
