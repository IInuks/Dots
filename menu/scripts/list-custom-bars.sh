#!/usr/bin/env bash
# Lists all saved custom bars as a JSON array [{slug, name}, ...] for the
# "Eigene" tab's overview. Empty array if none exist yet.
set -euo pipefail

STATE_DIR="$HOME/.local/state/quickdots/custom-bars"
mkdir -p "$STATE_DIR"

python3 -c '
import json, sys, glob, os
out = []
for path in sorted(glob.glob(sys.argv[1] + "/*.json")):
    slug = os.path.splitext(os.path.basename(path))[0]
    try:
        with open(path) as f:
            cfg = json.load(f)
        out.append({"slug": slug, "name": cfg.get("name", slug)})
    except Exception:
        continue
print(json.dumps(out))
' "$STATE_DIR"
