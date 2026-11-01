# quickdots greeter

A greetd login screen in Quickshell, in the same palette as `menu/`
(dark glass, JetBrains Mono). It shows your current wallpaper (it blurs
while you type), a clock, a login card, a session picker and power buttons.
All colors are derived from the wallpaper (tint + accent, darker on bright
images); a gray wallpaper falls back to the teal accent.

## Styles

Five complete layouts, all colored from the wallpaper. Switch with the
palette button (󰏘) that every style has, or with Alt+S: a carousel with
live previews opens (←/→, Enter, Esc). The choice is saved in the state file.

| Style | Look |
|---|---|
| Glass | Centered card on the blurred wallpaper (the original) |
| Sidebar | Frosted panel on the left, sharp, slowly drifting wallpaper |
| Terminal | tty login in a CRT window: power-on effect, typewriter banner, scanlines |
| Minimal | Huge thin clock with rolling digits; controls fade in on activity |
| Tiles | Glass top bar, user tiles that pop in, password pill |

New style: add `styles/<Name>Style.qml` (props `ctl`, `preview`, function
`focusField()`, use `components/PasswordField.qml`) and an entry in `Styles.qml`.

## Files

| File | Purpose |
|---|---|
| `shell.qml` | Entry point: a single `FloatingWindow` (cage shows it fullscreen) |
| `Auth.qml` | Wraps `Quickshell.Services.Greetd`, plus a mock backend |
| `Users.qml` | Login users from `/etc/passwd` (uid 1000–59999, real shell) |
| `Sessions.qml` | Wayland sessions via `scripts/sessions.sh` |
| `WallColors.qml` | Wallpaper path + colors from it (ColorQuantizer); `Theme.qml` builds on it |
| `Prefs.qml` | Remembers the last user and session (`$QD_GREETER_STATE`) |
| `Styles.qml` | List of styles (id, file, name, description) |
| `styles/` | The layouts, loaded by `components/Greeter.qml` |
| `components/` | Greeter (state + style loader), StyleMenu, PasswordField, Backdrop, Shake, LoginCard, SessionPicker, PowerBar, Clock, IconButton |
| `wallpaper.jpg` | Fallback background, copied at install (`$QD_GREETER_WALLPAPER` overrides it) |
| `scripts/wallsync.sh` | Runs in the session (mango `exec-once`) and copies the current awww wallpaper to the greeter |
| `greetd/config.toml` | greetd config: cage + `strat arch qs` |
| `install.sh` | Installs into the Void stratum, switches from LightDM, rolls back |

## Keys

Enter logs in, Esc clears the field, Alt+←/→ switches the user,
Alt+↑/↓ switches the session, Alt+S opens the style menu.

## Testing inside a session

    ./test.sh                                    # mock backend, password "test"
    qs ipc -p . call greeter submit wrong        # mock-only test hooks
    qs ipc -p . call greeter session 1
    qs ipc -p . call greeter style terminal      # or: styles (open menu), close
    qs ipc -p . call greeter shot /tmp/g.png     # screenshot

## Install

    sudo ./install.sh              # files + config, LightDM stays active
    sudo ./install.sh --switch     # enable greetd instead of LightDM (ends the session)
    sudo ./install.sh --rollback   # back to LightDM

After you change the QML, run `sudo ./install.sh` again to copy it over.

## Wallpaper sync

The greeter user can't read your home, so `scripts/wallsync.sh` (started
from the mango config) polls `awww query` every 5 s and writes a jpg copy to
Arch's `/var/cache/qd-greeter/wall/wallpaper.jpg`; `install.sh` creates that
directory owned by the user who ran sudo. `launch.sh` points
`$QD_GREETER_WALLPAPER` at it, so the next greeter start (logout or boot)
shows the wallpaper you last had.

Test another image: `QD_GREETER_WALLPAPER=/path/img.png ./test.sh`

## Bedrock notes

- greetd, cage and runit come from the **Void** stratum. Quickshell comes from
  **Arch**, so the greeter runs via `strat arch qs`.
- `/etc` and `/var/cache` are per-stratum. The greeter files live in Void's
  `/etc/greetd/quickdots` and qs reads them through
  `/bedrock/strata/void/...`. The state file is in Arch's
  `/var/cache/qd-greeter/`.
- Sessions are read from Arch's `/usr/share/wayland-sessions`.
