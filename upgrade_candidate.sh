#!/usr/bin/env bash
#
# Dotfiles linker: symlinks configs from ~/dotfiles into place.
#
# Usage:
#   ./rc-slinks.sh             link everything
#   ./rc-slinks.sh --dry-run   show what would happen, change nothing
#
# Safe to re-run. For every destination the script:
#   1. skips it if it is already the correct symlink
#   2. leaves it completely alone if the dotfiles source is missing
#   3. otherwise backs it up FIRST, and only then replaces it
#
# Environment overrides: DOTFILES_DIR, OSH, OSH_CUSTOM, XDG_STATE_HOME

set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/dotfiles}"

# Backups live outside the repo. The original put them inside ~/dotfiles,
# where `git add -A` would eventually commit a copy of your old configs.
BACKUP_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

DRY_RUN=0
BACKUP_USED=0
N_LINKED=0
N_OK=0
N_SKIPPED=0
N_BACKED_UP=0

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'; NC=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

log_info()    { printf '%s[INFO]%s    %s\n'  "$BLUE"   "$NC" "$*"; }
log_success() { printf '%s[SUCCESS]%s %s\n'  "$GREEN"  "$NC" "$*"; }
log_warning() { printf '%s[WARNING]%s %s\n'  "$YELLOW" "$NC" "$*" >&2; }
log_error()   { printf '%s[ERROR]%s   %s\n'  "$RED"    "$NC" "$*" >&2; }

on_error() {
  local code=$? line=$1
  log_error "Aborted at line ${line} (exit ${code}). Nothing is removed before its backup succeeds."
  if (( BACKUP_USED )); then log_error "Backups so far: ${BACKUP_DIR}"; fi
}
trap 'on_error $LINENO' ERR

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

run() {
  if (( DRY_RUN )); then
    log_info "[dry-run] $*"
  else
    "$@"
  fi
}

