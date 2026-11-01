#!/usr/bin/env python3
"""Launcher assignments: which app launcher a bar uses (SUPER+space).

Every bar uses its own launcher by default (adapters/<bar>.json
"hasLauncher": true), or the menu's own app search otherwise. The
"Launcher" tab can assign any other launcher instead -- the menu's app
search, or the launcher of another bar, which then runs alone (without its
bar) through menu/launchers/hosts/<bar>.qml (see launcher-host.sh).
Assignments live in ~/.local/state/quickdots/launchers.json and stay until
they are changed again.

Usage:
  launchers.py info               JSON for the menu (launchers, defaults, assignments)
  launchers.py resolve <bar>      "<mode> <launcher>" -- mode is own|appsearch|host
  launchers.py keybinds <bar>     the bar's keybinds with the SUPER+space bind
                                  pointing at its launcher, one per line
  launchers.py set <bar> <id>     assign a launcher; "default" removes the assignment
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MENU_DIR = os.path.join(ROOT, "menu")
BARS_DIR = os.path.join(ROOT, "bars")
HOSTS_DIR = os.path.join(MENU_DIR, "launchers", "hosts")
INFO_FILE = os.path.join(MENU_DIR, "launchers", "info.json")
STATE_FILE = os.path.expanduser("~/.local/state/quickdots/launchers.json")

APPSEARCH = "appsearch"
HOST_FILE = ".quickdots-launcher.qml"

SUPER_SPACE = re.compile(r"^\s*bind\s*=\s*SUPER\s*,\s*space\s*,", re.IGNORECASE)


def _load_json(path, fallback):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return fallback


def adapter(bar):
    data = _load_json(os.path.join(MENU_DIR, "adapters", bar + ".json"), None)
    if data is None:
        data = _load_json(os.path.join(MENU_DIR, "adapters", "_default.json"), {})
    return data


def has_own(bar):
    return bool(adapter(bar).get("hasLauncher"))


def host_ids():
    """Bars whose launcher can run on its own (a host file exists)."""
    try:
        names = os.listdir(HOSTS_DIR)
    except FileNotFoundError:
        return []
    ids = []
    for n in names:
        if not n.endswith(".qml"):
            continue
        bar = n[:-4]
        if os.path.isfile(os.path.join(BARS_DIR, bar, "shell.qml")):
            ids.append(bar)
    return sorted(ids)


def assignments():
    data = _load_json(STATE_FILE, {})
    a = data.get("assignments", {})
    return a if isinstance(a, dict) else {}


def effective(bar, hosts=None):
    hosts = host_ids() if hosts is None else hosts
    a = assignments().get(bar)
    if a == APPSEARCH or (a == bar and has_own(bar)) or (a in hosts and a != bar):
        return a
    return bar if has_own(bar) else APPSEARCH


def mode_of(bar, launcher):
    if launcher == APPSEARCH:
        return "appsearch"
    if launcher == bar:
        return "own"
    return "host"


def launcher_bind(bar):
    launcher = effective(bar)
    mode = mode_of(bar, launcher)
    if mode == "appsearch":
        return "bind=SUPER,space,spawn," + MENU_DIR + "/scripts/toggle-launcher.sh"
    if mode == "host":
        return ("bind=SUPER,space,spawn,qs -p " + os.path.join(BARS_DIR, launcher, HOST_FILE)
                + " ipc call launcher toggle")
    return None


def keybinds(bar):
    binds = [b.replace("@QUICKDOTS_ROOT@", ROOT)
             for b in adapter(bar).get("keybinds", [])]
    extra = launcher_bind(bar)
    if extra is None:
        return binds
    return [b for b in binds if not SUPER_SPACE.match(b)] + [extra]


def info():
    meta = _load_json(INFO_FILE, {})
    hosts = host_ids()
    launchers = []
    for lid in [APPSEARCH] + hosts:
        m = meta.get(lid, {})
        launchers.append({
            "id": lid,
            "bar": "" if lid == APPSEARCH else lid,
            "title": m.get("title", ""),
            "description": m.get("description", ""),
        })
    bars = sorted(d for d in os.listdir(BARS_DIR)
                  if os.path.isfile(os.path.join(BARS_DIR, d, "shell.qml")))
    return {
        "launchers": launchers,
        "own": {b: has_own(b) for b in bars},
        "effective": {b: effective(b, hosts) for b in bars},
        "assignments": assignments(),
    }


def set_assignment(bar, launcher):
    data = _load_json(STATE_FILE, {})
    a = data.get("assignments")
    if not isinstance(a, dict):
        a = {}
    # Assigning the bar's default is the same as having no assignment.
    default = bar if has_own(bar) else APPSEARCH
    if launcher in ("default", default):
        a.pop(bar, None)
    elif launcher == APPSEARCH or launcher in host_ids():
        a[bar] = launcher
    else:
        print("Fehler: unbekannter Launcher „%s“" % launcher, file=sys.stderr)
        sys.exit(1)
    data["assignments"] = a
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")
    os.replace(tmp, STATE_FILE)


def main(argv):
    if len(argv) >= 1 and argv[0] == "info":
        print(json.dumps(info()))
    elif len(argv) >= 2 and argv[0] == "resolve":
        launcher = effective(argv[1])
        print(mode_of(argv[1], launcher), launcher)
    elif len(argv) >= 2 and argv[0] == "keybinds":
        for b in keybinds(argv[1]):
            print(b)
    elif len(argv) >= 3 and argv[0] == "set":
        set_assignment(argv[1], argv[2])
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main(sys.argv[1:])
