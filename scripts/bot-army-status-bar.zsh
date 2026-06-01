# Bot Army Status Bar
# Comprehensive status display for terminal
# Usage: source ~/.config/bot-army-shell/bot-army-status-bar.zsh
#        PROMPT+='$(bot_army_status_bar)'

# Cache settings
_BOT_ARMY_STATUS_CACHE=()
_BOT_ARMY_STATUS_CACHE_TIME=0
_BOT_ARMY_STATUS_CACHE_TTL=10  # seconds

# Get comprehensive system status
_bot_army_get_status() {
  local now
  now=$EPOCHREALTIME

  # Return cached data if still fresh
  if (( now - _BOT_ARMY_STATUS_CACHE_TIME < _BOT_ARMY_STATUS_CACHE_TTL )) &&
     [[ ${#_BOT_ARMY_STATUS_CACHE[@]} -gt 0 ]]; then
    printf '%s' "${_BOT_ARMY_STATUS_CACHE[@]}"
    return 0
  fi

  local context_json

  # Get context from daemon or fallback
  # Only source if the function is not already defined (avoid recursive sourcing)
  if [[ -f ~/.config/bot-army-shell/bot-army-context.zsh ]]; then
    if ! typeset -f _bot_army_context_get >/dev/null 2>&1; then
      source ~/.config/bot-army-shell/bot-army-context.zsh
    fi
  fi
  # Use the function (either already defined or just sourced)
  local context_json
  context_json=$(_bot_army_context_get)

  # Parse context
  local bot git_branch context_mode
  if command -v jq >/dev/null 2>&1; then
    bot=$(echo "$context_json" | jq -r '.bot // ""' 2>/dev/null)
    context_mode=$(echo "$context_json" | jq -r '.context_mode // "unknown"' 2>/dev/null)
    git_branch=$(echo "$context_json" | jq -r '.git_branch // ""' 2>/dev/null)
  else
    # Fallback parsing without jq
    bot="unknown"
    context_mode="unknown"
    git_branch="none"
  fi

  # Get bot health
  local bot_health="?"
  if command -v nats >/dev/null 2>&1 && [[ -n "$bot" ]]; then
    local health_result
    health_result=$(nats request "system.health.$bot" '{}' --server "${NATS_SERVER:-localhost:4222}" --timeout 2s 2>/dev/null)
    if [[ -n "$health_result" && "$health_result" != *"No responders"* ]]; then
      bot_health="✓"
    else
      bot_health="⚠"
    fi
  fi

  # Get pending task count (if in gtd directory or bridge accessible)
  local pending_tasks="-"
  if [[ -n "$bot" && "$bot" == *"gtd"* ]] || command -v nats >/dev/null 2>&1; then
    local tasks_result
    tasks_result=$(nats request bridge.task.list '{"filter":"pending"}' --server "${NATS_SERVER:-localhost:4222}" --timeout 3s 2>/dev/null)
    if [[ -n "$tasks_result" ]]; then
      pending_tasks=$(echo "$tasks_result" | grep -o '"count":[0-9]*' | grep -o '[0-9]*' || echo "-")
    fi
  fi

  # Get LLM status
  local llm_status="?"
  if command -v nats >/dev/null 2>&1; then
    local llm_health
    llm_health=$(nats request system.health.llm '{}' --server "${NATS_SERVER:-localhost:4222}" --timeout 2s 2>/dev/null)
    if [[ -n "$llm_health" ]]; then
      llm_status="✓"
    fi
  fi

  # Get NATS connection status
  local nats_status="?"
  if command -v nats >/dev/null 2>&1; then
    local nats_info
    nats_info=$(nats info --server "${NATS_SERVER:-localhost:4222}" 2>/dev/null | head -1)
    if [[ -n "$nats_info" ]]; then
      nats_status="✓"
    fi
  fi

  # Get database status
  local db_status="?"
  # Check if PostgreSQL is accessible (simple check)
  if command -v psql >/dev/null 2>&1; then
    if psql -h localhost -p 35432 -U postgres -d postgres -c "SELECT 1" >/dev/null 2>&1; then
      db_status="✓"
    fi
  fi

  # Build status JSON
  local status_result
  status_result=$(printf '{"bot":"%s","context_mode":"%s","git_branch":"%s","bot_health":"%s","pending_tasks":"%s","llm_status":"%s","nats_status":"%s","db_status":"%s"}' \
    "$bot" "$context_mode" "$git_branch" "$bot_health" "$pending_tasks" "$llm_status" "$nats_status" "$db_status")

  # Cache the result
  _BOT_ARMY_STATUS_CACHE=("$status_result")
  _BOT_ARMY_STATUS_CACHE_TIME=$now

  # Return the result
  printf '%s' "$status_result"
}

# Check for git file status via context daemon
_bot_army_check_file_status() {
  local socket="${BOT_ARMY_CONTEXT_SOCKET:-/tmp/bot-army-context.sock}"

  # Only query if socket exists
  if [[ ! -S "$socket" ]]; then
    return 1
  fi

  # Query for file status using nc or socat
  local file_status
  if command -v nc >/dev/null 2>&1; then
    file_status=$(printf 'file_status' | nc -U "$socket" 2>/dev/null)
  elif command -v socat >/dev/null 2>&1; then
    file_status=$(printf 'file_status' | socat - UNIX-CONNECT:"$socket" 2>/dev/null)
  fi

  if [[ -n "$file_status" ]]; then
    echo "$file_status"
    return 0
  fi

  return 1
}

# Format status for prompt (single line)
bot_army_status_bar() {
  local status_json
  status_json=$(_bot_army_get_status)

  local bot context_mode bot_health pending_tasks
  if command -v jq >/dev/null 2>&1; then
    bot=$(echo "$status_json" | jq -r '.bot // ""' 2>/dev/null)
    context_mode=$(echo "$status_json" | jq -r '.context_mode // ""' 2>/dev/null)
    bot_health=$(echo "$status_json" | jq -r '.bot_health // "?"' 2>/dev/null)
    pending_tasks=$(echo "$status_json" | jq -r '.pending_tasks // "-"' 2>/dev/null)
  else
    bot=""
    context_mode=""
    bot_health="?"
    pending_tasks="-"
  fi

  local parts=()

  # Bot name (if in bot_army_* directory)
  [[ -n "$bot" ]] && parts+=("[$bot]")

  # Context mode with icon
  if [[ -n "$context_mode" && "$context_mode" != "unknown" ]]; then
    local icon="?"
    case "$context_mode" in
      focused) icon="🎯" ;;
      meeting) icon="💼" ;;
      casual) icon="💬" ;;
      DND) icon="🚫" ;;
    esac
    parts+=("$icon $context_mode")
  fi

  # Pending tasks if significant
  if [[ -n "$pending_tasks" && "$pending_tasks" != "-" && "$pending_tasks" != "0" ]]; then
    parts+=(".tasks $pending_tasks")
  fi

  # Bot health
  if [[ -n "$bot_health" && "$bot_health" != "?" ]]; then
    parts+=("$bot_health")
  fi

  # Check for git file status
  local file_status
  if command -v jq >/dev/null 2>&1; then
    # Try to get file status from context daemon
    local file_status_json
    file_status_json=$(_bot_army_check_file_status 2>/dev/null)
    if [[ -n "$file_status_json" ]]; then
      local file_total
      file_total=$(echo "$file_status_json" | jq -r '.total // 0' 2>/dev/null)
      if [[ "$file_total" -gt 0 ]]; then
        local file_icon="●"
        if [[ "$file_total" -gt 5 ]]; then
          file_icon="●●●"
        fi
        parts+=("$file_icon $file_total files")
      fi
    fi
  fi

  if [[ ${#parts[@]} -gt 0 ]]; then
    printf '%s' "${parts[*]}"
  fi
}

# Show full status (for deep dive)
bot_army_full_status() {
  local status_json
  status_json=$(_bot_army_get_status)

  echo "┌─────────────────────────────────────────────────────────────────┐"
  echo "│ Bot Army Status                                                 │"
  echo "├─────────────────────────────────────────────────────────────────┤"

  if command -v jq >/dev/null 2>&1; then
    echo "│ Bot:        $(echo "$status_json" | jq -r '.bot // "unknown"')                    │"
    echo "│ Context:    $(echo "$status_json" | jq -r '.context_mode // "unknown"')                │"
    echo "│ Git Branch: $(echo "$status_json" | jq -r '.git_branch // "none"')                │"
    echo "│ Bot Health: $(echo "$status_json" | jq -r '.bot_health // "?"')                    │"
    echo "│ Pending:    $(echo "$status_json" | jq -r '.pending_tasks // "-"') tasks           │"
    echo "│ LLM:        $(echo "$status_json" | jq -r '.llm_status // "?"')                    │"
    echo "│ NATS:       $(echo "$status_json" | jq -r '.nats_status // "?"')                   │"
    echo "│ Database:   $(echo "$status_json" | jq -r '.db_status // "?"')                   │"
  else
    echo "│ Bot:        unknown                                            │"
    echo "│ Context:    unknown                                            │"
    echo "│ Pending:    -                                                  │"
  fi

  echo "└─────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "Commands: ? for help, r to refresh, q to quit"
}

# Public functions
bot_army_status() {
  bot_army_status_bar
}
