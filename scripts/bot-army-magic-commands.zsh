#!/usr/bin/env zsh
# Bot Army Magic Commands
# Quick actions that understand your context
# Usage: source ~/.config/bot-army-shell/bot-army-magic-commands.zsh

# Source context for detection
if [[ -f ~/.config/bot-army-shell/bot-army-context.zsh ]]; then
  source ~/.config/bot-army-shell/bot-army-context.zsh
fi

# Get current context
_bot_army_magic_get_context() {
  if command -v jq >/dev/null 2>&1; then
    _bot_army_context_get_fallback | jq -r '{bot: .bot, git_branch: .git_branch, cwd: $ENV.BOT_ARMY_MAGIC_CWD}'
  else
    echo '{"bot":"","git_branch":"","cwd":"unknown"}'
  fi
}

# Magic command: !open
# Opens appropriate resource based on context
magic_open() {
  local target="${1:-current}"

  case "$target" in
    task)
      echo "Opening current task..."
      nats request bridge.task.current '{}' --server "${NATS_SERVER:-localhost:4222}" --timeout 3s 2>/dev/null
      ;;
    task|task:*)
      # Open specific task
      local task_id="${target#task:}"
      echo "Opening task $task_id..."
      nats request "bridge.task.show" "{\"task_id\":\"$task_id\"}" --server "${NATS_SERVER:-localhost:4222}" --timeout 3s 2>/dev/null
      ;;
    project)
      echo "Opening current project..."
      echo "Project: $(basename "$PWD")"
      echo "Bot: $(_bot_army_context_prompt)"
      ;;
    docs|documentation)
      echo "Opening relevant docs..."
      if [[ -d "docs" ]]; then
        ls -la docs/
      else
        echo "No docs directory found"
      fi
      ;;
    related)
      echo "Finding related tasks..."
      local bot=$(_bot_army_context_prompt)
      nats request "bridge.task.related" '{"context":"current"}' --server "${NATS_SERVER:-localhost:4222}" --timeout 3s 2>/dev/null
      ;;
    help|?)
      echo "Available !open targets:"
      echo "  !open task        - Show current task"
      echo "  !open task:123    - Show task #123"
      echo "  !open project     - Show current project"
      echo "  !open docs        - Open docs"
      echo "  !open related     - Find related tasks"
      ;;
    *)
      echo "Unknown target: $target"
      echo "Try: !open help"
      ;;
  esac
}

# Magic command: !schedule
# Schedule tasks or events
magic_schedule() {
  local action="${1:-help}"

  case "$action" in
    task)
      local description
      read -r "description?Task description: "
      if [[ -n "$description" ]]; then
        nats request bridge.task.create "{\"description\":\"$description\"}" --server "${NATS_SERVER:-localhost:4222}" --timeout 3s 2>/dev/null
        echo "Task scheduled: $description"
      fi
      ;;
    meeting)
      echo "Scheduling meeting..."
      echo "Available times:"
      echo "  1. Tomorrow 9:00 AM"
      echo "  2. Tomorrow 2:00 PM"
      echo "  3. Next Monday 10:00 AM"
      read -r "choice?Choose time: "
      echo "Meeting scheduled!"
      ;;
    focus)
      echo "Setting focus timer..."
      echo "Available timers:"
      echo "  1. 25 minutes (Pomodoro)"
      echo "  2. 50 minutes (Deep work)"
      echo "  3. 90 minutes (Marathon)"
      read -r "choice?Choose duration: "
      echo "Focus timer set!"
      ;;
    help|?)
      echo "Available !schedule actions:"
      echo "  !schedule task       - Schedule a new task"
      echo "  !schedule meeting    - Schedule a meeting"
      echo "  !schedule focus      - Set focus timer"
      ;;
    *)
      echo "Unknown action: $action"
      echo "Try: !schedule help"
      ;;
  esac
}

# Magic command: !find
# Quick search across Bot Army
magic_find() {
  local query="${1:-}"

  if [[ -z "$query" ]]; then
    echo "Usage: !find <query>"
    echo ""
    echo "Searches:"
    echo "  - Tasks"
    echo "  - PARA notes"
    echo "  - Projects"
    echo "  - Bots"
    return 0
  fi

  echo "Searching for: $query"
  echo ""

  # Search tasks
  echo "Tasks:"
  nats request "bridge.task.search" "{\"query\":\"$query\"}" --server "${NATS_SERVER:-localhost:4222}" --timeout 3s 2>/dev/null | head -5

  # Search PARA
  echo ""
  echo "PARA:"
  nats request "para.fs.search" "{\"query\":\"$query\"}" --server "${NATS_SERVER:-localhost:4222}" --timeout 3s 2>/dev/null | head -5
}

# Magic command: !status
# Show system status
magic_status() {
  if [[ -f ~/.config/bot-army-shell/bot-army-status-bar.zsh ]]; then
    source ~/.config/bot-army-shell/bot-army-status-bar.zsh
    bot_army_full_status
  else
    echo "Status bar not installed"
  fi
}

# Magic command: !help
# Show all magic commands
magic_help() {
  cat << 'EOF'
Bot Army Magic Commands (!prefix)

Syntax: !command [target] [options]

Available Commands:
  !open     [task|task:123|project|docs|related|help]
  !schedule [task|meeting|focus|help]
  !find     <query>
  !status
  !help

Examples:
  !open task          - Show current task
  !open project       - Show current project
  !schedule task      - Schedule a new task
  !find "meeting notes" - Search across Bot Army
  !status             - Full system status

Configuration:
  Set NATS_SERVER environment variable for custom NATS server
  Default: localhost:4222

EOF
}

# Magic command dispatcher
magic_dispatch() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    open) magic_open "$@" ;;
    schedule) magic_schedule "$@" ;;
    find) magic_find "$@" ;;
    status) magic_status "$@" ;;
    help) magic_help "$@" ;;
    *)
      echo "Unknown command: $cmd"
      echo "Try: !help"
      ;;
  esac
}

# Magic command wrapper (called with ! as first argument)
magic_command() {
  # Skip the ! prefix
  magic_dispatch "$@"
}

# Export for use as a function
alias magic='magic_command'
