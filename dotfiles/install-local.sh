#!/bin/bash

# Install Neovim
install_neovim() {
  if ! command -v nvim &>/dev/null; then
    echo "Installing Neovim..."
    apt install neovim -y
  fi

  local conf="${HOME}/.config"
  mkdir -p "${conf}/nvim"

  if [ ! -L "${conf}/nvim/init.vim" ]; then
    ln -sv "${HOME}/dotfiles/init.vim" "${conf}/nvim/init.vim"
    echo "Configured Neovim with init.vim from dotfiles."
  fi

  if [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim" ]; then
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    echo "Installed vim-plug for Neovim."
  fi
}

# Install nvm
install_nvm() {
  local version=${1:-0.40.1}
  local NVM_DIR="$HOME/.nvm"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm is already installed."
  else
    echo "Installing nvm..."
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v${version}/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    echo "nvm installed successfully."
  fi
}

# Install Deno
install_deno() {
  if command -v deno &>/dev/null; then
    echo "Deno is already installed."
    deno --version
  else
    echo "Installing Deno..."
    if curl -fsSL https://deno.land/install.sh | sh; then
      export DENO_INSTALL="$HOME/.deno"
      export PATH="$DENO_INSTALL/bin:$PATH"
      echo -e 'export DENO_INSTALL="$HOME/.deno"\nexport PATH="$DENO_INSTALL/bin:$PATH"' >>~/.bashrc
      source ~/.bashrc
      deno --version
    fi
  fi
}

# Install oh-my-bash
install_ohmybash() {
  if [ ! -d "$HOME/.oh-my-bash" ]; then
    echo "Installing oh-my-bash..."
    bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"
  else
    echo "oh-my-bash is already installed."
  fi
}

# Install SQLite
install_sqlite() {
  local sqlite_url="https://www.sqlite.org/2024"
  local file_name="sqlite-tools-linux-x64-3460100"
  local file_extension="zip"

  if command -v sqlite3 &>/dev/null; then
    echo "SQLite is already installed."
  else
    echo "Installing SQLite..."
    wget "${sqlite_url}/${file_name}.${file_extension}" -O "${file_name}.${file_extension}"
    mkdir -p "$HOME/sqlite"
    unzip "${file_name}.${file_extension}" -d "$HOME/sqlite"
    echo "export PATH=\$PATH:\$HOME/sqlite/${file_name}" >>~/.bashrc
    source ~/.bashrc
  fi
}

# Install Go
install_go() {
  local version=${1:-1.23.1}
  if command -v go &>/dev/null; then
    local installed_version=$(go version | awk '{print $3}' | sed 's/go//')
    if [ "$installed_version" = "$version" ]; then
      echo "Go version $version is already installed."
      return
    fi
    echo "Updating Go to version $version..."
    sudo rm -rf "$HOME/go" "/usr/local/go"
  else
    echo "Installing Go version $version..."
  fi
  wget "https://go.dev/dl/go${version}.linux-amd64.tar.gz"
  mkdir -p "$HOME/go"
  tar -C "$HOME" -xzf "go${version}.linux-amd64.tar.gz"
  echo 'export PATH=$PATH:${HOME}/go/bin' >>~/.bashrc
  source ~/.bashrc
  go version
}

# Install SDKMAN
install_sdkman() {
  if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "SDKMAN is already installed."
    source "$HOME/.sdkman/bin/sdkman-init.sh"
  else
    echo "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
  fi
  sdk version
}

# Install SDKs using SDKMAN
install_sdks() {
  echo "Installing Java..."
  sdk install java
  echo "Installing Kotlin..."
  sdk install kotlin
  echo "Installing Gradle..."
  sdk install gradle
  sdk current java && sdk current kotlin && sdk current gradle
}

main() {
  install_ohmybash
  install_neovim
  install_nvm
  install_deno
  install_sqlite
  install_go
  install_sdkman
  install_sdks
}

mian

