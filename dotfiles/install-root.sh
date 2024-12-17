#!/bin/bash

# Ensure the script is run as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
  fi
}

# Trap to handle errors gracefully
trap_error() {
  trap 'echo "An error occurred. Exiting."; exit 1' ERR
}

# Update and upgrade the system
update_system() {
  sudo apt update && apt upgrade -y
}

# Clean up unused packages
autoremove() {
  sudo apt autoremove -y
}

# Install basic packages
install_basic_packages() {
  sudo apt install -y sudo curl wget gnupg zip unzip build-essential \
    gdb apt-transport-https git ssh nano tmux vim neovim 
}

main() {
  check_root
  trap_error
  update_system
  install_basic_packages
  autoremove
}

main
