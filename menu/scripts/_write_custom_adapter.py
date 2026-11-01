#!/usr/bin/env python3
"""Called by save-custom-bar.sh. Writes the menu/adapters/custom-<slug>.json
structural fallback from the bar's own config -- BarTheme/BarCard treat this
custom bar exactly like any hand-built one, and CustomLive.qml (the live
reader used by the "Bars" tab card, mirroring how CustomBarRoot itself
renders) overrides surface/foreground/accent live for "adaptive" bars, so
this file only has to hold a reasonable fallback for the moment before that
live reader has loaded.

theme.mode == "adaptive" resolution used to run ImageMagick against a
manually-entered wallpaper path once, at save time. That's gone: shellwall
runs `wal -i <path> -n -q` on every wallpaper change (see shellwall's
Config.qml), so ~/.cache/wal/colors.json always already holds the current
wallpaper's palette -- reading it here (and live, in CustomBarRoot.qml /
CustomLive.qml) is simpler and never goes stale.
"""
import json
import os
import sys


def main():
    config_path, adapter_path = sys.argv[1], sys.argv[2]
    with open(config_path) as f:
        cfg = json.load(f)

    theme = cfg.get("theme", {})
    surface = theme.get("surface", "#1c1c26")
    foreground = theme.get("foreground", "#e8e8f0")
    accent = theme.get("accent", "#5b8cff")

    if theme.get("mode") == "adaptive":
        try:
            with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
                wal = json.load(f)
            surface = wal["special"]["background"]
            foreground = wal["special"]["foreground"]
            accent = wal["colors"]["color4"]
        except Exception:
            pass

    adapter = {
        "surface": surface,
        "foreground": foreground,
        "accent": accent,
        "barOpacity": theme.get("opacity", 0.9),
        "radius": theme.get("radius", 14),
        "keybinds": [],
        "hasLauncher": False,
    }
    with open(adapter_path, "w") as f:
        json.dump(adapter, f, indent=2)


if __name__ == "__main__":
    main()
