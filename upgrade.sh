#! /bin/bash

update() { sudo apt update; }
upgrade() {
		update;
		sudo apt full-upgrade -y;
}
autoremove() { sudo apt autoremove -y; }

upgrade
autoremove
