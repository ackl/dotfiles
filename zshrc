# ---- shell mode ----------------------------------------------------------------
# Skip heavy setup for non-interactive shells.
[[ $- != *i* ]] && return

# ---- oh-my-zsh -----------------------------------------------------------------
export local_bin="$HOME/.local/bin"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bira"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# ---- core env ------------------------------------------------------------------
export EDITOR="nvim"
export NVM_DIR="$HOME/.nvm"
export XDG_CONFIG_HOME="$HOME/.config"

# For compilers to find node@24.
export LDFLAGS="-L/opt/homebrew/opt/node@24/lib"
export CPPFLAGS="-I/opt/homebrew/opt/node@24/include"

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

# ---- path ----------------------------------------------------------------------
export PNPM_HOME="$HOME/Library/pnpm"
# Keep this order intentional: highest priority first in the final PATH.
path_prepend "$HOME/.jenv/bin"
path_prepend "$HOME/Library/Python/3.9/bin"
path_prepend "$HOME/Library/Python/3.14/bin"
path_prepend "$HOME/bin"
path_prepend "$PNPM_HOME"
path_prepend "$HOME/.camber/bin"
path_prepend "$HOME/.antigravity/antigravity/bin"
path_prepend "/opt/homebrew/opt/node@24/bin"
path_append "$local_bin"
path_append "$HOME/.lmstudio/bin"

# ---- lazy nvm ------------------------------------------------------------------
typeset -gi __NVM_LOADED=0
typeset -g __NVM_SAVED_PATH=""

nvm_on() {
  (( __NVM_LOADED )) && return 0

  __NVM_SAVED_PATH="$PATH"

  [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]] && . "/opt/homebrew/opt/nvm/nvm.sh"
  [[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

  if typeset -f nvm >/dev/null 2>&1; then
    functions -c nvm __nvm_real
    __NVM_LOADED=1
    return 0
  fi

  return 127
}

nvm_off() {
  (( __NVM_LOADED )) || return 0

  export PATH="$__NVM_SAVED_PATH"
  unset NVM_BIN NVM_INC
  unfunction __nvm_real 2>/dev/null || true

  __NVM_LOADED=0
  rehash
}

nvm() {
  nvm_on || return $?
  __nvm_real "$@"
}

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
alias ls='ls --color=tty'
alias lsa='ls -lah'

alias zellij='/Applications/zellij'
alias tmux='zellij'
alias {um,umm,urm,uhh,uh,hmm,hmm,ehh,uhhh,idk}='navi'

# ---- completions ---------------------------------------------------------------
[[ -r "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/andrew/.lmstudio/bin"
# End of LM Studio CLI section

# OpenClaw Completion
source "/Users/andrew/.openclaw/completions/openclaw.zsh"
