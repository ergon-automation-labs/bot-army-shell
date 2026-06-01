# Bot Army Shell Architecture

## Overview

Bot Army Shell provides context-aware terminal experiences through:
1. **Shell Plugin** - Zsh functions for prompt/title formatting
2. **Context Daemon** (optional) - Real-time context updates via NATS
3. **Fallback Mode** - Static context from filesystem when daemon unavailable

## Components

### Shell Plugin (`scripts/bot-army-context.zsh`)

Zsh functions that query the daemon or use fallback context:

```
bot_army_context_prompt()
    └─> _bot_army_context_get()
        ├─> _bot_army_context_query_daemon()  [Try daemon first]
        │   └─> Unix socket query
        │
        └─> _bot_army_context_get_fallback()   [If daemon fails]
            ├─> Directory parsing (bot_army_*)
            ├─> Git branch detection
            └─> JSON construction
```

### Context Daemon (`cmd/bot-army-context/`)

Go service that:
1. Subscribes to `context.state.current` via NATS
2. Serves JSON via Unix socket (`/tmp/bot-army-context.sock`)
3. Maintains fallback context via filesystem polling

```
┌─────────────────────────────────────────────┐
│           Go Daemon Process                 │
│                                             │
│  ┌──────────────┐  ┌─────────────────┐     │
│  │ NATS Subscribe │  │ Socket Listener │     │
│  │  context.state │  │   /tmp/sock     │     │
│  │   .current     │  │                 │     │
│  └──────┬───────┘  └────────┬────────┘     │
│         │                   │                │
│         ▼                   ▼                │
│  ┌─────────────────┐  ┌───────────────┐    │
│  │ Context Store   │  │ Filesystem    │    │
│  │ (currentContext)│  │ Poller        │    │
│  └─────────────────┘  └───────────────┘    │
└─────────────────────────────────────────────┘
```

## Protocol

### Daemon Query Protocol

**Request:** Empty JSON object `{}`
**Response:** JSON with fields:
```json
{
  "bot": "gtd",
  "git_branch": "main",
  "context_mode": "focused",
  "source": "daemon"
}
```

**Source Values:**
- `daemon` - Real-time context from NATS
- `fallback` - Filesystem-derived context

### NATS Message Schema

**Subject:** `context.state.current`

**Message:**
```json
{
  "bot": "gtd",
  "git_branch": "main",
  "context_mode": "focused",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Filesystem Detection

### Bot Detection
```
Path: /Users/abby/code/bot_army_gtd/lib/handlers.ex
Result: bot = "gtd"
```

Pattern: Extract `bot_army_` prefix from directory path

### Git Branch Detection
```bash
git -C /path/to/repo rev-parse --abbrev-ref HEAD
```

## Caching

Shell plugin caches context for 5 seconds:
- Reduces daemon queries
- Improves prompt responsiveness
- Falls back gracefully on cache expiry

## Error Handling

| Condition | Behavior |
|-----------|----------|
| Daemon not running | Falls back to filesystem context |
| Daemon socket timeout | Returns last cached context |
| jq not installed | Basic JSON parsing |
| Not in git repo | Empty git_branch, "unknown" mode |

## Performance Considerations

1. **5-second cache TTL** - Balances freshness vs. query overhead
2. **10-second filesystem poll** - Low-frequency fallback updates
3. **Unix socket** - Faster than TCP for local communication
4. **Async daemon updates** - NATS push model, no polling

## Security

- Socket permissions: `0666` (world-readable/writable)
- No authentication required (local only)
- No sensitive data in context messages
