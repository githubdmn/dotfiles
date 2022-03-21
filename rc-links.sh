
#!/bin/bash

function create_links () {
	sudo ln -sv /home/private/dotfiles/nanorc /home/private/.nanorc;
	sudo ln -sv /home/private/dotfiles/vimrc /home/private/.vimrc;
	sudo ln -sv /home/private/dotfiles/zshrc /home/private/.zshrc;
} 


function remove_files() {
	sudo rm -rv /home/private/.nanorc;
	sudo rm -rv /home/private/.vimrc;
	sudo rm -rv /home/private/.zshrc;
}


remove_files;
create_links;