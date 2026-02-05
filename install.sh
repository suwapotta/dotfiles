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

### Helper functions
function countdown() {
  for i in {3..1}; do
    case "$i" in
    3)
      COLOR=$RED
      ;;
    2)
      COLOR=$YELLOW
      ;;
    1)
      COLOR=$GREEN
      ;;
    esac

    printf "\r${BLUE}::${WHITE} Starting in ${COLOR}%d${WHITE}..." "$i"
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

function systemConfig() {
  # pacman.conf
  if [ ! -f "/etc/pacman.conf.bak" ]; then
    sudo cp -v "/etc/pacman.conf" "/etc/pacman.conf.bak"
  fi
  sudo cp -v "$DOTFILES_DIR/pacman/pacman.conf" "/etc/pacman.conf"

  # reflector.conf
  local REFLECTOR_DIR="/etc/xdg/reflector/"
  if command -v reflector &>/dev/null; then
    echo "Installing reflector..."
    sudo pacman -S --needed reflector
  fi

  if [ ! -f "$REFLECTOR_DIR/reflector.conf.bak" ]; then
    sudo cp -v "$REFLECTOR_DIR/reflector.conf" "$REFLECTOR_DIR/reflector.conf.bak"
  fi
  sudo cp -v "$DOTFILES_DIR/pacman/pacman.conf" "/etc/pacman.conf"
  sudo systemctl enable --now reflector.timer
}

### Main program
if ! confirm; then
  exit
fi

systemConfig
