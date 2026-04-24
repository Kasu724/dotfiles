#!/usr/bin/env bash

# Kill existing picom instances
killall -q picom

# Wait until they close
while pgrep -x picom >/dev/null; do sleep 1; done

# Give the session a moment to settle
sleep 2

# Launch picom with the configured settings
picom --config "$HOME/.config/picom/picom.conf" &
