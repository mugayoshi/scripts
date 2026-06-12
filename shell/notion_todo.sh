#!/bin/bash
# Creates a new todo task in your Notion database.
# Requires NOTION_TODO_DATABASE_ID env var to be set.
# To use from anywhere: ln -s /Users/muga/repos/scripts/shell/notion_todo.sh ~/.local/bin/notion_todo

set -e

for cmd in ntn jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

: "${NOTION_TODO_DATABASE_ID:?NOTION_TODO_DATABASE_ID is not set}"

usage() {
  echo "Usage: $0 <task_name> [due_date (YYYY-MM-DD)]"
  echo "Example: $0 \"Fix login bug\" 2026-06-20"
  exit 1
}

[[ -z "$1" ]] && usage

TASK_NAME="$1"
DUE_DATE="${2:-$(date +%Y-%m-%d)}"

echo "Creating task: $TASK_NAME..."

properties=$(jq -n --arg name "$TASK_NAME" --arg date "$DUE_DATE" '{
  "Task name": { "title": [{ "text": { "content": $name } }] },
  "Status": { "status": { "name": "Not started" } },
  "Due date": { "date": { "start": $date } }
}')

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
