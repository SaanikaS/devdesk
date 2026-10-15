#!/usr/bin/env bash
# launch-polybar — (re)start one bar per monitor; tray only on the primary one.
pkill -x polybar 2>/dev/null
while pgrep -x polybar >/dev/null; do sleep 0.1; done

primary="$(xrandr --query | awk '/ primary/{print $1; exit}')"
mapfile -t monitors < <(polybar --list-monitors | cut -d: -f1)
[[ -z $primary ]] && primary="${monitors[0]:-}"

for m in "${monitors[@]}"; do
  bar=secondary; [[ $m == "$primary" ]] && bar=main
  MONITOR="$m" setsid -f polybar --reload "$bar" >"/tmp/polybar-$m.log" 2>&1
done
