#!/usr/bin/env bash
# keybinds — fuzzy-searchable cheat-sheet generated from your i3 config.
# Any `bindsym <keys> <cmd>   # description` line is listed automatically.
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/i3/config"
grep -E '^\s*bindsym .*#' "$CONF" \
  | sed -E 's/^\s*bindsym\s+(\S+)\s+.*#\s*(.*)$/\1\t\2/' \
  | sed -E 's/\$mod/Super/g; s/\$alt/Alt/g' \
  | column -t -s $'\t' \
  | rofi -dmenu -i -p 'Keys' -theme-str 'window {width: 60%;}'
