# salbei

A calm glass desktop shell for **MangoWM** on **Bedrock Linux**, built with Quickshell.
It has translucent dark panels with strong compositor blur, large radii, and a single
sage accent (`#A8D5A2`, *Salbei* is German for sage). It was written from scratch and
shares no code with the other bars in `quickdots`.

Parts:

- **Bar:** floating centered pill. Launcher glyph, tags, CPU / temperature / RAM | clock | volume, brightness, battery, bell, tray, power.
- **Desktop:** big accent clock, month calendar with week numbers, cava visualizer on the bottom edge.
- **Launcher:** fuzzy search over desktop entries.
- **Control center:** Home, Media, Audio, Monitor, System, Server (SSH over Tailscale, host in `Theme.qml`), Power, Network, Bluetooth, Calendar, Notifications.
- **Popups:** calendar (click the bar clock) and power menu (with confirm).
- **Notifications:** toasts top right, history, DND.

## Start

```sh
qs -p ~/quickdots/bars/salbei            # test run
~/quickdots/bars/salbei/scripts/start.sh # what autostart uses
```

`scripts/start.sh` waits for `$XDG_RUNTIME_DIR/pipewire-0` before it starts Quickshell. Quickshell
doesn't retry a failed PipeWire connection, so starting too early would leave volume and the
visualizer dead. It needs no systemd (Void/runit is fine).

### Mango autostart (`~/.config/mango/config.conf`)

```ini
exec-once=~/quickdots/bars/salbei/scripts/start.sh &
```

Only run one bar at a time. Remove or comment out the `exec-once` of any other bar (for example
`bars/kurtz`). Two shells would both claim the notification server, and their exclusive zones
would stack.

### Keybinds

The quickdots menu manages these. `menu/adapters/salbei.json` (`hasLauncher: true` plus the
`keybinds` list) gets written into the `>>> quickdots >>>` block of the Mango config by
`menu/scripts/switch-bar.sh salbei`. To change the keys, edit the adapter and run that script
again. Don't edit the block by hand, because the next bar switch overwrites it.

```ini
bind=SUPER,space,spawn,qs -p ~/quickdots/bars/salbei ipc call launcher toggle
bind=CTRL+SUPER,c,spawn,qs -p ~/quickdots/bars/salbei ipc call controlcenter toggle
bind=SUPER,Escape,spawn,qs -p ~/quickdots/bars/salbei ipc call power toggle
bind=CTRL+SUPER,k,spawn,qs -p ~/quickdots/bars/salbei ipc call calendar toggle
bind=CTRL+SUPER,n,spawn,qs -p ~/quickdots/bars/salbei ipc call controlcenter page notifications
```

(The first three replace the kurtz binds with the same keys.)

### IPC

| target | functions |
|---|---|
| `launcher` | `toggle`, `open`, `close` |
| `controlcenter` | `toggle`, `page <home\|media\|audio\|monitor\|system\|power\|network\|bluetooth\|calendar\|notifications>`, `close` |
| `power` | `toggle` |
| `calendar` | `toggle` |
| `notifications` | `test`, `clear`, `dnd` |

### Mouse

- Tags: click to switch, scroll to step.
- Volume: click to mute, scroll to change.
- Brightness: scroll.
- Bell: click opens history, right-click toggles DND.
- Launcher glyph: right-click opens the control center.
- Home tiles: right-click on Wi-Fi or Bluetooth opens that page.
- Toasts: click opens history, right-click dismisses.

## Mango blur

The blur comes from Mango (scenefx), not from QML. These lines are in `config.conf`:

```ini
blur=1
blur_layer=1
blur_optimized=1
blur_params_num_passes = 3
blur_params_radius = 6
border_radius=20

layerrule=noblur:1,layer_name:^(?!qs-)   # layer blur only for this shell's surfaces
layerrule=noanim:1,layer_name:^qs-       # QML animates panels itself (fade + 0.96→1 scale)
```

- Mango 0.14.4 parses `layerrule=` with the keys `layer_name`, `noblur`, `noanim`, `noshadow`,
  `animation_type_open` and `animation_type_close`. Newer wiki pages spell them `layer_rule`/`no_blur`.
  Those spellings do **not** work on 0.14.4.
