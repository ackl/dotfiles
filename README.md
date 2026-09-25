# dotfiles

Personal macOS and Omarchy Linux configuration.

## Install

Choose an OS profile explicitly:

```sh
./link_configs.sh --darwin
./link_configs.sh --linux
```

| Profile | Configs installed |
| --- | --- |
| `--darwin` | `nvim`, `yazi`, `git`, `kitty`, `zsh`, `skhd`, `yabai` |
| `--linux` | `nvim`, `yazi`, `git`, `kitty`, `zsh`, `omarchy` |

`--linux` targets Omarchy's Quickshell/Lua Hyprland setup. Both profiles install the same Kitty config and the shared `zshrc` as `~/.zshrc`. Both profiles install the
repo's Git config as-is, backing up the old config rather than merging it.
Both profiles share a portable Zsh config with OS-specific `ls` aliases and pnpm
paths, optional Homebrew detection, and lazy NVM loading from `$NVM_DIR` or
Homebrew. Existing `NVM_DIR`, `XDG_CONFIG_HOME`, and `PNPM_HOME` settings are
preserved. `nvm_off` deactivates NVM while retaining later changes to `PATH`, such
as an activated Python environment. Oh My Zsh is optional; without it, standard Zsh completion is enabled.
Install Zellij on `PATH` for the `tmux` alias. The installer does not install Zsh,
shell tools, or change your login shell.

Choose one profile, optionally with `--dry-run`. Individual selections remain available:

```sh
./link_configs.sh nvim omarchy
./link_configs.sh git yazi
./link_configs.sh --help
```

No arguments prints help. `--all` installs every supported config across both
platforms; use an OS profile for normal installation. The legacy `i3` and
`i3status` folders are not installed by this script.

## Destinations and backups

- `nvim`, `yazi`, `git`, `kitty`, `yabai`: symlink into `${XDG_CONFIG_HOME:-~/.config}`.
- `zsh`, `skhd`: symlink to `~/.zshrc` and `~/.skhdrc`.
- `yabai`: also symlink `yabai-restart` into `~/.local/bin`.
- `omarchy`: copy the custom active-window widget, `shell.json`, Hyprland
  `input.lua`, `bindings.lua`, `uk-mac.xkb`, and `xdg-terminals.list` into their
  corresponding config locations. Other Omarchy files are preserved.

Existing destinations are moved into a unique backup directory under
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups`; each backup path is printed.
Already-correct links and identical copies are skipped. An Omarchy destination
that is still a symlink is backed up and replaced with a copy, even if it points
at this repository. Every installation that changes files records their original
paths in `manifest.tsv`, including destinations that did not previously exist.

Preview an installation or restore without changing files:

```sh
./link_configs.sh --dry-run --linux
./link_configs.sh --dry-run --restore /path/to/backup-directory
./link_configs.sh --restore /path/to/backup-directory
```

Use the backup directory printed by the installer and the same `HOME` and
`XDG_CONFIG_HOME` values as the original installation. Restore moves old files
back, removes destinations that were originally absent, and preserves current
files in a unique `restored-current.*` directory inside that backup. A completed
restore cannot be run twice. Backups made before manifests were introduced must
be restored manually. If installation fails or is interrupted, the destination
being installed is rolled back immediately; earlier successful changes can be
undone with `--restore`.
Any partial copy is preserved in the backup with a `.partial` suffix. Restore
is sequential; if interrupted, inspect the original backup and its preserved
current files before completing recovery manually.

Omarchy files are copied for compatibility with plugin validation, watchers and
config writers. Reinstall the `omarchy` selection after editing the repo. Copy
live changes back into the repo if you edit them through Omarchy instead.

## Omarchy prerequisites and reload

The installer handles configs only. Install the applications separately:

```sh
omarchy install terminal kitty
omarchy pkg add yazi
./link_configs.sh --linux
hyprctl reload
hyprctl configerrors
omarchy restart shell
```

The Omarchy profile selects Kitty as the default terminal and displays
application name plus window title in the bar. It includes UK Mac keyboard
settings (Option-2 for `€`, Option-3 for `#`), three-finger trackpad drag, natural
scrolling for `logitech-pebble-mouse`, and the personal Hyprland shortcuts in
`omarchy/hypr/bindings.lua`. Adjust the keyboard/device settings on other hardware.
The `andrew.active-window` plugin ID works independently of the login username.

## Shared Kitty configuration

Both OS profiles use `kitty/kitty.conf`: JetBrainsMono Nerd Font at size 9,
14px padding, powerline tabs, a blinking block cursor, close confirmation,
interactive scrolling and dynamic opacity. Install the font separately on macOS.
Base4Tone is the fallback theme; an optional include follows Omarchy's current
palette when available. `runtime.py` loads that optional theme and generates the remote-control
socket path using Kitty's built-in Python runtime, preserving Omarchy's runtime
path on Linux and falling back to the system temporary directory on macOS.
The existing SSH kitten settings in `kitty/ssh.conf` remain unchanged.

Apply with `./link_configs.sh kitty`. On Omarchy, `omarchy restart terminal`
reloads running terminals; open a new Kitty instance for socket-path changes.

## Neovim theme

Neovim reads Omarchy's current `neovim.lua` theme specification at startup,
loads its theme plugin and palette, and applies its colorscheme without loading
LazyVim. Reopen Neovim after switching the desktop theme. On machines without
an Omarchy theme file, Neovim keeps its built-in default colorscheme.
Theme plugin options (including generated palettes) are preserved. Themes such
as Nord that rely on LazyVim's bundled Tokyo Night plugin load it explicitly.
