#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  devdesk installer — one command:   ./install.sh
#  Flags:  --no-packages   skip installing system packages
#          --no-fonts      skip downloading JetBrainsMono Nerd Font
#  Existing files are moved to ~/.dotfiles-backup/<timestamp>/ — nothing is lost.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DO_PKGS=1; DO_FONTS=1
for a in "$@"; do
  case "$a" in
    --no-packages) DO_PKGS=0 ;;
    --no-fonts)    DO_FONTS=0 ;;
    -h|--help)     sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }

# ── 1. System packages ───────────────────────────────────────
install_packages() {
  if command -v apt-get >/dev/null; then
    log "Detected Debian/Ubuntu (apt)"
    sudo apt-get update
    sudo apt-get install -y i3 i3lock polybar rofi kitty picom dunst feh maim xclip xdotool \
      playerctl brightnessctl pulseaudio-utils pavucontrol imagemagick jq curl git unzip xz-utils \
      x11-xserver-utils x11-utils libnotify-bin network-manager-gnome pipx udev
  elif command -v pacman >/dev/null; then
    log "Detected Arch (pacman)"
    sudo pacman -Syu --needed --noconfirm i3-wm i3lock polybar rofi kitty picom dunst feh maim xclip \
      xdotool playerctl brightnessctl libpulse pavucontrol imagemagick jq curl git unzip xorg-xrdb \
      xorg-xrandr libnotify network-manager-applet python-pipx ttf-jetbrains-mono-nerd
    DO_FONTS=0   # installed from the repo above
  elif command -v dnf >/dev/null; then
    log "Detected Fedora (dnf)"
    sudo dnf install -y i3 i3lock polybar rofi kitty picom dunst feh maim xclip xdotool playerctl \
      brightnessctl pulseaudio-utils pavucontrol ImageMagick jq curl git unzip xrdb xrandr \
      libnotify NetworkManager-gnome pipx
  else
    warn "Unsupported package manager. Install the packages listed in README.md manually, then re-run with --no-packages."
    exit 1
  fi
}

# ── 2. Font ──────────────────────────────────────────────────
install_font() {
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then log "Nerd Font already installed"; return; fi
  log "Installing JetBrainsMono Nerd Font"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/font.tar.xz" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
  tar -xf "$tmp/font.tar.xz" -C "$HOME/.local/share/fonts/JetBrainsMonoNF"
  fc-cache -f
  rm -rf "$tmp"
}

# ── 3. pywal (wallpaper → colour scheme) ─────────────────────
install_pywal() {
  command -v wal >/dev/null && { log "pywal already installed"; return; }
  log "Installing pywal16 with pipx"
  pipx install pywal16
  pipx ensurepath >/dev/null || true
  export PATH="$HOME/.local/bin:$PATH"
}

# ── 4. Symlink configs + scripts (with backups) ──────────────
link() {   # link <source> <destination>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e $dst || -L $dst ]]; then
    [[ "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]] && return
    mkdir -p "$BACKUP"; mv "$dst" "$BACKUP/${dst//\//_}"
    warn "Backed up $dst → $BACKUP"
  fi
  ln -s "$src" "$dst"
}

link_all() {
  log "Linking configs → $CFG"
  while IFS= read -r -d '' f; do
    link "$f" "$CFG/${f#"$REPO/config/"}"
  done < <(find "$REPO/config" -type f -print0)

  log "Linking scripts → $BIN"
  mkdir -p "$BIN"
  for f in "$REPO"/scripts/*.sh; do
    chmod +x "$f"
    link "$f" "$BIN/$(basename "${f%.sh}")"
  done
}

# ── 5. Wallpapers + first theme ──────────────────────────────
setup_theme() {
  log "Copying wallpapers → ~/Pictures/Wallpapers"
  mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
  shopt -s nullglob
  for w in "$REPO"/wallpapers/*.{jpg,jpeg,png,webp}; do [[ -e "$HOME/Pictures/Wallpapers/$(basename "$w")" ]] || cp "$w" "$HOME/Pictures/Wallpapers/"; done
  shopt -u nullglob
  local first; first="$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f | sort | head -n1)"
  if [[ -n $first ]]; then
    log "Generating first colour scheme from $(basename "$first")"
    "$BIN/set-wallpaper" --init "$first"
  fi
}

(( DO_PKGS ))  && install_packages
(( DO_FONTS )) && install_font
install_pywal
link_all
setup_theme

cat <<MSG

$(printf '\033[1;32m')✔ devdesk installed.$(printf '\033[0m')

Next:
  1. Log out.
  2. On the login screen pick the "i3" session (gear / session icon), log in.
  3. Press Super+Return for a terminal, Super+F1 for the shortcut cheat-sheet.
  4. Press Super+N to change wallpaper and watch every component re-theme.
MSG
