#!/bin/bash

update() { sudo apt update; }
upgrade() {
		update;
		sudo apt full-upgrade -y; 
}
autoremove() { sudo apt autoremove -y; }

build_essential() { sudo apt install build-essential -y; }
curl() { sudo apt install curl -y; }
apt_transport_https() { sudo apt install apt-transport-https -y;}
git() { sudo apt install git -y; }
ssh() { sudo apt install ssh -y; }
nano() { sudo apt install nano -y; }
tmux() { sudo apt install tmux -y; }
vim() { sudo apt install vim -y; }
neovim() { sudo apt install neovim -y; }
nvm() {
	wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash;	
}
ohmybash() {
	bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)";
}
vlc() { sudo apt install vlc -y; }
brave() {
	sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg;
	echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list;
	update;
	sudo apt install brave-browser;
}
dropbox() { wget -O ~/ - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -; }
vscode () {
	wget -O ~/Downloads https://code.visualstudio.com/sha/download?build=stable&os=linux-x64 | tar xzf -;
}
ffmpeg(){ sudo apt install ffmpeg; }

upgrade
build_essential
curl
apt_transport_https 
git
ssh
nano
tmux
vim
neovim
nvm
ohmybash
vlc
brave
dropbox
ffmpeg
upgrade
autoremove
