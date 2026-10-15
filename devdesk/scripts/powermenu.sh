#!/usr/bin/env bash
# powermenu — lock / logout / suspend / reboot / shutdown via rofi
choice="$(printf 'Lock\nLogout\nSuspend\nReboot\nShutdown\n' | rofi -dmenu -i -p 'Power' -theme-str 'window {width: 20%;} listview {lines: 5;}')" || exit 0
confirm() { [[ "$(printf 'No\nYes\n' | rofi -dmenu -i -p "$1?" -theme-str 'window {width: 15%;} listview {lines: 2;}')" == Yes ]]; }
case "$choice" in
  Lock)     i3lock -f -c 1e1e2e ;;
  Logout)   confirm Logout   && i3-msg exit ;;
  Suspend)  systemctl suspend ;;
  Reboot)   confirm Reboot   && systemctl reboot ;;
  Shutdown) confirm Shutdown && systemctl poweroff ;;
esac
