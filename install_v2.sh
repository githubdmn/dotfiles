#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

LOG_FILE="${LOG_FILE:-$HOME/custom-install.log}"

# Where PATH / tool-manager lines get appended. If ~/.bashrc is a symlink into
# your dotfiles repo (rc-slinks.sh), set SHELL_RC=~/.bashrc.local instead so an
# install never edits the repo. Lines already present in the file are detected
# and not added twice.
SHELL_RC="${SHELL_RC:-$HOME/.bashrc}"

# Never let apt / dpkg / needrestart stop and wait for a keypress.
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Filled in by main(): packages that don't exist on this release, and tasks
# that failed, so the end-of-run summary can't hide them.
SKIPPED_FILE=""
FAILED_TASKS=()

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
# Dropbox and MEGA are installed via downloads, not apt repos

# ── Group F: Containers ──────────────────────────────────────────────────────
PACKAGES_PODMAN=(
    podman podman-compose
)

# ── Group G: Runtimes (local user installs) ──────────────────────────────────
# Go, nvm, pyenv, deno, SDKMAN — all installed locally in $HOME

# ─── Logging ─────────────────────────────────────────────────────────────────

# printf, not `echo -e`: a message containing a backslash must print as written.
log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

# ─── Helpers ─────────────────────────────────────────────────────────────────

have() { command -v "$1" &>/dev/null; }

# apt-get (stable scripting interface), and wait for the dpkg lock instead of
# failing instantly if something else is using apt.
apt_get() { sudo apt-get -o DPkg::Lock::Timeout=300 "$@"; }

# Correct "is it installed" test. `dpkg -l | grep` matches substrings and also
# matches packages that were removed but still have config files.
pkg_installed() {
    [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null)" == "installed" ]]
}

