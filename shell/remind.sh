#!/bin/bash

# Notify after a specified number of minutes — terminal-independent.
# The reminder survives closing the terminal or the shell that started it,
# because it relaunches itself as a detached (nohup) background process.
#
# Useful for "check back on X in N minutes" reminders (e.g. a Slack thread).
#
# Usage: ./remind.sh <minutes> [message]
#   ./remind.sh 10                       -> reminds after 10 minutes
#   ./remind.sh 10 "Check Slack thread"  -> reminds with a custom message
#
# To use from anywhere:
#   ln -s /Users/muga/repos/scripts/shell/remind.sh ~/.local/bin/remind

# ---- Daemon mode: the detached copy lands here, waits, then notifies. ----
if [ "$1" = "--_daemon" ]; then
    MINUTES="$2"
    MESSAGE="$3"
    sleep "${MINUTES}m"
    osascript -e "display notification \"$MESSAGE\" with title \"Reminder (${MINUTES} min)\" sound name \"Glass\""
    afplay "/System/Library/Sounds/Glass.aiff"
    say "$MESSAGE"
    exit 0
fi

# ---- Foreground mode: validate, then hand off to a detached copy. ----
if [ $# -lt 1 ]; then
    echo "Usage: $0 <minutes> [message]"
    exit 1
fi

MINUTES="$1"
shift
MESSAGE="${*:-Time is up!}"

# Validate that minutes is a positive number (integer or decimal).
if ! [[ "$MINUTES" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: minutes must be a positive number, got '$MINUTES'"
    exit 1
fi

# Launch a detached background copy. nohup + & + disown means it keeps
# running after this shell exits or the terminal window is closed.
nohup "$0" --_daemon "$MINUTES" "$MESSAGE" >/dev/null 2>&1 &
disown 2>/dev/null

# Confirm, showing the target clock time when it's a whole number of minutes.
TARGET=$(date -v +"${MINUTES}"M "+%H:%M" 2>/dev/null)
if [ -n "$TARGET" ]; then
    echo "Reminder set for ${MINUTES} min from now (~${TARGET}): $MESSAGE"
else
    echo "Reminder set for ${MINUTES} min from now: $MESSAGE"
fi
