# Bot Army Context Awareness
# Provides contextual information for shell prompts and terminal titles
#
# Usage:
#   source ~/.config/bot-army-shell/bot-army-context.zsh
#   RPROMPT+='$(bot_army_context_prompt)'
#
# For Ghostty:
#   title-command = ~/.config/bot-army-shell/bot-army-context-title

# Cache for context data to avoid excessive daemon queries
_BOT_ARMY_CONTEXT_CACHE=()
_BOT_ARMY_CONTEXT_CACHE_TIME=0
_BOT_ARMY_CONTEXT_CACHE_TTL=5  # seconds

# Path to the context daemon socket (can be overridden)
BOT_ARMY_CONTEXT_SOCKET="${BOT_ARMY_CONTEXT_SOCKET:-/tmp/bot-army-context.sock}"

# Query the context daemon for current context
# Returns JSON string or empty string on failure
_bot_army_context_query_daemon() {
  local socket="$BOT_ARMY_CONTEXT_SOCKET"

  # Check if socket exists
  if [[ ! -S "$socket" ]]; then
    return 1
  fi

  # Query daemon using netcat or socat
  if command -v nc >/dev/null 2>&1; then
    printf '{}' | nc -U "$socket" 2>/dev/null
  elif command -v socat >/dev/null 2>&1; then
    printf '{}' | socat - UNIX-CONNECT:"$socket" 2>/dev/null
  else
    # Fallback: try to read as if it's a file (not ideal but avoids hanging)
    cat "$socket" 2>/dev/null
  fi
}

