"neovim settings
syntax enable
set wrap
set cursorline
set cursorcolumn
set ruler
set rulerformat=%50(%{strftime('%A\ %e.%B\ %I:%M\%p')}\ %5l,%-6(%c%V%)\ %P%)
set showcmd
set wildmenu
set wildmode=longest,list
set scrolloff=5
set hlsearch
set incsearch
set ignorecase
set smartcase
set noswapfile
set number
set lbr
set cc=80
set ai
set si
set expandtab
set tabstop=2
set shiftwidth=2
set backspace=indent,eol,start
set clipboard+=unnamedplus
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" |-> Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
Plugin 'preservim/nerdtree'
Plugin 'eslint/eslint'
Plugin 'dracula/vim',{'name': 'dracula'} 
Plugin 'sonph/onehalf', { 'rtp': 'vim' }
Plugin 'chriskempson/base16-vim'
Plugin 'gosukiwi/vim-atom-dark'
Plugin 'NLKNguyen/papercolor-theme'
Plugin 'myhere/vim-nodejs-complete'
Plugin 'leafgarland/typescript-vim'
Plugin 'pangloss/vim-javascript'
Plugin 'fatih/vim-go'
Plugin 'c.vim'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" <CR> / <ENTER> -> Enter

"mkdir -p ~/.vim/pack/themes/start && cd ~/.vim/pack/themes/start
"git clone https://github.com/dracula/vim.git dracula


" <BS> -> Backspace
"
nnoremap <C-a> :NERDTreeRefreshRoot<CR>:NERDTreeToggle<CR> 
"nnoremap <C-q> :q!<CR>
"nnoremap <C-w> :wq<CR>
"nnoremap <C-s> :w<CR>
" Map save in isert mode
inoremap <C-a> <C-o>:NERDTreeToggle<CR>:NERDTreeRefreshRoot<CR>
"inoremap 
"inoremap <C-q> <C-o>:q!<CR>
"inoremap <C-w> <C-o>:wq<CR>
"inoremap <C-s> <C-o>:w<CR>

let g:NERDTreeWinPos = "right"
let NERDTreeShowHidden=1

"colorscheme base16-default-dark
"colorscheme onehalf 
set background=dark
colorscheme PaperColor

