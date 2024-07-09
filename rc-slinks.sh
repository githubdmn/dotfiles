#!/bin/bash

user=dmn

function create_links () {
	sudo ln -sv ${HOME}/dotfiles/nanorc ${HOME}/.nanorc;
	sudo ln -sv ${HOME}/dotfiles/vimrc ${HOME}/.vimrc;
	sudo ln -sv ${HOME}/dotfiles/bashrc ${HOME}/.bashrc;
	sudo ln -sv ${HOME}/dotfiles/tmux.conf ${HOME}/.tmux.conf;
	sudo ln -sv ${HOME}/dotfiles/terminalrc ${HOME}/.config/xfce4/terminal/terminalrc;
} 


function remove_files() {
	sudo rm -rv ${HOME}/.nanorc;
	sudo rm -rv ${HOME}/.vimrc;
	sudo rm -rv ${HOME}/.bashrc;
	sudo rm -rv ${HOME}/.tmux.conf;
	sudo rm -rv ${HOME}/.config/xfce4/terminal/terminalrc;
}

function prepare_terminal_theme() {
	sudo mkdir -p ${HOME}/.local/share/xfce4/terminal/colorschemes
	sudo cp -v ${HOME}/dotfiles/catppuccin/* ${HOME}/.local/share/xfce4/terminal/colorschemes
}

remove_files;
prepare_terminal_theme;
create_links;
