#!/bin/bash
# ASSUMES:
# - Arch Linux
# - git already installed
# Always installed packages 
# - base-devel gnupg openssh man-db man-pages git vim sudo

# undo all edits when any of the steps fail
function _build_failed {
  pacman -Rns --noconfirm base-devel gnupg openssh man-db man-pages git vim sudo 2>/dev/null
  mv /etc/environment.bak /etc/environment 2>/dev/null
  mv /etc/locale.gen.bak /etc/locale.gen 2>/dev/null
  mv /etc/locale.conf.bak /etc/locale.conf 2>/dev/null
  mv /etc/vconsole.conf.bak /etc/vconsole.conf 2>/dev/null
  mv /etc/wsl.conf.bak /etc/wsl.conf 2>/dev/null
  mv /etc/sudoers.bak /etc/sudoers 2>/dev/null
  passwd -d root 2>/dev/null
  userdel -r "$WSL_INSTALL_USERNAME" 2>/dev/null
  unset "$WSL_INSTALL_USERNAME" 2>/dev/null
  exit 1
}

# Recommended to run `pacman -Syu` on first launch
# The rest are what I consider an small base for all accounts
pacman -Syu --noconfirm base-devel gnupg openssh man-db man-pages git vim sudo
if [ $? -ne 0 ]; then
  echo "Failed to install base packages."
  _build_failed
fi

# Setting language
cp /etc/environment /etc/environment.bak && \
cp /etc/locale.gen /etc/locale.gen.bak && \
echo "EDITOR=vim" >> /etc/environment && \
echo "VISUAL=vim" >> /etc/environment && \
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
echo "en_US ISO-8859-1" >> /etc/locale.gen && \
locale-gen
if [ $? -ne 0 ]; then
  echo "Failed to generate locale"
  _build_failed
fi

# Setting tty keyboard map
cp /etc/locale.conf /etc/locale.conf.bak && \
cp /etc/vconsole.conf /etc/vconsole.conf.bak && \
echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
echo "KEYMAP=us" > /etc/vconsole.conf && \
echo "FONT=ter-v28n" >> /etc/vconsole.conf
if [ $? -ne 0 ]; then
  echo "Failed to set keyboard layout"
  _build_failed
fi

# Add password for root account and add default user and password
echo "Add password for root account" && \
passwd && \
read -p "Create user account. Enter username: " WSL_INSTALL_USERNAME && \
useradd -mG wheel "$WSL_INSTALL_USERNAME" && \
passwd "$WSL_INSTALL_USERNAME" && \
cp /etc/wsl.conf /etc/wsl.conf.bak && \
echo "
[user]
default=$WSL_INSTALL_USERNAME" >> /etc/wsl.conf
if [ $? -ne 0 ]; then
  echo "Failed to create user account"
  _build_failed
fi

# Allow the created user to use sudo by allowing all users under "wheel" group
# to execute any action
cp /etc/sudoers /etc/sudoers.bak && \
sed -i '/^#\s%wheel ALL=(ALL:ALL) ALL$/s/^# //' /etc/sudoers && \
visudo -c
if [ $? -ne 0 ]; then
  echo "Failed to edit sudoers file"
  _build_failed
fi
