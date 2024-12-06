#!/bin/bash

user=dmn

function create_links() {
	echo "Creating symbolic links..."
	# Create symlinks for configuration files
	ln -sv ${HOME}/dotfiles/nanorc ${HOME}/.nanorc
	ln -sv ${HOME}/dotfiles/vimrc ${HOME}/.config/nvim/init.vim
	ln -sv ${HOME}/dotfiles/bashrc ${HOME}/.bashrc
	ln -sv ${HOME}/dotfiles/tmux.conf ${HOME}/.tmux.conf
	ln -sv ${HOME}/dotfiles/terminalrc ${HOME}/.config/xfce4/terminal/terminalrc
	ln -sv ${HOME}/dotfiles/xfce4-panel/netload-7.rc ${HOME}/.config/xfce4/panel/netload-7.rc
	ln -sv ${HOME}/dotfiles/xfce4-panel/xfce4-clipman-actions.xml ${HOME}/.config/xfce4/panel/xfce4-clipman-actions.xml

	# Ensure that your custom lambda.theme.sh is used, even after git pull
	echo "Ensuring custom theme is used..."
	# Backup the existing theme (optional)
	if [ -f ~/.oh-my-bash/themes/lambda/lambda.theme.sh ]; then
		echo "Backing up existing lambda.theme.sh..."
		mv ~/.oh-my-bash/themes/lambda/lambda.theme.sh ~/.oh-my-bash/themes/lambda/lambda.theme.sh.bak
	fi

	# Create a symlink to your dotfiles theme
	echo "Creating symlink for lambda.theme.sh..."
	ln -sf ~/dotfiles/lambda.theme.sh ~/.oh-my-bash/themes/lambda/lambda.theme.sh
}

function remove_files() {
	echo "Removing old configuration files..."
	rm -rv ${HOME}/.nanorc
	rm -rv ${HOME}/.vimrc
	rm -rv ${HOME}/.bashrc
	rm -rv ${HOME}/.tmux.conf
	rm -rv ${HOME}/.config/xfce4/terminal/terminalrc
	rm -rv ${HOME}/.config/xfce4/panel
}

function prepare_terminal_theme() {
	echo "Setting up terminal theme..."
	mkdir -p ${HOME}/.local/share/xfce4/terminal/colorschemes
	cp -v ${HOME}/dotfiles/catppuccin/* ${HOME}/.local/share/xfce4/terminal/colorschemes
}

#!/bin/bash

function link_autostart_entries() {
  echo "Linking autostart .desktop files..."

  # Source directory containing the .desktop files
  local source_dir="${HOME}/dotfiles/config/autostart"
  # Destination directory for autostart files
  local dest_dir="${HOME}/.config/autostart"

  # Ensure the destination directory exists
  mkdir -p "$dest_dir"

  # Check if the source directory exists
  if [ ! -d "$source_dir" ]; then
    echo "Source directory '$source_dir' does not exist. Please check the path."
    return 1
  fi

  # Iterate over all .desktop files in the source directory
  for file in "$source_dir"/*.desktop; do
    # Check if there are any .desktop files
    if [ -e "$file" ]; then
      # Create a symbolic link in the destination directory
      ln -sfv "$file" "$dest_dir/"
    else
      echo "No .desktop files found in '$source_dir'."
    fi
  done

  echo "Autostart .desktop files linked successfully."
}

remove_files
prepare_terminal_theme
create_links
link_autostart_entries
