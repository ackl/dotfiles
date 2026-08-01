#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups"
backup_dir=""

usage() {
  cat <<'EOF'
Usage: ./link_configs.sh CONFIG [CONFIG ...]
       ./link_configs.sh --darwin
       ./link_configs.sh --linux
       ./link_configs.sh --all

Profiles (use one flag by itself):
  --darwin  nvim yazi git kitty zsh skhd yabai
  --linux   nvim yazi git kitty zsh omarchy (for Omarchy Linux)
  --all     Every config, including both macOS and Omarchy settings

Configs: nvim omarchy yazi git kitty zsh skhd yabai
The omarchy selection restores the bar, Hyprland overrides, and terminal preference.
Omarchy files are copied so its config writers and plugin watcher work normally.
The yabai selection also installs yabai-restart into ~/.local/bin.

Existing files, directories, and symlinks are moved into a unique backup
under ${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups before replacement.
Already-correct symlinks are left alone. No arguments prints this help.
EOF
}

if (( $# == 0 )); then
  usage
  exit 0
fi

if [[ $1 == --help || $1 == -h ]]; then
  usage
  exit 0
fi

case "$1" in
  --darwin|--linux|--all)
    if (( $# != 1 )); then
      printf 'Use %s by itself, or select individual configs.\n' "$1" >&2
      exit 1
    fi
    case "$1" in
      --darwin) set -- nvim yazi git kitty zsh skhd yabai ;;
      --linux) set -- nvim yazi git kitty zsh omarchy ;;
      --all) set -- nvim omarchy yazi git kitty zsh skhd yabai ;;
    esac
    ;;
esac

sources=()
targets=()
labels=()
modes=()
add_link() {
  sources+=("$repo_dir/$1")
  targets+=("$2")
  labels+=("${1//\//__}")
  modes+=("${3:-link}")
}

# Resolve and validate the whole selection before touching any config.
for name in "$@"; do
  case "$name" in
    nvim|yazi|git|kitty|yabai)
      add_link "$name" "$config_dir/$name"
      if [[ $name == yabai ]]; then
        add_link yabai/yabai-restart "$HOME/.local/bin/yabai-restart"
      fi
      ;;
    omarchy)
      add_link omarchy/plugins/andrew.active-window "$config_dir/omarchy/plugins/andrew.active-window" copy
      add_link omarchy/hypr/uk-mac.xkb "$config_dir/hypr/uk-mac.xkb" copy
      add_link omarchy/hypr/bindings.lua "$config_dir/hypr/bindings.lua" copy
      add_link omarchy/hypr/input.lua "$config_dir/hypr/input.lua" copy
      add_link omarchy/shell.json "$config_dir/omarchy/shell.json" copy
      add_link omarchy/xdg-terminals.list "$config_dir/xdg-terminals.list" copy
      ;;
    zsh) add_link zshrc "$HOME/.zshrc" ;;
    skhd) add_link skhdrc "$HOME/.skhdrc" ;;
    *) printf 'Unknown config: %s\n' "$name" >&2; usage >&2; exit 1 ;;
  esac
done

for src in "${sources[@]}"; do
  if [[ ! -e "$src" ]]; then
    printf 'Source not found: %s\n' "$src" >&2
    exit 1
  fi
done

for i in "${!sources[@]}"; do
  src="${sources[$i]}"
  target="${targets[$i]}"
  backup=""
  mode="${modes[$i]}"

  if [[ -L "$target" && "$target" -ef "$src" ]]; then
    printf 'Already linked: %s\n' "$target"
    continue
  fi

  if [[ $mode == copy && ! -L "$target" && -e "$target" ]] && diff -qr -- "$src" "$target" >/dev/null; then
    printf 'Already up to date: %s\n' "$target"
    continue
  fi

  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -z "$backup_dir" ]]; then
      mkdir -p "$backup_root"
      backup_dir="$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S).XXXXXX")"
    fi
    backup="$backup_dir/${labels[$i]}"
    mkdir -p "$(dirname "$backup")"
    mv -- "$target" "$backup"
    printf 'Backed up %s -> %s\n' "$target" "$backup"
  fi

  if [[ $mode == copy ]]; then
    install_command=(cp -R --)
    action=Copied
  else
    install_command=(ln -s --)
    action=Linked
  fi

  if "${install_command[@]}" "$src" "$target"; then
    printf '%s %s -> %s\n' "$action" "$src" "$target"
  else
    if [[ -n "$backup" ]]; then
      # Preserve a partial copy rather than overwrite either version.
      if [[ -e "$target" || -L "$target" ]]; then
        mv -- "$target" "$backup.partial"
      fi
      mv -- "$backup" "$target"
      printf 'Restored %s after installation failure\n' "$target" >&2
    fi
    exit 1
  fi
done
