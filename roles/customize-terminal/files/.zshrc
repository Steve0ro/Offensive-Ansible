# Exports
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:/usr/local/go/bin
export GOBIN="$HOME/go/bin"
export GOPATH="$HOME/go"
export PATH=$PATH:$GOBIN
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=/home/$USER/.nimble/bin:$PATH

# ZSH Theme
ZSH_THEME="steve0ro"

# ZSH Plugins
plugins=(
    tmux
    git
    zsh-autosuggestions 
    fast-syntax-highlighting 
    zsh-history-substring-search
)

ZSH_TMUX_AUTOSTART=false
ZSH_TMUX_DEFAULT_SESSION_NAME='New Build 👾'
ZSH_TMUX_CONFIG=~/.tmux.conf

HISTFILE=~/.zsh_history
HISTSIZE=9999999
SAVEHIST=$HISTSIZE

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh

autoload -U bashcompinit
bashcompinit

# Aliases
unalias gf
alias ip="ip -c"
alias vi='vim'
alias py='python3'
alias grep='grep --color=always'
alias colorMe='highlight -O xterm256'
alias uz='unzip'
alias ohmy="source ~/.zshrc"
alias tmux_new="tmux new-session -t"
alias tmux_ls="tmux list-sessions"
alias rm="rm -vi"
alias rmdir="rm -rfvi"
alias sp='searchsploit'