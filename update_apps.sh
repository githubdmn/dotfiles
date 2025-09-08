#!/usr/bin/env bash

set -euo pipefail

# --- Logging functions ---
log_info()  { echo -e "\n[INFO]  $1"; }
log_error() { echo -e "\n[ERROR] $1" >&2; }

# --- Function definition ---
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

# --- Call function if script is run directly ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    update_discord
fi
