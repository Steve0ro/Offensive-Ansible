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
    zsh-history-substring-search
    zsh-autosuggestions
    zsh-syntax-highlighting
)

ZSH_TMUX_AUTOSTART=false
ZSH_TMUX_DEFAULT_SESSION_NAME='New Build 👾'
ZSH_TMUX_CONFIG=~/.tmux.conf

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh
FORMAT="\nID\t{{.ID}}\nIMAGE\t{{.Image}}\nCOMMAND\t{{.Command}}\nCREATED\t{{.RunningFor}}\nSTATUS\t{{.Status}}\nPORTS\t{{.Ports}}\nNAMES\t{{.Names}}\n"

autoload -U bashcompinit
bashcompinit

# Aliases
unalias gf
alias ip="ip -c"
alias sqlmap="python /opt/Tools/sqlmap/./sqlmap.py"
alias vi='vim'
alias py='python3'
alias grep='grep --color=always'
alias colorMe='highlight -O xterm256'
alias uz='unzip'