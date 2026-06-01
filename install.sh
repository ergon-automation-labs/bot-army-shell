#!/usr/bin/env bash
# Bot Army Shell - One-click installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ergon-automation-labs/bot-army-shell/main/install.sh | bash
#
# This script:
#   1. Creates ~/.config/bot-army-shell directory
#   2. Copies shell plugin files
#   3. Makes Ghostty title command executable
#   4. Prints instructions for ~/.zshrc and ghostty config

set -e

CONFIG_DIR="$HOME/.config/bot-army-shell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Bot Army Shell..."

# Create config directory
mkdir -p "$CONFIG_DIR"

# Copy shell plugin
cp "$SCRIPT_DIR/bot-army-context.zsh" "$CONFIG_DIR/"

# Copy Ghostty title command
cp "$SCRIPT_DIR/bot-army-context-title" "$CONFIG_DIR/"
chmod +x "$CONFIG_DIR/bot-army-context-title"

echo ""
echo "Installation complete!"
echo ""
echo "=== Add to ~/.zshrc ==="
echo ""
echo "source $CONFIG_DIR/bot-army-context.zsh"
echo "RPROMPT+='\$$(bot_army_context_prompt)'"
echo ""
echo "=== Add to ~/.config/ghostty/config ==="
echo ""
echo "title-command = $CONFIG_DIR/bot-army-context-title"
echo ""
echo "=== Optional: Run context daemon ==="
echo ""
echo "Makefile targets:"
echo "  make daemon     # Start daemon"
echo "  make daemon-stop # Stop daemon"
echo ""
echo "Or use systemd (see docs/SYSTEMD.md)"
