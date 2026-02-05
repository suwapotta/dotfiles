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

function changeSystemConfigs() {
  ## 1. pacman.conf
  # Backup
  if [[ ! -f "/etc/pacman.conf.bak" ]]; then
    sudo cp -v "/etc/pacman.conf" "/etc/pacman.conf.bak"
  fi

  # Replace
  sudo cp -v "$DOTFILES_DIR/pacman/pacman.conf" "/etc/pacman.conf"

  # Sync servers
  sudo pacman -Syyy

  ## 2. reflector.conf
  local REFLECTOR_DIR="/etc/xdg/reflector"
  sudo pacman -S --needed --noconfirm reflector

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
  sudo pacman -S --needed --noconfirm bluez bluez-utils

  # Enable bluetooth service
  sudo systemctl enable --now bluetooth.service
}

### Main program
if ! confirm; then
  exit
fi

changeSystemConfigs
