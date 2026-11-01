#!/usr/bin/env python3
"""Prints {barName: {title, description, preview}} as JSON for every bar in
bars/ (folder with a shell.qml). Read by BarInfo.qml for the wizard's
preview pane.

- title/description: heading + first prose paragraph of bars/<name>/README.md
  (markdown stripped, shortened to a few sentences).
- preview: bars/<name>/preview.{png,jpg,jpeg} if present (a real
  screenshot beats the generated mockup), else "".
"""
import json
import os
import re
import sys

BARS = "~/quickdots/bars"
MAX_CHARS = 420


def strip_md(s):
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    s = re.sub(r"[*_`]{1,3}([^*_`]+)[*_`]{1,3}", r"\1", s)
    return re.sub(r"\s+", " ", s).strip()


def shorten(s):
    if len(s) <= MAX_CHARS:
        return s
    cut = s[:MAX_CHARS]
    end = max(cut.rfind(". "), cut.rfind("! "), cut.rfind("? "))
    return cut[: end + 1] if end > 120 else cut.rstrip() + " …"


def parse_readme(name, path):
    title, paras, cur, in_code = "", [], [], False
    with open(path, encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if line.lstrip().startswith("```"):
                in_code = not in_code
                continue
            if in_code:
                continue
            if line.startswith("# ") and not title:
                title = line[2:].strip()
                continue
            if line.startswith("#"):
                if paras or cur:
                    break
                continue
            if not line.strip():
                if cur:
                    paras.append(" ".join(cur))
                    cur = []
                    if paras:
                        break
                continue
            if line.lstrip().startswith(("|", ">", "-", "*", "<")) and not cur:
                continue
            cur.append(line.strip())
    if cur:
        paras.append(" ".join(cur))

    # "blobs — Drei-Kugel-Leiste" / "kurtz: eine Kurzgesagt-Shell" -> subtitle
    title = strip_md(title)
    m = re.match(r"^\s*" + re.escape(name) + r"\s*(?:—|–|-|:)\s*(.+)$", title, re.I)
    if m:
        title = m.group(1)
    elif title.lower() == name.lower():
        title = ""

    desc = strip_md(paras[0]) if paras else ""
    desc = re.sub(r"\s*Voller Auftrag steht unten[^.]*\.", "", desc).strip()
    return title, shorten(desc)


def main():
    out = {}
    for name in sorted(os.listdir(BARS)):
        d = os.path.join(BARS, name)
        if not os.path.isfile(os.path.join(d, "shell.qml")):
            continue
        title, desc = "", ""
        readme = os.path.join(d, "README.md")
        if os.path.isfile(readme):
            try:
                title, desc = parse_readme(name, readme)
            except OSError:
                pass
        preview = ""
        for ext in ("png", "jpg", "jpeg"):
            p = os.path.join(d, "preview." + ext)
            if os.path.isfile(p):
                preview = p
                break
        out[name] = {"title": title, "description": desc, "preview": preview}
    json.dump(out, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    main()
