# devdesk — a keyboard-driven developer desktop

A complete, reproducible Linux workstation built on **i3 + polybar + rofi + kitty + picom + dunst**,
themed from your wallpaper with **pywal**. Clone, run one script, log in.

![desktop](screenshots/desktop.png)

<p>
  <img src="screenshots/launcher.png" width="49%" alt="rofi launcher">
  <img src="screenshots/cheatsheet.png" width="49%" alt="shortcut cheat-sheet">
</p>

| Dynamic theme A | Dynamic theme B |
|---|---|
| ![theme 1](screenshots/theme-1.png) | ![theme 2](screenshots/theme-2.png) |

---

## Requirements checklist

| Requirement | How it's met |
|---|---|
| **Consistent visual theme** across terminal, launcher, status bar, window decorations | One colour source (pywal). kitty ← `colors-kitty.conf`, rofi ← `colors.rasi`, polybar + i3 borders ← Xresources, dunst ← `dunstrc.d`. Same font everywhere (JetBrainsMono Nerd Font). |
| **Shortcuts** for terminal, launcher, window/workspace switching, screenshots | See [Keybindings](#keybindings). |
| **Refreshable script** with CPU, RAM, battery (load average on desktops) | [`scripts/sysstat.sh`](scripts/sysstat.sh) — auto-updates every 5 s in polybar, click it to refresh instantly. |
| Bonus: wallpaper-synced dynamic theming | `Super+N` (random) / `Super+Shift+N` (pick) re-themes everything live. |
| Bonus: automatic workspace/layout assignment | Browsers → `2:web`, editors → `3:code`, file managers → `4:files`, chat → `5:chat`, Spotify → `9:music`; dialogs float. |
| Bonus: one-command install | `./install.sh` (apt / pacman / dnf). |
| Bonus: event-driven performance optimisation | [`perf-watch.sh`](scripts/perf-watch.sh): udev power events swap the compositor profile (full effects on AC, lite on battery) + power-profiles-daemon. Fullscreen apps bypass the compositor (`unredir-if-possible`). No polling. |
| Bonus: original productivity features | Auto-generated shortcut cheat-sheet (`Super+F1`), Pomodoro timer (`Super+P`), power menu, instant stats popup (`Super+I`). |
| Bonus: interactive widgets | Clickable polybar stats, rofi power menu / wallpaper picker / cheat-sheet. |

## Install

Tested layout: **Ubuntu 24.04+ / Debian 13 / Arch / Fedora**, X11 session. Needs **i3 ≥ 4.22** (built-in gaps) and **picom ≥ 10**.

```bash
git clone https://github.com/<your-username>/devdesk.git
cd devdesk
./install.sh
```

Then **log out → choose the “i3” session on the login screen → log in.**

Flags: `--no-packages` (skip apt/pacman/dnf), `--no-fonts` (skip the Nerd Font download).
Anything it replaces is moved to `~/.dotfiles-backup/<timestamp>/`.

<details>
<summary>What the installer does</summary>

1. Installs packages: `i3 i3lock polybar rofi kitty picom dunst feh maim xclip xdotool playerctl brightnessctl pactl(pulseaudio-utils) pavucontrol imagemagick jq xrdb libnotify nm-applet pipx`
2. Downloads JetBrainsMono Nerd Font to `~/.local/share/fonts`
3. Installs `pywal16` with `pipx`
4. Symlinks everything in `config/` → `~/.config/` and `scripts/*.sh` → `~/.local/bin/` (no extension)
5. Copies `wallpapers/` → `~/Pictures/Wallpapers` and generates the first colour scheme
</details>

## Keybindings

`Super` = Windows key. Press **`Super+F1`** any time for the live list (generated from the i3 config).

| Keys | Action |
|---|---|
| `Super+Enter` | Terminal (kitty) |
| `Super+D` / `Super+Shift+D` | App launcher / run command (rofi) |
| `Super+Tab` | Fuzzy window switcher |
| `Super+1…9` / `Super+Shift+1…9` | Go to / move window to workspace |
| `Super+Ctrl+←/→`, `Super+\`` | Next / previous / last workspace |
| `Super+H J K L` | Focus left / down / up / right |
| `Super+Shift+H J K L` | Move window |
| `Super+B` / `Super+V` | Split horizontal / vertical |
| `Super+F`, `Super+Shift+Space` | Fullscreen, toggle floating |
| `Super+S` / `W` / `E` | Layout stacking / tabbed / split |
| `Super+R` | Resize mode (`H J K L`, `Esc` to leave) |
| `Super+Shift+Q` | Close window |
| `Print` / `Shift+Print` / `Super+Print` / `Ctrl+Print` | Screenshot: full / area / window / area→clipboard |
| `Super+N` / `Super+Shift+N` | Random / picked wallpaper (re-themes everything) |
| `Super+P` | Pomodoro on/off (`Super+Shift+P` status) |
| `Super+I` | CPU / RAM / battery popup |
| `Super+Ctrl+L` | Lock screen |
| `Super+Shift+C` / `Super+Shift+R` | Reload / restart i3 |
| `Super+Shift+E` | Power menu |

Screenshots are saved to `~/Pictures/Screenshots/` **and** copied to the clipboard.

## How the theming works

```
wallpaper ──► wal ──► ~/.cache/wal/
                        ├─ colors.Xresources  ──► xrdb ──► i3 borders (set_from_resource) + polybar (${xrdb:…})
                        ├─ colors-kitty.conf  ──► kitty   (live-reload via SIGUSR1)
                        ├─ colors-rofi.rasi   ──► ~/.config/rofi/colors.rasi
                        └─ dunst-colors.conf  ──► ~/.config/dunst/dunstrc.d/10-colors.conf
```

`scripts/set-wallpaper.sh` runs the pipeline and reloads every component, so a wallpaper change updates the
terminal, launcher, bar, borders and notifications in about a second. Your last theme is restored at login.

## The status script

```console
$ sysstat
CPU 7%  RAM 3.4G  BAT 82%          # laptop
CPU 7%  RAM 3.4G  LOAD 0.42        # desktop (no battery)
```

| Command | Purpose |
|---|---|
| `sysstat` | print once |
| `sysstat --watch 5` | print every 5 s (polybar uses this) |
| `sysstat --refresh` | force a running `--watch` to update now (polybar click) |
| `sysstat --notify` | show as a notification |

## Repo layout

```
devdesk/
├── install.sh              one-command installer
├── config/                 → symlinked into ~/.config
│   ├── i3/config           keybindings, gaps, borders, workspace rules, autostart
│   ├── polybar/config.ini  status bar
│   ├── rofi/config.rasi    launcher
│   ├── kitty/kitty.conf    terminal
│   ├── picom/              compositor (full + battery-lite)
│   ├── dunst/dunstrc       notifications
│   └── wal/templates/      pywal templates for rofi + dunst
├── scripts/                → symlinked into ~/.local/bin
│   ├── sysstat.sh          CPU / RAM / battery
│   ├── set-wallpaper.sh    wallpaper + live re-theme
│   ├── screenshot.sh       maim wrapper (full/area/window/clip)
│   ├── keybinds.sh         auto cheat-sheet
│   ├── pomodoro.sh         focus timer
│   ├── powermenu.sh        lock/logout/suspend/reboot/shutdown
│   ├── perf-watch.sh       event-driven AC/battery tuning
│   └── launch-polybar.sh   one bar per monitor
├── wallpapers/             starter wallpapers (drop your own in)
└── screenshots/            images used in this README
```

## Customising

- **Add a wallpaper:** drop an image in `~/Pictures/Wallpapers` → `Super+Shift+N`.
- **Add a shortcut:** add `bindsym $mod+x exec …   # my description` to `config/i3/config`, then `Super+Shift+C`.
  The trailing comment makes it appear in the cheat-sheet.
- **Pin an app to a workspace:** copy an `assign [class="…"]` line. Find a window's class with `xprop WM_CLASS`.
- **Pomodoro length:** `POMO_WORK=50 POMO_BREAK=10 pomodoro start`.
- **Different terminal:** change `set $term` in the i3 config.

## Troubleshooting

| Problem | Fix |
|---|---|
| Bar shows no icons / odd glyphs | `fc-list \| grep -i "JetBrainsMono Nerd"` should list the font; re-run `./install.sh`. |
| i3 reports config errors on `gaps` | Your i3 is older than 4.22 — upgrade i3 or switch distro. |
| Colours look default after login | Run `set-wallpaper --restore` or press `Super+N`. |
| `wal: command not found` in the i3 session | `pipx ensurepath`, then log out and in. |
| Running in a VM and compositor is glitchy | In `picom.conf` change `backend = "glx"` to `"xrender"`, or delete the blur lines. |
| Want to undo everything | Delete the symlinks in `~/.config` / `~/.local/bin`; originals are in `~/.dotfiles-backup/`. |

## License

MIT — see [LICENSE](LICENSE).
