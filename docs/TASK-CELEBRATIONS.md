# Task Celebration Notifications

Automatic celebration popups in tmux when you complete GTD tasks via the bridge.

## Overview

When you mark a task as complete using `bridge.task.complete` or `/gtd complete <task_id>`, the task celebrations notifier:

1. Receives the completion event from NATS (port 4222)
2. Creates a new tmux window at the top of your active session
3. Displays the task title in large banner text
4. Auto-closes after 3 seconds

## Setup

### Build

```bash
cd /Users/abby/code/bot-army-shell
make build-task-celebrations
```

This creates the `./task-celebrations` binary.

### Install (Optional)

Add to your shell startup (`.zshrc` or `.bashrc`):

```bash
# Start task celebrations notifier on shell startup
~/code/bot-army-shell/task-celebrations &
```

Or use launchd for background operation.

### Manual Start

```bash
# In your tmux session
cd /Users/abby/code/bot-army-shell
make start-task-celebrations
```

Or directly:

```bash
NATS_URL=nats://localhost:4222 ./task-celebrations
```

## Usage

Once the notifier is running:

1. Complete a task via the CLI:
   ```bash
   /gtd complete <task_id>
   ```

2. Or via NATS directly:
   ```bash
   nats request --server nats://localhost:4222 bridge.task.complete '{
     "task_id": "<task_id>"
   }' --timeout 5s
   ```

3. A celebration window pops up in your active tmux session showing:
   ```
   🎉 Task Completed: <task title>
   ```

## Requirements

- **tmux**: Must be running with an active session
- **figlet** (optional): For fancy banner text. Install with:
  ```bash
  brew install figlet
  ```
  Without figlet, plain text display is used.

## Environment Variables

- `NATS_URL`: NATS server URL (default: `nats://localhost:4222`)

## Logs

The notifier outputs logs to stdout:

```
2026/06/06 15:49:41 Connected to NATS at nats://localhost:4222
2026/06/06 15:49:41 Listening for task completions... (Ctrl+C to exit)
2026/06/06 15:49:55 Task completed: Buy milk
```

## Troubleshooting

### No celebration window appears

1. **Check tmux is running**: `tmux list-sessions`
2. **Check notifier is running**: `ps aux | grep task-celebrations`
3. **Check NATS connection**: Notifier logs should show "Connected to NATS"
4. **Check figlet is available**: `which figlet` (optional, not required)

### "Failed to connect to NATS"

- Ensure NATS is running on port 4222: `nats server info --server nats://localhost:4222`
- Set `NATS_URL` environment variable if NATS is on a different host/port

## Example Flow

```bash
# Terminal 1: Start the notifier
cd ~/code/bot-army-shell
make start-task-celebrations

# Terminal 2 (in tmux): Create and complete a task
/gtd task "Do something awesome"

# Get the task ID from the response, then
/gtd complete <task_id>

# Terminal 1: See celebration window pop up with task title
# Celebration window auto-closes after 3 seconds
```

## Architecture

```
GTD Task Completed (bridge)
    ↓
NATS: events.gtd.task.completed
    ↓
task-celebrations listener
    ↓
tmux new-window (celebration)
    ↓
Display task title (3 seconds)
    ↓
Auto-close window
```

The notifier subscribes to `events.gtd.task.completed` on NATS and creates a popup window for each completion event.
