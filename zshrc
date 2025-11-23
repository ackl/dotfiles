# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="bira"

plugins=(git)

source $ZSH/oh-my-zsh.sh

EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

alias vim="nvim"
alias ranger="yazi"
alias dotfileedit="cd ~/lab/dotfiles && nvim ."

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
 export PATH=$HOME/bin:/usr/local/bin:/Users/andrew/Library/Python/3.9/bin:$PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/andrew/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/andrew/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/andrew/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/andrew/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# pnpm
export PNPM_HOME="/Users/andrew/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


#export DYLD_LIBRARY_PATH="/opt/homebrew/opt/hdf5/lib:/opt/homebrew/opt/curl/lib:/opt/homebrew/opt/openssl@3/lib:/opt/homebrew/opt/libaec/lib:/opt/homebrew/opt/zlib/lib:/opt/homebrew/Cellar/gsl/2.8/lib"


export PATH="$PATH:/Users/andrew/.lmstudio/bin"

alias l='ls -h'
alias la='ls -lAh'
alias lh='ls -lh'
alias ll='ls -lah'
alias ls='ls --color=tty'
alias lsa='ls -lah'
