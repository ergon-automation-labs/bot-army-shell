# Bot Army Shell - Systemd Service

## Quick Start

For persistent daemon without user login:

```bash
# Copy service file
mkdir -p ~/.config/systemd/user
cp docs/systemd/bot-army-context.service ~/.config/systemd/user/

# Enable and start
systemctl --user enable bot-army-context
systemctl --user start bot-army-context

# Check status
systemctl --user status bot-army-context
```

## Service File

See `docs/systemd/bot-army-context.service` for the service definition.

## Environment

The service reads environment from:
1. Systemd config file
2. `~/.config/environment` (for user-wide env)

## Logging

```bash
# View daemon logs
journalctl --user -u bot-army-context -f

# Logs go to systemd journal
```
