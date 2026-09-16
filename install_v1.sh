#!/usr/bin/env bash
set -euo pipefail
 
# ─── Configuration ───────────────────────────────────────────────────────────
 
LOG_FILE="/tmp/custom-install.log"
 
# ── Group A: Core packages (from install.sh install_bundle()) ────────────────
PACKAGES_CORE=(
    # Build tools
    build-essential
    # Archives & compression
    7zip unzip zip
    # Clipboard
    wl-clipboard
    # APT helpers
    apt-transport-https
    # Version control & network
    git curl wget rsync
    # SSH
    openssh-client
    # Editors
    nano vim neovim
    # Development libraries
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev
    llvm libncurses-dev libfuse2t64 xz-utils tk-dev
    libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    # Productivity & CLI tools
    jq ripgrep fd-find htop tree bat fzf mc nnn
    # System info
    inxi lshw hardinfo usbutils fastfetch
    # Terminal multiplexer
    tmux
    # sqlite
    sqlite3
)
 
# ── Group B: Media & utilities ───────────────────────────────────────────────
PACKAGES_MEDIA=(
    ffmpeg poppler-utils imagemagick zoxide
)
 
# ── Group C: Entertainment ───────────────────────────────────────────────────
PACKAGES_ENTERTAINMENT=(
    hardinfo vlc
)
 
# ── Group D: Browser (external repo) ─────────────────────────────────────────
PACKAGES_BRAVE=(
    brave-browser
)
 
# ── Group E: Cloud storage ───────────────────────────────────────────────────
# Dropbox and MEGA are installed via .deb downloads, not apt repos
 
# ── Group F: Containers ──────────────────────────────────────────────────────
PACKAGES_PODMAN=(
    podman podman-compose
)
 
# ── Group G: Runtimes (local user installs) ──────────────────────────────────
# Go, nvm, pyenv, deno, SDKMAN — all installed locally in $HOME
 
# ─── Logging ─────────────────────────────────────────────────────────────────
 
log() {
    local msg="$1"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}
 
# ─── Functions ───────────────────────────────────────────────────────────────
 
# Refresh the package index (run ONCE before any apt operation)
update() {
    log "Updating package index..."
    sudo apt update | tee -a "$LOG_FILE"
}
 
