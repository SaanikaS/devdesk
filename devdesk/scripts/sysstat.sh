#!/usr/bin/env bash
# sysstat — CPU, RAM and battery (or load average on desktops) in one line.
#
#   sysstat              print once
#   sysstat --watch [s]  print every s seconds (default 5) — used by polybar
#   sysstat --refresh    make a running --watch print immediately (polybar click)
#   sysstat --notify     show the stats as a desktop notification
set -u
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/devdesk-sysstat.pid"

cpu_usage() {
  local _ u1 n1 s1 i1 w1 q1 sq1 st1 u2 n2 s2 i2 w2 q2 sq2 st2
  read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
  sleep 0.3
  read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat
  local dt=$(( (u2+n2+s2+i2+w2+q2+sq2+st2) - (u1+n1+s1+i1+w1+q1+sq1+st1) ))
  local di=$(( (i2+w2) - (i1+w1) ))
  if (( dt > 0 )); then echo $(( 100 * (dt - di) / dt )); else echo 0; fi
}

mem_used() {
  awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{printf "%.1fG", (t-a)/1048576}' /proc/meminfo
}

# Laptop → battery %. Desktop (no battery) → 1-minute load average instead.
extra_metric() {
  local b cap status
  for b in /sys/class/power_supply/BAT*; do
    [[ -r $b/capacity ]] || continue
    cap=$(<"$b/capacity"); status=$(<"$b/status")
    case $status in
      Charging) printf 'BAT %s%% CHG' "$cap" ;;
      *)        printf 'BAT %s%%' "$cap" ;;
    esac
    return 0
  done
  printf 'LOAD %s' "$(cut -d' ' -f1 /proc/loadavg)"
}

line() { printf 'CPU %s%%  RAM %s  %s\n' "$(cpu_usage)" "$(mem_used)" "$(extra_metric)"; }

case "${1:-}" in
  --watch)
    interval="${2:-5}"
    echo $$ > "$PIDFILE"
    trap 'rm -f "$PIDFILE"' EXIT
    trap ':' USR1                      # signal just interrupts the sleep below
    while :; do
      line
      sleep "$interval" & sleeper=$!
      wait "$sleeper" 2>/dev/null
      kill "$sleeper" 2>/dev/null || true
    done
    ;;
  --refresh)
    [[ -r $PIDFILE ]] && kill -USR1 "$(<"$PIDFILE")" 2>/dev/null || true
    ;;
  --notify)
    notify-send -u low "System" "$(line)"
    ;;
  *) line ;;
esac
