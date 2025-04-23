#!/bin/bash

# Function to update the package index
update() {
    echo "Updating package index..."
    sudo apt update
}

# Function to upgrade installed packages
upgrade() {
    echo "Upgrading installed packages..."
    update
    sudo apt full-upgrade -y
}

# Function to remove unnecessary packages
autoremove() {
    echo "Removing unnecessary packages..."
    sudo apt autoremove -y
}

# Function to update Oh My Bash
update_oh_my_bash() {
    # Set Oh My Bash directory
    local OSH="${OSH:-$HOME/.oh-my-bash}"
    
    # Check if Oh My Bash is installed
    if [[ ! -d "$OSH" ]]; then
        echo "Oh My Bash not found. Skipping update."
        return 0
    fi

    echo "Checking for Oh My Bash updates..."
    
    # Navigate to Oh My Bash directory
    if ! cd "$OSH"; then
        echo "Failed to enter Oh My Bash directory"
        return 1
    fi

    local stash_created=false
    
    # Check for local changes
    if ! git diff-index --quiet HEAD --; then
        echo "Stashing local Oh My Bash modifications..."
        git stash push -m "Oh My Bash update stash $(date +%Y-%m-%d)"
        stash_created=true
    fi

    # Perform the update
    if git pull; then
        if [[ "$stash_created" == true ]]; then
            echo "Applying stashed changes..."
            if ! git stash pop; then
                echo "Conflict detected! Manual resolution required in: $OSH"
                return 1
            fi
        fi
        echo "Oh My Bash updated successfully."
        # Source the updated version
        source "$OSH"/oh-my-bash.sh
    else
        echo "Failed to update Oh My Bash"
        return 1
    fi
}

# Main function to manage updates and upgrades
main() {
    # echo "This script will update and upgrade your system."
    # read -p "Do you want to proceed? (y/n): " answer

    # if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        upgrade
        autoremove
        update_oh_my_bash
        echo "Update and upgrade completed successfully."
    # else
    #   echo "Operation canceled."
    # fi
}

# Execute the main function
main
