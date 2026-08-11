" ~/.vimrc -- symlinked from this repo by install.sh

set nocompatible              " be iMproved, required
filetype off                  " required

" --- plugins (Vundle) ----------------------------------------------------

set rtp+=~/.vim/vim-extensions/Vundle.vim
set rtp+=~/.vim/vim-extensions/ctrlp.vim

call vundle#begin()
Plugin 'VundleVim/Vundle.vim'   " let Vundle manage Vundle, required
Plugin 'preservim/nerdtree'
Plugin 'Yggdroot/indentLine'
Plugin 'itchyny/lightline.vim'
Plugin 'luochen1990/rainbow'
Plugin 'airblade/vim-gitgutter'
Plugin 'ctrlp.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-commentary'
Plugin 'majutsushi/tagbar'
Plugin 'dense-analysis/ale'
Plugin 'christoomey/vim-tmux-navigator'

" vim-autotag regenerates tags on every write, which is too slow on the Euler
" and Levante filesystems
if $DOTFILES_HOST !=# 'euler' && $DOTFILES_HOST !=# 'levante'
    Plugin 'craigemery/vim-autotag'
endif
call vundle#end()

filetype plugin indent on     " required

" --- editing -------------------------------------------------------------

set number
set mouse=""
set updatetime=100
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
autocmd Filetype fortran setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2

" --- appearance ----------------------------------------------------------

syntax enable
set t_Co=256
set t_ut=
set background=dark
colorscheme molokai_adjusted
set laststatus=2              " always show the status line (lightline)
let g:rainbow_active = 1

" --- key mappings --------------------------------------------------------

imap jk <Esc>
map <F9> gT
map <F10> gt
nnoremap <silent> <expr> ff g:NERDTree.IsOpen() ? "\:NERDTreeClose<CR>" : bufexists(expand('%')) ? "\:NERDTreeFind<CR>" : "\:NERDTree<CR>"
nnoremap <silent> tl<space> :TagbarToggle<CR>
nmap <silent> ft<space> :execute 'tab tag '.expand('<cword>')<CR>

" --- file types ----------------------------------------------------------

autocmd BufNewFile,BufRead *.cylc set filetype=automake

" --- OpenACC directive highlighting in Fortran ---------------------------

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

" --- RPM spec skeleton ---------------------------------------------------

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
autocmd BufNewFile *.spec call SKEL_spec()
