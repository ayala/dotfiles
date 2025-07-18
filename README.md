# ea → dotfiles

This directory contains the dotfiles for my system

1. Clone this repo into you local dotfiles.

```zsh
# Use SSH (if set up)...
git clone git@github.com:ayala/dotfiles.git ~/.dotfiles

# ...or use HTTPS and switch remotes later.
git clone https://github.com/ayala/dotfiles.git ~/.dotfiles
```

2. Setup git.

Let's initialize a Git repo for file versioning and push to Github

```zsh
cd ~/.dotfiles
git init
git add .
git commit -m "stowed"
git remote add origin git@github.com:ayala/.dotfiles.git
git push -u origin main
```

## Requirements

Ensure you have the following installed on your system

### git
```zsh
brew install git
```

3. Install GNU stow for symlinked configs

### stow
```zsh
brew install stow
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git
```zsh
$ git clone git@github.com/ayala/dotfiles.git
$ cd .dotfiles
```
then use GNU stow to create symlinks
```zsh
$ stow .
```

info → https://www.youtube.com/watch?v=y6XCebnB9gs&t=54s


## TODO List

- Learn how to use [`defaults`](https://macos-defaults.com/#%F0%9F%99%8B-what-s-a-defaults-command) to record and restore System Preferences and other macOS configurations.
