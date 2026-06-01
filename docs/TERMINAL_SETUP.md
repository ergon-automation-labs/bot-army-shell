# Bot Army Shell - Terminal Setup Guide

## Supported Terminals

| Terminal | Title Command Support | Status |
|----------|----------------------|--------|
| Ghostty  | `title-command`      | ✅ Full support |
| Alacritty | `window.title`       | ⚠️ Static only |
| Kitty    | `kitty @ set-window-title` | ⚠️ Requires command |
| WezTerm  | `osc52` / `set_title` | ⚠️ Requires config |
| Terminal.app | `osascript`        | ⚠️ Requires AppleScript |

## Ghostty (Recommended)

Ghostty provides the cleanest integration via `title-command`:

```ini
# ~/.config/ghostty/config
title-command = ~/.config/bot-army-shell/bot-army-context-title
window-decoration = true
```

## Zsh Integration

Add to `~/.zshrc`:

```zsh
# Source the plugin
source ~/.config/bot-army-shell/bot-army-context.zsh

# Add to right prompt (RPROMPT)
RPROMPT+='$(bot_army_context_prompt)'

# Or left prompt (PROMPT)
# PROMPT+='$(bot_army_context_prompt) '

# Optional: Enable automatic title updates
# autoload -Uz add-zsh-hook
# add-zsh-hook precmd bot_army_context_title
```

## Context Display Format

### Prompt Format: `[bot] (branch) [mode]`

Examples:
```
gtd (main) [focused]
para (dev) [meeting]
terrain (main) [deep_work]
```

### Empty State
```
# No bot directory
~ (main) [unknown]

# Not in git repo
gtd () [unknown]
```

## Troubleshooting

### Prompt not showing
1. Verify plugin is sourced: `type bot_army_context_prompt`
2. Check `jq` is installed: `which jq`
3. Verify `EPOCHSECONDS` is available (zsh 5.0+)

### Title not updating in Ghostty
1. Check `title-command` path is correct and executable
2. Verify daemon is running: `ls -la /tmp/bot-army-context.sock`
3. Test daemon query: `printf '{}' | nc -U /tmp/bot-army-context.sock`

### Context shows "unknown"
- Daemon not running → Falls back to filesystem detection
- Not in `bot_army_*` directory → Falls back to "unknown" mode
- Git repo without branch → Falls back to empty branch

## Examples

### Minimal Setup
```zsh
# ~/.zshrc
source ~/.config/bot-army-shell/bot-army-context.zsh
RPROMPT+='$(bot_army_context_prompt)'
```

### Advanced Setup
```zsh
# ~/.zshrc
source ~/.config/bot-army-shell/bot-army-context.zsh

# Right prompt: bot and branch
RPROMPT+='$(bot_army_context_prompt)'

# Left prompt: show time + context if available
PROMPT+='$(if [ -n "$(bot_army_context_prompt)" ]; then echo " [$(bot_army_context_prompt)]"; fi)%# '
```
