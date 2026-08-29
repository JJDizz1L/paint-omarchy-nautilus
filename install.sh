#!/bin/bash
# paint-omarchy-nautilus — Install script
# Run from a local clone: ./install.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[paint-omarchy-nautilus]${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }

log "Installing paint-omarchy-nautilus integration..."

# 1. Install theme-set hooks via Omarchy's hook system
log "Installing theme-set hooks..."
for hook in "$REPO_ROOT"/hooks/theme-set.d/*.sh; do
    omarchy hook install theme-set "$hook"
done
ok "Hooks installed to ~/.config/omarchy/hooks/theme-set.d/"

# 2. Install nautilus-python extension
log "Installing nautilus-python extension..."
mkdir -p ~/.local/share/nautilus-python/extensions
cp "$REPO_ROOT/extensions/omarchy_palette.py" ~/.local/share/nautilus-python/extensions/
ok "Extension installed to ~/.local/share/nautilus-python/extensions/"

# 3. Ensure required packages are installed
log "Checking required packages (nautilus, nautilus-python)..."
if ! pacman -Q nautilus nautilus-python &>/dev/null; then
    warn "Packages missing; installing via pkexec (GUI password prompt will appear)..."
    pkexec pacman -S --needed --noconfirm nautilus nautilus-python
    ok "Packages installed"
else
    ok "Packages already present"
fi

# 4. Bootstrap current theme (generates CSS + syncs accent)
log "Bootstrapping current theme palette..."
~/.config/omarchy/hooks/theme-set.d/70-omarchy-nautilus-palette.sh
~/.config/omarchy/hooks/theme-set.d/60-omarchy-gtk-accent.sh
ok "Palette CSS generated, accent synced"

# 5. Verify extension loads cleanly
log "Verifying extension syntax..."
python3 -m py_compile ~/.local/share/nautilus-python/extensions/omarchy_palette.py
ok "Extension compiles without errors"

echo
ok "Installation complete!"
echo
echo "Next steps:"
echo "  1. Restart Nautilus (or run 'omarchy theme set <theme>' to activate)"
echo "  2. Switch themes to see live palette + accent changes"
echo
echo "Files installed:"
echo "  ~/.config/omarchy/hooks/theme-set.d/60-omarchy-gtk-accent.sh"
echo "  ~/.config/omarchy/hooks/theme-set.d/70-omarchy-nautilus-palette.sh"
echo "  ~/.local/share/nautilus-python/extensions/omarchy_palette.py"