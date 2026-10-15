#!/usr/bin/env bash
# pomodoro [toggle|start|stop|status] — 25 min focus / 5 min break cycles with notifications.
# Override lengths:  POMO_WORK=50 POMO_BREAK=10 pomodoro start
WORK="${POMO_WORK:-25}"; BREAK="${POMO_BREAK:-5}"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/devdesk-pomodoro.pid"
running() { [[ -r $PIDFILE ]] && kill -0 "$(<"$PIDFILE")" 2>/dev/null; }

cycle() {
  local n=1
  while :; do
    notify-send -u normal "Focus #$n" "${WORK} minutes. Phone away."
    sleep $((WORK * 60))
    notify-send -u normal "Break" "${BREAK} minutes. Stand up, drink water."
    sleep $((BREAK * 60))
    n=$((n + 1))
  done
}

start() { running && return; setsid "$0" _cycle & echo $! > "$PIDFILE"; }
stop()  { running && kill -- "-$(<"$PIDFILE")" 2>/dev/null; rm -f "$PIDFILE"; notify-send -u low "Pomodoro" "Stopped"; }

case "${1:-toggle}" in
  _cycle) cycle ;;
  start)  start ;;
  stop)   stop ;;
  status) if running; then notify-send -u low "Pomodoro" "Running (${WORK}/${BREAK} min)"; else notify-send -u low "Pomodoro" "Not running"; fi ;;
  toggle) if running; then stop; else start; fi ;;
  *) echo "usage: pomodoro [toggle|start|stop|status]" >&2; exit 1 ;;
esac