# version_ge 1.25.3 1.23.1  ->  true
version_ge() {
    [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

# add_to_shell_rc NAME CONTENT [ALREADY_PRESENT_REGEX]
# Appends a marked block once. Skips if the marker, or the optional regex,
# is already anywhere in $SHELL_RC (e.g. your dotfiles bashrc already has it).
add_to_shell_rc() {
    local name="$1" content="$2" present="${3:-}"
    touch "$SHELL_RC"

    if grep -qF "# >>> ${name} >>>" "$SHELL_RC" ||
       { [[ -n "$present" ]] && grep -qE "$present" "$SHELL_RC"; }; then
        log "${name} already configured in ${SHELL_RC}."
        return 0
    fi

    printf '\n# >>> %s >>>\n%s\n# <<< %s <<<\n' "$name" "$content" "$name" >> "$SHELL_RC"
    log "Added ${name} to ${SHELL_RC}."
}

# Run one task so that `set -e` is genuinely active INSIDE it.
# Calling a function as `if ! task_x; then` silently disables errexit for its
# entire body, so a failed step in the middle of a task goes unnoticed and the
# task still reports success. A subshell run as a plain command avoids that.
# (Each task is self-contained, so nothing needs to leak out of the subshell.)
run_task() {
    local label="$1" rc
    shift

    set +e
    ( set -e; "$@" )
    rc=$?
    set -e

    if (( rc != 0 )); then
        log "${label} failed! (exit ${rc})"
        FAILED_TASKS+=("$label")
    fi
    return 0   # errexit is back on: never return non-zero from here
}

# Section header in the log, so the output reads as groups of related tasks.
group() {
    log ""
    log "━━━ $* ━━━"
}

# ─── Functions ───────────────────────────────────────────────────────────────

# Refresh the package index (run ONCE before any apt operation)
update() {
    log "Updating package index..."
    apt_get update 2>&1 | tee -a "$LOG_FILE"
}

# Install a list of packages from an array.
# apt rejects the WHOLE install if even one name doesn't exist on this release,
# so names with no installable candidate are skipped (and reported) up front.
install_packages() {
    local -n pkg_list=$1
    if [[ ${#pkg_list[@]} -eq 0 ]]; then
        log "No packages to install. Skipping."
        return 0
    fi

    local -a available=() missing=()
    local pkg candidate
    for pkg in "${pkg_list[@]}"; do
        candidate=$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}' || true)
        if [[ -n "$candidate" && "$candidate" != "(none)" ]]; then
            available+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "⚠️ Not available on this release, skipping: ${missing[*]}"
        printf '%s\n' "${missing[@]}" >> "${SKIPPED_FILE:-/dev/null}"
    fi

    if [[ ${#available[@]} -eq 0 ]]; then
        log "Nothing installable in this group."
        return 0
    fi

    log "Installing ${#available[@]} packages..."
    apt_get install -y "${available[@]}" 2>&1 | tee -a "$LOG_FILE"
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

    if have brave-browser; then
        log "Brave browser is already installed."
        return 0
    fi

    log "Adding Brave browser repository..."

    # Install GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
        -o /etc/apt/keyrings/brave-browser-archive-keyring.gpg

    # Add repository (single line; arch detected, not hardcoded)
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main\n' \
        "$(dpkg --print-architecture)" \
        | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null

    # Refresh package index for the new repo
    apt_get update
}

task_brave() {
    install_brave_repo
    install_packages PACKAGES_BRAVE
}

# ── Neovim setup (dotfiles + vim-plug) ───────────────────────────────────────

task_neovim() {
    log "=== Task: Neovim configuration ==="

    local src="${HOME}/dotfiles/config/rc/init.vim"
    local conf="${HOME}/.config"
    local nvim_conf="${conf}/nvim"
    local plug_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"

    # Create Neovim config directory
    mkdir -p "${nvim_conf}"

    # Link init.vim from dotfiles
    if [[ ! -f "$src" ]]; then
        log "Warning: ${src} not found. Skipping symlink."
    elif [[ -L "${nvim_conf}/init.vim" && "$(readlink -f "${nvim_conf}/init.vim")" == "$(readlink -f "$src")" ]]; then
        log "Neovim init.vim already linked."
    else
        # A real file (or a link to somewhere else) is already there. The old
        # code just ran `ln`, which failed with "File exists" and was still
        # reported as success. Keep the old one as a backup, then link.
        if [[ -e "${nvim_conf}/init.vim" || -L "${nvim_conf}/init.vim" ]]; then
            local backup="${nvim_conf}/init.vim.bak.$(date +%Y%m%d_%H%M%S)"
            mv -- "${nvim_conf}/init.vim" "$backup"
            log "Existing init.vim moved to ${backup}"
        fi
        ln -s "$src" "${nvim_conf}/init.vim"
        log "Configured Neovim with init.vim from dotfiles."
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
    # -C instead of `cd ~`: a cd inside a function changes the working
    # directory for everything that runs after it.
    wget -qO- "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - -C "$HOME"

    if [ ! -d "$HOME/.dropbox-dist" ]; then
        log "Dropbox installation failed."
        return 1
    fi

    # The daemon prints the link you must open to authorize this device. The
    # old code sent all of its output to /dev/null, so that link was thrown
    # away. Capture it to a file and show it.
    local dlog="$HOME/dropboxd-first-run.log"
    log "Dropbox installed. Starting daemon..."
    nohup "$HOME/.dropbox-dist/dropboxd" >"$dlog" 2>&1 &
    disown

    local i link=""
    for i in {1..20}; do
        link=$(grep -o 'https://www.dropbox.com/cli_link_nonce[^ ]*' "$dlog" 2>/dev/null | head -n1 || true)
        if [[ -n "$link" ]]; then break; fi
        sleep 1
    done

    if [[ -n "$link" ]]; then
        log "Authorize this device by opening: ${link}"
    else
        log "Daemon started, but no authorization link yet. See: ${dlog}"
    fi
}

task_dropbox_cli() {
    log "=== Task: Dropbox CLI ==="

    if have dropbox || [[ -x "$HOME/bin/dropbox" ]]; then
        log "Dropbox CLI is already installed."
        return 0
    fi

    log "Setting up Dropbox CLI..."
    mkdir -p "$HOME/bin"

    local tmp
    tmp=$(mktemp)
    # URL quoted: an unquoted `?` is a shell glob character.
    if wget -q -O "$tmp" "https://www.dropbox.com/download?dl=packages/dropbox.py"; then
        install -m 0755 "$tmp" "$HOME/bin/dropbox"
        rm -f "$tmp"
        log "Dropbox CLI installed at ~/bin/dropbox"
    else
        rm -f "$tmp"
        log "Failed to download Dropbox CLI."
        return 1
    fi
}

task_mega() {
    log "=== Task: MEGA client ==="

    if have megasync || pkg_installed megasync; then
        log "MEGA client is already installed."
        return 0
    fi

    # Was hardcoded to Debian_12. Use this system's release, and fall back to
    # the Debian_12 package if MEGA has no build for it.
    local base="https://mega.nz/linux/repo"
    local release repo_dir package_name url
    release=$(. /etc/os-release && echo "${VERSION_ID%%.*}")
    repo_dir="Debian_${release}"
    package_name="megasync-${repo_dir}_amd64.deb"
    url="${base}/${repo_dir}/amd64/${package_name}"

    if ! wget -q --spider "$url"; then
        log "No MEGA package found for ${repo_dir}; falling back to Debian_12."
        repo_dir="Debian_12"
        package_name="megasync-${repo_dir}_amd64.deb"
        url="${base}/${repo_dir}/amd64/${package_name}"
    fi

    local tmp
    tmp=$(mktemp -d)
    chmod 755 "$tmp"   # so apt's sandbox user can read the .deb

    log "Downloading MEGA client (${repo_dir})..."
    if ! wget -q "$url" -O "${tmp}/${package_name}"; then
        rm -rf "$tmp"
        log "Failed to download MEGA client package."
        return 1
    fi

    log "Installing MEGA client..."
    if apt_get install -y "${tmp}/${package_name}"; then
        rm -rf "$tmp"
        log "MEGA client installed successfully."
    else
        rm -rf "$tmp"
        log "MEGA client installation failed."
        return 1
    fi
}

# ── Containers ────────────────────────────────────────────────────────────────

task_docker() {
    log "=== Task: Docker ==="

    if have docker && pkg_installed docker-ce; then
        log "Docker already installed."
        return 0
    fi

    # Remove only conflicting packages that are actually present
    local pkg
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        if pkg_installed "$pkg"; then
            log "Removing conflicting package: $pkg"
            apt_get remove -y "$pkg"
        fi
    done

    # Install dependencies
    log "Installing Docker dependencies..."
    apt_get update
    apt_get install -y ca-certificates curl gnupg

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

    apt_get update

    # Install Docker
    log "Installing Docker..."
    apt_get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    # Enable and start service
    sudo systemctl enable --now docker

    # Add user to docker group ($USER can be unset under cron / minimal shells)
    sudo usermod -aG docker "${USER:-$(id -un)}"

    log "Docker installed successfully."
    log "Run 'newgrp docker' or log out/in to use docker without sudo."
}

task_podman() {
    log "=== Task: Podman ==="

    if have podman; then
        log "Podman is already installed."
        return 0
    fi

    log "Installing Podman..."
    install_packages PACKAGES_PODMAN

    if have podman; then
        log "Podman installed successfully. Version: $(podman --version)"
    else
        log "Podman installation failed."
        return 1
    fi
}

# ── Runtimes (local user installs) ────────────────────────────────────────────

# Installs the Go toolchain to /usr/local/go (Go's documented location).
# Your GOPATH ($HOME/go: module cache, installed binaries, sources) is NEVER
# touched. The old version deleted $HOME/go whenever the version differed.
# Version: task_go 1.25.3, or GO_VERSION=1.25.3, else the latest from go.dev.
task_go() {
    log "=== Task: Go runtime ==="

    local want="${1:-${GO_VERSION:-}}"
    if [[ -z "$want" ]]; then
        want=$(curl -fsSL 'https://go.dev/VERSION?m=text' 2>/dev/null | head -n1 | sed 's/^go//' || true)
        if [[ ! "$want" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
            want="1.25.1"
            log "Could not query the latest Go version; using ${want}."
        fi
    fi

    local goarch
    case "$(uname -m)" in
        x86_64)  goarch="amd64" ;;
        aarch64) goarch="arm64" ;;
        *) log "Unsupported architecture for Go: $(uname -m)"; return 1 ;;
    esac

    # Already installed at this version or newer: nothing to do. (String
    # equality would "upgrade" a newer Go down to an older one.)
    if [[ -x /usr/local/go/bin/go ]]; then
        local current
        current=$(/usr/local/go/bin/go version | awk '{print $3}' | sed 's/^go//')
        if version_ge "$current" "$want"; then
            log "Go ${current} already installed (>= ${want})."
            return 0
        fi
        log "Go ${current} found, replacing with ${want}..."
    fi

    local tarball="go${want}.linux-${goarch}.tar.gz"
    local tmp
    tmp=$(mktemp -d)

    log "Downloading Go ${want}..."
    if ! curl -fSL "https://go.dev/dl/${tarball}" -o "${tmp}/${tarball}"; then
        rm -rf "$tmp"
        log "Failed to download Go ${want}."
        return 1
    fi

    log "Extracting Go ${want} to /usr/local/go..."
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "${tmp}/${tarball}"
    rm -rf "$tmp"

    add_to_shell_rc "golang" \
'export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"' \
        '/usr/local/go/bin'

    /usr/local/go/bin/go version
    log "Go ${want} installed successfully."
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

    local python_version="${1:-3.12.1}"

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    # Check the directory, not `command -v pyenv`: in a script run from a
    # fresh shell pyenv is installed but not on PATH yet, and running the
    # installer again then fails ("remove the ~/.pyenv directory first").
    if [[ -x "$PYENV_ROOT/bin/pyenv" ]]; then
        log "pyenv is already installed. Version: $(pyenv --version)"
    else
        log "Installing pyenv..."
        curl -fsSL https://pyenv.run | bash
    fi

    add_to_shell_rc "pyenv" \
'export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"' \
        'PYENV_ROOT'

    # Install Python version. -s = skip if it already exists; without it,
    # `pyenv install` exits 1 on a re-run when the version is already there.
    log "Installing Python $python_version via pyenv (-s: skipped if present)..."
    if ! pyenv install -s "$python_version" 2>&1; then
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
        if ! grep -q 'DENO_INSTALL' "$SHELL_RC" 2>/dev/null; then
            echo 'export DENO_INSTALL="$HOME/.deno"' >> "$SHELL_RC"
            echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> "$SHELL_RC"
            log "Added Deno to PATH in $SHELL_RC."
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

# sdkman-init.sh is not written for `set -u`; load it with nounset relaxed.
sdkman_load() {
    set +u
    # shellcheck disable=SC1091
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    set -u
}

task_sdkman() {
    log "=== Task: SDKMAN ==="

    if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        log "SDKMAN is already installed."
        sdkman_load
        sdk version
        return 0
    fi

    log "Installing SDKMAN..."
    if curl -fsSL "https://get.sdkman.io" | bash; then
        log "SDKMAN installed."
    else
        log "SDKMAN installation failed."
        return 1
    fi

    sdkman_load
    sdk version
}

task_sdkman_java_gradle() {
    log "=== Task: SDKMAN Java + Gradle ==="

    # Source SDKMAN if not already loaded
    if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        sdkman_load
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
    apt_get autoremove -y 2>&1 | tee -a "$LOG_FILE"
}

run_system_packages() {
  group "System packages"
      run_task "Core packages"          task_core
      run_task "Media packages"         task_media
      run_task "Entertainment packages" task_entertainment
}

run_editors() {
    group "Editor setup"
    run_task "Neovim configuration"   task_neovim
}

run_browser() {
    group "Browser"
    run_task "Brave browser"          task_brave
}

run_cloud_storage() {
    group "Cloud storage"
    run_task "Dropbox (headless)"     task_dropbox_headless
    run_task "Dropbox CLI"            task_dropbox_cli
    run_task "MEGA client"            task_mega
}

run_constainers() {
    group "Containers"
    run_task "Docker"                 task_docker
    run_task "Podman"                 task_podman
}

run_languages() {
      group "Languages & runtimes"
      run_task "Go runtime"             task_go
      run_task "nvm"                    task_nvm
      run_task "pyenv"                  task_pyenv
  #    run_task "Deno"                  task_deno
  #    run_task "Bun"                   task_bun
      run_task "SDKMAN"                 task_sdkman
  #    run_task "SDKMAN Java + Gradle"  task_sdkman_java_gradle
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
    if [[ $EUID -eq 0 ]]; then
        echo "Do not run this as root: it installs into \$HOME and calls sudo itself." >&2
        exit 1
    fi

    SKIPPED_FILE=$(mktemp)
    trap 'rm -f "$SKIPPED_FILE"' EXIT

    log "Starting system package installation..."

    # Ask for the sudo password once, up front, not halfway through.
    sudo -v

    # 1. Update package index (once, shared by all apt operations)
    update

    # Groups are ordered so that work needing sudo (apt, repos, /usr/local)
    # comes first and the slow user-level builds (pyenv etc.) come late.

    run_system_packages
    # run_editors
    # run_browser
    # run_cloud_storage
    # run_languages

    group "Cleanup"
    # The runtime builds above can take a while; refresh sudo so autoremove
    # doesn't hit an expired timestamp.
    sudo -v || log "sudo timestamp could not be refreshed; autoremove may prompt."
    run_task "Autoremove"             autoremove

    # ── Summary ──────────────────────────────────────────────────────────────
    if [[ -s "$SKIPPED_FILE" ]]; then
        log "⚠️ Skipped (not available on this release): $(sort -u "$SKIPPED_FILE" | tr '\n' ' ')"
    fi

    if [[ ${#FAILED_TASKS[@]} -eq 0 ]]; then
        log "✅ All steps completed successfully."
        log "Open a new terminal (or log out/in) so PATH changes and the docker group apply."
    else
        log "⚠️ Failed: ${FAILED_TASKS[*]}"
        log "Check the log at $LOG_FILE."
        exit 1
    fi
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi