#!/usr/bin/env bash
# perf-watch — event-driven performance tuning (no polling).
# Listens to udev power_supply events; when AC is plugged/unplugged it
#   • swaps the compositor config (full effects on AC, lite on battery)
#   • switches power-profiles-daemon profile, if installed
# Fullscreen apps bypass the compositor via picom's `unredir-if-possible`.
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/picom"
STATE="${XDG_RUNTIME_DIR:-/tmp}/devdesk-power-mode"
rm -f "$STATE"

on_ac() {
  local f
  for f in /sys/class/power_supply/{AC,ADP,ACAD}*/online; do
    [[ -r $f ]] && { [[ $(<"$f") == 1 ]]; return; }
  done
  return 0                                  # no AC node found → desktop → treat as plugged in
}

apply() {
  local mode conf profile
  if on_ac; then mode=ac;      conf=picom.conf;      profile=balanced
  else           mode=battery; conf=picom-lite.conf; profile=power-saver; fi
  [[ -r $STATE && $(<"$STATE") == "$mode" ]] && return
  echo "$mode" > "$STATE"
  pkill -x picom 2>/dev/null; sleep 0.3
  picom --config "$CFG/$conf" -b
  command -v powerprofilesctl >/dev/null && powerprofilesctl set "$profile" 2>/dev/null
  notify-send -u low "Power: $mode" "compositor → $conf"
}

apply
udevadm monitor --udev --subsystem-match=power_supply 2>/dev/null | while read -r _; do
  sleep 0.5; apply
done
