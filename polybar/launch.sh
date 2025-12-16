#!/usr/bin/env bash
set -e
pkill -x polybar || true
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.1; done
for m in $(xrandr --query | awk '/ connected/{print $1}'); do
  MONITOR="$m" polybar --reload main &
done

