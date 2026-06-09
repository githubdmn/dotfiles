#!/bin/bash

set -euo pipefail

log_info()  { echo -e "\n[INFO]  $1"; }
log_warn()  { echo -e "\n[WARN]  $1"; }
log_error() { echo -e "\n[ERROR] $1" >&2; }

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

install_unzip() {
  if ! command -v unzip &>/dev/null; then
    echo "Installing unzip..."
    sudo apt install unzip -y
  else
    echo "unzip is already installed."
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

install_wget() {
  echo "Checking if wget is installed..."

  # Check if wget is available
  if ! command -v wget &> /dev/null; then
    echo "wget is not installed. Installing wget..."
    sudo apt update && sudo apt install wget -y || {
      echo "Failed to install wget!"
      return 1
    }
    echo "wget successfully installed."
  else
    echo "wget is already installed."
  fi
}

install_transport_https() {
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
    ln -sv "${HOME}/dotfiles/config/rc/init.vim" "${conf}/nvim/init.vim"
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

install_fastfetch() {
    echo "Updating package lists..."
    sudo apt update

    # 1. Install software-properties-common if add-apt-repository is missing
    if ! command -v add-apt-repository &> /dev/null; then
        echo "Installing software-properties-common to enable PPAs..."
        sudo apt install -y software-properties-common
    fi

    # 2. Add the Fastfetch PPA
    echo "Adding Fastfetch PPA..."
    sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch

    # 3. Update and Install
    sudo apt update
    sudo apt install -y fastfetch

    echo "Installation complete! Running fastfetch..."
    fastfetch
}

install_bundle() {
   sudo apt install -y \
  build-essential \
  wget \
  curl \
  unzip \
  7zip \
  wl-clipboard \
  apt-transport-https \
  git \
  ssh \
  nano \
  tmux \
  vim \
  neovim \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  llvm \
  libncurses5-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  liblzma-dev \
  libfuse2 \
  jq \
  ripgrep \
  fd-find \
  htop \
  tree \
  bat \
  fzf \
  mc \
  nnn \
  rsync \
  fastfetch
}

###
install_media_cli() {
  echo "--- Installing Media CLI tools ---"
  # in bundle 7zip jq fd-find ripgrep fzf curl
  echo "---  in bundle 7zip jq fd-find ripgrep fzf curl ---"
  sudo apt install -y ffmpeg poppler-utils imagemagick zoxide

  # Initialize zoxide for the current session
  eval "$(zoxide init bash)"
}

install_yazi() {

    echo "--- Downloading and installing Yazi (Pre-compiled Binary) ---"
    # Detect architecture (usually x86_64)
    ARCH=$(uname -m)

    # Fetch the latest release URL from GitHub API
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
        | grep "browser_download_url.*yazi-$ARCH-unknown-linux-gnu.zip" \
        | cut -d '"' -f 4)

    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Error: Could not find a matching Yazi release for $ARCH."
        return 1
    fi

    # Download and extract
    curl -L "$DOWNLOAD_URL" -o /tmp/yazi.zip
    unzip -q /tmp/yazi.zip -d /tmp/yazi_extracted

    # Move binaries to local bin
    sudo mv /tmp/yazi_extracted/yazi-*/yazi /usr/local/bin/
    sudo mv /tmp/yazi_extracted/yazi-*/ya /usr/local/bin/

    # Clean up
    rm -rf /tmp/yazi.zip /tmp/yazi_extracted

    echo "--- Yazi installation complete! Try running 'yazi' ---"
}

install_zed() {
    echo "Checking dependencies for Zed..."
        # Ensure curl is installed first
        if ! command -v curl &> /dev/null; then
            echo "curl is missing. Installing..."
            sudo apt update && sudo apt install -y curl
        fi

        echo "Installing Zed Editor..."
        ### curl -f https://zed.dev/install.sh | sh
        # Using -f (fail) and -s (silent) but showing errors if they happen
        if curl -fsSL https://zed.dev/install.sh | sh; then
            echo "Zed installed successfully."
            echo "Note: You may need to restart your terminal or add ~/.local/bin to your PATH."
        else
            echo "Zed installation failed."
            return 1
        fi
}

install_nvm() {
  version=${1:-0.40.1} # Default nvm version is set to 0.40.1
  NVM_DIR="$HOME/.nvm"

  # Check if nvm is installed by looking for the initialization script
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm is already installed."
  else
  	mkdir ${NVM_DIR}
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

    sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    update
    sudo apt install -y brave-browser
  else
    echo "Brave browser is already installed."
  fi
}

install_brave_one_command() {
  curl -fsS https://dl.brave.com/install.sh | sh
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


install_python() {
  PYTHON_VERSION="3.12.1"
  echo "--- Running pyenv installer script ---"
  curl https://pyenv.run | bash

  ### bashrc ####
    # export PYENV_ROOT="$HOME/.pyenv"
    # export PATH="$PYENV_ROOT/bin:$PATH"
    # eval "$(pyenv init --path)
  ##############

  # pyenv install --list
  # pyenv install 3.11.2
  # Set the New Version as Your Default
  # pyenv global 3.11.2


   echo "--- Adding pyenv configuration to ~/.bashrc ---"
    # Append the necessary environment variables to the user's bash profile
    cat <<EOF >> ~/.bashrc
      # --- Added by install_python_env.sh script ---
      export PYENV_ROOT="\$HOME/.pyenv"
      export PATH="\$PYENV_ROOT/bin:\$PATH"
      eval "\$(pyenv init --path)"
      # ---------------------------------------------
EOF
    echo "Configuration added to ~/.bashrc"

    # The current shell needs to be reloaded to recognize 'pyenv' commands immediately
    echo "--- Reloading shell configuration (source ~/.bashrc) ---"
    # Use 'source' to apply changes to the current script's environment
    source ~/.bashrc

    # Verify pyenv installation
    if command -v pyenv > /dev/null; then
        echo "pyenv installed successfully. Version: $(pyenv --version)"
    else
        echo "Error: pyenv command not found after install. Please check ~/.bashrc manually."
        exit 1
    fi

    echo "--- Installing Python $PYTHON_VERSION via pyenv ---"
    # This step will download and compile Python locally. It may take some time.
    # Note: This might still throw a tkinter warning if system libs are missing, but it installs Python core.
    pyenv install $PYTHON_VERSION

    if [ $? -eq 0 ]; then
        echo "Python $PYTHON_VERSION installed successfully."
        echo "--- Setting Python $PYTHON_VERSION as global default ---"
        pyenv global $PYTHON_VERSION
        echo "Default Python version set to $PYTHON_VERSION."
    else
        echo "Error installing Python $PYTHON_VERSION. Compilation failed."
        exit 1
    fi

    echo "--- Installation Complete ---"
    echo "Please close and reopen your terminal session for changes to take full effect."
    echo "You can verify the installation with: which python"
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

install_docker_debian_old() {
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
  sudo usermod -aG docker $USER

  # Print success message
  echo "Docker has been installed successfully on your Debian system."
}

install_docker_debian() {
  echo "[INFO] Installing Docker..."

  # Remove old versions
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
  done

  # Install dependencies
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg

  # Add Docker GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # Add repository
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update

  # Install Docker
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Enable Docker service
  sudo systemctl enable docker
  sudo systemctl start docker

  # Add current user to docker group
  sudo usermod -aG docker "$USER"

  echo "[INFO] Docker installed successfully."

  echo "[INFO] To use docker without sudo run:"
  echo "       newgrp docker"
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

	# Install Kotlin && sdk current kotlin
	#  echo "Installing Kotlin..."
	#  sdk install kotlin || {
	#  echo "Failed to install Kotlin"
	#    return 1
	#  }
	# echo "Kotlin installed successfully."

  # Install Gradle
  echo "Installing Gradle..."
  sdk install gradle || {
    echo "Failed to install Gradle"
    return 1
  }
  echo "Gradle installed successfully."

  # Check versions of all installed SDKs
  echo "Installed SDK versions:"
  sdk current java && sdk current gradle
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

generate_rsa_key() {
  # Set default values for key options
  local key_dir="$HOME/.ssh"
  local key_name="id_rsa"
  local key_bits=4096
  local key_comment="Generated by $(whoami)@$(hostname)"

  # Prompt the user for input
  echo "RSA Key Generation"
  read -p "Enter directory to save the key (default: $key_dir): " user_dir
  read -p "Enter key name (default: $key_name): " user_name
  read -p "Enter key size (default: $key_bits): " user_bits
  read -p "Enter a comment for the key (default: '$key_comment'): " user_comment

  # Override defaults with user input if provided
  key_dir=${user_dir:-$key_dir}
  key_name=${user_name:-$key_name}
  key_bits=${user_bits:-$key_bits}
  key_comment=${user_comment:-$key_comment}

  # Full key path
  local key_path="$key_dir/$key_name"

  # Ensure the directory exists
  if [ ! -d "$key_dir" ]; then
    echo "Creating directory $key_dir..."
    mkdir -p "$key_dir"
    chmod 700 "$key_dir"
  fi

  # Check if a key already exists
  if [ -f "$key_path" ]; then
    echo "A key already exists at $key_path."
    read -p "Do you want to overwrite it? (y/n): " overwrite
    if [[ "$overwrite" != "y" ]]; then
      echo "Aborting key generation."
      return 1
    fi
  fi

  # Generate the RSA key
  echo "Generating RSA key..."
  ssh-keygen -t rsa -b "$key_bits" -C "$key_comment" -f "$key_path" -q -N ""

  if [ $? -eq 0 ]; then
    echo "RSA key pair generated successfully!"
    echo "Private key: $key_path"
    echo "Public key: ${key_path}.pub"
  else
    echo "Failed to generate RSA key."
    return 1
  fi
}



install_bruno() {
    set -e  # Exit on any error

    echo "Installing Bruno..."

    # Update package list
    if ! sudo apt update; then
        echo "Error: Failed to update package lists" >&2
        return 1
    fi

    # Install dependencies
    if ! sudo apt install -y gpg curl; then
        echo "Error: Failed to install dependencies" >&2
        return 1
    fi

    # Create keyrings directory if it doesn't exist
    sudo mkdir -p /etc/apt/keyrings

    # Download and add GPG key
    if ! curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9FA6017ECABE0266" \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/bruno.gpg > /dev/null; then
        echo "Error: Failed to download and add GPG key" >&2
        return 1
    fi

    # Set appropriate permissions
    sudo chmod 644 /etc/apt/keyrings/bruno.gpg

    # Add Bruno repository
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable" \
        | sudo tee /etc/apt/sources.list.d/bruno.list

    # Update package list with new repository
    if ! sudo apt update; then
        echo "Error: Failed to update package lists after adding Bruno repository" >&2
        return 1
    fi

    # Install Bruno
    if sudo apt install -y bruno; then
        echo "✅ Bruno installed successfully!"
    else
        echo "Error: Failed to install Bruno" >&2
        return 1
    fi
}


# ==========================
# VSCodium
# ==========================

# Robust VSCodium installer with comprehensive error handling
install_vscodium() {
    set -euo pipefail  # Exit on error, undefined variable, or pipe failure
    #set +u
    local version="${1:-1.105.17075}"  # Allow version override, default to 1.105.17075
    local install_dir="$HOME/.local/opt/VSCodium"
    local codium_url="https://github.com/VSCodium/vscodium/releases/download/${version}/VSCodium-linux-x64-${version}.tar.gz"
    local temp_dir=""
    #set -u  # Re-enable unbound variable check

 		# Create temp directory
    temp_dir=$(mktemp -d)

    # Use a separate variable for cleanup to avoid unbound variable issues
    local cleanup_dir="$temp_dir"

    # Cleanup function
    cleanup() {
        if [[ -n "$cleanup_dir" ]] && [[ -d "$cleanup_dir" ]]; then
            echo "[INFO] Cleaning up temporary files..."
            rm -rf "$cleanup_dir"
        fi
    }

    trap cleanup EXIT INT TERM

    echo "[INFO] Starting VSCodium installation/update..."
    echo "[INFO] Version: $version"

    # Download
    echo "[INFO] Downloading VSCodium..."
    if ! wget -q --show-progress -O "$temp_dir/vscodium.tar.gz" "$codium_url"; then
        echo "[ERROR] Failed to download VSCodium."
        echo "[ERROR] URL: $codium_url"
        return 1
    fi

    # Verify download
    if [[ ! -s "$temp_dir/vscodium.tar.gz" ]]; then
        echo "[ERROR] Downloaded file is empty"
        return 1
    fi

    # Extract with --strip-components to remove top-level directory
    echo "[INFO] Extracting archive..."
    if ! tar -xzf "$temp_dir/vscodium.tar.gz" -C "$temp_dir" --strip-components=1; then
        echo "[ERROR] Failed to extract VSCodium archive."
        return 1
    fi

    # Verify extraction - VSCodium binary should be at bin/codium
    if [[ ! -f "$temp_dir/bin/codium" ]] && [[ ! -f "$temp_dir/codium" ]]; then
        echo "[ERROR] VSCodium binary not found after extraction"
        echo "[ERROR] Contents of extracted directory:"
        ls -la "$temp_dir" | head -20
        return 1
    fi

    # Stop running instances
    echo "[INFO] Stopping running VSCodium instances..."
    pkill -x codium 2>/dev/null || true
    sleep 1

    # Install
    echo "[INFO] Installing VSCodium..."
    rm -rf "$install_dir"
    mkdir -p "$install_dir"
    cp -r "$temp_dir"/* "$install_dir/"

    # Create symlink
    mkdir -p "$HOME/.local/bin"
    if [[ -f "$install_dir/bin/codium" ]]; then
        ln -sf "$install_dir/bin/codium" "$HOME/.local/bin/codium"
    else
        ln -sf "$install_dir/codium" "$HOME/.local/bin/codium"
    fi
    chmod +x "$HOME/.local/bin/codium"

    # Desktop integration
    echo "[INFO] Creating desktop entry..."
    mkdir -p "$HOME/.local/share/applications"

    # VSCodium uses the same icon as VS Code
    local icon_path="$install_dir/resources/app/resources/linux/code.png"
    if [[ ! -f "$icon_path" ]]; then
        icon_path="vscodium"  # Fallback to system icon
    fi

    cat > "$HOME/.local/share/applications/vscodium.desktop" <<EOF
[Desktop Entry]
Name=VSCodium
Comment=Code Editing. Redefined. (Open Source)
Exec=$HOME/.local/bin/codium %F
Icon=$icon_path
Type=Application
Terminal=false
Categories=Development;IDE;TextEditor;
StartupNotify=true
StartupWMClass=VSCodium
MimeType=text/plain;application/json;text/x-python;text/markdown;text/x-markdown;application/x-shellscript;application/javascript;text/x-yaml;application/x-yaml;text/x-typescript;text/x-rust;text/x-go;text/css;text/html;
EOF

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    echo "[SUCCESS] VSCodium installed successfully!"
    echo "          Version: $version"
    echo "          Installation directory: $install_dir"
    echo "          Launch with: codium"

    # Verify installation
    if command -v codium >/dev/null 2>&1; then
        echo "          ✓ 'codium' command is available"
    else
        echo "          ⚠ Add ~/.local/bin to your PATH if not already done"
        echo "          export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# Auto-fetch latest version installer
install_vscodium_latest() {
    set -euo pipefail

    local temp_dir=""

    # Cleanup function
    cleanup() {
        if [[ -n "$temp_dir" ]] && [[ -d "$temp_dir" ]]; then
            rm -rf "$temp_dir"
        fi
    }
    trap cleanup EXIT INT TERM

    echo "[INFO] Fetching latest VSCodium version..."

    # Get latest version from GitHub API
    local latest_version
    if command -v jq >/dev/null 2>&1; then
        latest_version=$(curl -fsSL https://api.github.com/repos/VSCodium/vscodium/releases/latest | jq -r '.tag_name')
    else
        latest_version=$(curl -fsSL https://api.github.com/repos/VSCodium/vscodium/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    fi

    if [[ -z "$latest_version" ]]; then
        echo "[ERROR] Could not determine latest version"
        echo "[INFO] Falling back to version 1.105.17075"
        latest_version="1.105.17075"
    else
        echo "[INFO] Latest version: $latest_version"
    fi

    # Call the main installer with the detected version
    install_vscodium "$latest_version"
}

install_dev_basic() {
	install_nvm
	install_go
	install_python
	install_sdkman
	install_docker_debian
	install_sqlite
	install_dropbox_headless
	install_mega_client
	install_bruno
	install_zed
}

install_dev_additional() {
	install_deno
	install_dropbox
	# install_java # Installs OpenJDK 21+35 ## install_java 17 30  # Installs OpenJDK 17+30
	# install_gradle
	# install_sdkman
	# install_sdks
	install_vscodium_latest
}


### MAIN EXECUTION

upgrade

install_bundle
install_fastfetch
# install_vlc
# install_brave_one_command
# install_ffmpeg
# install_ohmybash
# install_dev_basic
# install_dev_additional

upgrade
autoremove
