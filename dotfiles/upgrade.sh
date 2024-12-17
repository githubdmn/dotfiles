#! /bin/bash

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

# Main function to manage updates and upgrades
main() {
    # echo "This script will update and upgrade your system."
    # read -p "Do you want to proceed? (y/n): " answer

    # if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        upgrade
        autoremove
        echo "Update and upgrade completed successfully."
    # else
      # echo "Operation canceled."
    # fi
}

# Execute the main function
main