#!/bin/bash
set -euo pipefail

# Configuration
BACKUP_DIR="$HOME/dotfiles/vscode-backup"
EXTENSIONS_FILE="$BACKUP_DIR/extensions.txt"
SETTINGS_DIR="$BACKUP_DIR/settings"
VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"

# Create backup directory
mkdir -p "$SETTINGS_DIR"

has_code_command() {
    command -v code >/dev/null 2>&1
}

install_vscode() {
    echo "Downloading VS Code..."
    temp_dir=$(mktemp -d)
    
    # Check system requirements
    os=$(uname -s)
    arch=$(uname -m)
    [ "$os" != "Linux" ] && echo "Unsupported OS: $os" && exit 1
    [ "$arch" != "x86_64" ] && echo "Unsupported architecture: $arch" && exit 1

    # Download and extract
    wget -O "$temp_dir/vscode.tar.gz" "$VSCODE_URL"
    tar -xzf "$temp_dir/vscode.tar.gz" -C "$temp_dir"
    
    # Add to PATH for current session
    extracted_dir="$temp_dir/$(tar -tzf "$temp_dir/vscode.tar.gz" | head -1 | cut -f1 -d"/")"
    export PATH="$extracted_dir:$PATH"
    
    echo "Temporary VS Code installation added to PATH"
    echo "For permanent installation, move this directory to your preferred location:"
    echo "$extracted_dir"
}

check_vscode() {
    if ! has_code_command; then
        read -p "VS Code not found. Download and temporary install? (y/n) " answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            install_vscode
            [ $? -ne 0 ] && exit 1
        else
            echo "VS Code required for extensions management"
            exit 1
        fi
    fi
}

backup() {
    check_vscode
    echo "Backing up extensions..."
    code --list-extensions > "$EXTENSIONS_FILE"
    
    echo "Backing up settings..."
    cp "$HOME/.config/Code/User/"*.json "$SETTINGS_DIR/"
    
    [ -d "$HOME/.config/Code/User/snippets" ] && \
        cp -r "$HOME/.config/Code/User/snippets" "$SETTINGS_DIR/"
    
    echo "Backup completed at: $BACKUP_DIR"
}

restore() {
    check_vscode
    echo "Restoring extensions..."
    [ -f "$EXTENSIONS_FILE" ] && \
        xargs -L 1 code --install-extension < "$EXTENSIONS_FILE"
    
    echo "Restoring settings..."
    mkdir -p "$HOME/.config/Code/User"
    cp "$SETTINGS_DIR/"*.json "$HOME/.config/Code/User/"
    
    [ -d "$SETTINGS_DIR/snippets" ] && \
        cp -r "$SETTINGS_DIR/snippets" "$HOME/.config/Code/User/"
    
    echo "Restore completed"
}

usage() {
    echo "Usage: $0 [backup|restore|help]"
    exit 1
}

main() {
    case "${1:-}" in
        backup) backup ;;
        restore) restore ;;
        help|*) usage ;;
    esac
}

[ $# -ne 1 ] && usage
main "$1"
