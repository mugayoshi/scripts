#!/bin/bash
# Creates a new task in your Notion database interactively.
# Requires NOTION_TODO_DATABASE_ID env var to be set.
# To use from anywhere: ln -s /Users/muga/repos/scripts/shell/notion_todo.sh ~/.local/bin/notion_todo
#
# Usage: notion_todo [task_name]
#   - If task_name is omitted, you'll be prompted for it.
#   - All other fields are prompted interactively with defaults.
#   - Leave "Start date" blank to use today's date for Planned start.

set -e

for cmd in ntn jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

: "${NOTION_TODO_DATABASE_ID:?NOTION_TODO_DATABASE_ID is not set}"

TODAY=$(date +%Y-%m-%d)
NOW_TIME=$(date +%H:%M)

TASK_NAME="${1:-}"
if [[ -z "$TASK_NAME" ]]; then
  echo "Create a Notion task. Press Enter to accept the value in [brackets]."
  read -r -p "Task name (required): " TASK_NAME
fi
[[ -z "$TASK_NAME" ]] && { echo "Error: task name is required." >&2; exit 1; }

read -r -p "Due date [$TODAY]: " DUE_DATE
DUE_DATE="${DUE_DATE:-$TODAY}"

read -r -p "Start date [$TODAY]: " START_DATE
START_DATE="${START_DATE:-$TODAY}"

read -r -p "Start time [$NOW_TIME]: " START_TIME
START_TIME="${START_TIME:-$NOW_TIME}"

read -r -p "Duration in min [30]: " DURATION
DURATION="${DURATION:-30}"
[[ "$DURATION" =~ ^[0-9]+$ ]] || { echo "Error: duration must be an integer." >&2; exit 1; }

START_ISO=""
if ! START_ISO=$(date -j -f "%Y-%m-%d %H:%M" "$START_DATE $START_TIME" "+%Y-%m-%dT%H:%M:%S%z" 2>/dev/null); then
  echo "Error: could not parse '$START_DATE $START_TIME'." >&2
  exit 1
fi

echo "Creating task: $TASK_NAME..."

properties=$(jq -n \
  --arg name "$TASK_NAME" \
  --arg due "$DUE_DATE" \
  --arg duration "$DURATION" \
  --arg start "$START_ISO" \
  '
  {
    "Task name": { "title": [{ "text": { "content": $name } }] },
    "Status":    { "status": { "name": "Not started" } },
    "Due date":  { "date": { "start": $due } }
  }
  + (if $duration != "" then { "Duration (min)": { "number": ($duration | tonumber) } } else {} end)
  + (if $start    != "" then { "Planned start":  { "date":   { "start": $start } } } else {} end)
  ')

parent=$(jq -n --arg db "$NOTION_TODO_DATABASE_ID" '{"database_id": $db}')

response=$(PAGER=cat ntn api --method POST v1/pages \
  parent:="$parent" \
  properties:="$properties")

PAGE_URL=$(echo "$response" | jq -r '.url')
if [[ -z "$PAGE_URL" || "$PAGE_URL" == "null" ]]; then
  echo "Error: failed to create page." >&2
  echo "$response" >&2
  exit 1
fi

echo "Done! Task created: $PAGE_URL"
