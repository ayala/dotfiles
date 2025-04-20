# ea → dotfiles

This directory contains the dotfiles for my system

```
# Use SSH (if set up)...
git clone git@github.com:ayala/dotfiles.git ~/.dotfiles

# ...or use HTTPS and switch remotes later.
git clone https://github.com/ayala/dotfiles.git ~/.dotfiles
```

## Requirements

Ensure you have the following installed on your system

### git
```
brew install git
```

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

info → https://www.youtube.com/watch?v=y6XCebnB9gs&t=54s

