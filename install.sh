#!/bin/bash

update() { sudo apt update; }
upgrade() {
  update
  sudo apt full-upgrade -y
}
autoremove() { sudo apt autoremove -y; }

install_build_essential() {
  if ! dpkg -l | grep -q build-essential; then
    echo "Installing build-essential..."
    sudo apt install build-essential gdb -y
  else
    echo "build-essential is already installed."
  fi
}

install_curl() {
  if ! command -v curl &>/dev/null; then
    echo "Installing curl..."
    sudo apt install curl -y
  else
    echo "curl is already installed."
  fi
}

apt_transport_https() {
  if ! dpkg -l | grep -q apt-transport-https; then
    echo "Installing apt-transport-https..."
    sudo apt install apt-transport-https -y
  else
    echo "apt-transport-https is already installed."
  fi
}

install_git() {
  if ! command -v git &>/dev/null; then
    echo "Installing git..."
    sudo apt install git -y
  else
    echo "git is already installed."
  fi
}

install_ssh() {
  if ! command -v ssh &>/dev/null; then
    echo "Installing ssh..."
    sudo apt install ssh -y
  else
    echo "ssh is already installed."
  fi
}

install_nano() {
  if ! command -v nano &>/dev/null; then
    echo "Installing nano..."
    sudo apt install nano -y
  else
    echo "nano is already installed."
  fi
}

install_tmux() {
  if ! command -v tmux &>/dev/null; then
    echo "Installing tmux..."
    sudo apt install tmux -y
  else
    echo "tmux is already installed."
  fi
}

install_vim() {
  if ! command -v vim &>/dev/null; then
    echo "Installing vim..."
    sudo apt install vim -y
  else
    echo "vim is already installed."
  fi
}

install_neovim() {
  # Check if Neovim is installed
  if ! command -v nvim &>/dev/null; then
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
  version=${1:-0.40.1} # Default nvm version is set to 0.40.1
  NVM_DIR="$HOME/.nvm"

  # Check if nvm is installed by looking for the initialization script
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm is already installed."
  else
    echo "Installing nvm..."
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v${version}/install.sh | bash

    # Source nvm to the current shell session
    export NVM_DIR="$HOME/.nvm"
    # Check if the nvm.sh script exists before sourcing
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      . "$NVM_DIR/nvm.sh" # This loads nvm
      echo "nvm installed successfully."
    else
      echo "nvm installation failed."
      return 1
    fi
  fi

  # Check if nvim is installed
  if command -v nvim &>/dev/null; then
    echo "nvim is already installed."
  else
    echo "nvim is not installed."
  fi
}

install_deno() {
  # Check if Deno is already installed
  if command -v deno &>/dev/null; then
    echo "Deno is already installed."
    deno --version
    return
  fi

  # Install Deno using the official install script
  echo "Installing Deno..."
  if curl -fsSL https://deno.land/install.sh | sh; then
    echo "Deno installed successfully."

    # Add Deno to the system PATH if it wasn't automatically added
    if ! command -v deno &>/dev/null; then
      export DENO_INSTALL="$HOME/.deno"
      export PATH="$DENO_INSTALL/bin:$PATH"
      echo -e 'export DENO_INSTALL="$HOME/.deno"\nexport PATH="$DENO_INSTALL/bin:$PATH"' >>~/.bashrc
      source ~/.bashrc
      echo "Deno added to PATH."
    fi

    # Verify installation
    deno --version
  else
    echo "Failed to install Deno."
    return 1
  fi
}

install_ohmybash() {
  if [ ! -d "$HOME/.oh-my-bash" ]; then
    echo "Installing oh-my-bash..."
    bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"
  else
    echo "oh-my-bash is already installed."
  fi
}

install_vlc() {
  if ! command -v vlc &>/dev/null; then
    echo "Installing VLC..."
    sudo apt install vlc -y
  else
    echo "VLC is already installed."
  fi
}

install_brave() {
  if ! command -v brave-browser &>/dev/null; then
    echo "Installing Brave browser..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    update
    sudo apt install brave-browser
  else
    echo "Brave browser is already installed."
  fi
}

install_dropbox() {
  if ! command -v dropbox &>/dev/null; then
    echo "Installing Dropbox..."
    wget -O ~/ - "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2024.04.17_amd64.deb" | tar xzf -
  else
    echo "Dropbox is already installed."
  fi
}

