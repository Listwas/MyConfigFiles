syntax on
filetype on
filetype plugin on
filetype indent on
set number
set tabstop=4
set expandtab
set smartindent
set incsearch
set showcmd
set showmode
set showmatch
set hlsearch
set wildmenu
set wildmode=list:longest
set scrolloff=10
set t_Co=256
set nohlsearch
"colorscheme molokai

set clipboard=unnamedplus

xnoremap <C-_> :s/^\(#\)\?\(.*\)/\=(submatch(1)=="" ? "#".submatch(2) : submatch(2))/<CR>:noh<CR>
