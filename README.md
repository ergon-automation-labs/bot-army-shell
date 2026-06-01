# Bot Army Shell

Terminal context awareness for Bot Army - shell prompt enhancements and Ghostty integration.

## Features

- **Context-aware prompts** - Shows bot name, git branch, and current context mode
- **Ghostty title integration** - Auto-updates terminal tab/window titles
- **Optional daemon** - NATS subscriber that tracks `context.state.current` for real-time updates

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ergon-automation-labs/bot-army-shell/main/install.sh | bash
```

## Usage

### Zsh Configuration

Add to `~/.zshrc`:

```zsh
source ~/.config/bot-army-shell/bot-army-context.zsh
RPROMPT+='$(bot_army_context_prompt)'
```

### Ghostty Configuration

Add to `~/.config/ghostty/config`:

```ini
title-command = ~/.config/bot-army-shell/bot-army-context-title
```

## Architecture

```
┌─────────────────────────────────────────────┐
│          Shell (zsh)                        │
│                                             │
│  prompt = $(bot_army_context_prompt)       │
│  title  = bot_army_context_title           │
│                                             │
└──────────────────┬──────────────────────────┘
                   │ Query socket
                   ▼
┌─────────────────────────────────────────────┐
│       Context Daemon (optional)             │
│                                             │
│  - Subscribes to context.state.current      │
│  - Serves via Unix socket                   │
│  - Tracks PWD for bot detection             │
│                                             │
└──────────────────┬──────────────────────────┘
                   │ Query socket
                   ▼
┌─────────────────────────────────────────────┐
│          Fallback Context                   │
│                                             │
│  - Directory-based (bot_army_*)            │
│  - Git branch detection                     │
│  - Default "unknown" mode                   │
│                                             │
└─────────────────────────────────────────────┘
```

## Components

| Component | Location | Description |
|-----------|----------|-------------|
| Shell plugin | `scripts/bot-army-context.zsh` | Zsh functions for prompt/title |
| Daemon (optional) | `cmd/bot-army-context/` | Go service for real-time updates |
| Installer | `install.sh` | One-click setup |

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `BOT_ARMY_CONTEXT_SOCKET` | `/tmp/bot-army-context.sock` | Daemon socket path |
| `NATS_SERVERS` | `localhost:4223` | NATS cluster for context updates |

## Commands

```bash
# Run the context daemon
bot-army-context start

# Stop the context daemon
bot-army-context stop

# Check daemon status
bot-army-context status

# Test shell integration
bot-army-context test
```

## Project Structure

```
bot-army-shell/
├── cmd/
│   └── bot-army-context/           # Go daemon
│       └── main.go
├── scripts/
│   ├── bot-army-context.zsh        # Zsh plugin
│   └── bot-army-context-title      # Ghostty title command
├── internal/
│   └── daemon/                     # Daemon implementation
│       └── nats.go
├── docs/
│   └── ARCHITECTURE.md
├── config/
│   └── default.yaml                # Daemon config
├── Makefile
└── install.sh
```

## License

MIT
