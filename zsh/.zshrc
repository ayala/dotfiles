# ------------------------------------------------------------------------------
#
#                               ea → zsh for mac 
#
# ------------------------------------------------------------------------------

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# zoxide integration
eval "$(zoxide init --cmd cd zsh)"

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# # Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
# zinit light Aloxaf/fzf-tab

# Add in snippets
# zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ------------------------------------------------------------------------------
#
#                               Custom Aliases 
#
# ------------------------------------------------------------------------------

# Location aliases
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias docs="cd ~/Documents"
alias cfs="cd ~/.config"
alias dots="cd ~/.dotfiles"

alias clear="clear && printf '\n%.0s' {1..$LINES}" ## Keep prompt to the bottom on Ctrl+L.
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
alias clean="find ~/.dotfiles ~/.config -name .DS_Store -delete" # Remove *.DS_Store files from .dotfiles

alias nz="nano ~/.zshrc" # Quick edit .zshrc
alias sz="source ~/.zshrc; echo '.zshrc 📦 ➜ sourced'" # Quick source .zshrc

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word

# History
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

# # Completion styling
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# zstyle ':completion:*' menu no
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# # Aliases
# alias vim='nvim'

# # Shell integrations
# eval "$(fzf --zsh)"
# eval "$(zoxide init --cmd cd zsh)"

# test -e /Users/ea/.iterm2_shell_integration.zsh && source /Users/ea/.iterm2_shell_integration.zsh || true
