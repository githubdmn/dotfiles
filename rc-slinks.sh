#!/bin/bash

function create_links () {
	sudo ln -sv /home/dmn/dotfiles/nanorc /home/dmn/.nanorc;
	sudo ln -sv /home/dmn/dotfiles/vimrc /home/dmn/.vimrc;
	sudo ln -sv /home/dmn/dotfiles/bashrc /home/dmn/.bashrc;
	sudo ln -sv /home/dmn/dotfiles/tmux.conf /home/dmn/.tmux.conf;
	sudo ln -sv /home/dmn/dotfiles/terminalrc /home/dmn/.config/xfce4/terminal/terminalrc;
} 


function remove_files() {
	sudo rm -rv /home/dmn/.nanorc;
	sudo rm -rv /home/dmn/.vimrc;
	sudo rm -rv /home/dmn/.bashrc;
	sudo rm -rv /home/dmn/.tmux.conf;
	sudo rm -rv /home/dmn/.config/xfce4/terminal/terminalrc;
}


remove_files;
create_links;
