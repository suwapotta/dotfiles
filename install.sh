#!/usr/bin/env bash

# This script automates the installing process for
# dotfiles and several configs for pacman, systemd, etc.
# Author: suwapotta

# ANSI Color codes
URED="\e[4;31m"
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
WHITE="\e[0m"

# Global variables
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

### Helper functions
function countdown() {
  for i in {3..1}; do
    case "$i" in
    3)
      CURRENT_COLOR=$RED
      ;;
    2)
      CURRENT_COLOR=$YELLOW
      ;;
    1)
      CURRENT_COLOR=$GREEN
      ;;
    esac

    printf "\r${BLUE}::${WHITE} Starting in ${CURRENT_COLOR}%d${WHITE}..." "$i"
    sleep 1
  done

  echo -e "Go!"
}

function confirm() {
  echo -en "${URED}Do you wish to continue?${WHITE} [Y/n] "
  read -r CONFIRMATION

  case "$CONFIRMATION" in
  "y" | "Y" | "")
    countdown
    return 0
    ;;
  *)
    echo "${RED}Aborting...${WHITE}"
    return 1
    ;;
  esac
}

function changeSystemConfigs() {
  ## 1. pacman.conf
  # Backup
  if [[ ! -f "" ]]; then
    sudo cp -v "/etc/pacman.conf" "/etc/pacman.conf.bak"
  fi

  # Replace
  sudo cp -v "$DOTFILES_DIR/pacman/pacman.conf" "/etc/pacman.conf"

  # Sync servers
  sudo pacman -Syyy

  ## 2. reflector.conf
  local REFLECTOR_DIR="/etc/xdg/reflector"
  sudo SNAP_PAC_SKIP=y pacman -S --needed --noconfirm reflector

  # Safety check for first time installing
  if [[ ! -d "$REFLECTOR_DIR" ]]; then
    sudo mkdir -p "$REFLECTOR_DIR"
  fi

  # Backup
  if [[ ! -f "$REFLECTOR_DIR/reflector.conf.bak" ]]; then
    sudo cp -v "$REFLECTOR_DIR/reflector.conf" "$REFLECTOR_DIR/reflector.conf.bak"
  fi

  # Replace
  sudo cp -v "$DOTFILES_DIR/reflector/reflector.conf" "$REFLECTOR_DIR/reflector.conf"

  # Enable weekly reflector service
  sudo systemctl enable --now reflector.timer

  ## 3. bluez + bluez-utils
  # Installing
  sudo SNAP_PAC_SKIP=y pacman -S --needed --noconfirm bluez bluez-utils

  # Enable bluetooth service
  sudo systemctl enable --now bluetooth.service
}

function bulkInstall() {
  local PKGAUR_DIR="$DOTFILES_DIR/pacman"

  # Offical packages
  cat "$PKGAUR_DIR/pkglist.txt" | sudo SNAP_PAC_SKIP=y pacman -S --needed --noconfirm -

  # AURs
  # NOTE: Can't skip snap-pac here using paru
  paru -S --needed --noconfirm - <"$PKGAUR_DIR/aurlist.txt"
}

function stowDotfiles() {
  local STOW_DIRS=(btop cava fastfetch fcitx5 fish gtk-3.0 gtk-4.0 kitty niri noctalia nvim qt5ct qt6ct snapper starship tealdeer tmux yazi zathura)

  # Check and convert to .bak if there exists any config file
  cd "$DOTFILES_DIR" || return
  for dir in "${STOW_DIRS[@]}"; do
    case "$dir" in
    "snapper")
      local currentTarget="$HOME/.scripts/snapper-notify.sh"
      ;;
    "starship")
      local currentTarget="$CONFIG_DIR/starship.toml"
      ;;
    "tmux")
      local currentTarget="$HOME/.tmux.conf"
      ;;
    *)
      local currentTarget="$CONFIG_DIR/$dir"
      ;;
    esac

    if [[ -e "$currentTarget" && ! -L "$currentTarget" ]]; then
      mv "$currentTarget" "${currentTarget}.bak"
    fi

    stow -R -v "$dir"
  done
}

function others() {
  # Install fish's plugins
  fish -c "fisher update"

  # Install tmux's plugin mangager (tpm)
  if [[ ! -e "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi

  # Start-up login screen
  sudo systemctl enable sddm.service

  # GTK Theme
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'

  # Symlink qt6 config for root
  local QT6_ROOTDIR="/root/.config/qt6ct"
  sudo mkdir -p "$QT6_ROOTDIR"
  sudo ln -s "/home/$USER/.config/qt6ct" "$QT6_ROOTDIR"

  # Update cache for tldr
  tldr --update
}

### MAIN PROGRAM

# Start timer + Before script snapshot
START=$SECONDS
sudo snapper create -c root -c timeline -d "Before install.sh"

# Confirmation
if ! confirm; then
  exit
fi

# Calling defined functions
changeSystemConfigs
bulkInstall
stowDotfiles
others

# Finishing backup
sudo snapper create -c root -c timeline -d "After install.sh"

# Return script runtime
END=$SECONDS
DURATION=$((END - START))
echo -e "${YELLOW}Script ran for $DURATION seconds!${WHITE}"
