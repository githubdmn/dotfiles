
#!/bin/bash

function create_links () {
	sudo ln -sv /Users/private/dotfiles/nanorc /Users/private/.nanorc;
	sudo ln -sv /Users/private/dotfiles/vimrc /Users/private/.vimrc;
	sudo ln -sv /Users/private/dotfiles/zshrc /Users/private/.zshrc;
} 


function remove_files() {
	sudo rm -rv /Users/private/.nanorc;
	sudo rm -rv /Users/private/.vimrc;
	sudo rm -rv /Users/private/.zshrc
}


remove_files;
create_links;