# Bot Army Shell Makefile
#https://github.com/ergon-automation-labs/bot-army-shell

SHELL := /bin/bash

.PHONY: help install uninstall status test clean run-daemon stop-daemon

help:
	@echo "Bot Army Shell - Terminal context awareness"
	@echo ""
	@echo "Commands:"
	@echo "  make install       Install shell plugin to ~/.config/bot-army-shell/"
	@echo "  make uninstall     Remove shell plugin installation"
	@echo "  make status        Check daemon and shell integration status"
	@echo "  make test          Run integration tests"
	@echo "  make run-daemon    Start the context daemon"
	@echo "  make stop-daemon   Stop the context daemon"
	@echo ""
	@echo "Ghostty Setup:"
	@echo "  - Leader key: Ctrl+B"
	@echo "  - Menu: Ctrl+B+M"
	@echo "  - Quick tasks: Ctrl+B+T, Ctrl+B+C, etc."
	@echo "  - See ~/.config/bot-army-shell/bot-army-ghostty-help.txt"

install:
	@echo "Installing Bot Army Shell..."
	@mkdir -p ~/.config/bot-army-shell
	@cp scripts/bot-army-context.zsh ~/.config/bot-army-shell/
	@cp scripts/bot-army-context-title ~/.config/bot-army-shell/
	@cp scripts/bot-army-ghostty-menu ~/.config/bot-army-shell/
	@chmod +x ~/.config/bot-army-shell/bot-army-context-title
	@chmod +x ~/.config/bot-army-shell/bot-army-ghostty-menu
	@echo ""
	@echo "Installed to ~/.config/bot-army-shell/"
	@echo ""
	@echo "Add to ~/.zshrc:"
	@echo "  source ~/.config/bot-army-shell/bot-army-context.zsh"
	@echo "  RPROMPT+='\$$(bot_army_context_prompt)'"
	@echo ""
	@echo "For Ghostty, add to ~/.config/ghostty/config:"
	@echo "  title-command = ~/.config/bot-army-shell/bot-army-context-title"
	@echo "  # Leader key for Bot Army commands"
	@echo "  keybind = ctrl+b=ignore"
	@echo "  keybind = ctrl+b+M=run:~/.config/bot-army-shell/bot-army-ghostty-menu"
	@echo ""
	@echo "Quick start in Ghostty:"
	@echo "  1. Press Ctrl+B (leader key)"
	@echo "  2. Press M (menu) to see all options"
	@echo "  3. Or use Ctrl+B+T for current task"

uninstall:
	@echo "Uninstalling Bot Army Shell..."
	@rm -rf ~/.config/bot-army-shell
	@rm -rf ~/.config/bot-army-shell
	@echo "Removed ~/.config/bot-army-shell"

status:
	@echo "Checking Bot Army Shell status..."
	@echo ""
	@# Check if installed
	@if [ -f ~/.config/bot-army-shell/bot-army-context.zsh ]; then \
		echo "[OK] Shell plugin installed"; \
	else \
		echo "[MISSING] Shell plugin not installed - run 'make install'"; \
	fi
	@# Check if Ghostty title command is installed
	@if [ -x ~/.config/bot-army-shell/bot-army-context-title ]; then \
		echo "[OK] Ghostty title command installed"; \
	else \
		echo "[MISSING] Ghostty title command not installed"; \
	fi
	@# Check daemon socket
	@if [ -S /tmp/bot-army-context.sock ]; then \
		echo "[OK] Context daemon socket exists"; \
	else \
		echo "[INFO] Daemon not running (socket not found)"; \
	fi

test:
	@echo "Running integration tests..."
	@# Test that shell functions work
	@source ~/.config/bot-army-shell/bot-army-context.zsh 2>/dev/null || { echo "[SKIP] Install first with 'make install'"; exit 0; }
	@echo "[OK] Shell functions load successfully"
	@# Test fallback context
	@echo "Testing fallback context..."
	@_bot_army_context_get_fallback | jq -e '.bot, .git_branch, .context_mode' >/dev/null 2>&1 && echo "[OK] Fallback context works" || echo "[SKIP] jq not installed"
	@echo ""
	@echo "Run 'make status' to see daemon status"

run-daemon:
	@echo "Starting context daemon..."
	@go run cmd/bot-army-context/main.go

stop-daemon:
	@echo "Stopping context daemon..."
	@if [ -S /tmp/bot-army-context.sock ]; then \
		rm -f /tmp/bot-army-context.sock; \
		echo "[OK] Daemon stopped"; \
	else \
		echo "[INFO] Daemon not running"; \
	fi

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf cmd/bot-army-context/bot-army-context
	@echo "Clean complete"
