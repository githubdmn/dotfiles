"sh -c 'curl -fLo \"${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs\https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
" sh -c 'curl -fLo
" \"${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim
" --create-dirs \
"         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
"         
syntax enable
set wrap
set guicursor=n-v-c:block-Cursor
set cursorline
set cursorcolumn
set ruler
set rulerformat=%50(%{strftime('%A\ %e.%B\ %I:%M\%p')}\ %5l,%-6(%c%V%)\ %P%)
set showcmd
set wildmenu
set scrolloff=0
set nohlsearch
set incsearch
set ignorecase
set smartcase
set noswapfile
set number
set linebreak
set signcolumn=yes
set colorcolumn=80
set autoindent
set smartindent
set expandtab
set tabstop=2
set shiftwidth=2
set backspace=indent,eol,start
set clipboard+=unnamedplus
set nocompatible
filetype off

call plug#begin("~/.vim/plugged")
  " Plugin Section
  Plug 'preservim/nerdtree'
  Plug 'eslint/eslint'
  Plug 'myhere/vim-nodejs-complete'
  Plug 'leafgarland/typescript-vim'
  Plug 'pangloss/vim-javascript'
 "Plug 'fatih/vim-go'
  Plug 'c.vim'
  Plug 'ray-x/go.nvim'
  Plug 'dracula/vim',{'name': 'dracula'} 
  Plug 'sonph/onehalf', { 'rtp': 'vim' }
  Plug 'chriskempson/base16-vim'
  Plug 'gosukiwi/vim-atom-dark'
  Plug 'NLKNguyen/papercolor-theme'
 
call plug#end()

"Config Section
filetype plugin indent on  
nnoremap <C-a> :NERDTreeRefreshRoot<CR>:NERDTreeToggle<CR>
inoremap <C-a> <C-o>:NERDTreeToggle<CR>:NERDTreeRefreshRoot<CR>
let g:NERDTreeWinPos = "right"
let NERDTreeShowHidden=1

"colorscheme base16-default-dark
""colorscheme onehalf 
set background=dark
colorscheme PaperColor

