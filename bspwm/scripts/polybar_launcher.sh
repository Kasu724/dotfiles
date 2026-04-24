#!/usr/bin/env bash

# Kill existing bars
killall -q polybar

# Wait until they close
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch bar
polybar main &