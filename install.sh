#!/bin/bash

update() { sudo apt update; }
upgrade() {
    update;
    sudo apt full-upgrade -y; 
}
autoremove() { sudo apt autoremove -y; }

install_build_essential() {
  if ! dpkg -l | grep -q build-essential; then
    echo "Installing build-essential..."
    sudo apt install build-essential -y;
  else
    echo "build-essential is already installed."
  fi
}

install_curl() {
  if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    sudo apt install curl -y;
  else
    echo "curl is already installed."
  fi
}

apt_transport_https() {
  if ! dpkg -l | grep -q apt-transport-https; then
    echo "Installing apt-transport-https..."
    sudo apt install apt-transport-https -y;
  else
    echo "apt-transport-https is already installed."
  fi
}

install_git() {
  if ! command -v git &> /dev/null; then
    echo "Installing git..."
    sudo apt install git -y;
  else
    echo "git is already installed."
  fi
}

install_ssh() {
  if ! command -v ssh &> /dev/null; then
    echo "Installing ssh..."
    sudo apt install ssh -y;
  else
    echo "ssh is already installed."
  fi
}

install_nano() {
  if ! command -v nano &> /dev/null; then
    echo "Installing nano..."
    sudo apt install nano -y;
  else
    echo "nano is already installed."
  fi
}

install_tmux() {
  if ! command -v tmux &> /dev/null; then
    echo "Installing tmux..."
    sudo apt install tmux -y;
  else
    echo "tmux is already installed."
  fi
}

install_vim() {
  if ! command -v vim &> /dev/null; then
    echo "Installing vim..."
    sudo apt install vim -y;
  else
    echo "vim is already installed."
  fi
}

install_neovim() {
  # Check if Neovim is installed
  if ! command -v nvim &> /dev/null; then
    echo "Installing Neovim..."
    sudo apt install neovim -y
  else
    echo "Neovim is already installed."
  fi

  # Create Neovim configuration directory if it doesn't exist
  conf="${HOME}/.config"
  mkdir -p "${conf}/nvim"

  # Create symbolic link for init.vim
  if [ ! -L "${conf}/nvim/init.vim" ]; then
    ln -sv "${HOME}/dotfiles/init.vim" "${conf}/nvim/init.vim"
    echo "Configured Neovim with init.vim from dotfiles."
  else
    echo "Neovim configuration file already linked."
  fi

  # Install vim-plug for plugin management if it doesn't already exist
  if [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim" ]; then
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
           https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    echo "Installed vim-plug for Neovim."
  else
    echo "vim-plug is already installed for Neovim."
  fi
}


install_nvm() {
  if ! command -v nvm &> /dev/null; then
    echo "Installing nvm..."
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash;
  else
    echo "nvm is already installed."
  fi
}

install_ohmybash() {
  if [ ! -d "$HOME/.oh-my-bash" ]; then
    echo "Installing oh-my-bash..."
    bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)";
  else
    echo "oh-my-bash is already installed."
  fi
}

install_vlc() {
  if ! command -v vlc &> /dev/null; then
    echo "Installing VLC..."
    sudo apt install vlc -y;
  else
    echo "VLC is already installed."
  fi
}

install_brave() {
  if ! command -v brave-browser &> /dev/null; then
    echo "Installing Brave browser..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg;
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list;
    update;
    sudo apt install brave-browser;
  else
    echo "Brave browser is already installed."
  fi
}

install_dropbox() {
  if ! command -v dropbox &> /dev/null; then
    echo "Installing Dropbox..."
    wget -O ~/ - "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2024.04.17_amd64.deb" | tar xzf -;
  else
    echo "Dropbox is already installed."
  fi
}

install_vscode() {
  if ! command -v code &> /dev/null; then
    echo "Installing Visual Studio Code..."
    wget -O ~/Downloads https://code.visualstudio.com/sha/download?build=stable&os=linux-x64 | tar xzf -;
  else
    echo "Visual Studio Code is already installed."
  fi
}

install_ffmpeg() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Installing ffmpeg..."
    sudo apt install ffmpeg -y;
  else
    echo "ffmpeg is already installed."
  fi
}

