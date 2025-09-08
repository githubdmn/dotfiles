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

set -euo pipefail

log_info()  { echo -e "\n[INFO]  $1"; }
log_warn()  { echo -e "\n[WARN]  $1"; }
log_error() { echo -e "\n[ERROR] $1" >&2; }

install_discord() {
    local install_dir="$HOME/.local/opt/Discord"
    local app_dir="$HOME/.local/share/applications"
    local icon_dir="$HOME/.local/share/icons"
    local discord_url="https://discord.com/api/download?platform=linux&format=tar.gz"

    log_info "Installing Discord..."

    # Check dependencies
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed. Please install curl."
        return 1
    fi

    if ! command -v tar &> /dev/null; then
        log_error "tar is required but not installed. Please install tar."
        return 1
    fi

    # Create necessary directories
    mkdir -p "$install_dir" "$app_dir" "$icon_dir"

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'if [ -n "${temp_dir-}" ] && [ -d "$temp_dir" ]; then rm -rf "$temp_dir"; fi' EXIT

    # Download
    log_info "Downloading Discord package..."
    if ! curl -sSLf -o "$temp_dir/discord.tar.gz" "$discord_url"; then
        log_error "Failed to download Discord. Check your internet connection."
        return 1
    fi

    # Verify download
    if [ ! -s "$temp_dir/discord.tar.gz" ]; then
        log_error "Downloaded file is empty or corrupted."
        return 1
    fi

    # Extract
    log_info "Extracting package..."
    if ! tar -xzf "$temp_dir/discord.tar.gz" -C "$temp_dir"; then
        log_error "Failed to extract the archive. The file may be corrupted."
        return 1
    fi

    local extracted_dir="$temp_dir/Discord"
    if [ ! -d "$extracted_dir" ]; then
        log_error "Extracted 'Discord' directory not found."
        return 1
    fi

    # Check if extracted directory has content
    if [ -z "$(ls -A "$extracted_dir")" ]; then
        log_error "Extracted directory is empty."
        return 1
    fi

    # Stop any running Discord instances to prevent conflicts
    log_info "Checking for running Discord instances..."
    if pgrep -x "discord" > /dev/null; then
        log_info "Stopping running Discord instances..."
        pkill -x discord || log_warn "Could not stop Discord (process might have ended)"
        sleep 2
    fi

    # Install
    log_info "Installing to $install_dir..."
    rm -rf "$install_dir"
    mkdir -p "$install_dir"
    if ! mv "$extracted_dir"/* "$install_dir/"; then
        log_error "Failed to move files to installation directory."
        return 1
    fi

    # Set executable permissions
    if [ -f "$install_dir/Discord" ]; then
        chmod +x "$install_dir/Discord" || log_warn "Failed to set executable permissions"
    fi
    
     # Desktop integration (optional)
    if [ -f "$install_dir/discord.desktop" ]; then
        log_info "Updating desktop entry..."
        cp "$install_dir/discord.desktop" "$HOME/.local/share/applications/"
        update-desktop-database "$HOME/.local/share/applications/" || true
    fi
    
    # Copy icon to standard location for easier access
    if [ -f "$install_dir/discord.png" ]; then
        cp "$install_dir/discord.png" "$icon_dir/discord.png" 2>/dev/null || true
    fi

    log_info "Discord installed successfully!"
    log_info "Installation directory: $install_dir"
    log_info "You can launch Discord from your application menu or by running:"
    log_info "  $install_dir/Discord"
}

# --- Function to create desktop entry ---
create_postman_desktop_entry() {
    local install_dir="$1"
    local app_dir="$2"

    log_info "Creating Postman desktop entry..."

    cat > "$app_dir/postman.desktop" << EOF
[Desktop Entry]
Name=Postman
Exec=$install_dir/Postman
Icon=$install_dir/app/resources/app/assets/icon.png
Type=Application
Categories=Development;Network;
StartupWMClass=postman
Comment=API Development Environment
Keywords=api;rest;http;testing;development;
EOF

    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$app_dir" || log_warn "Failed to update desktop database"
    fi
}

# --- Function to install Postman ---
install_postman() {
    # --- Configuration ---
    POSTMAN_INSTALL_DIR="$HOME/.local/opt/Postman"
    POSTMAN_APP_DIR="$HOME/.local/share/applications"
    POSTMAN_ICON_DIR="$HOME/.local/share/icons"
    POSTMAN_URL="https://dl.pstmn.io/download/latest/linux_64"

    log_info "Installing Postman..."

    # Check dependencies
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed. Please install curl."
        return 1
    fi

    if ! command -v tar &> /dev/null; then
        log_error "tar is required but not installed. Please install tar."
        return 1
    fi

    # Create necessary directories
    mkdir -p "$POSTMAN_INSTALL_DIR" "$POSTMAN_APP_DIR" "$POSTMAN_ICON_DIR"

    # Create temp dir
    local temp_dir
    temp_dir=$(mktemp -d)

    # Download
    log_info "Downloading Postman package..."
    if ! curl -sSLf -o "$temp_dir/postman.tar.gz" "$POSTMAN_URL"; then
        rm -rf "$temp_dir"
        log_error "Failed to download Postman. Check your internet connection."
        return 1
    fi

    # Check file is not empty
    if [ ! -s "$temp_dir/postman.tar.gz" ]; then
        rm -rf "$temp_dir"
        log_error "Downloaded file is empty or corrupted."
        return 1
    fi

    # Extract
    log_info "Extracting package..."
    if ! tar -xzf "$temp_dir/postman.tar.gz" -C "$temp_dir"; then
        rm -rf "$temp_dir"
        log_error "Failed to extract the archive. The file may be corrupted."
        return 1
    fi

    local extracted_dir="$temp_dir/Postman"
    if [ ! -d "$extracted_dir" ]; then
        rm -rf "$temp_dir"
        log_error "Extracted directory 'Postman' not found."
        return 1
    fi

    # Check if extracted directory has content
    if [ -z "$(ls -A "$extracted_dir")" ]; then
        rm -rf "$temp_dir"
        log_error "Extracted directory is empty."
        return 1
    fi

    # Stop any running Postman instances to prevent conflicts
    log_info "Checking for running Postman instances..."
    if pgrep -f "postman" > /dev/null; then
        log_info "Stopping running Postman instances..."
        pkill -f postman || log_warn "Could not stop Postman (process might have ended)"
        sleep 2
    fi

    # Remove previous installation if it exists
    if [ -d "$POSTMAN_INSTALL_DIR" ]; then
        log_info "Removing previous installation..."
        rm -rf "$POSTMAN_INSTALL_DIR"
    fi

    # Create installation directory
    mkdir -p "$POSTMAN_INSTALL_DIR"

    # Install
    log_info "Installing to $POSTMAN_INSTALL_DIR..."
    if ! mv "$extracted_dir"/* "$POSTMAN_INSTALL_DIR/"; then
        rm -rf "$temp_dir"
        log_error "Failed to move files to installation directory."
        return 1
    fi

    # Set executable permissions
    if [ -f "$POSTMAN_INSTALL_DIR/Postman" ]; then
        chmod +x "$POSTMAN_INSTALL_DIR/Postman" || log_warn "Failed to set executable permissions"
    fi

    # Create desktop entry
    create_postman_desktop_entry "$POSTMAN_INSTALL_DIR" "$POSTMAN_APP_DIR"

    # Clean up temp directory
    log_info "Cleaning up temporary files..."
    rm -rf "$temp_dir"

    log_info "Postman installed successfully!"
    log_info "Installation directory: $POSTMAN_INSTALL_DIR"
    log_info "You can launch Postman from your application menu or by running:"
    log_info "  $POSTMAN_INSTALL_DIR/Postman"
}

# --- Common functions ---
add_to_path() {
    local bin_dir="$1"
    if ! echo "$PATH" | grep -q "$bin_dir"; then
        echo "export PATH=\"$bin_dir:\$PATH\"" >> "$HOME/.bashrc"
        export PATH="$bin_dir:$PATH"
        log_info "Added $bin_dir to PATH in .bashrc"
    fi
}

create_uninstaller() {
    local install_dir="$1"
    local bin_dir="$2"
    local bin_name="$3"
    local desktop_file="$4"

    cat > "$install_dir/uninstall.sh" <<EOF
#!/bin/bash
set -e

echo "Uninstalling..."
rm -f "$bin_dir/$bin_name"
rm -f "$desktop_file"
update-desktop-database ~/.local/share/applications 2>/dev/null || true
sed -i '/.local\/bin/d' ~/.bashrc
rm -rf "$install_dir"
echo "✅ Uninstallation complete"
EOF
    chmod +x "$install_dir/uninstall.sh"
}

# --- VS Code Installation ---
install_vscode_headless() {
    log_info "Installing Visual Studio Code..."

    # Configuration
    local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
    local temp_dir=$(mktemp -d)
    local install_dir="$HOME/.vscode"
    local bin_dir="$HOME/.local/bin"
    local desktop_file="$HOME/.local/share/applications/code.desktop"

     # Cleanup function - defined after temp_dir is assigned
        cleanup() {
            if [[ -n "${temp_dir:-}" && -d "$temp_dir" ]]; then
                rm -rf "$temp_dir"
            fi
             # Only clean install_dir if it exists and is empty (safe cleanup)
                    if [[ -n "${install_dir:-}" && -d "$install_dir" && -z "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
                        rmdir "$install_dir" 2>/dev/null || true
                    fi
        }
    trap cleanup EXIT

    # Check for existing installation
    if [[ -d "$install_dir" ]]; then
        log_warn "Existing VS Code installation found at $install_dir"
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
        rm -rf "$install_dir"
    fi

    # Download
    log_info "Downloading Visual Studio Code..."
    if ! curl -sSLf -o "$temp_dir/vscode.tar.gz" "$vscode_url"; then
        log_error "Download failed! Check network connection or URL"
        return 1
    fi

    # Verify download
    if [ ! -s "$temp_dir/vscode.tar.gz" ]; then
        log_error "Downloaded file is empty or corrupted"
        return 1
    fi

    # Extract
    log_info "Extracting Visual Studio Code..."
    mkdir -p "$install_dir"
    if ! tar -xzf "$temp_dir/vscode.tar.gz" -C "$install_dir" --strip-components=1; then
        log_error "Extraction failed! Corrupted download?"
        return 1
    fi

    # Create executable symlink
    mkdir -p "$bin_dir"
    ln -sf "$install_dir/bin/code" "$bin_dir/code"

    # Ensure PATH setup
    add_to_path "$bin_dir"

    # GUI integration only if in desktop environment
    if [ -n "$DISPLAY" ] && command -v xdg-mime &>/dev/null; then
        log_info "Setting up GUI integration..."
        mkdir -p "$(dirname "$desktop_file")"

        # Create desktop entry
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=$bin_dir/code --unity-launch %F
Icon=$install_dir/resources/app/resources/linux/code.png
Type=Application
Terminal=false
Categories=Development;IDE;TextEditor;
StartupNotify=true
StartupWMClass=Code
MimeType=text/plain;text/x-c;text/x-c++;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-makefile;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;application/x-designer;application/x-desktop;application/x-m4;application/x-perl;application/x-php;application/x-python;application/x-ruby;application/x-scheme;application/x-javascript;application/xml;text/x-mxml;text/x-sql;text/x-diff;text/x-patch;application/json;text/markdown;text/x-yaml;text/x-toml;
EOF

        # Set file associations
        xdg-mime default code.desktop text/plain application/json text/x-python text/markdown text/x-shellscript 2>/dev/null || true

        update-desktop-database ~/.local/share/applications
        log_info "GUI setup complete"
    else
        log_warn "Skipping GUI setup (no display detected)"
    fi

    # Create uninstaller
    create_uninstaller "$install_dir" "$bin_dir" "code" "$desktop_file"

    log_info "Visual Studio Code installed successfully!"
    log_info "Launch with: code"
    log_info "Uninstall with: $install_dir/uninstall.sh"
}

# --- VSCodium Installation ---
install_vscodium_headless() {
    log_info "Installing VSCodium..."

    # Configuration
    local version="1.100.33714"
    local vscodium_url="https://github.com/VSCodium/vscodium/releases/download/$version/VSCodium-linux-x64-$version.tar.gz"
    local temp_dir=$(mktemp -d)
    local install_dir="$HOME/.vscodium"
    local bin_dir="$HOME/.local/bin"
    local desktop_file="$HOME/.local/share/applications/vscodium.desktop"

     # Cleanup function - defined after temp_dir is assigned
        cleanup() {
            if [[ -n "${temp_dir:-}" && -d "$temp_dir" ]]; then
                rm -rf "$temp_dir"
            fi
             # Only clean install_dir if it exists and is empty (safe cleanup)
                    if [[ -n "${install_dir:-}" && -d "$install_dir" && -z "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
                        rmdir "$install_dir" 2>/dev/null || true
                    fi
        }
    trap cleanup EXIT

    # Check for existing installation
    if [[ -d "$install_dir" ]]; then
        log_warn "Existing VSCodium installation found at $install_dir"
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
        rm -rf "$install_dir"
    fi

    # Download
    log_info "Downloading VSCodium $version..."
    if ! curl -sSLf -o "$temp_dir/vscodium.tar.gz" "$vscodium_url"; then
        log_error "Download failed! Please check the URL and version."
        return 1
    fi

    # Verify download
    if [ ! -s "$temp_dir/vscodium.tar.gz" ]; then
        log_error "Downloaded file is empty or corrupted"
        return 1
    fi

    # Extract
    log_info "Extracting VSCodium..."
    mkdir -p "$install_dir"
    if ! tar -xzf "$temp_dir/vscodium.tar.gz" -C "$install_dir" --strip-components=1; then
        log_error "Extraction failed! Corrupted download?"
        return 1
    fi

    # Create executable symlink
    mkdir -p "$bin_dir"
    ln -sf "$install_dir/bin/codium" "$bin_dir/codium"

    # Ensure PATH setup
    add_to_path "$bin_dir"

    # GUI integration only if in desktop environment
    if [ -n "$DISPLAY" ] && command -v xdg-mime &>/dev/null; then
        log_info "Setting up GUI integration..."
        mkdir -p "$(dirname "$desktop_file")"

        # Create desktop entry
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=VSCodium
Comment=Code Editing. Redefined. (VSCodium)
Exec=$bin_dir/codium --unity-launch %F
Icon=$install_dir/resources/app/resources/linux/code.png
Type=Application
Terminal=false
Categories=Development;IDE;TextEditor;
StartupNotify=true
StartupWMClass=codium
MimeType=text/plain;text/x-c;text/x-c++;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-makefile;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;application/x-designer;application/x-desktop;application/x-m4;application/x-perl;application/x-php;application/x-python;application/x-ruby;application/x-scheme;application/x-javascript;application/xml;text/x-mxml;text/x-sql;text/x-diff;text/x-patch;application/json;text/markdown;text/x-yaml;text/x-toml;
EOF

        # Set file associations
        xdg-mime default vscodium.desktop text/plain application/json text/x-python text/markdown 2>/dev/null || true

        update-desktop-database ~/.local/share/applications
        log_info "GUI setup complete"
    else
        log_warn "Skipping GUI setup (no display detected)"
    fi

    # Create uninstaller
    create_uninstaller "$install_dir" "$bin_dir" "codium" "$desktop_file"

    log_info "VSCodium $version installed successfully!"
    log_info "Launch with: codium"
    log_info "Uninstall with: $install_dir/uninstall.sh"
}


upgrade
# install_build_essential
# install_unzip
# install_curl
# install_wget
# install_transport_https
# install_git
# install_ssh
# install_nano
# install_tmux
# install_vim
# install_neovim
# install_nvm
# install_deno
# install_vlc
# install_brave
# install_dropbox
# install_ffmpeg
# install_sqlite
# install_go
# install_java # Installs OpenJDK 21+35 ## install_java 17 30  # Installs OpenJDK 17+30
# install_docker_debian
# install_gradle
# install_sdkman
# install_sdks
# install_ohmybash
# install_dropbox_headless
# install_mega_client
# install_vscode_headless
# install_vscodium_headless
# install_discord
# install_postman
upgrade
autoremove
