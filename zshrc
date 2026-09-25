# ---- shell mode ----------------------------------------------------------------
# Skip heavy setup for non-interactive shells.
[[ $- != *i* ]] && return

# ---- oh-my-zsh -----------------------------------------------------------------
export local_bin="$HOME/.local/bin"
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="bira"
plugins=(git)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
fi

# ---- core env ------------------------------------------------------------------
export EDITOR="nvim"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ---- path helpers ---------------------------------------------------------------
path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$dir:$PATH" ;;
  esac
}

path_append() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$PATH:$dir" ;;
  esac
}

# ---- Homebrew (optional on either OS) ------------------------------------------
# Find brew even when the login shell has not added it to PATH yet.
typeset -g __BREW_PREFIX=""
if (( $+commands[brew] )); then
  __BREW_PREFIX="$(command brew --prefix 2>/dev/null)"
else
  for __brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$__brew_bin" ]]; then
      __BREW_PREFIX="$("$__brew_bin" --prefix 2>/dev/null)"
      break
    fi
  done
  unset __brew_bin
fi
if [[ -n "$__BREW_PREFIX" ]]; then
  path_prepend "$__BREW_PREFIX/sbin"
  path_prepend "$__BREW_PREFIX/bin"
fi

# ---- path ----------------------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
else
  export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"
fi
# Later prepend calls have higher priority in the final PATH.
path_prepend "$HOME/.jenv/bin"
path_prepend "$HOME/Library/Python/3.9/bin"
path_prepend "$HOME/Library/Python/3.14/bin"
path_prepend "$HOME/bin"
path_prepend "$PNPM_HOME"
path_prepend "$HOME/.camber/bin"
path_prepend "$HOME/.antigravity/antigravity/bin"
if [[ -n "$__BREW_PREFIX" && -d "$__BREW_PREFIX/opt/node@24" ]]; then
  path_prepend "$__BREW_PREFIX/opt/node@24/bin"
  # Preserve flags supplied by the environment, without duplicating on re-source.
  if [[ " ${LDFLAGS:-} " != *" -L$__BREW_PREFIX/opt/node@24/lib "* ]]; then
    export LDFLAGS="-L$__BREW_PREFIX/opt/node@24/lib${LDFLAGS:+ $LDFLAGS}"
  fi
  if [[ " ${CPPFLAGS:-} " != *" -I$__BREW_PREFIX/opt/node@24/include "* ]]; then
    export CPPFLAGS="-I$__BREW_PREFIX/opt/node@24/include${CPPFLAGS:+ $CPPFLAGS}"
  fi
fi
path_append "$local_bin"
path_append "$HOME/.lmstudio/bin"

# ---- lazy nvm ------------------------------------------------------------------
typeset -gi __NVM_LOADED=0

nvm_on() {
  (( __NVM_LOADED )) && return 0

  local nvm_script="$NVM_DIR/nvm.sh"
  if [[ ! -s "$nvm_script" && -n "$__BREW_PREFIX" ]]; then
    nvm_script="$__BREW_PREFIX/opt/nvm/nvm.sh"
  fi
  if [[ ! -s "$nvm_script" ]]; then
    print -u2 "nvm: installation not found (checked NVM_DIR and Homebrew)"
    return 127
  fi

  # Remove the wrapper so it cannot be mistaken for a successfully loaded NVM.
  unfunction nvm 2>/dev/null
  source "$nvm_script"

  if (( $+functions[nvm] )); then
    __NVM_LOADED=1
    if [[ -r "$NVM_DIR/bash_completion" ]]; then
      source "$NVM_DIR/bash_completion"
    elif [[ -n "$__BREW_PREFIX" && -r "$__BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]]; then
      source "$__BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
    fi
    return 0
  fi

  functions[nvm]=$functions[__nvm_lazy]
  print -u2 "nvm: failed to load $nvm_script"
  return 127
}

nvm_off() {
  (( __NVM_LOADED )) || return 0

  # Let NVM remove its own paths without undoing later environment changes.
  nvm deactivate --silent || return $?
  functions[nvm]=$functions[__nvm_lazy]

  __NVM_LOADED=0
  rehash
}

__nvm_lazy() {
  nvm_on || return $?
  nvm "$@"
}
functions[nvm]=$functions[__nvm_lazy]

# ---- lazy jenv -----------------------------------------------------------------
typeset -gi __JENV_LOADED=0

__jenv_on() {
  (( __JENV_LOADED )) && return 0
  command -v jenv >/dev/null 2>&1 || return 127

  eval "$(command jenv init - 2>/dev/null)"
  __JENV_LOADED=1
}

jenv() {
  unfunction jenv 2>/dev/null || true
  __jenv_on || return $?
  jenv "$@"
}

# ---- lazy conda ----------------------------------------------------------------
typeset -gi __CONDA_LOADED=0

__conda_on() {
  (( __CONDA_LOADED )) && return 0

  if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
    __CONDA_LOADED=1
    return 0
  fi

  if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
    export PATH="$HOME/miniconda3/bin:$PATH"
    __CONDA_LOADED=1
    return 0
  fi

  return 127
}

conda() {
  unfunction conda 2>/dev/null || true
  __conda_on || return $?
  conda "$@"
}

# ---- helper -------------------------------------------------------------------
dotfiles() {
  cd "$HOME/lab/dotfiles/" || return

  local -a files
  if (( $# == 0 )); then
    files=(zshrc)   # swap to .zshrc if that's your filename
  else
    setopt local_options null_glob
    files=( ${(~)^@} )   # force zsh glob expansion on args
    (( $#files )) || { print -u2 " no files matched"; return 1; }
  fi

  nvim -- "${files[@]}"
}

_dotfiles_completion() {
  _files -W "$HOME/lab/dotfiles/"
}
compdef _dotfiles_completion dotfiles de dtf dfe dtfe conf

# ---- aliases -------------------------------------------------------------------
alias vim="nvim"
alias ranger="yazi"
alias {de,dtf,dfe,dtfe,conf}="dotfiles"


alias l='ls -h'
alias la='ls -lAh'
alias lh='ls -lh'
alias ll='ls -lah'
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi
alias lsa='ls -lah'

alias tmux='zellij'
alias {um,umm,urm,uhh,uh,hmm,hmm,ehh,uhhh,idk}='navi'

# ---- completions ---------------------------------------------------------------
if [[ -r "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi
