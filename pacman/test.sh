#!/usr/bin/env bash

URED="\e[4;31m"
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
WHITE="\e[0m"

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
    echo "Aborting..."
    return 1
    ;;
  esac
}
