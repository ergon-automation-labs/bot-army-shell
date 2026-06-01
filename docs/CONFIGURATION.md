# Bot Army Shell - Configuration

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BOT_ARMY_CONTEXT_SOCKET` | `/tmp/bot-army-context.sock` | Path to Unix socket |
| `NATS_SERVERS` | `localhost:4223` | NATS servers for context updates |

## Makefile Targets

### Installation
```bash
make install        # Install shell plugin
make uninstall      # Remove installation
```

### Daemon Management
```bash
make daemon         # Start daemon
make daemon-stop    # Stop daemon
make status         # Check daemon status
```

### Testing
```bash
make test           # Run integration tests
make clean          # Clean build artifacts
```

## Config File Format

Not currently used - all configuration via environment variables.

## Ghostty Integration

```ini
# ~/.config/ghostty/config
title-command = ~/.config/bot-army-shell/bot-army-context-title
window-decoration = true
```

## Zsh Integration

```zsh
# ~/.zshrc
source ~/.config/bot-army-shell/bot-army-context.zsh
RPROMPT+='$(bot_army_context_prompt)'
```

## Systemd Service (Optional)

For persistent daemon:

```ini
# ~/.config/systemd/user/bot-army-context.service
[Unit]
Description=Bot Army Context Daemon
After=nats-server.service

[Service]
Type=simple
ExecStart=/usr/local/bin/bot-army-context
Environment=NATS_SERVERS=localhost:4223
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable with:
```bash
systemctl --user enable bot-army-context
systemctl --user start bot-army-context
```
