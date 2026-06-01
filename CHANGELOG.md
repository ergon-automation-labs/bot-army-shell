# Bot Army Shell -CHANGELOG

## v0.1.0 (2024-01-15)

Initial release

### Features
- Shell plugin with context-aware prompt formatting
- Ghostty title command integration
- Optional context daemon with NATS subscription
- Fallback context from filesystem detection

### Components
- `scripts/bot-army-context.zsh` - Zsh plugin
- `scripts/bot-army-context-title` - Ghostty title command
- `cmd/bot-army-context/` - Go context daemon
- `Makefile` - Installation and management targets
