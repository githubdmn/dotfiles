# install.sh — Software Inventory & Installation Methods
 
> Generated: 2026-10-07
> Source: `/srv/projekte/onboarding/damjan/dotfiles/install.sh`
 
---
 
## 1. apt / apt-get packages (direct install)
 
| # | Package(s) | Install Method | Function |
|---|-----------|---------------|----------|
| 1 | `build-essential`, `gdb` | `apt install build-essential gdb -y` | `install_build_essential()` |
| 2 | `unzip` | `apt install unzip -y` | `install_unzip()` |
| 3 | `curl` | `apt install curl -y` | `install_curl()` |
| 4 | `wget` | `apt update && apt install wget -y` | `install_wget()` |
| 5 | `apt-transport-https` | `apt install apt-transport-https -y` | `install_transport_https()` |
| 6 | `git` | `apt install git -y` | `install_git()` |
| 7 | `ssh` | `apt install ssh -y` | `install_ssh()` |
| 8 | `nano` | `apt install nano -y` | `install_nano()` |
| 9 | `tmux` | `apt install tmux -y` | `install_tmux()` |
| 10 | `vim` | `apt install vim -y` | `install_vim()` |
| 11 | `neovim` | `apt install neovim -y` | `install_neovim()` |
| 12 | **Bundle** (30+ packages) | `apt install -y <list>` | `install_bundle()` |
| 13 | `ffmpeg`, `poppler-utils`, `imagemagick`, `zoxide` | `apt install -y` | `install_media_cli()` |
| 14 | `hardinfo` | `apt install hardinfo -y` | `install_hardinfo()` |
| 15 | `vlc` | `apt install vlc -y` | `install_vlc()` |
| 16 | `brave-browser` | APT repo + `apt install -y` | `install_brave()` |
| 17 | `brave-browser` | `curl -fsS https://dl.brave.com/install.sh \| sh` | `install_brave_one_command()` |
| 18 | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` | APT repo + `apt install -y` | `install_docker_debian()`, `install_docker_debian_old()` |
| 19 | `podman`, `podman-compose` | `apt-get install -y` (requires root) | `install_podman()` |
| 20 | `bruno` | APT repo + `apt install -y` | `install_bruno()` |
 
### `install_bundle()` — full package list (34 packages)
 
```
build-essential  wget  curl  unzip  7zip  wl-clipboard  apt-transport-https
git  ssh  nano  tmux  vim  neovim  libssl-dev  zlib1g-dev  libbz2-dev
libreadline-dev  libsqlite3-dev  llvm  libncurses-dev  libfuse2t64
xz-utils  tk-dev  libxml2-dev  libxmlsec1-dev  libffi-dev  liblzma-dev
jq  ripgrep  fd-find  htop  tree  bat  fzf  mc  nnn  rsync  inxi
lshw  hardinfo  usbutils  fastfetch
```
 
---
 
## 2. External / Binary installs (not via apt)
 
| # | Software | Install Method | Function |
|---|---------|---------------|----------|
| 1 | **Neovim plugins** (vim-plug) | `curl` → `plug.vim` from GitHub | `install_neovim()` |
| 2 | **Yazi** file manager | GitHub release `.zip` → extract → `sudo mv` binaries to `/usr/local/bin/` | `install_yazi()` |
| 3 | **Zed** editor | `curl -fsSL https://zed.dev/install.sh \| sh` | `install_zed()` |
| 4 | **nvm** (Node Version Manager) | `wget -qO-` install script from GitHub | `install_nvm()` |
| 5 | **Deno** runtime | `curl -fsSL https://deno.land/install.sh \| sh` | `install_deno()` |
| 6 | **Oh My Bash** | `wget` install script from GitHub → `bash -c` | `install_ohmybash()` |
| 7 | **Dropbox** (GUI) | `wget` `.deb` from Dropbox → `tar xzf -` | `install_dropbox()` |
| 8 | **Dropbox** (headless) | `wget` tarball → `tar xzf -` → `nohup dropboxd` | `install_dropbox_headless()` |
| 9 | **Dropbox CLI** | `wget dropbox.py` → `chmod +x` → `mv ~/bin/dropbox` | `control_dropbox()` |
| 10 | **VS Code** | `wget` SHA download → `tar xzf -` | `install_vscode()` |
| 11 | **SQLite** (standalone) | `wget` from sqlite.org → `unzip` → `~/.sqlite/` → PATH in `.bashrc` | `install_sqlite()` |
| 12 | **Go** (1.23.1) | `wget` `.tar.gz` from go.dev → `tar -C $HOME` → PATH in `.bashrc` | `install_go()` |
| 13 | **Java** (OpenJDK 21+35) | `wget` `.tar.gz` from java.net → `tar -C $HOME` → `JAVA_HOME` + PATH in `.bashrc` | `install_java()` |
| 14 | **pyenv** (Python 3.12.1) | `curl https://pyenv.run \| bash` → `pyenv install 3.12.1` → `pyenv global` | `install_python()` |
| 15 | **Gradle** (8.10.2) | `wget` `.zip` from services.gradle.org → `unzip` → PATH in `.bashrc` | `install_gradle()` |
| 16 | **SDKMAN** | `curl -s "https://get.sdkman.io" \| bash` → `source` init script | `install_sdkman()` |
| 17 | **SDKMAN Java + Gradle** | `sdk install java` + `sdk install gradle` | `install_sdkman_java_gradle()` |
| 18 | **MEGA client** | `wget` `.deb` from mega.nz → `apt install ./package.deb` | `install_mega_client()` |
| 19 | **VSCodium** | GitHub release `.tar.gz` → extract → `~/.local/opt/VSCodium` → symlink + desktop entry | `install_vscodium()` / `install_vscodium_latest()` |
 
---
 
## 3. System-level operations
 
| # | Operation | Function |
|---|-----------|----------|
| 1 | `apt update` + `apt full-upgrade -y` | `upgrade()` |
| 2 | `apt autoremove -y` | `autoremove()` |
| 3 | `sudo usermod -aG docker $USER` | `install_docker_debian()` |
| 4 | `sudo systemctl enable docker` + `start` | `install_docker_debian()` |
| 5 | `ssh-keygen -t rsa -b 4096` (interactive) | `generate_rsa_key()` |
| 6 | `pkill -x codium` (stop running instances) | `install_vscodium()` |
 
---
 
## 4. Dotfile / config operations
 
| # | Action | Function |
|---|--------|----------|
| 1 | `mkdir -p ~/.config/nvim` + `ln -s` to `init.vim` | `install_neovim()` |
| 2 | Append `PYENV_ROOT`, `PATH`, `eval "$(pyenv init --path)"` to `.bashrc` | `install_python()` |
| 3 | Append `JAVA_HOME`, `PATH` to `.bashrc` | `install_java()` |
| 4 | Append `PATH=$PATH:$HOME/go/bin` to `.bashrc` | `install_go()` |
| 5 | Append `PATH=$PATH:$HOME/gradle/gradle-*/bin` to `.bashrc` | `install_gradle()` |
| 6 | Append `DENO_INSTALL`, `PATH` to `.bashrc` | `install_deno()` |
| 7 | Create `~/.local/share/applications/vscodium.desktop` | `install_vscodium()` |
 
---
 
## 5. Summary counts
 
| Category | Count |
|----------|-------|
| apt packages (individual) | ~16 functions |
| apt packages (bundle) | 34 packages in 1 call |
| External/binary installs | 19 functions |
| System operations | 6 |
| Dotfile/config operations | 7 |
| **Total functions** | **~43** |