install_sqlite() {
  # Set the base URL and file name
  sqlite_url="https://www.sqlite.org/2024"
  file_name="sqlite-tools-linux-x64-3460100"
  file_extension="zip"

  # Check if SQLite is already installed
  if command -v sqlite3 &> /dev/null; then
    echo "SQLite is already installed."
  else
    echo "Installing SQLite..."

    # Download SQLite
    wget "${sqlite_url}/${file_name}.${file_extension}" -O "${file_name}.${file_extension}"

    # Create a specific directory for SQLite
    mkdir -p "$HOME/sqlite"

    # Unzip the downloaded file into the directory
    unzip "${file_name}.${file_extension}" -d "$HOME/sqlite"

    
    # Add SQLite to the PATH if it's not already there
    if ! grep -q "export PATH=\$PATH:\$HOME/sqlite/${file_name}" ~/.bashrc; then
      echo "export PATH=\$PATH:\$HOME/sqlite/${file_name}" >> ~/.bashrc
    fi

    # Reload the .bashrc to apply changes
    source ~/.bashrc

    # Verify the installation
    sqlite3 --version
  fi
}


install_go() {
  # Set the desired version
  version=${1:-1.23.1}  # Default Go version is set to 1.23.1

  # Check if Go is installed
  if command -v go &> /dev/null; then
    # Get the installed Go version
    installed_version=$(go version | awk '{print $3}' | sed 's/go//')

    # Compare installed version with the desired version
    if [ "$installed_version" = "$version" ]; then
      echo "Go version $version is already installed."
      return
    else
      echo "Removing Go version $installed_version..."
      sudo rm -rf "${HOME}/go"  # Remove the existing Go directory
      sudo rm -rf "/usr/local/go"  # Remove the default installation directory if it exists
      echo "Updating Go from version $installed_version to $version..."
    fi
  else
    echo "Installing Go version $version..."
  fi

  # Download and install the new version
  base_url="https://go.dev/dl/"
  file_name="go${version}.linux-amd64.tar.gz"
  wget "${base_url}${file_name}"
  tar -C ${HOME} -xzf "${file_name}"

  # Update PATH in .bashrc if not already present
  if ! grep -q 'export PATH=$PATH:${HOME}/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:${HOME}/go/bin' >> ~/.bashrc
  fi

  # Reload .bashrc to apply the changes immediately
  source ~/.bashrc

  # Verify the updated Go version
  go version
}


install_java() {
  # Set default version values if not provided
  version=${1:-21}                # Default version is 21
  file_version=${2:-35}           # Default file_version is 35

  # Check if Java is installed
  if command -v java &> /dev/null; then
    # Get the installed Java version
    installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk '{print $1}' | sed 's/[^0-9.]*//g')
    
    # Compare installed version with the desired version
    if [ "$installed_version" = "$version" ]; then
      echo "Java version $version is already installed."
      return
    else
      echo "Removing Java version $installed_version..."
      sudo rm -rf "${HOME}/jdk-${installed_version}"  # Remove the existing Java directory in home
      sudo rm -rf "/usr/lib/jvm/java-${installed_version}-openjdk-amd64"  # Remove the installed Java directory (adjust as necessary)
      echo "Updating Java from version $installed_version to $version..."
    fi
  else
    echo "Installing Java version $version..."
  fi

  # Download and install the new version
  base_url="https://download.java.net/openjdk/jdk${version}/ri/"
  file_name="openjdk-${version}+${file_version}_linux-x64_bin.tar.gz"
  
  wget "${base_url}${file_name}"  # Download the OpenJDK binary
  tar -C ${HOME} -xzf "${file_name}"  # Extract the tar.gz into the user's home directory

  # Set JAVA_HOME and update PATH in .bashrc
  echo "export JAVA_HOME=\${HOME}/jdk-${version}" >> ~/.bashrc
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc

  # Reload .bashrc to apply the changes immediately
  source ~/.bashrc
  
  # Verify the Java installation
  java -version
}


upgrade
install_build_essential
install_curl
apt_transport_https 
install_git
install_ssh
install_nano
install_tmux
install_vim
install_neovim
install_nvm
install_vlc
install_brave
# install_dropbox
install_ffmpeg
install_sqlite
install_go
install_java    # Installs OpenJDK 21+35
# install_java 17 30  # Installs OpenJDK 17+30
install_ohmybash
upgrade
autoremove
