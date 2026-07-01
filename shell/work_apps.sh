#!/bin/bash
# To use from anywhere: ln -s /Users/muga/repos/scripts/shell/work_apps.sh ~/.local/bin/work_apps

apps=("Slack" "Ovice")

usage() {
  echo "Usage: $0 [open|close]"
  exit 1
}

case "$1" in
  open)
    for app in "${apps[@]}"; do
      echo "Launching $app..."
      if [[ "$app" == "Slack" ]]; then
        echo "Reminder: freee で出勤しましたか?"
      fi
      open -a "$app"
    done
    echo "Work apps launched!"
    ;;
  close)
    read -p "Are you sure you want to close work apps? (freee で退勤しましたか?) (y/n): " confirm
    if [[ $confirm == [yY] ]]; then
      for app in "${apps[@]}"; do
        echo "Closing $app..."
        osascript -e "quit app \"$app\""
      done
      echo "Work apps closed!"
      read -p "Kill Claude Code sessions? (y/n): " kill_claude
      if [[ $kill_claude == [yY] ]]; then
        pkill -f "claude" && echo "Claude Code sessions killed." || echo "No Claude Code sessions found."
      fi
      running_containers=$(docker ps -q 2>/dev/null)
      if [[ -n "$running_containers" ]]; then
        echo "Warning: Docker containers are still running:"
        docker ps --format "  {{.Names}} ({{.Image}})"
      fi
    else
      echo "Aborted."
    fi
    ;;
  *)
    usage
    ;;
esac
