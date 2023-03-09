#!/bin/bash

user=dmn

function create_links () {
	sudo ln -sv ${HOME}/dotfiles/nanorc ${HOME}/.nanorc;
	sudo ln -sv ${HOME}/dotfiles/vimrc ${HOME}/.vimrc;
	sudo ln -sv ${HOME}/bashrc ${HOME}/.bashrc;
	sudo ln -sv ${HOME}/tmux.conf ${HOME}/.tmux.conf;
	sudo ln -sv ${HOME}/terminalrc ${HOME}/.config/xfce4/terminal/terminalrc;
} 


function remove_files() {
	sudo rm -rv ${HOME}/.nanorc;
	sudo rm -rv ${HOME}/.vimrc;
	sudo rm -rv ${HOME}/.bashrc;
	sudo rm -rv ${HOME}/.tmux.conf;
	sudo rm -rv ${HOME}/.config/xfce4/terminal/terminalrc;
}


remove_files;
create_links;
