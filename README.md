# paint-omarchy-nautilus

Live, hot-reloading Omarchy theme palette for **GNOME Nautilus** (Files).
<img width="360" height="203" alt="2026-08-29_20-09-42_trimmed (1)" src="https://github.com/user-attachments/assets/1ee943b8-6767-4b41-acab-a7f7aef00d0d" />

## What it does


- **Accent color follows your Omarchy theme** — every `omarchy theme set` instantly re-accents every running libadwaita app (Nautilus, zenity dialogs, gnome-software, etc.) via `org.gnome.desktop.interface accent-color`.
- **Full palette matches your theme** — Nautilus windows restyle in-place (backgrounds, sidebars, headerbars, buttons, selections) without restart, using a nautilus-python extension that watches a generated CSS file.
- **Omarchy-native** — uses Omarchy's hook system, survives `omarchy refresh`.

## Install

```bash
yay -S paint-omarchy-nautilus
```
## Enable (if Nautilus is already running)

```bash
systemctl --user enable --now paint-omarchy-nautilus-bootstrap && nautilus -q && nautilus &
```

OR manually:
```bash
git clone https://github.com/JJDizz1L/paint-omarchy-nautilus
cd paint-omarchy-nautilus
./install.sh
```

## How it works

```
omarchy theme set <theme>
       │
       ▼
┌──────────────────┐     ┌─────────────────────────┐
│ omarchy-theme-   │────▶│ 60-omarchy-gtk-accent.sh │──▶ gsettings set accent-color
│ set-gnome        │     └─────────────────────────┘
└──────────────────┘
       │
       ▼
┌──────────────────┐     ┌──────────────────────────────────┐
│ omarchy-hook     │────▶│ 70-omarchy-nautilus-palette.sh   │──▶ ~/.cache/omarchy/gtk/nautilus.css
│ theme-set        │     └──────────────────────────────────┘
└──────────────────┘              │
                                  ▼
                       ┌──────────────────────────────────────────┐
                       │ omarchy_palette.py (nautilus-python)    │
                       │ - GFileMonitor on CSS dir               │
                       │ - Gtk.CssProvider @ STYLE_PROVIDER_     │
                       │   PRIORITY_USER + 1                     │
                       │ - load_from_file() on change            │
                       └──────────────────────────────────────────┘
                                  │
                                  ▼
                       Nautilus windows repaint instantly
```

## Files

```
paint-omarchy-nautilus/
├── colors.toml                    # Default palette (used if no theme active)
├── hooks/theme-set.d/
│   ├── 60-omarchy-gtk-accent.sh   # Maps theme accent → libadwaita enum
│   └── 70-omarchy-nautilus-palette.sh  # Generates @define-color CSS
├── extensions/
│   └── omarchy_palette.py         # In-process hot-reloader
├── install.sh                     # Post-install bootstrap
└── README.md
```

## Requirements

- Omarchy 4.x (Hyprland + Quickshell)
- `nautilus` + `nautilus-python` (installed automatically by `install.sh`)
- `python3` + `gi` (PyGObject, standard on Arch)

## Hook details

### 60-omarchy-gtk-accent.sh
Runs on every theme switch. Reads `accent` from the active theme's `colors.toml`, computes the nearest of libadwaita's 9 accent colors (`blue`, `teal`, `green`, `yellow`, `orange`, `red`, `pink`, `purple`, `slate`), and sets `gsettings set org.gnome.desktop.interface accent-color`. All running libadwaita apps update instantly.

### 70-omarchy-nautilus-palette.sh
Generates 43 `@define-color` overrides (`window_bg_color`, `sidebar_bg_color`, `accent_bg_color`, `destructive_bg_color`, `success_bg_color`, `warning_bg_color`, `shade_color`, etc.) from the theme's `colors.toml` and writes them atomically to `~/.cache/omarchy/gtk/nautilus.css`.

### omarchy_palette.py
Loaded by `nautilus-python` inside the Nautilus process. Installs a `Gtk.CssProvider` at `STYLE_PROVIDER_PRIORITY_USER + 1` (above `~/.config/gtk-4.0/gtk.css`) and monitors the CSS directory. On change, calls `provider.load_from_file()` → Nautilus restyles immediately.

## Uninstall

### AUR Package (`yay -R paint-omarchy-nautilus`)

**Automatically removed by pacman:**
- `/usr/share/paint-omarchy-nautilus/` (system hooks, bootstrap script)
- `/usr/share/nautilus-python/extensions/omarchy_palette.py` (system extension)
- `/usr/lib/systemd/user/paint-omarchy-nautilus-bootstrap.service`
- `/usr/share/licenses/paint-omarchy-nautilus/`

**Preserved (user data — not removed by package manager):**
- `~/.config/omarchy/hooks/theme-set.d/60-omarchy-gtk-accent.sh`
- `~/.config/omarchy/hooks/theme-set.d/70-omarchy-nautilus-palette.sh`
- `~/.cache/omarchy/gtk/nautilus.css` (generated palette)
- Any running Nautilus processes (extension stays loaded until restart)

**Run after AUR removal for full cleanup:**
```bash
# 1. Disable systemd service
systemctl --user disable --now paint-omarchy-nautilus-bootstrap 2>/dev/null

# 2. Remove user hooks
rm -f ~/.config/omarchy/hooks/theme-set.d/60-omarchy-gtk-accent.sh
rm -f ~/.config/omarchy/hooks/theme-set.d/70-omarchy-nautilus-palette.sh

# 3. Clear generated CSS cache
rm -f ~/.cache/omarchy/gtk/nautilus.css

# 4. Restart Nautilus to unload extension
nautilus -q && nautilus &

# 5. Optionally remove packages (keeps nautilus if you use it)
pkexec pacman -R nautilus-python
```

### Manual Install (git clone + `./install.sh`)

**Run for full cleanup:**
```bash
# 1. Remove user hooks
rm -f ~/.config/omarchy/hooks/theme-set.d/60-omarchy-gtk-accent.sh
rm -f ~/.config/omarchy/hooks/theme-set.d/70-omarchy-nautilus-palette.sh

# 2. Remove extension
rm -f ~/.local/share/nautilus-python/extensions/omarchy_palette.py

# 3. Clear generated CSS cache
rm -f ~/.cache/omarchy/gtk/nautilus.css

# 4. Restart Nautilus to unload extension
nautilus -q && nautilus &

# 5. Optionally remove packages
pkexec pacman -R nautilus-python  # keep nautilus if you use it
```

### Transparency Note

Per Arch/Omarchy conventions, **user configuration in `~/.config/` and `~/.local/share/` is never automatically removed** by package managers or install scripts — it's owned by you. This ensures your customizations survive updates and reinstalls. The commands above let you explicitly opt in to full removal.

## License

MIT — do whatever you want with it.

## Credits

Built on Omarchy's hook system, nautilus-python, and libadwaita's live theming channels.