- Mango blurs a layer with `backdrop_blur_ignore_transparent`, so only non-transparent pixels get
  blurred. That's why the rounded panels get correctly rounded blur. No square corners, no extra
  configuration needed.
- Background and Bottom layers are never blurred. The desktop widgets live on the **Bottom** layer:
  above the wallpaper tool's Background surface, below windows. A restarted wallpaper daemon can't
  cover them.
- Namespaces: `qs-bar`, `qs-launcher`, `qs-controlcenter`, `qs-notifications`, `qs-calendar`,
  `qs-power`, `qs-desktop`.
- `blur_params_radius` × passes sets the strength. Mango has no per-layer blur radius.
- You can change all blur values live in the quickdots menu, "Blur" tab
  (`qs -p ~/quickdots/menu ipc call wizard blur`). Mango caps brightness, contrast and
  saturation at 1.0.

## Dependencies (per stratum)

| What | Tool | Stratum | Without it |
|---|---|---|---|
| Shell | `quickshell` 0.3.1 | arch | – |
| Tags | `mmsg` | void (mango) | tags hidden |
| Audio | PipeWire (native module) | debian (pipewire), arch (wpctl) | volume hidden |
| Visualizer | `cava` | arch: `sudo strat arch pacman -S cava` | visualizer hidden |
| Media | MPRIS over D-Bus | – | "Nothing Playing" |
| Network | `nmcli` + running NetworkManager | debian | falls back to `/sys/class/net` (wired only) |
| Bluetooth | BlueZ over D-Bus (`bluetoothd`) | debian | tile shows "No Bluetooth" |
| Brightness | `brightnessctl` (backlight) or `ddcutil` (DDC/CI) | – | module hidden |
| Battery | UPower | void | hidden on desktops |
| Night light | `wlsunset` / `gammastep` / `hyprsunset` | – | tile disabled |
| Video wallpaper | `mpvpaper` + `~/Videos/wallpaper.{mp4,webm,mkv}` | – | tile disabled |
| Lock | `hyprlock` / `swaylock` / `gtklock` / `waylock` | – | lock button hidden |
| Power | `loginctl` (elogind) | void | – |
| Terminal | `kitty` | arch | – |
| Text font | Outfit → Lexend → Adwaita Sans | Outfit not packaged; put the TTFs in `~/.local/share/fonts` | system sans |
| Icon font | Material Symbols Rounded (`strat arch pacman -S ttf-material-symbols-variable`) | arch | JetBrainsMono Nerd Font (Material Design glyphs) |

Every missing tool hides or disables its module. Nothing crashes. Commands are resolved through
`/bedrock/cross/bin`, so it doesn't matter which stratum provides them.

Media, tray, notifications and Bluetooth need a session D-Bus: start Mango with `dbus-run-session mango`.

## Desktop widgets: quickdots menu, "Widgets" tab

Open it with the menu (CTRL+SUPER+ALT+Space → Widgets) or
`qs -p ~/quickdots/menu ipc call wizard widgets`.

| Widget | Settings |
|---|---|
| Clock | 24 h, seconds, size |
| Calendar | week numbers, events column, width (clickable: ‹ › month) |
| Visualizer | width (%), height; off = cava never starts |
| Greeting | name (empty = user name), date line, size |
| Media | cover, controls (clickable), hide without a player, size |
| System | CPU / RAM / temperature rings, size |
| Weather | city (empty = by IP), °F, details line, size; wttr.in via curl every 30 min (`services/Weather.qml`) |