install_vscode() {
  if ! command -v code &>/dev/null; then
    echo "Installing Visual Studio Code..."
    wget -O ~/Downloads https://code.visualstudio.com/sha/download?build=stable &
    os=linux-x64 | tar xzf -
  else
    echo "Visual Studio Code is already installed."
  fi
}

install_ffmpeg() {
  if ! command -v ffmpeg &>/dev/null; then
    echo "Installing ffmpeg..."
    sudo apt install ffmpeg -y
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
  if command -v sqlite3 &>/dev/null; then
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
      echo "export PATH=\$PATH:\$HOME/sqlite/${file_name}" >>~/.bashrc
    fi

    # Reload the .bashrc to apply changes
    source ~/.bashrc

    # Verify the installation
    sqlite3 --version
  fi
}

install_go() {
  # Set the desired version
  version=${1:-1.23.1} # Default Go version is set to 1.23.1

  # Check if Go is installed
  if command -v go &>/dev/null; then
    # Get the installed Go version
    installed_version=$(go version | awk '{print $3}' | sed 's/go//')

    # Compare installed version with the desired version
    if [ "$installed_version" = "$version" ]; then
      echo "Go version $version is already installed."
      return
    else
      echo "Removing Go version $installed_version..."
      sudo rm -rf "${HOME}/go"    # Remove the existing Go directory
      sudo rm -rf "/usr/local/go" # Remove the default installation directory if it exists
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
    echo 'export PATH=$PATH:${HOME}/go/bin' >>~/.bashrc
  fi

  # Reload .bashrc to apply the changes immediately
  source ~/.bashrc

  # Verify the updated Go version
  go version
}

install_java() {
  # Set default version values if not provided
  version=${1:-21}      # Default version is 21
  file_version=${2:-35} # Default file_version is 35

  # Check if Java is installed
  if command -v java &>/dev/null; then
    # Get the installed Java version
    installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk '{print $1}' | sed 's/[^0-9.]*//g')

    # Compare installed version with the desired version
    if [ "$installed_version" = "$version" ]; then
      echo "Java version $version is already installed."
      return
    else
      echo "Removing Java version $installed_version..."
      sudo rm -rf "${HOME}/jdk-${installed_version}"                     # Remove the existing Java directory in home
      sudo rm -rf "/usr/lib/jvm/java-${installed_version}-openjdk-amd64" # Remove the installed Java directory (adjust as necessary)
      echo "Updating Java from version $installed_version to $version..."
    fi
  else
    echo "Installing Java version $version..."
  fi

  # Download and install the new version
  base_url="https://download.java.net/openjdk/jdk${version}/ri/"
  file_name="openjdk-${version}+${file_version}_linux-x64_bin.tar.gz"

  wget "${base_url}${file_name}"     # Download the OpenJDK binary
  tar -C ${HOME} -xzf "${file_name}" # Extract the tar.gz into the user's home directory

  # Set JAVA_HOME and update PATH in .bashrc
  echo "export JAVA_HOME=\${HOME}/jdk-${version}" >>~/.bashrc
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >>~/.bashrc

  # Reload .bashrc to apply the changes immediately
  source ~/.bashrc

  # Verify the Java installation
  java -version
}

install_docker_debian() {
  # Remove older versions of Docker and related packages if they exist
  echo "Removing older versions of Docker and related packages..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    if dpkg -l | grep -q $pkg; then
      sudo apt-get remove -y $pkg
      echo "$pkg removed."
    fi
  done

  # Update package list and install necessary packages
  echo "Updating package list and installing dependencies..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl

  # Add Docker's official GPG key
  echo "Adding Docker's official GPG key..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add Docker's repository to Apt sources
  echo "Adding Docker repository to sources list..."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  # Update the package list again with Docker repo
  sudo apt-get update

  # Install Docker components
  echo "Installing Docker..."
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Verify Docker installation
  echo "Verifying Docker installation by running hello-world container..."
  sudo docker run hello-world

  # Print success message
  echo "Docker has been installed successfully on your Debian system."
}

