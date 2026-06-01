# Ghostty Menu - Quick Actions for Bot Army

The Ghostty menu system provides quick access to Bot Army commands without leaving your terminal.

## Quick Start

1. Press **Ctrl+B** (leader key)
2. Press **M** to show the full menu
3. Or use direct bindings:
   - **Ctrl+B+T** - Show current task
   - **Ctrl+B+C** - Create new task
   - **Ctrl+B+R** - Record reflection
   - **Ctrl+B+P** - PARA search
   - **Ctrl+B+S** - Bot status

## Menu Options

| Key | Action | Description |
|-----|--------|-------------|
| **M** | Show current task | Queries `bridge.task.current` |
| **N** | Create new task | Opens task creation form via `bridge.task.create` |
| **C** | Context switch | Change focus mode (focused/meeting/casual/DND) |
| **P** | PARA search | Search PARA for notes |
| **B** | Bot status | Shows system health from NATS |
| **R** | Reflection | Record a reflection via `bridge.reflection.record` |
| **T** | Timer | Timer / focus mode (in development) |
| **Q** | Quick command | Quick command interface (in development) |

## Direct Key Bindings

All bindings use **Ctrl+B** as the leader key:

| Binding | Command |
|---------|---------|
| `Ctrl+B+M` | Menu |
| `Ctrl+B+T` | `bridge.task.current` |
| `Ctrl+B+C` | `bridge.task.create` |
| `Ctrl+B+R` | `bridge.reflection.record` |
| `Ctrl+B+P` | `para.fs.search` |
| `Ctrl+B+S` | `system.health.list` |
| `Ctrl+B+F` | Context: focused |
| `Ctrl+B+M` | Context: meeting |
| `Ctrl+B+C` | Context: casual |
| `Ctrl+B+D` | Context: DND |
| `Ctrl+B+H` | Show help |
| `Ctrl+B+I` | Current context info |
| `Ctrl+B+N` | NATS CLI |
| `Ctrl+B+L` | Log tail |

## Configuration

Add to `~/.config/ghostty/config`:

```ini
# Leader key (required - ignore prevents it from reaching terminal)
keybind = ctrl+b=ignore

# Menu
keybind = ctrl+b+M=run:~/.config/bot-army-shell/bot-army-ghostty-menu

# Quick actions
keybind = ctrl+b+T=text:\x15bridge.task.current\n
keybind = ctrl+b+C=text:\x15bridge.task.create\n
keybind = ctrl+b+R=text:\x15bridge.reflection.record\n
```

## Notes

- The leader key (`Ctrl+B`) is configured to `ignore` so it doesn't get sent to the shell
- Quick actions use `text:` to send commands to the terminal
- The menu script uses `fzf`, `bemenu`, or `rofi` if available, otherwise shows a terminal menu
