#!/usr/bin/env bash
set -euo pipefail

# Resolve repository directory relative to this script.
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dotfile_links=(
  ".yabairc:yabairc"
  ".skhdrc:skhdrc"
  ".zshrc:zshrc"
)

for item in "${dotfile_links[@]}"; do
  dest="${item%%:*}"
  rel_src="${item#*:}"
  src="${repo_dir}/${rel_src}"
  target="${HOME}/${dest}"

  if [[ ! -f "$src" ]]; then
    echo "Source file not found: $src" >&2
    exit 1
  fi

  ln -sf "$src" "$target"
  printf 'Linked %s -> %s\n' "$target" "$src"
done

config_dir="${HOME}/.config"
mkdir -p "$config_dir"

config_links=(
  ghostty
  nvim
  yazi
  git
)

for name in "${config_links[@]}"; do
  src="${repo_dir}/${name}"
  target="${config_dir}/${name}"

  if [[ ! -d "$src" ]]; then
    echo "Source directory not found: $src" >&2
    exit 1
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -d "$target" && ! -L "$target" ]]; then
      rm -rf "$target"
    else
      rm -f "$target"
    fi
  fi

  ln -sfn "$src" "$target"
  printf 'Linked %s -> %s\n' "$target" "$src"
done