install_gradle() {
  # Set the version and direct download URL for Gradle
  version=${1:-8.10.2}
  gradle_url="https://services.gradle.org/distributions/gradle-${version}-all.zip"

  # Define the local installation directory for Gradle
  install_dir="$HOME/gradle/gradle-${version}"

  # Check if Gradle is already installed locally and verify version
  if [ -d "$install_dir" ]; then
    echo "Gradle version $version is already installed locally in $install_dir."
    return
  fi

  echo "Installing Gradle version $version locally..."

  # Download Gradle from the direct URL
  wget "$gradle_url" -O gradle-${version}-all.zip

  # Create the local Gradle directory and unzip the package there
  mkdir -p "$install_dir"
  unzip gradle-${version}-all.zip -d "$HOME/gradle"

  # Add Gradle to the PATH in .bashrc if it's not already there
  if ! grep -q 'export PATH=$PATH:$HOME/gradle/gradle-' ~/.bashrc; then
    echo "export PATH=\$PATH:\$HOME/gradle/gradle-${version}/bin" >>~/.bashrc
  fi

  # Reload .bashrc to apply the changes immediately
  source ~/.bashrc

  # Verify the installation
  gradle -v

  # Clean up the downloaded zip file
  rm gradle-${version}-all.zip

  echo "Gradle version $version installed successfully in $install_dir."
}

install_sdkman() {
  # Update package list and install necessary packages
  sudo apt install zip
  # Check if SDKMAN is installed by looking for the initialization script
  if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "SDKMAN is already installed."

    # Source SDKMAN if not already sourced
    if ! command -v sdk &>/dev/null; then
      echo "Sourcing SDKMAN..."
      source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi

    sdk version
    return
  fi

  # Install SDKMAN using curl
  echo "Installing SDKMAN..."
  if curl -s "https://get.sdkman.io" | bash; then
    echo "SDKMAN installed successfully."
  else
    echo "SDKMAN installation failed."
    return 1
  fi

  # Source SDKMAN into the current shell session
  source "$HOME/.sdkman/bin/sdkman-init.sh"

  # Check and print the SDKMAN version
  sdk version
}

install_sdks() {
  # Install Java (default version)
  echo "Installing Java..."
  sdk install java || {
    echo "Failed to install Java"
    return 1
  }
  echo "Java installed successfully."

  # Install Kotlin
  echo "Installing Kotlin..."
  sdk install kotlin || {
    echo "Failed to install Kotlin"
    return 1
  }
  echo "Kotlin installed successfully."

  # Install Gradle
  echo "Installing Gradle..."
  sdk install gradle || {
    echo "Failed to install Gradle"
    return 1
  }
  echo "Gradle installed successfully."

  # Check versions of all installed SDKs
  echo "Installed SDK versions:"
  sdk current java && sdk current kotlin && sdk current gradle
}

install_dropbox_headless() {
  echo "Installing Dropbox headless version..."

  # Check if Dropbox is already installed
  if [ -d "$HOME/.dropbox-dist" ]; then
    echo "Dropbox is already installed."
    return
  fi

  # Download and extract the Dropbox daemon
  cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -

  # Check if the installation succeeded
  if [ -d "$HOME/.dropbox-dist" ]; then
    echo "Dropbox installed successfully."
  else
    echo "Dropbox installation failed."
    return 1
  fi

  # Start the Dropbox daemon
  echo "Starting Dropbox daemon..."
  nohup ~/.dropbox-dist/dropboxd >/dev/null 2>&1 &

  echo "Dropbox daemon started. You might need to authorize this device."
  echo "Please copy and paste the link provided by the Dropbox daemon into a browser to complete the setup."
}

# Set Up CLI Script: To control Dropbox via the command line
control_dropbox() {
  echo "Setting up Dropbox CLI..."

  # Download the Dropbox Python control script
  wget -O dropbox.py https://www.dropbox.com/download?dl=packages/dropbox.py

  # Make it executable
  chmod +x dropbox.py

  # Move it to a directory in PATH (e.g., ~/bin)
  if [ ! -d "$HOME/bin" ]; then
    mkdir -p "$HOME/bin"
  fi
  mv dropbox.py "$HOME/bin/dropbox"

  # Check if the script is accessible
  if command -v dropbox &>/dev/null; then
    echo "Dropbox CLI script installed successfully. You can now use the 'dropbox' command."
  else
    echo "Failed to set up Dropbox CLI script. Ensure ~/bin is in your PATH."
  fi
}

