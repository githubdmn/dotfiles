
conf="${HOME}/.config"
mkdir -p "${conf}/nvim"
ln -sv "${HOME}/dotfiles/init.vim" "${conf}/nvim/init.vim"
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