Every widget is a `modules/widgets/DeskWidget.qml` and also has: on/off, position (top-left in % of
the screen, clamped on screen; 100 = glued to the right/bottom edge, dragged in the menu's preview),
**An Hintergrund anpassen** and (not the visualizer) a **Glas-Karte** behind it. New widgets start off.

**Adapting to the wallpaper:** `AccentSource.qml` shrinks the current wallpaper to a 32×18 color grid
with `magick` (works for webp too). `lumAt()` gives the average brightness under a widget; above 0.58
the widget switches to dark ink and a deeper accent of the same hue (and a frosted white card instead
of a smoked one). Moving a widget or changing the wallpaper re-evaluates it.

The **accent color** is the last entry in the same tab:

- **Fest:** one of the preset pastels. The default is sage `#A8D5A2`.
- **Aus dem Wallpaper:** the hues of the same grid are binned and weighted by saturation, the five
  strongest distinct ones are softened to pastels and written (with the grid) to
  `~/.local/state/quickshell/salbei-palette.json`. The menu shows them as swatches and uses the grid
  for its preview. `accentInk` (text on accent) is derived from the same hue.

Changes apply live. The menu writes `~/.local/state/quickshell/salbei-widgets.json` and
`services/WidgetSettings.qml` reloads it on change (read with `WidgetSettings.v(key)`). Missing
file or keys = the defaults.

## Changing the look: `Theme.qml`

All colors, radii, spacing, font sizes, animation timings and component sizes are in `Theme.qml`.
Nothing is hardcoded elsewhere.

- **Accent:** `accent`, plus `accentInk` for text on accent surfaces. Both come from
  `AccentSource.qml` (fixed or from the wallpaper, see the Widgets tab). The spec called it `onAccent`,
  but QML reads any property named `on` + capital letter as a signal handler, and the color silently
  stays black.
- **Panel glass:** `panelFrom` (top-left) → `panelTo` (bottom-right), `border`, `tile`. The bar,
  popups and toasts all use the same glass (`components/GlassSurface.qml`).
- **Radii:** `radiusPanel`, `radiusTile`, `radiusRow`, `radiusField`, `radiusDay`, …
- **Fonts:** `fontFamily` picks the first installed family from the list in `_pick(...)`.
  `iconFamily` switches to Material Symbols automatically once it's installed.
- **Sizes:** `barWidthFraction`, `barHeight`, `launcherWidth/Height`, `ccWidth/Height`,
  `visualizerBar*` (desktop widget size and position are set in the Widgets tab).
- **Polling:** `statsInterval` (CPU/RAM/temp, default 2 s).

Quickshell hot-reloads on save.

## Layout

```
shell.qml               windows + IPC handlers
Theme.qml               design tokens (singleton)
Ui.qml                  popup state, DND (singleton)
components/             GlassSurface (glass body), GlassPanel (popup window base: namespace,
                        animation, close on Esc/click outside), Tile, IconButton, Slider, ListRow,
                        Icon (+IconMap), Txt, AppIcon, MonthGrid, PowerActions
services/               Tags, SystemStats, Audio, Brightness, Network, Bluetooth, Cava, Media,
                        Battery, Notifs, NightLight, VideoWallpaper, Session, AppIcons
modules/bar/            Bar, TagStrip, StatsCluster, ClockLabel, StatusCluster, ButtonCluster,
                        CalendarPopup
modules/launcher/       Launcher
modules/controlcenter/  ControlCenter, *Page, PowerMenu
modules/widgets/        Desktop (all desktop widgets), DeskWidget (position/adapt/card), Visualizer
modules/notifications/  Toasts
assets/cava.conf        raw ASCII, 72 bars, mono, PipeWire input
scripts/start.sh        autostart wrapper
```

### Notes

- **No `qmldir`.** Quickshell registers every `pragma Singleton` file in imported directories by
  itself. A hand-written qmldir would replace that and would have to list every file.
- **The list-row component is `ListRow`**, not `Row`, because `Row` is a QtQuick type.
- **Tags** come from `mmsg watch all-tags` (one JSON line per change). Quickshell has no dwl-ipc-v2
  module, so this is the cleanest event source. Switching uses `mmsg dispatch view,<n>,0`.
- **Bluetooth** uses Quickshell's native BlueZ module instead of `bluetoothctl`. It's event-driven
  instead of polled.
- **Network** listens to `nmcli monitor` (event-driven). It only polls `/sys` every 15 s while
  NetworkManager isn't running.
- **cava only runs while sound is audible.** A PipeWire peak monitor on the default sink starts it,
  and 3 s of silence stops it again.
- **App icons:** Qt misses most icons on Bedrock because `/bedrock/cross/icons/hicolor` has a
  near-empty `icon-theme.cache`. `services/AppIcons.qml` indexes the cross icon dirs once as a fallback.
- **Kitty:** use `~/.config/kitty/theme-rice.conf`. kitty's `background_blur` needs the Wayland
  background-blur protocol, which Mango doesn't implement. Mango's own window blur (`blur=1`)
  blurs behind the translucent kitty window instead.