# Install a list of packages from an array
install_packages() {
    local -n pkg_list=$1
    if [[ ${#pkg_list[@]} -eq 0 ]]; then
        log "No packages to install. Skipping."
        return 0
    fi
 
    log "Installing ${#pkg_list[@]} packages..."
    sudo apt install -y "${pkg_list[@]}" | tee -a "$LOG_FILE"
}
 
# ── Task functions ────────────────────────────────────────────────────────────
 
task_core() {
    log "=== Task: Core packages ==="
    install_packages PACKAGES_CORE
}
 
task_media() {
    log "=== Task: Media & utilities ==="
    install_packages PACKAGES_MEDIA
}
 
task_entertainment() {
    log "=== Task: Entertainment ==="
    install_packages PACKAGES_ENTERTAINMENT
}
 
# ── Brave Browser (external APT repo) ────────────────────────────────────────
 
install_brave_repo() {
    log "=== Task: Brave Browser ==="
 
    if command -v brave-browser &>/dev/null; then
        log "Brave browser is already installed."
        return 0
    fi
 
    log "Adding Brave browser repository..."
 
    # Install GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
        -o /etc/apt/keyrings/brave-browser-archive-keyring.gpg
 
    # Add repository
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] \
        https://brave-browser-apt-release.s3.brave.com/ stable main" \
        | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
 
    # Refresh package index for the new repo
    sudo apt update
}
 
task_brave() {
    install_brave_repo
    install_packages PACKAGES_BRAVE
}
 
# ── Neovim setup (dotfiles + vim-plug) ───────────────────────────────────────
 
task_neovim() {
    log "=== Task: Neovim configuration ==="
 
    local conf="${HOME}/.config"
    local nvim_conf="${conf}/nvim"
    local plug_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
 
    # Create Neovim config directory
    mkdir -p "${nvim_conf}"
 
    # Link init.vim from dotfiles
    if [ ! -L "${nvim_conf}/init.vim" ]; then
        if [ -f "${HOME}/dotfiles/config/rc/init.vim" ]; then
            ln -sv "${HOME}/dotfiles/config/rc/init.vim" "${nvim_conf}/init.vim"
            log "Configured Neovim with init.vim from dotfiles."
        else
            log "Warning: ${HOME}/dotfiles/config/rc/init.vim not found. Skipping symlink."
        fi
    else
        log "Neovim init.vim already linked."
    fi
 
    # Install vim-plug if not present
    if [ ! -f "${plug_path}" ]; then
        mkdir -p "$(dirname "${plug_path}")"
        curl -fLo "${plug_path}" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        log "Installed vim-plug for Neovim."
    else
        log "vim-plug already installed."
    fi
}
 
# ── Cloud storage ─────────────────────────────────────────────────────────────
 
task_dropbox_headless() {
    log "=== Task: Dropbox (headless) ==="
 
    if [ -d "$HOME/.dropbox-dist" ]; then
        log "Dropbox is already installed."
        return 0
    fi
 
    log "Installing Dropbox headless daemon..."
    cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
 
    if [ -d "$HOME/.dropbox-dist" ]; then
        log "Dropbox installed. Starting daemon..."
        nohup ~/.dropbox-dist/dropboxd >/dev/null 2>&1 &
        log "Dropbox daemon started. Authorize this device via the link it provides."
    else
        log "Dropbox installation failed."
        return 1
    fi
}
 
task_dropbox_cli() {
    log "=== Task: Dropbox CLI ==="
 
    if command -v dropbox &>/dev/null; then
        log "Dropbox CLI is already installed."
        return 0
    fi
 
    log "Setting up Dropbox CLI..."
    mkdir -p "$HOME/bin"
 
    if wget -q -O dropbox.py https://www.dropbox.com/download?dl=packages/dropbox.py; then
        chmod +x dropbox.py
        mv dropbox.py "$HOME/bin/dropbox"
        rm -f dropbox.py
        log "Dropbox CLI installed at ~/bin/dropbox"
    else
        log "Failed to download Dropbox CLI."
        return 1
    fi
}
 
task_mega() {
    log "=== Task: MEGA client ==="
 
    local url="https://mega.nz/linux/repo/Debian_12/amd64/megasync-Debian_12_amd64.deb"
    local package_name="megasync-Debian_12_amd64.deb"
 
    if command -v megasync &>/dev/null; then
        log "MEGA client is already installed."
        return 0
    fi
 
    log "Downloading MEGA client..."
    if wget -q "$url" -O "$package_name"; then
        log "Installing MEGA client..."
        if sudo apt install "./$package_name" -y; then
            log "MEGA client installed successfully."
        else
            log "MEGA client installation failed."
            rm -f "$package_name"
            return 1
        fi
        rm -f "$package_name"
    else
        log "Failed to download MEGA client package."
        return 1
    fi
}
 
# ── Containers ────────────────────────────────────────────────────────────────
 
task_docker() {
    log "=== Task: Docker ==="
 
    if command -v docker &>/dev/null && dpkg -l docker-ce &>/dev/null; then
        log "Docker already installed."
        return 0
    fi
 
    # Remove only conflicting packages that are actually present
    local pkg
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            log "Removing conflicting package: $pkg"
            sudo apt-get remove -y "$pkg"
        fi
    done
 
    # Install dependencies
    log "Installing Docker dependencies..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
 
    # Add Docker GPG key (skip if already present)
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        log "Adding Docker GPG key..."
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    else
        log "Docker GPG key already present."
    fi
 
    # Add repository
    local arch codename
    arch=$(dpkg --print-architecture)
    codename=$(. /etc/os-release && echo "${VERSION_CODENAME}")
    log "Adding Docker repository (arch=$arch, codename=$codename)..."
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian %s stable\n' \
        "$arch" "$codename" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
 
    sudo apt-get update
 
    # Install Docker
    log "Installing Docker..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
 
    # Enable and start service
    sudo systemctl enable --now docker
 
    # Add user to docker group
    sudo usermod -aG docker "$USER"
 
    log "Docker installed successfully."
    log "Run 'newgrp docker' or log out/in to use docker without sudo."
}
 
task_podman() {
    log "=== Task: Podman ==="
 
    if command -v podman &>/dev/null; then
        log "Podman is already installed."
        return 0
    fi
 
    log "Installing Podman..."
    sudo apt-get update
    sudo apt-get install -y podman podman-compose
 
    if command -v podman &>/dev/null; then
        log "Podman installed successfully. Version: $(podman --version)"
    else
        log "Podman installation failed."
        return 1
    fi
}
 
# ── Runtimes (local user installs) ────────────────────────────────────────────
 
task_go_local() {
    log "=== Task: Go runtime ==="
 
    local version="${1:-1.23.1}"
    local base_url="https://go.dev/dl/"
    local file_name="go${version}.linux-amd64.tar.gz"
    local install_dir="$HOME/go"
 
    # Check if correct version is already installed
    if command -v go &>/dev/null; then
        local installed_version
        installed_version=$(go version | sed 's/go//')
        if [[ "$installed_version" == "$version" ]]; then
            log "Go version $version is already installed."
            go version
            return 0
        fi
        log "Go $installed_version found, replacing with $version..."
        rm -rf "$install_dir" "/usr/local/go"
    fi
 
    log "Downloading Go $version..."
    if ! wget -q "${base_url}${file_name}"; then
        log "Failed to download Go $version."
        return 1
    fi
 
    log "Extracting Go $version..."
    tar -C "$HOME" -xzf "$file_name"
    rm -f "$file_name"
 
    # Add to PATH in .bashrc if not already present
    if ! grep -q "export PATH=\$PATH:\$HOME/go/bin" "$HOME/.bashrc" 2>/dev/null; then
        echo "export PATH=$PATH:$HOME/go/bin" >> "$HOME/.bashrc"
        log "Added Go to PATH in .bashrc."
    fi
 
    export PATH="$PATH:$HOME/go/bin"
    log "Go $version installed successfully."
    go version
}

task_go() {
  log "=== Task: Go runtime ==="

  local want="${1:-1.25.1}"
  local install_dir="/usr/local/go"

  if have go; then
    local current; current=$(go version | awk '{print $3}' | sed 's/^go//')
    if version_ge "$current" "$want"; then
      log_ok "Go ${current} already installed (>= ${want}). Nothing to do."
      return 0
    fi
    log_info "Upgrading Go ${current} -> ${want}"
  else
    log_info "Installing Go ${want}..."
  fi

  local tarball="go${want}.linux-amd64.tar.gz"
  local tmp; tmp=$(make_tmpdir)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN

  run curl -fSL "https://go.dev/dl/${tarball}" -o "${tmp}/${tarball}"

  # Only remove the toolchain directory. NEVER touch $HOME/go — that is your
  # GOPATH (module cache, installed binaries, sources).
  log_info "Replacing ${install_dir} (your \$HOME/go GOPATH is left alone)..."
  run sudo rm -rf "$install_dir"
  run sudo tar -C /usr/local -xzf "${tmp}/${tarball}"

  bashrc_block "golang" \
'export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"'

  run /usr/local/go/bin/go version
  log_ok "Go ${want} installed."
}
 
task_nvm() {
    log "=== Task: nvm (Node Version Manager) ==="
 
    local version="${1:-0.40.1}"
    local NVM_DIR="$HOME/.nvm"
 
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        log "nvm is already installed."
        return 0
    fi
 
    log "Installing nvm v${version}..."
    mkdir -p "$NVM_DIR"
    wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/v${version}/install.sh" | bash
 
    # Source nvm
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
        log "nvm installed successfully. Version: $(nvm --version)"
    else
        log "nvm installation failed."
        return 1
    fi
}
 
task_pyenv() {
    log "=== Task: pyenv (Python version manager) ==="
 
    local python_version="3.12.1"
 
    # Check if pyenv is already installed
    if command -v pyenv &>/dev/null; then
        log "pyenv is already installed. Version: $(pyenv --version)"
    else
        log "Installing pyenv..."
        curl https://pyenv.run | bash
 
        # Add pyenv config to .bashrc if not already present
        if ! grep -q 'export PYENV_ROOT' "$HOME/.bashrc" 2>/dev/null; then
            cat <<'BASHRC' >> "$HOME/.bashrc"
 
# --- pyenv ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
BASHRC
            log "Added pyenv configuration to .bashrc."
        fi
 
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
    fi
 
    # Install Python version
    log "Installing Python $python_version via pyenv..."
    if ! pyenv install "$python_version" 2>&1; then
        log "Python $python_version installation failed."
        return 1
    fi
 
    pyenv global "$python_version"
    log "Python $python_version set as global default."
}
 
task_deno() {
    log "=== Task: Deno runtime ==="
 
    if command -v deno &>/dev/null; then
        log "Deno is already installed. Version: $(deno --version)"
        return 0
    fi
 
    log "Installing Deno..."
    if curl -fsSL https://deno.land/install.sh | sh; then
        log "Deno installed successfully."
 
        # Add to PATH if not already there
        if ! grep -q 'DENO_INSTALL' "$HOME/.bashrc" 2>/dev/null; then
            echo 'export DENO_INSTALL="$HOME/.deno"' >> "$HOME/.bashrc"
            echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> "$HOME/.bashrc"
            log "Added Deno to PATH in .bashrc."
        fi
 
        export DENO_INSTALL="$HOME/.deno"
        export PATH="$DENO_INSTALL/bin:$PATH"
        deno --version
    else
        log "Deno installation failed."
        return 1
    fi
}
 
task_bun() {
    log "=== Task: Bun runtime ==="
 
    if command -v bun &>/dev/null; then
        log "Bun is already installed. Version: $(bun --version)"
        return 0
    fi
 
    log "Installing Bun..."
    if curl -fsSL https://bun.sh/install | bash; then
        log "Bun installed successfully."
        bun --version
    else
        log "Bun installation failed."
        return 1
    fi
}
 
task_sdkman() {
    log "=== Task: SDKMAN ==="
 
    if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        log "SDKMAN is already installed."
        if command -v sdk &>/dev/null; then
            sdk version
        else
            source "$HOME/.sdkman/bin/sdkman-init.sh"
            sdk version
        fi
        return 0
    fi
 
    log "Installing SDKMAN..."
    if curl -s "https://get.sdkman.io" | bash; then
        log "SDKMAN installed."
    else
        log "SDKMAN installation failed."
        return 1
    fi
 
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk version
}
 
task_sdkman_java_gradle() {
    log "=== Task: SDKMAN Java + Gradle ==="
 
    # Source SDKMAN if not already loaded
    if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
 
    # Install Java
    log "Installing Java via SDKMAN..."
    if ! sdk install java; then
        log "Java installation via SDKMAN failed."
        return 1
    fi
    log "Java installed successfully."
 
    # Install Gradle
    log "Installing Gradle via SDKMAN..."
    if ! sdk install gradle; then
        log "Gradle installation via SDKMAN failed."
        return 1
    fi
    log "Gradle installed successfully."
 
    sdk current java && sdk current gradle
}
 
autoremove() {
    log "Removing unnecessary packages..."
    sudo apt autoremove -y | tee -a "$LOG_FILE"
}
 
# ─── Main ────────────────────────────────────────────────────────────────────
 
main() {
    log "Starting system package installation..."
 
    local status=0
 
    # 1. Update package index (once, shared by all apt operations)
    update
 
    # 2. Install core packages
    if ! task_core; then
        log "Core package installation failed!"
        status=1
    fi
 
    # 3. Install media & utilities
    if ! task_media; then
        log "Media package installation failed!"
        status=1
    fi
 
    # 4. Install entertainment
    if ! task_entertainment; then
        log "Entertainment package installation failed!"
        status=1
    fi
 
    # 5. Install Brave browser
    if ! task_brave; then
        log "Brave browser installation failed!"
        status=1
    fi
 
    # 6. Configure Neovim
    if ! task_neovim; then
        log "Neovim configuration failed!"
        status=1
    fi
 
    # 7. Cloud storage
    if ! task_dropbox_headless; then
        log "Dropbox (headless) installation failed!"
        status=1
    fi
 
    if ! task_dropbox_cli; then
        log "Dropbox CLI installation failed!"
        status=1
    fi
 
    if ! task_mega; then
        log "MEGA client installation failed!"
        status=1
    fi
 
    # 8. Clean up
    if ! autoremove; then
        log "Autoremove failed!"
        status=1
    fi
 
    # 9. Containers
    if ! task_docker; then
        log "Docker installation failed!"
        status=1
    fi
 
    if ! task_podman; then
        log "Podman installation failed!"
        status=1
    fi
 
    # 10. Runtimes
    if ! task_go; then
        log "Go runtime installation failed!"
        status=1
    fi
 
    if ! task_nvm; then
        log "nvm installation failed!"
        status=1
    fi
 
    if ! task_pyenv; then
        log "pyenv installation failed!"
        status=1
    fi
 
#    if ! task_deno; then
#        log "Deno installation failed!"
#        status=1
#    fi
 
#    if ! task_bun; then
#        log "Bun installation failed!"
#        status=1
#    fi
 
    if ! task_sdkman; then
        log "SDKMAN installation failed!"
        status=1
    fi
 
#    if ! task_sdkman_java_gradle; then
#        log "SDKMAN Java + Gradle installation failed!"
#        status=1
#    fi
 
    if [[ $status -eq 0 ]]; then
        log "✅ All steps completed successfully."
    else
        log "⚠️ Some steps failed. Check the log at $LOG_FILE."
        exit 1
    fi
}
 
# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi