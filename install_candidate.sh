#!/usr/bin/env bash
#
# Debian (Trixie) workstation bootstrap.
#
# Usage:
#   ./install.sh --list                 show every available task
#   ./install.sh bundle media_cli yazi  run specific tasks, in order
#   ./install.sh --all-base             upgrade + bundle + media_cli + yazi
#   ./install.sh --dry-run bundle       print what would run, change nothing
#
# Run as your normal user. The script calls sudo where it needs to.

set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

readonly BASHRC="${HOME}/.bashrc"
readonly LOCAL_BIN="${HOME}/.local/bin"
readonly LOG_FILE="${TMPDIR:-/tmp}/install-$(date +%Y%m%d-%H%M%S).log"

DRY_RUN=0
NEEDS_RESHELL=0
FAILED_TASKS=()

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m';  C_GREEN=$'\033[32m'; C_BOLD=$'\033[1m'
else
  C_RESET=''; C_BLUE=''; C_YELLOW=''; C_RED=''; C_GREEN=''; C_BOLD=''
fi

_log() { printf '%s\n' "$*" | tee -a "$LOG_FILE" >&2; }

log_info() { _log "${C_BLUE}[INFO]${C_RESET}  $*"; }
log_ok()   { _log "${C_GREEN}[ OK ]${C_RESET}  $*"; }
log_warn() { _log "${C_YELLOW}[WARN]${C_RESET}  $*"; }
log_error(){ _log "${C_RED}[FAIL]${C_RESET}  $*"; }
log_step() { _log ""; _log "${C_BOLD}==> $*${C_RESET}"; }

# Fires on any unhandled non-zero exit, thanks to `set -E` + ERR trap.
on_error() {
  local exit_code=$? line=$1
  log_error "Aborted at line ${line} (exit ${exit_code}). Log: ${LOG_FILE}"
}
trap 'on_error $LINENO' ERR

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

preflight() {
  if [[ $EUID -eq 0 ]]; then
    log_error "Do not run this as root. It installs into \$HOME and uses sudo itself."
    exit 1
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    log_error "sudo is not installed."
    exit 1
  fi

  if [[ ! -r /etc/os-release ]]; then
    log_error "Cannot read /etc/os-release. This script targets Debian/Ubuntu."
    exit 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}:${ID_LIKE:-}" in
    debian:*|ubuntu:*|*:*debian*) : ;;
    *) log_warn "Untested distro: ${PRETTY_NAME:-unknown}. Continuing anyway." ;;
  esac

  local arch; arch=$(dpkg --print-architecture)
  if [[ "$arch" != "amd64" ]]; then
    log_warn "Architecture is ${arch}. Several tasks here hardcode amd64/x86_64 and will fail."
  fi

  log_info "Host: ${PRETTY_NAME:-unknown} (${arch})"
  log_info "Log:  ${LOG_FILE}"

  # Prime the sudo timestamp once, up front, instead of prompting mid-run.
  if (( ! DRY_RUN )); then
    log_info "Requesting sudo (you may be prompted once)..."
    sudo -v
    # Keep the timestamp alive for the duration of the script.
    while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
  fi
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

