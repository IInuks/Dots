# mangobar

A Quickshell status bar for [mango](https://github.com/mangowm/mango) (mangowc),
built around "liquid" menus: hovering a module makes its dropdown flow out of
the bar as one continuous, flat-colored shape (bar and menu share the exact
same fill color, joined by concave fillets — no popup, no seam, no shadow).

## Running

```sh
qs -p ~/shellbar
```

(equivalently `quickshell -p ~/shellbar`). Config lives in
`~/shellbar/` — it's a plain path-based config, not registered
under `~/.config/quickshell/`, so it's always `-p <path>`, not `-c <name>`.

To run it on login, add that command to your mango autostart
(`exec-once=...` / `autostart=...` in `~/.config/mango/config.conf` — check
`man mango` for the exact directive name you're using).

## Runtime dependencies

- `quickshell` 0.3.0+ (`qs`)
- `mango` + `mmsg` — tags are read/switched over `mmsg watch|dispatch`
- `pipewire` + `wireplumber` — volume module uses `Quickshell.Services.Pipewire`
  directly (no `wpctl` needed)
- `nvidia-smi` for GPU stats on NVIDIA; falls back to
  `/sys/class/drm/card*/device/gpu_busy_percent` (AMD) if it's missing
- a `/sys/class/hwmon` sensor for CPU temperature (works out of the box on
  most systems; picks `k10temp`/`coretemp`/`zenpower`/`cpu_thermal` if present,
  otherwise just takes the first hwmon it finds)
- a `StatusNotifierItem` tray host isn't otherwise running (Quickshell hosts
  its own tray watcher; a second one, e.g. from another bar, will just fail to
  register and is harmless)

## Layout

Horizontal (top/bottom bar): **settings trigger, tags** — **clock**
(center) — **CPU%, volume, tray** (end cluster).

Vertical (left/right bar): **settings trigger, clock** (start/top) —
**tags** (middle) — **CPU%, volume, tray** (end/bottom). The bar docks to
any of the 4 screen edges via the settings menu's **Bar** tab; the vertical
bar is thickened (`Settings.barThickness`) so the clock's stacked time/date
lines still fit.

## Files

| File               | Role                                                        |
|--------------------|--------------------------------------------------------------|
| `shell.qml`         | `ShellRoot`, one `Bar` per screen                            |
| `Bar.qml`           | `PanelWindow`/layer-shell setup, start/middle/end groups, input mask, per-edge docking |
| `LiquidMenu.qml`    | The reusable trigger+liquid-dropdown component, edge-aware (flows out of whichever screen edge the bar docks to) |
| `Theme.qml`         | Color singleton: presets + custom RGB/opacity override, persistence |
| `Settings.qml`      | Bar position + clock date-display singleton, persistence      |
| `Toggle.qml`        | Reusable on/off switch used across the settings menu           |
| `SliderRow.qml`     | Reusable labelled 0..1 slider used across the settings menu    |
| `SettingsMenu.qml`  | Settings trigger; tabbed menu (Themes / Monitor / Colors / Bar / Sound / Wi-Fi / Commands / Chess) |
| `Shortcuts.qml`     | Singleton: persisted list of user-defined name+script buttons for the Commands tab |
| `ShortcutsEditor.qml` | Singleton: open/prefill state for the Commands tab's add/edit modal (rendered in `Bar.qml`) |
| `ChessEngine.js`    | Pure move-generation/rules library: legal moves, check/checkmate/stalemate, castling, en passant, promotion |
| `ChessBot.js`       | Negamax bot with alpha-beta pruning; depth (1-3) and blunder chance scale with the difficulty slider |
| `ChessState.qml`    | Singleton: board/turn/mode/difficulty, persisted mode+difficulty, drives moves via `ChessEngine`/`ChessBot` |
| `ChessBoard.qml`    | 8x8 board: click-to-select/move, legal-move dots, inline promotion picker |
| `ChessWindow.qml`   | Big centered modal (rendered in `Bar.qml`) opened from the Chess tab: mode toggle, difficulty slider, board |
| `Tags.qml`          | mango tags via `mmsg watch/dispatch`                          |
| `Clock.qml`         | Clock trigger, wraps `Launcher` as its menu content            |
| `Launcher.qml`      | Live-search `.desktop` app launcher                            |
| `SysMonData.qml`    | Singleton: polls CPU/RAM/GPU/temp/disk/uptime once, shared by `SysMon` and the Monitor tab, keeps rolling history for the charts |
| `SysMon.qml`        | CPU trigger, wraps CPU/RAM/GPU/temp monitor (from `SysMonData`) as its menu content |
| `MeterRow.qml`      | Small labelled progress bar used by `SysMon`'s menu             |
| `MonitorCard.qml`   | Label+value card with a `HistoryChart` used by the Monitor tab  |
| `HistoryChart.qml`  | Small filled line chart for a rolling 0..100 history            |
| `StatTile.qml`      | Small label+value tile (temps/disk/uptime) used by the Monitor tab |
| `Volume.qml`        | Pipewire volume slider + mute (no menu)                        |
| `Tray.qml`          | `SystemTray` icons (no menu; right-click opens native menu)     |

## Settings menu

Hovering the (invisible) trigger in the bar's starting corner opens a
tabbed menu:

- **Themes** — the original fixed color presets.
- **Colors** — transparency slider + custom RGB sliders for the surface and
  accent colors, plus a light/dark foreground toggle. Touching any of these
  switches the bar to `Theme.useCustomColors`, overriding whichever preset
  was active; picking a preset in the Themes tab switches back.
- **Bar** — dock position (top/bottom/left/right) and a toggle for showing
  the day/date next to the clock.
- **Sound** — master volume plus a live per-application mixer (every
  playback stream Pipewire currently reports gets its own slider).
- **Wi-Fi** — toggle the radio, see scanned networks with signal strength,
  connect (with an inline password field for secured networks), disconnect,
  forget. Backed by `Quickshell.Networking` (NetworkManager).
- **Commands** — user-defined buttons. Hitting **+** (or a row's **✎**)
  opens a big centered modal (name field + a multi-line script box, one
  command per line) over the whole bar window; **Escape** or **Cancel**
  closes it without saving, **Save** commits it. Rows run their script (via
  `sh -c`, detached) on click, **×** removes one. Persisted to
  `Quickshell.statePath("shortcuts.json")`, so entries survive a restart.

## Customizing

- **Bar height / menu radii**: `Theme.qml` — `barHeight`, `menuTopRadius`
  (the concave fillet), `menuBottomRadius` (the convex bottom corners).
  Vertical-bar thickness is `Settings.barThickness` (in `Settings.qml`).
- **Themes**: add an entry to `Theme.presets` and `Theme.presetOrder` in
  `Theme.qml` (needs `surface`, `foreground`, `mutedText`, `accent`,
  `urgent`). Selection is persisted to `Quickshell.statePath("theme.json")`
  (survives full restarts, not just `qs` reloads) and applies live
  everywhere the instant you pick it in the Themes tab.
- **Module order**: `startGroup`/`middleGroup`/`endGroup` in `Bar.qml` are
  independent `GridLayout`s; `SettingsMenu` is fixed to `startGroup` and
  `SysMon`/`Volume`/`Tray` to `endGroup`, while `Tags`/`Clock` swap groups
  based on `Settings.vertical` (see the `parent:` bindings at the bottom of
  `Bar.qml`).
- **Max menu height**: if you make a menu grow past ~380px total
  (`menuContentHeight` + radii), bump `Bar.qml`'s `maxMenuHeight`, which
  sets how much extra window space is reserved past the bar strip (in
  whichever direction menus flow away from the docked edge) for open menus.

## Known limitation

`SysMon`'s hwmon lookup takes whatever sensor matches first; on unusual
hardware (multiple CPU packages, no matching driver) `cpuTemp` may show `—`
or pick an unrelated sensor — check `sh -c 'for f in
/sys/class/hwmon/hwmon*/temp1_input; do cat "$(dirname "$f")/name"; done'`
and adjust the `priority` list in `SysMon.qml` if needed.
