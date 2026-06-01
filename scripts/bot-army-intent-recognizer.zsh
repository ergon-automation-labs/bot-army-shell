#!/usr/bin/env zsh
# Bot Army Intent Recognizer
# Learns user patterns and offers proactively helpful suggestions
# Usage: source ~/.config/bot-army-shell/bot-army-intent-recognizer.zsh

# Intent tracking database
_BOT_ARMY_INTENT_DB="${HOME}/.config/bot-army-shell/intents.json"

# Initialize intent database if needed
_bot_army_intent_init() {
  if [[ ! -f "$_BOT_ARMY_INTENT_DB" ]]; then
    echo '{}' > "$_BOT_ARMY_INTENT_DB"
  fi
}

# Learn an intent pattern
_bot_army_intent_learn() {
  local intent="$1"
  local context="$2"

  _bot_army_intent_init

  # Read current intents
  local intents
  intents=$(cat "$_BOT_ARMY_INTENT_DB" 2>/dev/null || echo '{}')

  # Update intent count
  local new_count
  new_count=$(echo "$intents" | jq ".\"$intent\".count = ((.\"$intent\".count // 0) + 1)" 2>/dev/null || echo "$intents")
  new_count=$(echo "$new_count" | jq ".\"$intent\".last = now | .\"$intent\".context = \"$context\"" 2>/dev/null || echo "$new_count")

  echo "$new_count" > "$_BOT_ARMY_INTENT_DB"
}

# Get intent suggestions based on current context
_bot_army_intent_suggest() {
  _bot_army_intent_init

  # Get current context
  local current_context="unknown"
  if [[ -f ~/.config/bot-army-shell/bot-army-context.zsh ]]; then
    source ~/.config/bot-army-shell/bot-army-context.zsh
    current_context=$(_bot_army_context_prompt)
  fi

  # Check intent database for patterns
  if [[ -f "$_BOT_ARMY_INTENT_DB" ]]; then
    local intents
    intents=$(cat "$_BOT_ARMY_INTENT_DB" 2>/dev/null)

    # Get most common intent
    local top_intent
    top_intent=$(echo "$intents" | jq -r 'to_entries | sort_by(.value.count) | .[-1].key // ""' 2>/dev/null)

    if [[ -n "$top_intent" ]]; then
      echo "Suggested: $top_intent"
    fi
  fi

  # Context-based suggestions
  case "$current_context" in
    *"[gtd]"*) echo "Suggested: !open task - to review your tasks" ;;
    *"[para]"*) echo "Suggested: !find <query> - search your notes" ;;
    *"DND"*) echo "Suggested: quiet mode active - notifications muted" ;;
  esac
}

# Intent patterns to detect

# Pattern: Running tests frequently
_bot_army_intent_test_pattern() {
  local cmd="$1"

  if [[ "$cmd" == *"mix test"* ]] || [[ "$cmd" == *"test"* ]] || [[ "$cmd" == *"go test"* ]]; then
    # Count how many times tests have been run
    local test_count
    test_count=$(echo "$_BOT_ARMY_INTENT_DB" | jq '.\"test_run\".count // 0' 2>/dev/null || echo "0")

    case $test_count in
      1) echo "First test run! Consider adding integration tests" ;;
      2) echo "Tests running... need me to watch for failures?" ;;
      3) echo "Test suite running for the 3rd time today" ;;
      *) echo "Test count: $test_count" ;;
    esac

    # Learn this pattern
    _bot_army_intent_learn "test_run" "$(basename "$PWD")"
  fi
}

# Pattern: Committing frequently
_bot_army_intent_commit_pattern() {
  local cmd="$1"

  if [[ "$cmd" == *"git commit"* ]] || [[ "$cmd" == *"git push"* ]]; then
    local commit_count
    commit_count=$(echo "$_BOT_ARMY_INTENT_DB" | jq '.\"commit\".count // 0' 2>/dev/null || echo "0")

    case $commit_count in
      1) echo "First commit! Starting a new feature?" ;;
      5) echo "5 commits already today - nice progress!" ;;
      10) echo "10 commits! This is a productive session" ;;
    esac

    _bot_army_intent_learn "commit" "$(basename "$PWD")"
  fi
}

# Pattern: Building frequently
_bot_army_intent_build_pattern() {
  local cmd="$1"

  if [[ "$cmd" == *"make build"* ]] || [[ "$cmd" == *"docker build"* ]]; then
    local build_count
    build_count=$(echo "$_BOT_ARMY_INTENT_DB" | jq '.\"build\".count // 0' 2>/dev/null || echo "0")

    case $build_count in
      1) echo "First build... taking ~2 minutes" ;;
      3) echo "Build #3 - cache warming up" ;;
      5) echo "5 builds today - are you iterating on something?" ;;
    esac

    _bot_army_intent_learn "build" "$(basename "$PWD")"
  fi
}

# Pattern: Running development servers
_bot_army_intent_dev_pattern() {
  local cmd="$1"

  if [[ "$cmd" == *"mix phx.server"* ]] || [[ "$cmd" == *"docker compose up"* ]] || [[ "$cmd" == *"go run"* ]]; then
    local dev_count
    dev_count=$(echo "$_BOT_ARMY_INTENT_DB" | jq '.\"dev_server\".count // 0' 2>/dev/null || echo "0")

    case $dev_count in
      1) echo "Starting development server... ready for changes" ;;
      3) echo "Server restart #3 - any changes to watch?" ;;
    esac

    _bot_army_intent_learn "dev_server" "$(basename "$PWD")"
  fi
}

# Main intent recognition dispatcher
_bot_army_intent_recognize() {
  local cmd="$1"

  # Only recognize if command is non-empty
  [[ -z "$cmd" ]] && return

  # Run all pattern detectors
  _bot_army_intent_test_pattern "$cmd"
  _bot_army_intent_commit_pattern "$cmd"
  _bot_army_intent_build_pattern "$cmd"
  _bot_army_intent_dev_pattern "$cmd"

  # Show suggestions
  _bot_army_intent_suggest
}

# Export function for use in shell
bot_army_intent_recognize() {
  local cmd="${1:-}"
  _bot_army_intent_recognize "$cmd"
}
