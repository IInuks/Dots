#!/usr/bin/env bash
# Called by the mango keybind. Routed through a script file (instead of the
# ipc call inline in bind=) so mango's own config-line parser never has to
# deal with shell metacharacters -- it choked on `>`/`2>&1` when an earlier,
# more complex debug version of this command was inlined directly.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
exec qs -p "$ROOT/menu" ipc call menu toggle
