#!/usr/bin/env bash
# set-wallpaper — change wallpaper and re-theme the whole desktop from it.
#
#   set-wallpaper <image>     use this image
#   set-wallpaper --random    random image from ~/Pictures/Wallpapers
#   set-wallpaper --pick      choose from a rofi menu
#   set-wallpaper --restore   re-apply the last theme (runs at login)
#   set-wallpaper --init <i>  generate theme files only, no X needed (used by install.sh)
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE="$HOME/.cache/wal"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

list_images() { find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort; }

# Copy generated colour files to where rofi and dunst look for them.
sync_files() {
  mkdir -p "$CFG/rofi" "$CFG/dunst/dunstrc.d"
  cp -f "$CACHE/colors-rofi.rasi"  "$CFG/rofi/colors.rasi"
  cp -f "$CACHE/dunst-colors.conf" "$CFG/dunst/dunstrc.d/10-colors.conf"
}

# Tell every running component to pick up the new colours.
reload_all() {
  xrdb -merge "$CACHE/colors.Xresources"            # i3 + polybar read colours from here
  pkill -USR1 -x kitty 2>/dev/null || true          # live-reload all kitty windows
  dunstctl reload 2>/dev/null || { pkill -x dunst || true; setsid -f dunst; }
  i3-msg -q reload                                  # re-reads set_from_resource colours
  launch-polybar
}

apply() {
  wal -q -e -i "$1"                                 # -e: we do the reloading ourselves
  sync_files
  reload_all
  notify-send -u low "Theme updated" "$(basename "$1")"
}

case "${1:-}" in
  --init)
    wal -q -n -e -i "${2:?usage: set-wallpaper --init <image>}"
    sync_files
    ;;
  --restore)
    if [[ -r $CACHE/wal ]]; then
      wal -q -e -R
      sync_files
      reload_all
    else
      first="$(list_images | head -n1)"
      [[ -n $first ]] && apply "$first"
    fi
    ;;
  --random)
    img="$(list_images | shuf -n1)"
    [[ -n $img ]] || { notify-send "No wallpapers" "Put images in $WALL_DIR"; exit 1; }
    apply "$img"
    ;;
  --pick)
    choice="$(list_images | xargs -n1 basename | rofi -dmenu -i -p 'Wallpaper')" || exit 0
    apply "$WALL_DIR/$choice"
    ;;
  ""|-h|--help)
    sed -n '2,9p' "$0"; exit 0 ;;
  *)
    apply "$1"
    ;;
esac