install_mega_client() {
  echo "Installing MEGA cloud client..."

  # Define the URL and package name
  local url="https://mega.nz/linux/repo/Debian_12/amd64/megasync-Debian_12_amd64.deb"
  local package_name="megasync-Debian_12_amd64.deb"

  # Download the .deb package
  echo "Downloading MEGA cloud client..."
  if wget -q "$url" -O "$package_name"; then
    echo "Download successful: $package_name"
  else
    echo "Failed to download the MEGA client package."
    return 1
  fi

  # Install the package using apt
  echo "Installing the MEGA client package..."
  if sudo apt install "./$package_name" -y; then
    echo "MEGA cloud client installed successfully."
  else
    echo "Failed to install MEGA cloud client."
    rm -f "$package_name" # Clean up the downloaded file if installation fails
    return 1
  fi

  # Clean up the downloaded package
  rm -f "$package_name"
  echo "Installation complete. The package has been removed."
}

install_vscode() {
  echo "Installing Visual Studio Code..."

  # Define the URL and package name
  local url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  local package_name="vscode-linux-deb-x64.deb"

  # Download the .deb package
  echo "Downloading Visual Studio Code..."
  if wget -q "$url" -O "$package_name"; then
    echo "Download successful: $package_name"
  else
    echo "Failed to download Visual Studio Code package."
    return 1
  fi

  # Install the package using apt
  echo "Installing the Visual Studio Code package..."
  if sudo apt install "./$package_name" -y; then
    echo "Visual Studio Code installed successfully."
  else
    echo "Failed to install Visual Studio Code."
    rm -f "$package_name" # Clean up the downloaded file if installation fails
    return 1
  fi

  # Clean up the downloaded package
  rm -f "$package_name"
  echo "Installation complete. The package has been removed."
}

setup_vscode_xdg_open() {
  echo "Setting up Visual Studio Code as the default application for text files..."

  # Associate VS Code with common text and code files
  xdg-mime default code.desktop text/plain
  xdg-mime default code.desktop text/x-shellscript
  xdg-mime default code.desktop application/json
  xdg-mime default code.desktop text/x-python

  # Update MIME database
  update-desktop-database ~/.local/share/applications

  echo "Setup complete. Test using 'xdg-open example.txt'."
}

install_vscode_headless() {
  # Base URL for downloading VS Code tar.gz
  local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
  local temp_dir=$(mktemp -d)
  local install_dir="$HOME/.vscode"

  echo "Downloading the latest Visual Studio Code tar.gz..."
  wget -O "$temp_dir/vscode.tar.gz" "$vscode_url" || {
    echo "Download failed!"
    return 1
  }

  echo "Extracting Visual Studio Code..."
  mkdir -p "$install_dir"
  tar -xzf "$temp_dir/vscode.tar.gz" -C "$install_dir" --strip-components=1 || {
    echo "Extraction failed!"
    return 1
  }

  # Clean up the temporary directory
  rm -rf "$temp_dir"

  # Create a symlink for easy access
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  ln -sf "$install_dir/code" "$bin_dir/code"

  # Ensure $HOME/.local/bin is in PATH
  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
  fi

  # Set up file type associations using xdg-mime
  echo "Setting up Visual Studio Code as the default application for specific file types..."
  local vscode_desktop_file="$HOME/.local/share/applications/code.desktop"
  mkdir -p "$(dirname "$vscode_desktop_file")"

  cat >"$vscode_desktop_file" <<EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=$HOME/.local/bin/code %U
Icon=$install_dir/resources/app/resources/linux/code.png
Type=Application
Terminal=false
Categories=Development;IDE;TextEditor;

MimeType=text/plain;text/x-shellscript;application/json;text/x-python;
StartupNotify=true
EOF
  update-desktop-database ~/.local/share/applications

  echo "Visual Studio Code installed and configured successfully."
  echo "You can launch it using 'code' or test with 'xdg-open <file>'."
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
install_deno
install_vlc
install_brave
# install_dropbox
install_ffmpeg
install_sqlite
install_go
# install_java    # Installs OpenJDK 21+35 ## install_java 17 30  # Installs OpenJDK 17+30
# install_docker_debian
# install_gradle
install_sdkman
install_sdks
install_ohmybash
# install_dropbox_headless
# install_mega_client
# install_vscode_headless
upgrade
autoremove
