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
}

function prepare_terminal_theme() {
	echo "Setting up terminal theme..."
	mkdir -p ${HOME}/.local/share/xfce4/terminal/colorschemes
	cp -v ${HOME}/dotfiles/catppuccin/* ${HOME}/.local/share/xfce4/terminal/colorschemes
}

# Run the functions
remove_files
prepare_terminal_theme
create_links
