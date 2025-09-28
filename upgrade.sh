#!/usr/bin/env bash
set -euo pipefail

# Log file (user-writable)
LOG_FILE="$HOME/custom-update.log"


log() {
    local msg="$1"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

# Function to update the package index
update() {
    log "Updating package index..."
    sudo apt update | tee -a "$LOG_FILE"
}

# Function to upgrade installed packages safely
upgrade() {
    log "Upgrading installed packages..."
    update
    sudo apt upgrade -y | tee -a "$LOG_FILE"
}

# Function to remove unnecessary packages
autoremove() {
    log "Removing unnecessary packages..."
    sudo apt autoremove -y | tee -a "$LOG_FILE"
}

# Function to update Oh My Bash safely
update_oh_my_bash() {
    local OSH="${OSH:-$HOME/.oh-my-bash}"

    if [[ ! -d "$OSH" ]]; then
        log "Oh My Bash not found at $OSH. Skipping update."
        return 0
    fi

    log "Updating Oh My Bash..."

    # Remove stale lock file
    rm -f "${OSH}/log/update.lock"

    local stash_created=false

    pushd "$OSH" > /dev/null

    # Check for local modifications
    if ! git diff-index --quiet HEAD --; then
        log "Stashing local Oh My Bash modifications..."
        git stash push -m "Oh My Bash update stash $(date +%Y-%m-%d)"
        stash_created=true
    fi

    if git pull | tee -a "$LOG_FILE"; then
        if [[ "$stash_created" == true ]]; then
            log "Applying stashed changes..."
            if ! git stash pop | tee -a "$LOG_FILE"; then
                log "Conflict detected! Manual resolution required in $OSH"
                popd > /dev/null
                return 1
            fi
        fi
        log "Oh My Bash updated successfully."
        source "$OSH/oh-my-bash.sh"
    else
        log "Failed to update Oh My Bash"
        popd > /dev/null
        return 1
    fi

    popd > /dev/null
}


# CLEAR CACHE
# sudo rm -rf /var/lib/apt/lists/*


# Main function to manage updates and upgrades
main() {

    log "⚠️ #Clear cache sudo rm -rf /var/lib/apt/lists/*"

    log "Starting system and Oh My Bash update (auto-confirmed)..."

    local status=0

    if ! upgrade; then
        log "Package upgrade failed!"
        status=1
    fi

    if ! autoremove; then
        log "Autoremove failed!"
        status=1
    fi

    if ! update_oh_my_bash; then
        log "Oh My Bash update failed!"
        status=1
    fi

    if [[ $status -eq 0 ]]; then
        log "✅ All updates completed successfully."
    else
        log "⚠️ Some steps failed. Check the log at $LOG_FILE."
        exit 1
    fi
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
