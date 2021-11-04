set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
 set rtp+=~/.vim/vim-extensions/Vundle.vim
 set rtp+=~/.vim/vim-extensions/ctrlp.vim

if $BASHRC_HOST == "tsa"
    call vundle#begin()
    " " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'preservim/nerdtree'
    Plugin 'Yggdroot/indentLine'
    Plugin 'itchyny/lightline.vim'
    Plugin 'luochen1990/rainbow'
    Plugin 'airblade/vim-gitgutter'
    Plugin 'ctrlp.vim'
    call vundle#end()            " required
    filetype plugin indent on    " required

elseif $BASHRC_HOST == "euler"
    call vundle#begin()
    " " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'preservim/nerdtree'
    Plugin 'Yggdroot/indentLine'
    Plugin 'itchyny/lightline.vim'
    Plugin 'luochen1990/rainbow'
    Plugin 'airblade/vim-gitgutter'
    Plugin 'ctrlp.vim'
    call vundle#end()            " required
    filetype plugin indent on    " required
else
    call vundle#begin()
    " " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'preservim/nerdtree'
    Plugin 'Yggdroot/indentLine'
    Plugin 'itchyny/lightline.vim'
    Plugin 'luochen1990/rainbow'
    Plugin 'airblade/vim-gitgutter'
    Plugin 'taglist.vim'
    Plugin 'ctrlp.vim'
    Plugin 'craigemery/vim-autotag'
    call vundle#end()            " required
    filetype plugin indent on    " required
endif
"

" ~/.vimrc (configuration file for vim only)
" skeletons
function! SKEL_spec()
    0r /usr/share/vim/current/skeletons/skeleton.spec
    language time en_US
    let login = system('whoami')
    if v:shell_error
       let login = 'unknown'
    else
       let newline = stridx(login, "\n")
       if newline != -1
        let login = strpart(login, 0, newline)
       endif
    endif
    let hostname = system('hostname -f')
    if v:shell_error
        let hostname = 'localhost'
    else
        let newline = stridx(hostname, "\n")
        if newline != -1
        let hostname = strpart(hostname, 0, newline)
        endif
    endif
    exe "%s/specRPM_CREATION_DATE/" . strftime("%a\ %b\ %d\ %Y") . "/ge"
    exe "%s/specRPM_CREATION_AUTHOR_MAIL/" . login . "@" . hostname . "/ge"
    exe "%s/specRPM_CREATION_NAME/" . expand("%:t:r") . "/ge"
endfunction
autocmd BufNewFile  *.spec  call SKEL_spec()

set nocompatible              " be iMproved, required
filetype off                  " required
autocmd BufNewFile  *.spec  call SKEL_spec()

"autocmd vimenter * NERDTree"
set updatetime=100
:imap jk <Esc>
set number
map <F9> gT
map <F10> gt
nnoremap <silent> <expr> ff g:NERDTree.IsOpen() ? "\:NERDTreeClose<CR>" : bufexists(expand('%')) ? "\:NERDTreeFind<CR>" : "\:NERDTree<CR>"
nnoremap <silent> tl<space> :Tlist<CR> 
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4
%retab
set autoindent
autocmd Filetype fortran setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
"used for nice Mode display"
set laststatus=2
"used for rainbow plugin
let g:rainbow_active = 1

syntax enable
set t_Co=256
set background=dark
colorscheme PaperColor
set t_ut=
au BufReadPost * if exists('b:current_syntax') && b:current_syntax == "fortran"
au BufReadPost *   syntax match ACC /!$acc.*/ contains=ACCKey,ACCKeys,ACCKeysUpdate,ACCKeysLoop,ACCKeysData,ACCKeysCond
au BufReadPost *   syntax match ACCKey /!$acc/ contained
au BufReadPost *   syntax keyword ACCKeys update data parallel loop enter exit end declare kernels atomic contained
au BufReadPost *   syntax keyword ACCKeysUpdate host device contained
au BufReadPost *   syntax keyword ACCKeysLoop gang vector seq contained
au BufReadPost *   syntax keyword ACCKeysData present create pcreate pcopy pcopyin pcopyout delete copy copyin copyout private reduction present_or_create contained
au BufReadPost *   syntax keyword ACCKeysCond if contained
au BufReadPost *   highlight ACC ctermfg=40 ctermbg=235
au BufReadPost *   highlight ACCKey ctermfg=4 ctermbg=235 cterm=bold
au BufReadPost *   highlight ACCKeys ctermfg=50 ctermbg=235 cterm=bold
au BufReadPost *   highlight ACCKeysUpdate ctermfg=132 ctermbg=235 cterm=bold
au BufReadPost *   highlight ACCKeysLoop ctermfg=208 ctermbg=235 cterm=bold
au BufReadPost *   highlight ACCKeysData ctermfg=132 ctermbg=235 cterm=bold
au BufReadPost *   highlight ACCKeysCond ctermfg=124 ctermbg=235 cterm=bold
au BufReadPost * endif