# Get context data, using cache if available and fresh
_bot_army_context_get() {
  local now=$EPOCHSECONDS

  # Return cached data if still fresh
  if (( now - _BOT_ARMY_CONTEXT_CACHE_TIME < _BOT_ARMY_CONTEXT_CACHE_TTL )) &&
     [[ ${#_BOT_ARMY_CONTEXT_CACHE[@]} -gt 0 ]]; then
    printf '%s' "${_BOT_ARMY_CONTEXT_CACHE[@]}"
    return 0
  fi

  # Try to query daemon
  local context_json
  context_json=$(_bot_army_context_query_daemon)

  if [[ -n "$context_json" ]]; then
    _BOT_ARMY_CONTEXT_CACHE=("$context_json")
    _BOT_ARMY_CONTEXT_CACHE_TIME=$now
    printf '%s' "$context_json"
    return 0
  fi

  # Fallback to basic context if daemon not available
  local fallback_context
  fallback_context=$(_bot_army_context_get_fallback)

  _BOT_ARMY_CONTEXT_CACHE=("$fallback_context")
  _BOT_ARMY_CONTEXT_CACHE_TIME=$now
  printf '%s' "$fallback_context"
}

# Get fallback context when daemon is not available
_bot_army_context_get_fallback() {
  local bot_name=""
  local git_branch=""
  local context_mode="unknown"

  # Extract bot name from directory if in bot_army_* directory
  local cwd="$PWD"
  if [[ "$cwd" =~ /bot_army_([^/]+)(/.*)?$ ]]; then
    bot_name="${match[1]}"
  fi

  # Get git branch if in a git repository
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || git_branch=""
  fi

  # Build fallback JSON
  printf '{"bot":"%s","git_branch":"%s","context_mode":"%s","source":"fallback"}' \
    "$bot_name" "$git_branch" "$context_mode"
}

# Format context for shell prompt (e.g., RPROMPT)
# Returns string suitable for right prompt
_bot_army_context_prompt() {
  local context_json
  context_json=$(_bot_army_context_get)

  # If we have jq, use it to parse JSON
  if command -v jq >/dev/null 2>&1 && [[ -n "$context_json" ]]; then
    local bot git_branch context_mode
    bot=$(echo "$context_json" | jq -r '.bot // empty' 2>/dev/null)
    git_branch=$(echo "$context_json" | jq -r '.git_branch // empty' 2>/dev/null)
    context_mode=$(echo "$context_json" | jq -r '.context_mode // empty' 2>/dev/null)

    local parts=()
    [[ -n "$bot" ]] && parts+=("[${bot}]")
    [[ -n "$git_branch" ]] && parts+=("(${git_branch})")
    [[ -n "$context_mode" && "$context_mode" != "unknown" ]] && parts+=("${context_mode}")

    if [[ ${#parts[@]} -gt 0 ]]; then
      printf '%s' "${parts[*]}"
    else
      printf ''
    fi
  else
    # Simple fallback without jq
    if [[ "$context_json" == *'bot'* ]]; then
      # Very basic extraction - look for patterns
      if [[ "$context_json" == *'bot"*'*'git_branch'* ]]; then
        echo "[context]"
      fi
    fi
  fi
}

# Format context for terminal title (e.g., for ghostty title-command)
# Returns string suitable for window/tab title
_bot_army_context_title() {
  local context_json
  context_json=$(_bot_army_context_get)

  if command -v jq >/dev/null 2>&1 && [[ -n "$context_json" ]]; then
    local bot git_branch context_mode
    bot=$(echo "$context_json" | jq -r '.bot // ""' 2>/dev/null)
    git_branch=$(echo "$context_json" | jq -r '.git_branch // ""' 2>/dev/null)
    context_mode=$(echo "$context_json" | jq -r '.context_mode // ""' 2>/dev/null)

    local title_parts=()
    [[ -n "$bot" ]] && title_parts+=("$bot")
    [[ -n "$git_branch" ]] && title_parts+=("$git_branch")
    [[ -n "$context_mode" && "$context_mode" != "unknown" ]] && title_parts+=("$context_mode")

    if [[ ${#title_parts[@]} -gt 0 ]]; then
      printf '%s' "${title_parts[*]}"
    else
      # Fallback to just current directory if no context
      basename "$PWD"
    fi
  else
    # Fallback: show current directory
    basename "$PWD"
  fi
}

# Public function to get context-aware prompt segment
# Usage: PROMPT+='$(bot_army_context_prompt)'
bot_army_context_prompt() {
  _bot_army_context_prompt
}

# Public function to get context-aware title
# Usage: For ghostty title-command or precmd hook
bot_army_context_title() {
  _bot_army_context_title
}

# Initialize: Add to precmd to update title before each prompt
# Uncomment to enable automatic title updates
# autoload -Uz add-zsh-hook
# add-zsh-hook precmd bot_army_context_title

# Status bar for bot army in prompt
# Shows: bot name, context mode, git branch in a compact format
bot_army_status() {
  local context_json
  context_json=$(_bot_army_context_get)

  if command -v jq >/dev/null 2>&1 && [[ -n "$context_json" ]]; then
    local bot context_mode
    bot=$(echo "$context_json" | jq -r '.bot // ""' 2>/dev/null)
    context_mode=$(echo "$context_json" | jq -r '.context_mode // ""' 2>/dev/null)

    if [[ -n "$bot" ]]; then
      # Format: [gtd] 🎯 focused or [para] 💼 meeting
      local icon="💡"
      case "$context_mode" in
        focused) icon="🎯" ;;
        meeting) icon="💼" ;;
        casual) icon="💬" ;;
        DND) icon="🚫" ;;
      esac
      echo "[$bot] $icon $context_mode"
    fi
  fi
}

# Test function to verify integration
_bot_army_context_test() {
  echo "Testing Bot Army Context Integration..."
  echo ""

  # Check if functions are loaded
  if type -f bot_army_context_prompt >/dev/null 2>&1; then
    echo "[OK] Shell functions are loaded"
  else
    echo "[ERROR] Shell functions not loaded - source the script first"
    return 1
  fi

  # Test fallback context
  echo ""
  echo "Testing fallback context..."
  local test_context
  test_context=$(_bot_army_context_get_fallback)
  echo "Fallback context: $test_context"

  # Test with jq if available
  if command -v jq >/dev/null 2>&1; then
    echo ""
    echo "Parsing with jq:"
    echo "$test_context" | jq '.'
  else
    echo ""
    echo "[SKIP] jq not installed - skipping JSON parsing test"
  fi

  # Check daemon socket
  echo ""
  if [[ -S "$BOT_ARMY_CONTEXT_SOCKET" ]]; then
    echo "[OK] Context daemon socket exists at $BOT_ARMY_CONTEXT_SOCKET"
    echo "Testing daemon query..."
    local daemon_context
    daemon_context=$(_bot_army_context_query_daemon)
    if [[ -n "$daemon_context" ]]; then
      echo "Daemon context: $daemon_context"
    else
      echo "[WARN] Daemon responded but no context returned"
    fi
  else
    echo "[INFO] Context daemon not running (socket not found)"
    echo "[INFO] Install daemon with 'make run-daemon' or see docs/SYSTEMD.md"
  fi

  echo ""
  echo "Test complete!"
}
