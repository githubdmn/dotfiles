#!/usr/bin/env bash
set -euo pipefail

# ==========================
# --- Logging functions ---
# ==========================
log_info()  { echo -e "\n[INFO]  $1"; }
log_warn()  { echo -e "\n[WARN]  $1"; }
log_error() { echo -e "\n[ERROR] $1" >&2; }

# =========================================================
# --- Shared helper: download and extract tarball safely ---
# =========================================================
download_and_extract() {
    local url="$1"
    local temp_dir
    temp_dir=$(mktemp -d)

    local archive="$temp_dir/package.tar.gz"
    log_info "Downloading package from $url ..."
    if ! curl -sSLf -o "$archive" "$url"; then
        rm -rf "$temp_dir"
        log_error "Download failed from $url"
        return 1
    fi

    if [ ! -s "$archive" ]; then
        rm -rf "$temp_dir"
        log_error "Downloaded file is empty or corrupted."
        return 1
    fi

    log_info "Extracting package..."
    if ! tar -xzf "$archive" -C "$temp_dir" >/dev/null 2>&1; then
        rm -rf "$temp_dir"
        log_error "Extraction failed."
        return 1
    fi

    echo "$temp_dir"
}

# =====================
# --- Discord update ---
# =====================
update_discord() {
    local install_dir="$HOME/.local/opt/Discord"
    local discord_url="https://discord.com/api/download?platform=linux&format=tar.gz"

    log_info "Starting Discord update process..."

    # Create temp dir
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Download
    log_info "Downloading the latest Discord package..."
    if ! curl -sSLf -o "$temp_dir/discord.tar.gz" "$discord_url"; then
        rm -rf "$temp_dir"
        log_error "Failed to download Discord."
        return 1
    fi

    # Check file is not empty
    if [ ! -s "$temp_dir/discord.tar.gz" ]; then
        rm -rf "$temp_dir"
        log_error "Downloaded file is empty. Aborting."
        return 1
    fi

    # Extract
    log_info "Extracting package..."
    if ! tar -xzf "$temp_dir/discord.tar.gz" -C "$temp_dir"; then
        rm -rf "$temp_dir"
        log_error "Failed to extract package."
        return 1
    fi

    local extracted_dir="$temp_dir/Discord"
    if [ ! -d "$extracted_dir" ]; then
        rm -rf "$temp_dir"
        log_error "Extracted directory 'Discord' not found."
        return 1
    fi

    # Stop running instances
    log_info "Stopping running Discord instances..."
    pkill -x discord || true

    # Remove previous installation if it exists
    if [ -d "$install_dir" ]; then
        log_info "Removing previous installation..."
        rm -rf "$install_dir"
    fi

    # Create installation directory
    mkdir -p "$install_dir"

    # Install
    log_info "Installing new Discord version..."
    mv "$extracted_dir"/* "$install_dir/"

    # Clean up temp directory
    log_info "Cleaning up temporary files..."
    rm -rf "$temp_dir"

    log_info "Discord has been successfully updated!"
}

# =====================
# --- Postman update ---
# =====================
update_postman() {

  # --- Function to update Postman ---
  # --- Configuration ---
  POSTMAN_INSTALL_DIR="$HOME/.local/opt/Postman"
  POSTMAN_APP_DIR="$HOME/.local/share/applications"
  POSTMAN_ICON_DIR="$HOME/.local/share/icons"
  POSTMAN_URL="https://dl.pstmn.io/download/latest/linux_64"

    log_info "Updating Postman..."

    # Check if Postman is installed
    if [ ! -d "$POSTMAN_INSTALL_DIR" ]; then
        log_info "Postman is not installed. Installing now..."
        install_postman
        return $?
    fi

    # Check dependencies
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed. Please install curl."
        return 1
    fi

    # Create temp dir
    local temp_dir
    temp_dir=$(mktemp -d)

    # Download
    log_info "Downloading latest Postman package..."
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

    # Remove previous installation
    log_info "Removing previous installation..."
    rm -rf "$POSTMAN_INSTALL_DIR"
    mkdir -p "$POSTMAN_INSTALL_DIR"

    # Install
    log_info "Installing new version..."
    if ! mv "$extracted_dir"/* "$POSTMAN_INSTALL_DIR/"; then
        rm -rf "$temp_dir"
        log_error "Failed to move files to installation directory."
        return 1
    fi

    # Set executable permissions
    if [ -f "$POSTMAN_INSTALL_DIR/Postman" ]; then
        chmod +x "$POSTMAN_INSTALL_DIR/Postman" || log_warn "Failed to set executable permissions"
    fi

    # Update desktop entry
    # create_postman_desktop_entry "$POSTMAN_INSTALL_DIR" "$POSTMAN_APP_DIR"

    # Clean up temp directory
    log_info "Cleaning up temporary files..."
    rm -rf "$temp_dir"

    log_info "Postman updated successfully!"
    log_info "Installation directory: $POSTMAN_INSTALL_DIR"
}

# ==========================
# Utility Functions
# ==========================

log_info() { echo -e "[INFO]  $*"; }
log_error() { echo -e "[ERROR] $*" >&2; }
download_and_extract() {
    local url="$1"
    local temp_dir
    temp_dir=$(mktemp -d)
    log_info "Downloading from $url ..."
    wget -qO "$temp_dir/archive.tar.gz" "$url"
    log_info "Extracting package..."
    tar -xzf "$temp_dir/archive.tar.gz" -C "$temp_dir" || true
    echo "$temp_dir"
}

# ==========================
# VS Code
# ==========================

# More robust version with better error handling
install_vscode() {
    set -euo pipefail  # Exit on error, undefined variable, or pipe failure
    
    local install_dir="$HOME/.local/opt/VSCode"
    local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
    local temp_dir=""

    # Cleanup function
    cleanup() {
        if [[ -n "$temp_dir" ]] && [[ -d "$temp_dir" ]]; then
            rm -rf "$temp_dir"
        fi
    }
    trap cleanup EXIT INT TERM

    echo "[INFO] Starting VS Code installation/update..."
    
    # Create temp directory
    temp_dir=$(mktemp -d)

    # Download
    echo "[INFO] Downloading VS Code..."
    if ! wget -q --show-progress -O "$temp_dir/vscode.tar.gz" "$vscode_url"; then
        echo "[ERROR] Failed to download VS Code."
        return 1
    fi

    # Verify download
    if [[ ! -s "$temp_dir/vscode.tar.gz" ]]; then
        echo "[ERROR] Downloaded file is empty"
        return 1
    fi

    # Extract
    echo "[INFO] Extracting archive..."
    if ! tar -xzf "$temp_dir/vscode.tar.gz" -C "$temp_dir" --strip-components=1; then
        echo "[ERROR] Failed to extract VS Code archive."
        return 1
    fi

    # Verify extraction
    if [[ ! -f "$temp_dir/bin/code" ]] && [[ ! -f "$temp_dir/code" ]]; then
        echo "[ERROR] VS Code binary not found after extraction"
        return 1
    fi

    # Stop running instances
    echo "[INFO] Stopping running VS Code instances..."
    pkill -x code 2>/dev/null || true
    sleep 1

    # Install
    echo "[INFO] Installing VS Code..."
    rm -rf "$install_dir"
    mkdir -p "$install_dir"
    cp -r "$temp_dir"/* "$install_dir/"

    # Create symlink
    mkdir -p "$HOME/.local/bin"
    if [[ -f "$install_dir/bin/code" ]]; then
        ln -sf "$install_dir/bin/code" "$HOME/.local/bin/code"
    else
        ln -sf "$install_dir/code" "$HOME/.local/bin/code"
    fi
    chmod +x "$HOME/.local/bin/code"

    # Desktop integration
    echo "[INFO] Creating desktop entry..."
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/code.desktop" <<EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=$HOME/.local/bin/code %F
Icon=$install_dir/resources/app/resources/linux/code.png
Type=Application
Terminal=false
Categories=Development;IDE;TextEditor;
StartupNotify=true
StartupWMClass=Code
MimeType=text/plain;application/json;text/x-python;text/markdown;application/x-shellscript;
EOF

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    echo "[SUCCESS] VS Code installed successfully!"
    echo "          Launch with: code"
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
    
    # Cleanup function
    cleanup() {
        if [[ -n "$temp_dir" ]] && [[ -d "$temp_dir" ]]; then
            echo "[INFO] Cleaning up temporary files..."
            rm -rf "$temp_dir"
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

# Combined installer with version options
install_vscodium_installer() {
    local version="${1:-}"
    
    if [[ -z "$version" ]]; then
        echo "Choose VSCodium installation option:"
        echo "  1) Install version 1.105.17075 (default)"
        echo "  2) Install latest version (auto-fetch)"
        echo "  3) Specify custom version"
        echo
        read -rp "Enter your choice [1-3]: " choice
        
        case "$choice" in
            1)
                install_vscodium "1.105.17075"
                ;;
            2)
                install_vscodium_latest
                ;;
            3)
                read -rp "Enter version number (e.g., 1.105.17075): " custom_version
                if [[ -z "$custom_version" ]]; then
                    echo "[ERROR] Version cannot be empty"
                    return 1
                fi
                install_vscodium_robust "$custom_version"
                ;;
            *)
                echo "[ERROR] Invalid choice"
                return 1
                ;;
        esac
    else
        # Version was provided as argument
        if [[ "$version" == "latest" ]]; then
            install_vscodium_latest
        else
            install_vscodium_robust "$version"
        fi
    fi
}

# Simple uninstaller
uninstall_vscodium() {
    local install_dir="$HOME/.local/opt/VSCodium"
    
    echo "[INFO] Uninstalling VSCodium..."
    
    # Stop running instances
    pkill -x codium 2>/dev/null || true
    sleep 1
    
    # Remove files
    [[ -L "$HOME/.local/bin/codium" ]] && rm -f "$HOME/.local/bin/codium" && echo "✓ Removed symlink"
    [[ -f "$HOME/.local/share/applications/vscodium.desktop" ]] && rm -f "$HOME/.local/share/applications/vscodium.desktop" && echo "✓ Removed desktop entry"
    [[ -d "$install_dir" ]] && rm -rf "$install_dir" && echo "✓ Removed installation directory"
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    echo "[SUCCESS] VSCodium uninstalled"
}

# =====================
# --- Dispatcher ---
# =====================
main() {
    local cmd="${1:-update-all}"

    case "$cmd" in
        discord) update_discord ;;
        postman) update_postman ;;
        vscode|code) install_vscode ;;
        vscodium) update_vscodium ;;
        update-all)
            log_info "No command specified. Running update-all..."
            update_discord
            update_postman
            install_vscode
            install_vscodium_latest
            ;;
        *)
            log_error "Unknown command: $cmd"
            echo "Usage: $0 [discord|postman|vscode|vscodium|update-all]"
            exit 1
            ;;
    esac
}

main "${1:-}"
