#!/bin/bash

# Dotfiles Installation Script
# This script creates symbolic links for configuration files and sets up themes

set -euo pipefail  # Exit on error, undefined variables, pipe failures

readonly USER="dmn"
readonly DOTFILES_DIR="${HOME}/dotfiles"
readonly BACKUP_DIR="${HOME}/dotfiles/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Backup existing files before removing
backup_files() {
    log_info "Creating backup of existing files in ${BACKUP_DIR}..."
    mkdir -p "${BACKUP_DIR}"
    
    local files_to_backup=(
        "${HOME}/.nanorc"
        "${HOME}/.vimrc"
        "${HOME}/.bashrc"
        "${HOME}/.tmux.conf"
        "${HOME}/.config/nvim/init.vim"
        "${HOME}/.config/xfce4/terminal/terminalrc"
        "${HOME}/.config/xfce4/panel/xfce4-clipman-actions.xml"
        "${HOME}/.config/Code/User/settings.json"
        "${HOME}/.config/VSCodium/User/settings.json"
        "${HOME}/.oh-my-bash/themes/lambda/lambda.theme.sh"
    )
    
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$file" ]]; then
            local backup_path="${BACKUP_DIR}${file}"
            mkdir -p "$(dirname "$backup_path")"
            cp -r "$file" "$backup_path" && log_info "Backed up: $file"
        fi
    done
    
    log_success "Backup completed in ${BACKUP_DIR}"
}

# Remove old configuration files
remove_files() {
    log_info "Removing old configuration files..."
    
    local files_to_remove=(
        "${HOME}/.nanorc"
        "${HOME}/.vimrc"
        "${HOME}/.bashrc"
        "${HOME}/.tmux.conf"
        "${HOME}/.config/nvim/init.vim"
        "${HOME}/.config/xfce4/terminal/terminalrc"
        "${HOME}/.config/xfce4/panel/xfce4-clipman-actions.xml"
        "${HOME}/.config/Code/User/settings.json"
        "${HOME}/.config/VSCodium/User/settings.json"
    )
    
    for file in "${files_to_remove[@]}"; do
        if [[ -e "$file" || -L "$file" ]]; then
            rm -rv "$file" && log_info "Removed: $file"
        fi
    done
}

# Create symbolic links for configuration files
create_links() {
    log_info "Creating symbolic links..."
    
    # Ensure target directories exist
    mkdir -p "${HOME}/.config/nvim"
    mkdir -p "${HOME}/.config/xfce4/terminal"
    mkdir -p "${HOME}/.config/xfce4/panel"
    mkdir -p "${HOME}/.config/Code/User"
    mkdir -p "${HOME}/.config/VSCodium/User"
    mkdir -p "${HOME}/.oh-my-bash/themes/lambda"
    
    # Array of source -> destination mappings
    local link_mappings=(
        "${DOTFILES_DIR}/config/rc/nanorc:${HOME}/.nanorc"        
        "${DOTFILES_DIR}/config/rc/vimrc:${HOME}/.vimrc"
        "${DOTFILES_DIR}/config/rc/init.vim:${HOME}/.config/nvim/init.vim"
        "${DOTFILES_DIR}/config/rc/bashrc:${HOME}/.bashrc"
        "${DOTFILES_DIR}/config/rc/tmux.conf:${HOME}/.tmux.conf"
        "${DOTFILES_DIR}/config/rc/terminalrc:${HOME}/.config/xfce4/terminal/terminalrc"
        "${DOTFILES_DIR}/config/rc/xfce4-panel/xfce4-clipman-actions.xml:${HOME}/.config/xfce4/panel/xfce4-clipman-actions.xml"
        "${DOTFILES_DIR}/vscode-backup/settings.json:${HOME}/.config/Code/User/settings.json"
        "${DOTFILES_DIR}/vscode-backup/settings.json:${HOME}/.config/VSCodium/User/settings.json"
        "${DOTFILES_DIR}/config/rc/lambda.theme.sh:${HOME}/.oh-my-bash/themes/lambda/lambda.theme.sh"
    )
    
    for mapping in "${link_mappings[@]}"; do
        local source="${mapping%%:*}"
        local destination="${mapping##*:}"
        
        if [[ ! -e "$source" ]]; then
            log_warning "Source file does not exist: $source"
            continue
        fi
        
        # Remove existing file/symlink if it exists
        if [[ -e "$destination" || -L "$destination" ]]; then
            rm -rf "$destination"
        fi
        
        # Create parent directory if it doesn't exist
        mkdir -p "$(dirname "$destination")"
        
        # Create symbolic link
        if ln -sv "$source" "$destination"; then
            log_success "Linked: $destination → $source"
        else
            log_error "Failed to link: $destination"
        fi
    done
}

# Set up terminal color schemes
prepare_terminal_theme() {
    log_info "Setting up terminal theme..."
    
    local colorschemes_dir="${HOME}/.local/share/xfce4/terminal/colorschemes"
    mkdir -p "$colorschemes_dir"
    
    if [[ -d "${DOTFILES_DIR}/catppuccin" ]]; then
        if cp -v "${DOTFILES_DIR}"/catppuccin/* "$colorschemes_dir"/ 2>/dev/null; then
            log_success "Terminal themes installed successfully"
        else
            log_warning "No terminal theme files found or copy failed"
        fi
    else
        log_warning "Terminal themes directory not found: ${DOTFILES_DIR}/catppuccin"
    fi
}

# Set up mousepad editor themes
prepare_mousepad_theme() {
    log_info "Setting up mousepad theme..."
    
    local styles_dir="${HOME}/.local/share/gtksourceview-4/styles"
    mkdir -p "$styles_dir"
    
    if [[ -d "${DOTFILES_DIR}/mousepad-themes" ]]; then
        for theme_file in "${DOTFILES_DIR}"/mousepad-themes/*; do
            if [[ -f "$theme_file" ]]; then
                local theme_name=$(basename "$theme_file")
                ln -sfv "$theme_file" "${styles_dir}/${theme_name}"
            fi
        done
        log_success "Mousepad themes linked successfully"
    else
        log_warning "Mousepad themes directory not found: ${DOTFILES_DIR}/mousepad-themes"
    fi
}

# Link autostart .desktop files
link_autostart_entries() {
    log_info "Linking autostart .desktop files..."
    
    local source_dir="${DOTFILES_DIR}/config/autostart"
    local dest_dir="${HOME}/.config/autostart"
    
    mkdir -p "$dest_dir"
    
    if [[ ! -d "$source_dir" ]]; then
        log_warning "Autostart source directory not found: $source_dir"
        return 1
    fi
    
    local linked_count=0
    for file in "$source_dir"/*.desktop; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            ln -sfv "$file" "${dest_dir}/${filename}"
            ((linked_count++))
        fi
    done
    
    if [[ $linked_count -gt 0 ]]; then
        log_success "Linked $linked_count autostart .desktop files"
    else
        log_warning "No .desktop files found in $source_dir"
    fi
}

# Verify dotfiles directory exists
verify_environment() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    
    log_info "Dotfiles directory: $DOTFILES_DIR"
    log_info "Backup directory: $BACKUP_DIR"
}

# Main execution function
main() {
    log_info "Starting dotfiles installation..."
    log_info "User: $USER"
    
    verify_environment
    backup_files
    remove_files
    prepare_terminal_theme
    prepare_mousepad_theme
    create_links
    link_autostart_entries
    
    log_success "Dotfiles installation completed successfully!"
    log_info "Backup created in: $BACKUP_DIR"
    log_info "You may need to restart your terminal or desktop session to see all changes."
}

# Run main function
main "$@"
