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
    read -p "Are you sure you want to close work apps? (y/n): " confirm
    if [[ $confirm == [yY] ]]; then
      read -p "freee で退勤しましたか? (y/n): " freee_confirm
      if [[ $freee_confirm != [yY] ]]; then
        echo "Please clock out on freee."
      fi
      read -p "Did you disconnect the VPN? (y/n): " vpn_confirm
      if [[ $vpn_confirm != [yY] ]]; then
        echo "Please disconnect the VPN before closing work apps."
      fi
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
      # Port forwards (ssh tunnels incl. ones defined in ~/.ssh/config, kubectl, AWS SSM)
      # show up as these processes listening on a local TCP port.
      port_forwards=$(lsof -nP +c 0 -iTCP -sTCP:LISTEN 2>/dev/null \
        | awk '$1 ~ /^(ssh|autossh|kubectl|session-manager-plugin)$/ {
            port = $9; sub(/.*:/, "", port)   # drop the IPv4/IPv6 address, keep the port
            print "  " $1 " (pid " $2 ") port " port
          }' \
        | sort -u)
      if [[ -n "$port_forwards" ]]; then
        echo "Warning: Port forwarding is still running:"
        echo "$port_forwards"
      fi
    else
      echo "Aborted."
    fi
    ;;
  *)
    usage
    ;;
esac
