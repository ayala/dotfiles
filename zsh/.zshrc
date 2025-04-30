# ------------------------------------------------------------------------------
#
#                               ea → zsh for mac
#
# ------------------------------------------------------------------------------

# install starship
if ! command -v starship &> /dev/null; then
  echo "Installing Starship..."
  brew install starship
  if [ $? -eq 0 ]; then
    echo "Starship installed successfully!"
  else
    echo "Failed to install Starship."
  fi
fi

# shell integrations
eval "$(starship init zsh)" # initialize starship
eval "$(fzf --zsh)" # fzf integration → Fuzzy search in a directory
eval "$(zoxide init --cmd cd zsh)" # cd command on steroids → https://www.youtube.com/watch?v=aghxkpyRVDY

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# zinit integration
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
# zinit light zdharma-continuum/fast-syntax-highlighting

# add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# load completions
autoload -Uz compinit
compinit

zinit cdreplay -q

# ------------------------------------------------------------------------------
#
#                               Custom Aliases
#
# ------------------------------------------------------------------------------

# aliases
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias docs="cd ~/Documents"
alias cfs="cd ~/.config"
alias dots="cd ~/.dotfiles"

alias clear="clear && printf '\n%.0s' {1..$LINES}" # Keep prompt to the bottom on Ctrl+L.
alias top="htop"
alias cat="bat"
alias yay="imgcat /Users/ea/.config/yay.gif"
alias ls='EZA_ICON_SPACING=2 eza --icons --color=always --group-directories-first'
alias ll='EZA_ICON_SPACING=2 eza -alF --icons --color=always --group-directories-first'
alias la='eza -a --icons --color=always --group-directories-first'
alias l='EZA_ICON_SPACING=2 eza -F --icons --color=always --group-directories-first'
alias l.='eza -a | egrep "^\."'
alias ..='cd ..'

alias ff='fastfetch --load-config ~/.config/fastfetch/mac.jsonc' # Fastfetch shortner
alias nff="nano ~/.config/fastfetch/mac.jsonc" # Quick edit — mac.jsonc
alias push='git add . && git commit -m "stowed" && git push' # git add + commit + push combined with "stowed" comment
alias clean="find ~/.dotfiles ~/.config -name .DS_Store -delete" # Remove *.DS_Store files from .dotfiles and .config

alias nz="nano ~/.zshrc" # Quick edit .zshrc
alias sz="source ~/.zshrc; echo '.zshrc 📦 ➜ sourced'" # Quick source .zshrc

# keybindings
bindkey -e
# bindkey '^p' history-search-backward
# bindkey '^n' history-search-forward
# bindkey '^[w' kill-region
# bindkey "^[^[[C" forward-word
# bindkey "^[^[[D" backward-word

# history
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # Completions not case sensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored folder
zstyle ':completion:*' menu no # no menu on fzf
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath' # folder preview fzf
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# test -e /Users/ea/.iterm2_shell_integration.zsh && source /Users/ea/.iterm2_shell_integration.zsh || true
