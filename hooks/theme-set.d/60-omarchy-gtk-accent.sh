#!/bin/bash
# Sync the active Omarchy theme accent to libadwaita's accent-color gsetting.
# libadwaita hot-reloads accent-color in every running app (Nautilus, GNOME
# apps, GTK dialogs, ...), so this restyles them live on `omarchy theme set`.
# Theme slug arrives in $1; the staged colors.toml is the source of truth.

[[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || exit 0

COLORS_FILE=$HOME/.local/state/omarchy/current/theme/colors.toml
[[ -f $COLORS_FILE ]] || exit 0

NEAREST=$(python3 - "$COLORS_FILE" <<'PY'
import re, sys

try:
    text = open(sys.argv[1]).read()
except OSError:
    sys.exit(0)
m = re.search(r'^[ \t]*accent[ \t]*=[ \t]*["\']?#?([0-9a-fA-F]{6})', text, re.M)
if not m:
    sys.exit(0)
r, g, b = (int(m.group(1)[i:i + 2], 16) for i in (0, 2, 4))
mx, mn = max(r, g, b), min(r, g, b)
if mx == 0 or (mx - mn) / mx < 0.20:
    print("slate")
    sys.exit(0)
d = mx - mn
if mx == r:
    hue = (60 * ((g - b) / d)) % 360
elif mx == g:
    hue = 60 * ((b - r) / d) + 120
else:
    hue = 60 * ((r - g) / d) + 240
names = ["red", "orange", "yellow", "green", "teal", "blue", "purple", "pink"]
refs = [0, 28, 52, 125, 185, 215, 275, 330]
best, best_d = "blue", 999
for name, ref in zip(names, refs):
    diff = abs(hue - ref)
    diff = min(diff, 360 - diff)
    if diff < best_d:
        best, best_d = name, diff
print(best)
PY
)

[[ -n $NEAREST ]] || exit 0

CURRENT=$(gsettings get org.gnome.desktop.interface accent-color 2>/dev/null | tr -d "'")
[[ $CURRENT == "$NEAREST" ]] || gsettings set org.gnome.desktop.interface accent-color "$NEAREST"
