#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups"
backup_dir=""

usage() {
  cat <<'EOF'
Usage: ./link_configs.sh [--dry-run] CONFIG [CONFIG ...]
       ./link_configs.sh --darwin
       ./link_configs.sh --linux
       ./link_configs.sh --all
       ./link_configs.sh [--dry-run] --restore BACKUP_DIR

Profiles (choose one, optionally with --dry-run):
  --darwin  nvim yazi git kitty zsh skhd yabai
  --linux   nvim yazi git kitty zsh omarchy (for Omarchy Linux)
  --all     Every config, including both macOS and Omarchy settings

Configs: nvim omarchy yazi git kitty zsh skhd yabai
The omarchy selection restores the bar, Hyprland overrides, and terminal preference.
Omarchy files are copied so its config writers and plugin watcher work normally.
The yabai selection also installs yabai-restart into ~/.local/bin.

Existing files, directories, and symlinks are moved into a unique backup
under ${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups before replacement.
Already-correct symlinks in link mode are left alone. No arguments prints help.
--dry-run previews installation or restore without writing files.
--restore undoes a recorded installation and preserves current files in the backup.
Use the same HOME and XDG_CONFIG_HOME values when restoring.
EOF
}

dry_run=false
restore_dir=""
selections=()
while (( $# )); do
  case "$1" in
    --dry-run) dry_run=true ;;
    --restore)
      if (( $# < 2 )) || [[ -n "$restore_dir" ]]; then
        printf 'Use --restore BACKUP_DIR once.\n' >&2; exit 1
      fi
      restore_dir="$2"
      shift
      ;;
    --help|-h) usage; exit 0 ;;
    *) selections+=("$1") ;;
  esac
  shift
done
if [[ -n "$restore_dir" ]]; then
  if (( ${#selections[@]} )); then
    printf 'Do not combine --restore with config selections.\n' >&2; exit 1
  fi
  selections=(--all)
elif (( ${#selections[@]} == 0 )); then
  usage; exit 0
fi
set -- "${selections[@]}"
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
  # Avoid backing up the same destination twice for duplicate selections.
  local existing
  for existing in "${targets[@]+"${targets[@]}"}"; do
    [[ "$existing" == "$2" ]] && return 0
  done
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

# The manifest uses tabs/newlines as delimiters. Refuse ambiguous paths before writes.
for path in "$config_dir" "$HOME" "$backup_root" "${targets[@]}"; do
  if [[ "$path" != /* || "$path" == *$'\t'* || "$path" == *$'\n'* ]]; then
    printf 'Expected an absolute path without tabs or newlines: %s\n' "$path" >&2
    exit 1
  fi
done

if [[ -n "$restore_dir" ]]; then
  if [[ ! -d "$restore_dir" || -L "$restore_dir" ]]; then
    printf 'Not a backup directory: %s\n' "$restore_dir" >&2; exit 1
  fi
  restore_dir="$(cd "$restore_dir" && pwd -P)"
  manifest="$restore_dir/manifest.tsv"
  if [[ ! -f "$manifest" || -L "$manifest" || -e "$restore_dir/restored" ]]; then
    printf 'Missing manifest or backup already restored: %s\n' "$restore_dir" >&2; exit 1
  fi
  restore_states=()
  restore_labels=()
  restore_targets=()
  {
    IFS= read -r header || exit 1
    [[ "$header" == dotfiles-backup-v1 ]] || { printf 'Invalid backup manifest.\n' >&2; exit 1; }
    while IFS= read -r line || [[ -n "$line" ]]; do
      state="${line%%$'\t'*}"
      rest="${line#*$'\t'}"
      label="${rest%%$'\t'*}"
      target="${rest#*$'\t'}"
      if [[ "$line" != "$state"$'\t'"$label"$'\t'"$target" || "$target" == *$'\t'* ||
            ( "$state" != present && "$state" != absent ) ]]; then
        printf 'Invalid backup manifest record.\n' >&2; exit 1
      fi
      valid=false
      for i in "${!targets[@]}"; do
        if [[ "$label" == "${labels[$i]}" && "$target" == "${targets[$i]}" ]]; then valid=true; break; fi
      done
      if ! "$valid"; then
        printf 'Unrecognized backup destination (use the original HOME and XDG_CONFIG_HOME): %s\n' "$target" >&2; exit 1
      fi
      for previous in "${restore_targets[@]+"${restore_targets[@]}"}"; do
        [[ "$previous" != "$target" ]] || { printf 'Duplicate backup destination.\n' >&2; exit 1; }
      done
      if [[ "$state" == present && ! -e "$restore_dir/$label" && ! -L "$restore_dir/$label" ]]; then
        printf 'Backup payload missing: %s\n' "$restore_dir/$label" >&2; exit 1
      fi
      restore_states+=("$state")
      restore_labels+=("$label")
      restore_targets+=("$target")
    done
  } < "$manifest"
  # Validate every entry before moving anything. Never overwrite current files.
  preserved=""
  for i in "${!restore_targets[@]}"; do
    target="${restore_targets[$i]}"
    label="${restore_labels[$i]}"
    if "$dry_run"; then
      printf 'Would restore %s (%s before install); preserve current contents.\n' "$target" "${restore_states[$i]}"
      continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
      if [[ -z "$preserved" ]]; then preserved="$(mktemp -d "$restore_dir/restored-current.XXXXXX")"; fi
      mv -- "$target" "$preserved/$label"
      printf 'Preserved %s -> %s\n' "$target" "$preserved/$label"
    fi
    if [[ "${restore_states[$i]}" == present ]]; then
      mkdir -p "$(dirname "$target")"
      if ! mv -- "$restore_dir/$label" "$target"; then
        if [[ -n "$preserved" && ( -e "$preserved/$label" || -L "$preserved/$label" ) ]]; then
          mv -- "$preserved/$label" "$target"
        fi
        exit 1
      fi
    fi
    printf 'Restored: %s\n' "$target"
  done
  if ! "$dry_run"; then touch "$restore_dir/restored"; fi
  exit 0
fi

for src in "${sources[@]}"; do
  if [[ ! -e "$src" ]]; then
    printf 'Source not found: %s\n' "$src" >&2
    exit 1
  fi
done

# Undo the destination being installed. This also runs on errors and signals,
# so an original is never left unrecorded in the backup directory.
pending_target=""
pending_label=""
pending_backup=""
rollback_pending() {
  [[ -n "$pending_target" ]] || return 0
  local target="$pending_target"
  pending_target=""
  # The original has not been moved yet, so it is still in place.
  if [[ -n "$pending_backup" && ! -e "$pending_backup" && ! -L "$pending_backup" ]]; then
    return 0
  fi
  # Preserve a partial copy rather than overwrite either version.
  if [[ -e "$target" || -L "$target" ]]; then
    mv -- "$target" "$backup_dir/$pending_label.partial"
  fi
  if [[ -n "$pending_backup" ]]; then
    mv -- "$pending_backup" "$target"
    printf 'Restored %s after installation failure\n' "$target" >&2
  fi
}
trap_signals() {
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
}
trap rollback_pending EXIT
trap_signals

for i in "${!sources[@]}"; do
  src="${sources[$i]}"
  target="${targets[$i]}"
  mode="${modes[$i]}"

  if [[ $mode == link && -L "$target" && "$target" -ef "$src" ]]; then
    printf 'Already linked: %s\n' "$target"
    continue
  fi

  if [[ $mode == copy && ! -L "$target" && -e "$target" ]] && diff -qr -- "$src" "$target" >/dev/null; then
    printf 'Already up to date: %s\n' "$target"
    continue
  fi

  state=absent
  if [[ -e "$target" || -L "$target" ]]; then state=present; fi
  if "$dry_run"; then
    printf 'Would %s %s -> %s (%s before install)\n' "$mode" "$src" "$target" "$state"
    continue
  fi
  if [[ -z "$backup_dir" ]]; then
    mkdir -p "$backup_root"
    backup_dir="$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S).XXXXXX")"
    printf 'dotfiles-backup-v1\n' > "$backup_dir/manifest.tsv"
    printf 'Backup directory: %s\n' "$backup_dir"
  fi
  mkdir -p "$(dirname "$target")"
  pending_label="${labels[$i]}"
  pending_backup=""
  if [[ "$state" == present ]]; then pending_backup="$backup_dir/${labels[$i]}"; fi
  pending_target="$target"
  if [[ -n "$pending_backup" ]]; then
    mv -- "$target" "$pending_backup"
    printf 'Backed up %s -> %s\n' "$target" "$pending_backup"
  fi

  if [[ $mode == copy ]]; then
    install_command=(cp -R --)
    action=Copied
  else
    install_command=(ln -s --)
    action=Linked
  fi

  if ! "${install_command[@]}" "$src" "$target"; then
    exit 1
  fi
  # Record and stop tracking together, so a signal cannot roll back a recorded install.
  trap '' HUP INT TERM
  printf '%s\t%s\t%s\n' "$state" "${labels[$i]}" "$target" >> "$backup_dir/manifest.tsv"
  pending_target=""
  trap_signals
  printf '%s %s -> %s\n' "$action" "$src" "$target"
done
