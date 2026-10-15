#!/usr/bin/env bash
# screenshot [full|area|window|clip] — saves to ~/Pictures/Screenshots and copies to clipboard
set -euo pipefail
DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$DIR"
file="$DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-full}" in
  full)   maim "$file" ;;
  area)   maim -s -u "$file" || exit 0 ;;                       # Esc while selecting = cancel
  window) maim -u -i "$(xdotool getactivewindow)" "$file" ;;
  clip)   maim -s -u | xclip -selection clipboard -t image/png
          notify-send -u low "Screenshot" "Copied to clipboard"; exit 0 ;;
  *)      echo "usage: screenshot [full|area|window|clip]" >&2; exit 1 ;;
esac

xclip -selection clipboard -t image/png < "$file"
notify-send -u low "Screenshot saved" "$file"