# Back up whatever currently sits at $1. Preserves symlinks as symlinks
# (cp -a), so a pre-existing link's original target is recorded.
backup_existing() {
  local dest="$1" rel bpath

  if [[ "$dest" == "${HOME}"/* ]]; then
    rel="${dest#"${HOME}"/}"
  else
    rel="_root${dest}"
  fi
  bpath="${BACKUP_DIR}/${rel}"

  if (( DRY_RUN )); then
    log_info "[dry-run] back up ${dest} -> ${bpath}"
    return 0
  fi

  mkdir -p -- "$(dirname -- "$bpath")"
  cp -a -- "$dest" "$bpath"
  BACKUP_USED=1
  N_BACKED_UP=$(( N_BACKED_UP + 1 ))
  log_info "Backed up: ${dest}"
}

# link_file SOURCE DEST
link_file() {
  local src="$1" dest="$2"

  # Source missing: do NOT touch the destination. The original deleted your
  # live config in a separate pass first, then discovered the source was
  # missing and left you with nothing.
  if [[ ! -e "$src" ]]; then
    log_warning "Source missing, leaving destination untouched: ${src}"
    N_SKIPPED=$(( N_SKIPPED + 1 ))
    return 0
  fi

  # Already correct: nothing to do, and no pointless backup of a symlink.
  if [[ -L "$dest" ]] && [[ "$(readlink -f -- "$dest")" == "$(readlink -f -- "$src")" ]]; then
    log_info "Already linked: ${dest}"
    N_OK=$(( N_OK + 1 ))
    return 0
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    # install.sh appends marked blocks (nvm, pyenv, go, ...) to ~/.bashrc.
    # Replacing .bashrc drops them from the live shell, so say so.
    if [[ -f "$dest" && ! -L "$dest" && "$(basename -- "$dest")" == ".bashrc" ]]; then
      if grep -q '(install.sh) >>>' "$dest" 2>/dev/null; then
        log_warning "~/.bashrc contains install.sh blocks (PATH/nvm/pyenv/...). They will not be active after relinking; see backup."
      fi
    fi

    backup_existing "$dest"   # must succeed (set -e) before anything is removed
    run rm -rf -- "$dest"
  fi

  run mkdir -p -- "$(dirname -- "$dest")"
  run ln -s -- "$src" "$dest"
  log_success "Linked: ${dest} -> ${src}"
  N_LINKED=$(( N_LINKED + 1 ))
}

# link_tree SRC_DIR DEST_DIR GLOB LABEL
# Links every entry in SRC_DIR matching GLOB into DEST_DIR.
link_tree() {
  local src_dir="$1" dest_dir="$2" pattern="$3" label="$4"

  if [[ ! -d "$src_dir" ]]; then
    log_warning "${label}: source directory not found: ${src_dir}"
    return 0
  fi

  local -a entries=()
  shopt -s nullglob
  # shellcheck disable=SC2206  # glob expansion of $pattern is intentional
  entries=("${src_dir}"/$pattern)
  shopt -u nullglob

  if (( ${#entries[@]} == 0 )); then
    log_warning "${label}: nothing matching '${pattern}' in ${src_dir}"
    return 0
  fi

  local entry
  for entry in "${entries[@]}"; do
    link_file "$entry" "${dest_dir}/$(basename -- "$entry")"
  done
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

verify_environment() {
  if [[ $EUID -eq 0 ]]; then
    log_error "Do not run as root; this would link into /root instead of your home."
    exit 1
  fi
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "Dotfiles directory not found: ${DOTFILES_DIR}"
    exit 1
  fi
  log_info "Dotfiles: ${DOTFILES_DIR}"
  log_info "Backups:  ${BACKUP_DIR} (created only if something is replaced)"
}

link_core_configs() {
  log_info "Linking core configs..."
  local rc="${DOTFILES_DIR}/config/rc"

  link_file "${rc}/nanorc"     "${HOME}/.nanorc"
  link_file "${rc}/vimrc"      "${HOME}/.vimrc"
  link_file "${rc}/init.vim"   "${HOME}/.config/nvim/init.vim"
  link_file "${rc}/bashrc"     "${HOME}/.bashrc"
  link_file "${rc}/tmux.conf"  "${HOME}/.tmux.conf"

  link_file "${rc}/terminalrc" \
            "${HOME}/.config/xfce4/terminal/terminalrc"
  link_file "${rc}/xfce4-panel/xfce4-clipman-actions.xml" \
            "${HOME}/.config/xfce4/panel/xfce4-clipman-actions.xml"

  link_file "${DOTFILES_DIR}/vscode-backup/settings.json" \
            "${HOME}/.config/Code/User/settings.json"
  link_file "${DOTFILES_DIR}/vscode-backup/settings.json" \
            "${HOME}/.config/VSCodium/User/settings.json"
}

link_themes() {
  log_info "Linking terminal / editor themes..."
  link_tree "${DOTFILES_DIR}/catppuccin" \
            "${HOME}/.local/share/xfce4/terminal/colorschemes" '*' "Terminal themes"
  link_tree "${DOTFILES_DIR}/mousepad-themes" \
            "${HOME}/.local/share/gtksourceview-4/styles" '*' "Mousepad themes"
}

link_autostart() {
  log_info "Linking autostart entries..."
  link_tree "${DOTFILES_DIR}/config/autostart" \
            "${HOME}/.config/autostart" '*.desktop' "Autostart"
}

link_applications() {
  log_info "Linking application launchers..."
  local dest="${HOME}/.local/share/applications"

  link_tree "${DOTFILES_DIR}/config/_local_share_applications" \
            "$dest" '*.desktop' "Applications"

  # Refresh the desktop MIME/launcher cache so new entries show up in menus.
  if (( ! DRY_RUN )) && (( N_LINKED > 0 )) && command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$dest" 2>/dev/null || true
  fi
}

# Oh My Bash looks for themes in $OSH_CUSTOM/<name>/ and $OSH_CUSTOM/themes/<name>/
# BEFORE $OSH/themes/<name>/, so a custom theme overrides the stock one without
# touching the git checkout.
#
# The original symlinked straight over themes/lambda/lambda.theme.sh, which is
# a tracked file: that leaves the repo permanently dirty, makes every
# `git pull` stash and pop it, and conflicts whenever upstream edits the theme.
# It also did `mkdir -p ~/.oh-my-bash/...` unconditionally, which creates a
# stub directory that makes the real Oh My Bash installer refuse to clone.
link_oh_my_bash_theme() {
  local osh="${OSH:-${HOME}/.oh-my-bash}"
  local src="${DOTFILES_DIR}/config/rc/lambda.theme.sh"

  if [[ ! -d "$osh" ]]; then
    log_warning "Oh My Bash not installed at ${osh}; skipping theme (not creating the directory)."
    return 0
  fi

  # Migrate from the old layout: put the stock file back if v1 linked over it.
  local legacy="${osh}/themes/lambda/lambda.theme.sh"
  if [[ -L "$legacy" ]] && [[ "$(readlink -f -- "$legacy")" == "$(readlink -f -- "$src")" ]]; then
    log_info "Restoring stock lambda theme overwritten by an earlier run..."
    if [[ -d "${osh}/.git" ]]; then
      run git -C "$osh" checkout -- themes/lambda/lambda.theme.sh \
        || log_warning "Could not restore ${legacy}; run: git -C ${osh} checkout -- themes/lambda/lambda.theme.sh"
    else
      log_warning "${osh} is not a git checkout; remove the old symlink ${legacy} manually."
    fi
  fi

  local custom="${OSH_CUSTOM:-${osh}/custom}"
  link_file "$src" "${custom}/themes/lambda/lambda.theme.sh"
}

print_summary() {
  printf '\n'
  log_info "Linked: ${N_LINKED}   Already correct: ${N_OK}   Skipped (missing source): ${N_SKIPPED}   Backed up: ${N_BACKED_UP}"
  if (( BACKUP_USED )); then
    log_info "Backups are in: ${BACKUP_DIR}"
  fi
  if (( N_SKIPPED > 0 )); then
    log_warning "Skipped destinations were left exactly as they were."
  fi
  if (( DRY_RUN )); then
    log_warning "DRY RUN: nothing was changed."
  fi
  log_info "Restart your terminal or desktop session to pick up all changes."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

usage() {
  sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

main() {
  while (( $# )); do
    case "$1" in
      -n|--dry-run) DRY_RUN=1; shift ;;
      -h|--help)    usage; exit 0 ;;
      *)            log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  log_info "Starting dotfiles installation for ${USER:-$(id -un)}..."
  verify_environment
  link_core_configs
  link_themes
  link_autostart
  link_applications
  link_oh_my_bash_theme
  print_summary
}

main "$@"