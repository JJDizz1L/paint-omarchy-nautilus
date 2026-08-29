# paint-omarchy-nautilus

Live, hot-reloading Omarchy theme palette for **GNOME Nautilus** (Files).

## What it does

- **Accent color follows your Omarchy theme** — every `omarchy theme set` instantly re-accents every running libadwaita app (Nautilus, zenity dialogs, gnome-software, etc.) via `org.gnome.desktop.interface accent-color`.
- **Full palette matches your theme** — Nautilus windows restyle in-place (backgrounds, sidebars, headerbars, buttons, selections) without restart, using a nautilus-python extension that watches a generated CSS file.
- **Omarchy-native** — installs via `omarchy theme install`, uses Omarchy's hook system, survives `omarchy refresh`.

## Demo

| Moon Orbit (dark) | Catppuccin Latte (light) |
|:---:|:---:|
| ![Moon Orbit](backgrounds/preview.png) | ![Catppuccin Latte](backgrounds/preview-unlock.png) |

*(Screenshots auto-generated on theme switch — no Nautilus restart)*

## Install

### Option A: As an Omarchy theme (recommended)

```bash
omarchy theme install https://github.com/yourname/paint-omarchy-nautilus
cd ~/.config/omarchy/themes/paint-omarchy-nautilus
./install.sh
```

### Option B: Standalone (no theme dependency)

```bash
git clone https://github.com/yourname/paint-omarchy-nautilus
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
├── colors.toml                    # Theme palette (mode, accent, backgrounds...)
├── icons.theme                    # GTK icon theme (Yaru-purple)
├── shell.toml                     # Optional bar customizations
├── backgrounds/                   # Theme wallpapers
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

```bash
# Remove hooks
rm ~/.config/omarchy/hooks/theme-set.d/60-omarchy-gtk-accent.sh
rm ~/.config/omarchy/hooks/theme-set.d/70-omarchy-nautilus-palette.sh

# Remove extension
rm ~/.local/share/nautilus-python/extensions/omarchy_palette.py

# Optionally remove packages
pkexec pacman -R nautilus-python  # keep nautilus if you use it
```

## License

MIT — do whatever you want with it.

## Credits

Built on Omarchy's hook system, nautilus-python, and libadwaita's live theming channels.