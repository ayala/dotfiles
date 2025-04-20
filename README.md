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

## Requirements

Ensure you have the following installed on your system

### git
```
brew install git
```

3. Install GNU stow for symlinked configs

### stow
```
brew install stow
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git
```
$ git clone git@github.com/ayala/dotfiles.git
$ cd .dotfiles
```
then use GNU stow to create symlinks
```
$ stow .
```

4. Install Homebrew, followed by the software listed in the Brewfile.

```zsh
# These could also be in an install script.

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then pass in the Brewfile location...
brew bundle --file ~/.dotfiles/Brewfile

# ...or move to the directory first.
cd ~/.dotfiles && brew bundle
```

info → https://www.youtube.com/watch?v=y6XCebnB9gs&t=54s

## TODO List

- Learn how to use [`defaults`](https://macos-defaults.com/#%F0%9F%99%8B-what-s-a-defaults-command) to record and restore System Preferences and other macOS configurations.
