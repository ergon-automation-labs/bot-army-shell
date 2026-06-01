# Bot Army Shell

Terminal context awareness for Bot Army - shell prompt enhancements and Ghostty integration.

## Features

- **Context-aware prompts** - Shows bot name, git branch, and current context mode
- **Git file status detection** - Displays file change indicators when there are untracked/staged/unstaged files
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
RPROMPT+='$(_bot_army_context_prompt)'
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
│  prompt = $(_bot_army_context_prompt)       │
│  title  = bot_army_context_title           │
│                                             │
└──────────────────┬──────────────────────────┘
                   │ Query socket
                   ▼
┌─────────────────────────────────────────────┐
│       Context Daemon (optional)             │
│                                             │
│  - Subscribes to context.state.current      │
│  - Subscribes to context.signal.filewatcher │
│  - Serves via Unix socket                   │
│  - Tracks PWD for bot detection             │
│  - Queries filewatcher for git status       │
│                                             │
└──────────────────┬──────────────────────────┘
                   │ Query socket
                   ▼
┌─────────────────────────────────────────────┐
│          Fallback Context                   │
│                                             │
│  - Directory-based (bot_army_*)            │
│  - Git branch detection                     │
│  - File status detection (git status)       │
│  - Default "unknown" mode                   │
│                                             │
└─────────────────────────────────────────────┘
```

## File Status Display

The shell prompt (via `bot_army_context_prompt`) and status bar (via `bot_army_status_bar`) show file change indicators when git changes are detected:

| Icon | Meaning |
|------|---------|
| `●` | Some files changed (1-5) |
| `●●●` | Multiple files changed (6+) |

Example prompt:
```
[gtd] (main) ● 3 files
```

When there are no changes, the prompt shows only the context information:
```
[gtd] (main) focused
```

## Quick Reference

| Function | Usage | Description |
|----------|-------|-------------|
| `bot_army_context_prompt` | `RPROMPT+='$(bot_army_context_prompt)'` | Shows bot, branch, and file status |
| `bot_army_status_bar` | `RPROMPT+='$(_bot_army_status_bar)'` | Shows system status with file indicators |

**Note**: In zsh, use `$(function_name)` for command substitution, not `$function_name`. The latter tries to expand a variable named `function_name`.

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
│   ├── bot-army-context.zsh        # Zsh context plugin
│   ├── bot-army-context-title      # Ghostty title command
│   ├── bot-army-status-bar.zsh     # Zsh status bar plugin
│   ├── bot-army-magic-commands.zsh # Magic commands (!open, etc.)
│   └── bot-army-intent-recognizer.zsh # Intent recognition
├── internal/
│   └── daemon/                     # Daemon implementation
├── docs/
├── config/
├── Makefile
└── install.sh
```

## License

MIT
