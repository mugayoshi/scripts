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
    else
      echo "Aborted."
    fi
    ;;
  *)
    usage
    ;;
esac
