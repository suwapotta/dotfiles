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
NOCOLOR="\e[0m"

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

    printf "\r${BLUE}::${NOCOLOR} Starting in ${CURRENT_COLOR}%d${NOCOLOR}..." "$i"
    sleep 1
  done

  echo -e "Go!"
}

function confirm() {
  echo -en "${URED}Do you wish to continue?${NOCOLOR} [Y/n] "
  read -r CONFIRMATION

  case "$CONFIRMATION" in
  "y" | "Y" | "")
    countdown
    return 0
    ;;
  *)
    echo "${RED}Aborting...${NOCOLOR}"
    return 1
    ;;
  esac
}

function changeSystemConfigs() {
  ## 1. pacman.conf
  # Backup
  if [[ ! -e "/etc/pacman.conf.bak" ]]; then
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
  if [[ ! -e "$REFLECTOR_DIR/reflector.conf.bak" ]]; then
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
  if ! stow --version &>/dev/null; then
    echo "${RED}ERROR${NOCOLOR}: ${BLUE}stow${NOCOLOR} not available!"
    return 1
  fi

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
      mv -v "$currentTarget" "${currentTarget}.bak"
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
  sudo ln -sf "/home/$USER/.config/qt6ct" "$QT6_ROOTDIR"

  # First update cache for tealdeer
  if [[ ! -e "$HOME/.cache/tealdeer/tldr-pages/pages.en/" ]]; then
    tldr --update
  fi
}

function cleanUp() {
  local SEARCH_TERM1=$1
  local SEARCH_TERM2=$2

  local SNAPPER_OUTPUT=$(snapper ls)

  local TARGET1=$(echo "$SNAPPER_OUTPUT" | awk -v search="$SEARCH_TERM1" -F'│' 'NR>2 {
    num=$1;  gsub(/^[ \t]+|[ \t]+$/, "", num);
    desc=$7; gsub(/^[ \t]+|[ \t]+$/, "", desc);
    if(desc == search) { print num; exit }
  }')

  local TARGET2=$(echo "$SNAPPER_OUTPUT" | awk -v search="$SEARCH_TERM2" -F'│' 'NR>2 {
    num=$1;  gsub(/^[ \t]+|[ \t]+$/, "", num);
    desc=$7; gsub(/^[ \t]+|[ \t]+$/, "", desc);
    if(desc == search) { print num; exit }
  }')

  if ! [[ "$TARGET1" =~ ^[0-9]+$ ]] || ! [[ "$TARGET2" =~ ^[0-9]+$ ]]; then
    echo "Error: Could not find exact matches for both '$SEARCH_TERM1' and '$SEARCH_TERM2'."
    local TEMP=$(snapper ls | awk -F'│' 'NR>2 {
    num=$1; gsub(/^[ \t]+|[ \t]+$/, "", num);
    if (num > 0) {
        print num;
        exit;
    }
  }')
    sudo snapper delete "$TEMP"-$((TARGET2 - 1))

    return 1
  fi

  sudo snapper delete $((TARGET1 + 1))-$((TARGET2 - 1))
}

### MAIN PROGRAM
# Exit whenever there is error
set -euo pipefail

# Ask for password and keep sudo alive throughout script
sudo --validate
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

# Start timer + Before script snapshot
START=$SECONDS
sudo snapper create -c root -c timeline -d "Before install.sh"

# Initial confirmation
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

# Delete all auto snapshots in process
cleanUp "Before install.sh" "After install.sh"

# Return script runtime
END=$SECONDS
DURATION=$((END - START))
echo -e "${YELLOW}Script ran for $DURATION seconds!${NOCOLOR}"

echo -e "You may now reboot!"