run() {
  if (( DRY_RUN )); then
    log_info "[dry-run] $*"
    return 0
  fi
  "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

# Correct package-installed check. `dpkg -l | grep` matches substrings and
# also matches removed-but-configured (rc) packages.
pkg_installed() {
  dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null | grep -q '^installed$'
}

apt_update() {
  log_info "Updating package lists..."
  run sudo apt-get update -qq
}

apt_install() {
  local -a missing=()
  local pkg
  for pkg in "$@"; do
    pkg_installed "$pkg" || missing+=("$pkg")
  done

  if (( ${#missing[@]} == 0 )); then
    log_ok "Already installed: $*"
    return 0
  fi

  log_info "Installing: ${missing[*]}"
  run sudo apt-get install -y "${missing[@]}"
}

# Idempotent .bashrc edits, guarded by markers. Never re-appends.
# Deliberately does NOT `source ~/.bashrc` — Debian's .bashrc returns early
# for non-interactive shells, so sourcing it from a script does nothing.
bashrc_block() {
  local id="$1" content="$2"
  local start="# >>> ${id} (install.sh) >>>"
  local end="# <<< ${id} (install.sh) <<<"

  touch "$BASHRC"
  if grep -qF "$start" "$BASHRC"; then
    log_ok "~/.bashrc already configured for ${id}"
    return 0
  fi

  if (( DRY_RUN )); then
    log_info "[dry-run] would append ${id} block to ~/.bashrc"
    return 0
  fi

  printf '\n%s\n%s\n%s\n' "$start" "$content" "$end" >> "$BASHRC"
  log_ok "Added ${id} config to ~/.bashrc"
  NEEDS_RESHELL=1
}

# Proper version comparison. version_ge 1.25.0 1.23.1 -> true
version_ge() {
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

ensure_local_bin() {
  mkdir -p "$LOCAL_BIN"
  bashrc_block "local-bin" 'export PATH="$HOME/.local/bin:$PATH"'
}

# Creates a temp dir and registers cleanup for THIS function only.
# Caller must `local tmp; tmp=$(make_tmpdir)` and `rm -rf "$tmp"` itself,
# or use with_tmpdir below.
make_tmpdir() { mktemp -d "${TMPDIR:-/tmp}/install.XXXXXXXX"; }

# ---------------------------------------------------------------------------
# apt maintenance
# ---------------------------------------------------------------------------

task_update()     { apt_update; }
task_upgrade()    { apt_update; log_info "Running full-upgrade..."; run sudo apt-get full-upgrade -y; }
task_autoremove() { log_info "Removing orphaned packages..."; run sudo apt-get autoremove --purge -y; }

# ---------------------------------------------------------------------------
# Base package bundle
# ---------------------------------------------------------------------------

task_bundle() {
  apt_update

  # Split into groups so one bad package name doesn't sink the whole install.
  local -a core=(
    build-essential gdb git ssh curl wget unzip xz-utils
    apt-transport-https ca-certificates gnupg rsync
  )
  local -a editors=(nano vim neovim tmux)
  local -a cli=(jq ripgrep fd-find htop tree bat fzf mc nnn 7zip)
  local -a hwinfo=(usbutils lshw inxi fastfetch)
  # Build deps for pyenv / compiling CPython.
  local -a builddeps=(
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev
    llvm libncurses-dev tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
  )

  apt_install "${core[@]}"
  apt_install "${editors[@]}"
  apt_install "${cli[@]}"
  apt_install "${hwinfo[@]}"
  apt_install "${builddeps[@]}"

  # Optional / environment-dependent. Don't abort the run if unavailable.
  # - wl-clipboard is Wayland-only
  # - libfuse2t64 is the Trixie name (libfuse2 on Bookworm)
  # - hardinfo was dropped in Debian 13; hardinfo2 replaces it
  local opt
  for opt in wl-clipboard libfuse2t64 hardinfo2; do
    if apt-cache show "$opt" >/dev/null 2>&1; then
      apt_install "$opt" || log_warn "Optional package '${opt}' failed to install."
    else
      log_warn "Optional package '${opt}' not available in this release; skipping."
    fi
  done

  # Debian renames these binaries to avoid collisions; add the usual aliases.
  bashrc_block "debian-cli-aliases" \
'command -v batcat >/dev/null 2>&1 && alias bat="batcat"
command -v fdfind >/dev/null 2>&1 && alias fd="fdfind"'
}

# ---------------------------------------------------------------------------
# Media / CLI extras
# ---------------------------------------------------------------------------

task_media_cli() {
  apt_install ffmpeg poppler-utils imagemagick zoxide
  # The original ran `eval "$(zoxide init bash)"` inside the script, which has
  # no effect on your interactive shell. Persist it instead.
  bashrc_block "zoxide" 'eval "$(zoxide init bash)"'
}

# ---------------------------------------------------------------------------
# Neovim config + vim-plug
# ---------------------------------------------------------------------------

task_neovim_config() {
  apt_install neovim curl

  local conf="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  local dotfile="${HOME}/dotfiles/config/rc/init.vim"

  mkdir -p "$conf"

  if [[ -e "${conf}/init.vim" || -L "${conf}/init.vim" ]]; then
    log_ok "Neovim init.vim already present."
  elif [[ -f "$dotfile" ]]; then
    run ln -sv "$dotfile" "${conf}/init.vim"
    log_ok "Linked init.vim from dotfiles."
  else
    log_warn "No dotfiles init.vim at ${dotfile}; skipping symlink."
  fi

  local plug="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
  if [[ -f "$plug" ]]; then
    log_ok "vim-plug already installed."
  else
    run curl -fLo "$plug" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    log_ok "Installed vim-plug."
  fi
}

# ---------------------------------------------------------------------------
# Yazi (prebuilt binary from GitHub releases)
# ---------------------------------------------------------------------------

task_yazi() {
  if have yazi; then
    log_ok "yazi already installed ($(yazi --version 2>/dev/null | head -n1))."
    return 0
  fi

  apt_install curl unzip
  ensure_local_bin

  local arch; arch=$(uname -m)
  local asset="yazi-${arch}-unknown-linux-gnu.zip"

  log_info "Looking up latest yazi release for ${arch}..."
  local api="https://api.github.com/repos/sxyazi/yazi/releases/latest"
  local url

  # Authenticate if a token is around — unauthenticated GitHub API is 60/hr.
  local -a curl_args=(-fsSL)
  [[ -n "${GITHUB_TOKEN:-}" ]] && curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

  if have jq; then
    url=$(curl "${curl_args[@]}" "$api" | jq -r --arg a "$asset" \
      '.assets[] | select(.name == $a) | .browser_download_url')
  else
    url=$(curl "${curl_args[@]}" "$api" \
      | grep -o "https://[^\"]*${asset}" | head -n1)
  fi

  if [[ -z "$url" || "$url" == "null" ]]; then
    log_error "No yazi release asset found for ${arch}."
    return 1
  fi

  local tmp; tmp=$(make_tmpdir)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN

  log_info "Downloading ${url}"
  run curl -fSL "$url" -o "${tmp}/yazi.zip"
  run unzip -q "${tmp}/yazi.zip" -d "${tmp}/extracted"

  # Quote the glob expansion properly and fail loudly if it matches nothing.
  local src
  src=$(find "${tmp}/extracted" -mindepth 2 -maxdepth 2 -type f -name yazi -print -quit)
  if [[ -z "$src" ]]; then
    log_error "yazi binary not found inside the archive."
    return 1
  fi

  local dir; dir=$(dirname "$src")
  run install -m 0755 "${dir}/yazi" "${LOCAL_BIN}/yazi"
  [[ -f "${dir}/ya" ]] && run install -m 0755 "${dir}/ya" "${LOCAL_BIN}/ya"

  log_ok "yazi installed to ${LOCAL_BIN}."
}

# ---------------------------------------------------------------------------
# Editors
# ---------------------------------------------------------------------------

task_zed() {
  if have zed; then
    log_ok "Zed already installed."
    return 0
  fi
  apt_install curl
  log_warn "This pipes zed.dev/install.sh into sh — vendor's supported path, but review it if that bothers you."
  if (( DRY_RUN )); then
    log_info "[dry-run] curl -fsSL https://zed.dev/install.sh | sh"
    return 0
  fi
  if curl -fsSL https://zed.dev/install.sh | sh; then
    log_ok "Zed installed. Ensure ~/.local/bin is on PATH."
    ensure_local_bin
  else
    log_error "Zed installation failed."
    return 1
  fi
}

task_vscodium() {
  apt_install curl wget tar
  ensure_local_bin

  local version="${1:-}"
  if [[ -z "$version" ]]; then
    log_info "Fetching latest VSCodium version..."
    local -a curl_args=(-fsSL)
    [[ -n "${GITHUB_TOKEN:-}" ]] && curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    if have jq; then
      version=$(curl "${curl_args[@]}" https://api.github.com/repos/VSCodium/vscodium/releases/latest | jq -r '.tag_name')
    else
      version=$(curl "${curl_args[@]}" https://api.github.com/repos/VSCodium/vscodium/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    fi
  fi

  if [[ -z "$version" || "$version" == "null" ]]; then
    log_error "Could not determine a VSCodium version."
    return 1
  fi

  local install_dir="${HOME}/.local/opt/VSCodium"
  local url="https://github.com/VSCodium/vscodium/releases/download/${version}/VSCodium-linux-x64-${version}.tar.gz"

  local tmp; tmp=$(make_tmpdir)
  # RETURN-scoped trap: does not clobber the script's global traps.
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN

  log_info "Downloading VSCodium ${version}..."
  if ! run wget -q --show-progress -O "${tmp}/vscodium.tar.gz" "$url"; then
    log_error "Download failed: ${url}"
    return 1
  fi

  if (( DRY_RUN )); then
    log_info "[dry-run] would extract and install VSCodium ${version} to ${install_dir}"
    return 0
  fi

  [[ -s "${tmp}/vscodium.tar.gz" ]] || { log_error "Downloaded archive is empty."; return 1; }

  # Extract into a dedicated subdir so the tarball itself never gets copied
  # into the install directory (the original bug).
  mkdir -p "${tmp}/extracted"
  if ! tar -xzf "${tmp}/vscodium.tar.gz" -C "${tmp}/extracted"; then
    log_error "Extraction failed."
    return 1
  fi

  local bin
  bin=$(find "${tmp}/extracted" -maxdepth 3 -type f -name codium -print -quit)
  if [[ -z "$bin" ]]; then
    log_error "codium binary not found in archive."
    return 1
  fi
  local root; root=$(dirname "$(dirname "$bin")")
  [[ "$(basename "$(dirname "$bin")")" == "bin" ]] || root=$(dirname "$bin")

  log_info "Stopping running VSCodium instances..."
  pkill -x codium 2>/dev/null || true
  sleep 1

  rm -rf "$install_dir"
  mkdir -p "$install_dir"
  cp -a "${root}/." "$install_dir/"

  ln -sf "${install_dir}/bin/codium" "${LOCAL_BIN}/codium"

  local icon="${install_dir}/resources/app/resources/linux/code.png"
  [[ -f "$icon" ]] || icon="vscodium"

  mkdir -p "${HOME}/.local/share/applications"
  cat > "${HOME}/.local/share/applications/vscodium.desktop" <<EOF
[Desktop Entry]
Name=VSCodium
Comment=Code Editing. Redefined. (Open Source)
Exec=${LOCAL_BIN}/codium %F
Icon=${icon}
Type=Application
Terminal=false
Categories=Development;IDE;TextEditor;
StartupNotify=true
StartupWMClass=VSCodium
MimeType=text/plain;application/json;text/x-python;text/markdown;application/x-shellscript;application/javascript;text/x-yaml;text/x-typescript;text/css;text/html;
EOF

  have update-desktop-database && update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true

  log_ok "VSCodium ${version} installed to ${install_dir}."
}

# ---------------------------------------------------------------------------
# Language runtimes
# ---------------------------------------------------------------------------

task_nvm() {
  local version="${1:-0.40.3}"
  local nvm_dir="${HOME}/.nvm"

  if [[ -s "${nvm_dir}/nvm.sh" ]]; then
    log_ok "nvm already installed."
    return 0
  fi

  apt_install curl
  log_info "Installing nvm v${version}..."
  # nvm's installer creates NVM_DIR itself; the original `mkdir ${NVM_DIR}`
  # (no -p, unquoted) would fail on a second run.
  if (( DRY_RUN )); then
    log_info "[dry-run] would install nvm v${version}"
    return 0
  fi

  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${version}/install.sh" | bash

  if [[ -s "${nvm_dir}/nvm.sh" ]]; then
    log_ok "nvm installed. Open a new shell, then: nvm install --lts"
    NEEDS_RESHELL=1
  else
    log_error "nvm installation failed."
    return 1
  fi
}

task_go() {
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

task_python() {
  local py_version="${1:-3.12.7}"

  apt_install curl git build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses-dev tk-dev libxml2-dev \
    libxmlsec1-dev libffi-dev liblzma-dev

  if [[ ! -d "${HOME}/.pyenv" ]]; then
    log_info "Installing pyenv..."
    # -fsSL matters: without it, an HTTP error page gets piped into bash.
    if (( DRY_RUN )); then
      log_info "[dry-run] curl -fsSL https://pyenv.run | bash"
    else
      curl -fsSL https://pyenv.run | bash
    fi
  else
    log_ok "pyenv already installed."
  fi

  # `pyenv init --path` alone does not set up shims for `pyenv shell`/plugins
  # on modern pyenv. Both lines are needed.
  bashrc_block "pyenv" \
'export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"'

  local pyenv_bin="${HOME}/.pyenv/bin/pyenv"
  if [[ ! -x "$pyenv_bin" ]]; then
    log_error "pyenv not found at ${pyenv_bin}. Check ~/.bashrc manually."
    return 1
  fi

  export PYENV_ROOT="${HOME}/.pyenv"
  export PATH="${PYENV_ROOT}/bin:${PATH}"

  if "$pyenv_bin" versions --bare 2>/dev/null | grep -qx "$py_version"; then
    log_ok "Python ${py_version} already built."
  else
    log_info "Building Python ${py_version} (this takes a few minutes)..."
    run "$pyenv_bin" install "$py_version"
  fi

  run "$pyenv_bin" global "$py_version"
  log_ok "Python ${py_version} set as pyenv global."
  NEEDS_RESHELL=1
}

task_sdkman() {
  apt_install zip unzip curl

  if [[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
    log_ok "SDKMAN already installed."
    return 0
  fi

  log_info "Installing SDKMAN..."
  if (( DRY_RUN )); then
    log_info "[dry-run] curl -fsSL https://get.sdkman.io | bash"
    return 0
  fi

  if curl -fsSL "https://get.sdkman.io" | bash; then
    log_ok "SDKMAN installed. Open a new shell, then: sdk install java"
    NEEDS_RESHELL=1
  else
    log_error "SDKMAN installation failed."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Containers
# ---------------------------------------------------------------------------

task_docker() {
  if have docker && pkg_installed docker-ce; then
    log_ok "Docker already installed."
    return 0
  fi

  log_info "Installing Docker CE..."

  # Only remove distro/conflicting packages that are actually present.
  local pkg
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    if pkg_installed "$pkg"; then
      log_warn "Removing conflicting package: ${pkg}"
      run sudo apt-get remove -y "$pkg"
    fi
  done

  apt_update
  apt_install ca-certificates curl gnupg

  run sudo install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    if (( DRY_RUN )); then
      log_info "[dry-run] would add Docker GPG key"
    else
      curl -fsSL https://download.docker.com/linux/debian/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi
  fi

  local arch codename
  arch=$(dpkg --print-architecture)
  codename=$(. /etc/os-release && echo "${VERSION_CODENAME}")

  # Single-line source entry. The original had embedded newlines from the
  # backslash continuations.
  if (( DRY_RUN )); then
    log_info "[dry-run] would write /etc/apt/sources.list.d/docker.list"
  else
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian %s stable\n' \
      "$arch" "$codename" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi

  apt_update
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  run sudo systemctl enable --now docker
  run sudo usermod -aG docker "$USER"

  log_ok "Docker installed."
  log_warn "Log out and back in (or run 'newgrp docker') to use docker without sudo."
}

task_podman() {
  # The original required root here while everything else used sudo, so it
  # always failed when called from the dev bundle.
  apt_update
  apt_install podman podman-compose
  have podman && log_ok "Podman $(podman --version | awk '{print $3}') installed."
}

# ---------------------------------------------------------------------------
# Apps
# ---------------------------------------------------------------------------

task_brave() {
  if have brave-browser; then
    log_ok "Brave already installed."
    return 0
  fi

  apt_install curl

  # Use ONLY the official deb822 .sources file. The original also wrote a
  # legacy .list for the same repo, producing duplicate-source warnings.
  if (( DRY_RUN )); then
    log_info "[dry-run] would add Brave repository"
  else
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
      https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
    sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list
  fi

  apt_update
  apt_install brave-browser
}

task_bruno() {
  if have bruno || pkg_installed bruno; then
    log_ok "Bruno already installed."
    return 0
  fi

  apt_install gpg curl
  run sudo mkdir -p /etc/apt/keyrings

  if (( DRY_RUN )); then
    log_info "[dry-run] would add Bruno repository"
  else
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9FA6017ECABE0266" \
      | gpg --dearmor \
      | sudo tee /etc/apt/keyrings/bruno.gpg >/dev/null
    sudo chmod 644 /etc/apt/keyrings/bruno.gpg

    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable\n' \
      "$(dpkg --print-architecture)" | sudo tee /etc/apt/sources.list.d/bruno.list >/dev/null
  fi

  apt_update
  apt_install bruno
}

task_mega() {
  if pkg_installed megasync; then
    log_ok "MEGAsync already installed."
    return 0
  fi

  # Match the actual release rather than hardcoding Debian_12.
  local codename; codename=$(. /etc/os-release && echo "${VERSION_ID:-12}")
  local repo_dir
  case "$codename" in
    13*) repo_dir="Debian_13" ;;
    12*) repo_dir="Debian_12" ;;
    *)   repo_dir="Debian_12"; log_warn "Unrecognised release; falling back to Debian_12 package." ;;
  esac

  local tmp; tmp=$(make_tmpdir)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN

  local url="https://mega.nz/linux/repo/${repo_dir}/amd64/megasync-${repo_dir}_amd64.deb"
  log_info "Downloading MEGAsync (${repo_dir})..."
  if ! run curl -fSL "$url" -o "${tmp}/megasync.deb"; then
    log_error "Download failed: ${url}"
    return 1
  fi

  run sudo apt-get install -y "${tmp}/megasync.deb"
  log_ok "MEGAsync installed."
}

task_dropbox_headless() {
  if [[ -d "${HOME}/.dropbox-dist" ]]; then
    log_ok "Dropbox daemon already present."
    return 0
  fi

  apt_install wget
  log_info "Downloading Dropbox headless daemon..."
  if (( DRY_RUN )); then
    log_info "[dry-run] would extract dropboxd into \$HOME"
    return 0
  fi

  ( cd "$HOME" && wget -qO- "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - )

  if [[ ! -d "${HOME}/.dropbox-dist" ]]; then
    log_error "Dropbox installation failed."
    return 1
  fi

  log_ok "Dropbox installed."
  log_info "Start it manually and follow the auth link:  ~/.dropbox-dist/dropboxd"
}

# ---------------------------------------------------------------------------
# SSH key
# ---------------------------------------------------------------------------

task_ssh_key() {
  local key_dir="${HOME}/.ssh"
  local key_type="ed25519"
  local key_name="id_ed25519"
  local key_comment="${USER}@$(hostname)"

  read -r -p "Key type [ed25519/rsa] (default: ed25519): " in_type
  case "${in_type:-ed25519}" in
    rsa)     key_type="rsa"; key_name="id_rsa" ;;
    ed25519) key_type="ed25519"; key_name="id_ed25519" ;;
    *)       log_error "Unsupported key type: ${in_type}"; return 1 ;;
  esac

  read -r -p "Key name (default: ${key_name}): " in_name
  key_name="${in_name:-$key_name}"
  read -r -p "Comment (default: ${key_comment}): " in_comment
  key_comment="${in_comment:-$key_comment}"

  local -a keygen_args=(-t "$key_type" -C "$key_comment")
  if [[ "$key_type" == "rsa" ]]; then
    read -r -p "Key size (default: 4096): " in_bits
    local bits="${in_bits:-4096}"
    [[ "$bits" =~ ^[0-9]+$ ]] || { log_error "Key size must be numeric."; return 1; }
    keygen_args+=(-b "$bits")
  fi

  mkdir -p "$key_dir"
  chmod 700 "$key_dir"

  local key_path="${key_dir}/${key_name}"
  if [[ -f "$key_path" || -f "${key_path}.pub" ]]; then
    read -r -p "A key already exists at ${key_path}. Overwrite? (y/N): " overwrite
    [[ "$overwrite" == "y" || "$overwrite" == "Y" ]] || { log_info "Aborted."; return 0; }
    rm -f "$key_path" "${key_path}.pub"
  fi

  # Prompt for a passphrase rather than silently creating an unprotected key.
  log_info "You'll be asked for a passphrase. Leaving it empty creates an unprotected key."
  if (( DRY_RUN )); then
    log_info "[dry-run] ssh-keygen ${keygen_args[*]} -f ${key_path}"
    return 0
  fi

  ssh-keygen "${keygen_args[@]}" -f "$key_path"
  chmod 600 "$key_path"
  chmod 644 "${key_path}.pub"

  log_ok "Key pair created."
  log_info "Private: ${key_path}"
  log_info "Public:  ${key_path}.pub"
}

# ---------------------------------------------------------------------------
# Composite
# ---------------------------------------------------------------------------

task_dev_basic() {
  run_tasks nvm go python sdkman docker sqlite_note bruno zed dropbox_headless mega
}

task_sqlite_note() {
  # The original downloaded a hardcoded 2024 tarball and added a PATH entry
  # pointing at a directory that never existed. The repo package is current
  # and on PATH already.
  apt_install sqlite3
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

TASKS=(
  update upgrade autoremove
  bundle media_cli neovim_config yazi
  zed vscodium
  nvm go python sdkman sqlite_note
  docker podman
  brave bruno mega dropbox_headless
  ssh_key
  dev_basic
)

usage() {
  cat <<EOF
Usage: ${0##*/} [options] <task> [task...]

Options:
  --list          List available tasks
  --all-base      upgrade bundle media_cli yazi autoremove
  --dry-run       Print actions without changing anything
  -h, --help      This message

Examples:
  ${0##*/} --all-base
  ${0##*/} bundle media_cli yazi
  ${0##*/} --dry-run docker
  ${0##*/} go 1.25.1          (tasks that accept a version take one argument)
EOF
}

list_tasks() {
  printf 'Available tasks:\n'
  local t
  for t in "${TASKS[@]}"; do printf '  %s\n' "$t"; done
}

run_tasks() {
  local t
  for t in "$@"; do
    if ! declare -F "task_${t}" >/dev/null; then
      log_error "Unknown task: ${t}"
      FAILED_TASKS+=("$t")
      continue
    fi
    log_step "${t}"
    # Isolate failures: one bad task shouldn't abort the whole run.
    if "task_${t}"; then
      log_ok "${t} complete."
    else
      log_error "${t} failed (continuing)."
      FAILED_TASKS+=("$t")
    fi
  done
}

main() {
  local -a requested=()

  while (( $# )); do
    case "$1" in
      --list)     list_tasks; exit 0 ;;
      --dry-run)  DRY_RUN=1; shift ;;
      --all-base) requested+=(upgrade bundle media_cli yazi autoremove); shift ;;
      -h|--help)  usage; exit 0 ;;
      -*)         log_error "Unknown option: $1"; usage; exit 1 ;;
      *)          requested+=("$1"); shift ;;
    esac
  done

  if (( ${#requested[@]} == 0 )); then
    usage
    exit 1
  fi

  preflight
  (( DRY_RUN )) && log_warn "DRY RUN — no changes will be made."

  run_tasks "${requested[@]}"

  log_step "Summary"
  if (( ${#FAILED_TASKS[@]} )); then
    log_error "Failed tasks: ${FAILED_TASKS[*]}"
  else
    log_ok "All requested tasks completed."
  fi

  if (( NEEDS_RESHELL )); then
    log_warn "~/.bashrc was modified. Open a new terminal or run: exec bash -l"
  fi

  log_info "Full log: ${LOG_FILE}"
  (( ${#FAILED_TASKS[@]} == 0 ))
}

main "$@"
