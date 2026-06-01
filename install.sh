#!/usr/bin/env bash
# Bot Army Shell - One-click installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ergon-automation-labs/bot-army-shell/main/install.sh | bash
#
# This script:
#   1. Creates ~/.config/bot-army-shell directory
#   2. Copies all shell plugin files
#   3. Makes Ghostty title command and menu executable
#   4. Prints instructions for ~/.zshrc and ghostty config

set -e

CONFIG_DIR="$HOME/.config/bot-army-shell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Bot Army Shell..."

# Create config directory
mkdir -p "$CONFIG_DIR"

# Copy shell plugins
cp "$SCRIPT_DIR/bot-army-context.zsh" "$CONFIG_DIR/"
cp "$SCRIPT_DIR/bot-army-context-title" "$CONFIG_DIR/"
cp "$SCRIPT_DIR/bot-army-ghostty-menu" "$CONFIG_DIR/"
cp "$SCRIPT_DIR/bot-army-status-bar.zsh" "$CONFIG_DIR/"
cp "$SCRIPT_DIR/bot-army-magic-commands.zsh" "$CONFIG_DIR/"
cp "$SCRIPT_DIR/bot-army-intent-recognizer.zsh" "$CONFIG_DIR/"
chmod +x "$CONFIG_DIR/bot-army-context-title"
chmod +x "$CONFIG_DIR/bot-army-ghostty-menu"

# Create help file
cat > "$CONFIG_DIR/bot-army-ghostty-help.txt" << 'EOF'
Bot Army Ghostty Menu

Quick Start:
  Ctrl+B  → Leader key (press first)
  Ctrl+B+M → Show menu
  Ctrl+B+T → Show current task
  Ctrl+B+C → Create new task

Menu Options:
  M - Show current task       (bridge.task.current)
  N - Create new task         (bridge.task.create)
  C - Context switch          (change focus mode)
  P - PARA search             (para.fs.search)
  B - Bot status              (system.health.list)
  R - Reflection              (bridge.reflection.record)
  T - Timer / focus           (in development)
  Q - Quick command           (in development)

Key Sequences (Leader: Ctrl+B):
  M / m  → Menu
  T      → Show current task
  C      → Create new task
  R      → Record reflection
  P      → PARA search
  S      → Bot status
  F      → Context: focused
  M      → Context: meeting
  C      → Context: casual
  D      → Context: DND
  H      → Show this help
  I      → Current context info
  N      → NATS CLI
  L      → Log tail

Magic Commands (shell):
  !open    - Open task, project, docs, related
  !schedule - Schedule tasks, meetings, timers
  !find    - Search across Bot Army
  !status  - Full system status

For full documentation, visit:
https://github.com/ergon-automation-labs/bot-army-shell
EOF

echo ""
echo "Installation complete!"
echo ""
echo "=== Add to ~/.zshrc ==="
echo ""
echo "source $CONFIG_DIR/bot-army-context.zsh"
echo "source $CONFIG_DIR/bot-army-status-bar.zsh"
echo "source $CONFIG_DIR/bot-army-magic-commands.zsh"
echo "source $CONFIG_DIR/bot-army-intent-recognizer.zsh"
echo "RPROMPT+='\$(_bot_army_status_bar)'"
echo ""
echo "=== Add to ~/.config/ghostty/config ==="
echo ""
echo "title-command = $CONFIG_DIR/bot-army-context-title"
echo "# Leader key for Bot Army commands"
echo "keybind = ctrl+b=ignore"
echo "keybind = ctrl+b+M=run:$CONFIG_DIR/bot-army-ghostty-menu"
echo ""
echo "=== Quick Start in Ghostty ==="
echo "1. Press Ctrl+B (leader key)"
echo "2. Press M (menu) to see all options"
echo "3. Or use !open, !find, !schedule commands"
echo ""
echo "Or use systemd (see docs/SYSTEMD.md)"
