
#!/bin/bash

function create_links () {
	sudo ln -sv /Users/damjan/dotfiles/nanorc /Users/damjan/.nanorc;
	sudo ln -sv /Users/damjan/dotfiles/vimrc /Users/damjan/.vimrc;
	sudo ln -sv /Users/damjan/dotfiles/zshrc /Users/damjan/.zshrc;
} 


function remove_files() {
	sudo rm -rv /Users/damjan/.nanorc;
	sudo rm -rv /Users/damjan/.vimrc;
	sudo rm -rv /Users/damjan/.zshrc
}


remove_files;
create_links;