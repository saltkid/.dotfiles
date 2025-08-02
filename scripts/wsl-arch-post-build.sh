#!/bin/bash
# ASSUMES:
# - Arch Linux
# - git already installed
# Always installed packages 
# - base-devel gnupg openssh man-db man-pages git vim sudo
# - stow (dotfile configs)

DOTFILES_DIR=$(dirname $(dirname $(realpath $0)))

function _unset_build_vars() {
  unset DOTFILES_DIR zsh_plugins zsh_plugin nerd_fonts nerd_font
}

function _build_failed {
  uv cache clean 2>/dev/null
  rm -rf ~/.config ~/.zsh_plugins ~/.local \
  "$(uv python dir)" "$(uv tool dir)" /usr/local/bin/lazygit /opt/nvim \
  ~/lazygit.tar.gz ~/lazygit 2>/dev/null
  for nerd_font in $(< $DOTFILES_DIR/nerd-fonts.txt); do
    rm ~/$nerd_font.tar.xz 2>/dev/null
  done
  sudo pacman -Rns --noconfirm stow $(< $DOTFILES_DIR/wsl-arch-packages.txt) 2>/dev/null
  cd $DOTFILES_DIR
  stow . --delete
  cd $HOME
  _unset_build_vars
  exit 1
}


# INSTALL PACKAGES {{{
mkdir -p ~/Source ~/Work ~/Projects ~/.config
git clone https://aur.archlinux.org/yay.git $HOME/Source/yay && \
  cd $HOME/Source/yay && makepkg -si && cd $HOME && \
  rm -fr $HOME/Source/yay && \

sudo pacman -S --noconfirm stow && \

# user packages
sudo pacman -S --noconfirm $(< $DOTFILES_DIR/wsl-arch-packages.txt) && \
if [ $? -ne 0 ]; then
  echo "Failed to install required and user packages"
  _build_failed
fi
# }}}

# INSTALL ZSH PLUGINS {{{
# based on u/colemaker360's snippet
# https://www.reddit.com/r/zsh/comments/dlmf7r/manually_setup_plugins/
for zsh_plugin in $(< $DOTFILES_DIR/zsh-plugins.txt); do
  if [[ ! -d ${ZDOTDIR:-$HOME}/.zsh_plugins/$zsh_plugin ]]; then
    mkdir -p ${ZDOTDIR:-$HOME}/.zsh_plugins/${zsh_plugin%/*} && \
    git clone --depth 1 --recurse-submodules -j8 https://github.com/$zsh_plugin.git ${ZDOTDIR:-$HOME}/.zsh_plugins/$zsh_plugin
    if [ $? -ne 0 ]; then
      echo "Failed to install zsh plugin: $zsh_plugin"
      _build_failed
    fi
  fi
done
# }}}

# INSTALL NERD FONTS {{{
mkdir -p ~/.local/share/fonts/
for nerd_font in $(< $DOTFILES_DIR/nerd-fonts.txt); do
  curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$nerd_font.tar.xz && \
  tar xf $nerd_font.tar.xz -C ~/.local/share/fonts/ && \
  rm $nerd_font.tar.xz
  if [ $? -ne 0 ]; then
    echo "Failed to install nerd font: $nerd_font"
    _build_failed
  fi
done
# }}}

# INSTALL PACKAGES NOT IN REPOS {{{
# GT FOR FZFCD
git clone git@github.com-saltkid:saltkid/gt.git ~/Projects/etc/gt
if [ $? -ne 0 ]; then
  echo "Failed to clone saltkid/gt"
  _build_failed
fi
# }}}

# FINISH {{{
chsh -s $(which zsh) $USER
# initialize dotfiles
cd $DOTFILES_DIR
stow . --adopt
git restore . # remove adopted changes
cd $HOME
_unset_build_vars
# }}}
