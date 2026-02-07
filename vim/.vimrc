""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Plugins {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

" Install vim-plug if not found
" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

" Colors
if has('nvim')
  Plug 'catppuccin/nvim', { 'as': 'catppuccin-nvim' }
else
  Plug 'catppuccin/vim', { 'as': 'catppuccin-vim' }
endif

Plug 'christoomey/vim-tmux-navigator'
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_disable_when_zoomed = 1

Plug 'editorconfig/editorconfig-vim'

" Perform all your vim insert mode completions with Tab
Plug 'ervandew/supertab'
let g:SuperTabClosePreviewOnPopupClose = 1
let g:SuperTabLongestEnhanced = 1
let g:SuperTabLongestHighlight = 1
let g:SuperTabDefaultCompletionType = "<c-n>"

" A light and configurable statusline/tabline plugin for Vim
Plug 'itchyny/lightline.vim'

" Vim plugin for the Perl module / CLI script 'ack'
Plug 'mileszs/ack.vim'
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" A command-line fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
let g:fzf_history_dir = '~/.config/vim-fzf-history'

" Combine with netrw to create a delicious salad dressing
Plug 'tpope/vim-vinegar'

" comment stuff out
Plug 'tpope/vim-commentary'

" eunuch.vim: helpers for UNIX
Plug 'tpope/vim-eunuch'

" A Git wrapper so awesome, it should be illegal
Plug 'tpope/vim-fugitive'

" Defaults everyone can agree on
Plug 'tpope/vim-sensible'

" quoting/parenthesizing made simple
Plug 'tpope/vim-surround'

" Pairs of handy bracket mappings  (]op to insert paste mode)
Plug 'tpope/vim-unimpaired'

" enable repeating supported plugin maps with '.'
Plug 'tpope/vim-repeat'

call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} General Configurations {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

set autoindent                                        " Copy indent from current line when starting a new line
set autowrite                                         " Write on :next/:prev/^Z
set completeopt=menu                                  " Do not show preview for insert mode completion
set expandtab                                         " Tabs are spaces, not tabs
set hidden                                            " Allow buffer switching without saving
set hlsearch                                          " Highlight all matches when searching
set ignorecase                                        " Ignore case when the pattern contains lowercase letters only
set infercase                                         " Completion recognizes capitalization
set nolist                                            " Do not display unprintable characters
set mouse-=a                                          " Disable mouse usage
set mouse=a                                           " Automatically enable mouse usage
set nojoinspaces                                      " Prevents inserting two spaces after punctuation on a join (J)
set noswapfile                                        " No swapfile
set nowritebackup                                     " No backup files
set nostartofline                                     " Leave the cursor where it was
set number                                            " Line numbers on
set scroll=5                                          " Number of lines to scroll with ^U/^D
set scrolljump=5                                      " Lines to scroll when cursor leaves screen
set scrolloff=10                                      " Keep cursor away from this many chars top/bot
set shiftround                                        " Shift to certain columns, not just n spaces
set shiftwidth=2                                      " Use indents of 2 spaces
set shortmess+=filmnrxoOtTA                           " Abbrev. of messages (avoids 'hit enter')
set showbreak=                                        " Show for lines that have been wrapped, like Emacs
set showmatch                                         " Show matching bracket
set noshowmode                                        " NO Show Insert, Replace or Visual mode message
set smartcase                                         " Override 'ignorecase' option if the search pattern contains upper case letters
set softtabstop=2                                     " Let backspace delete indent
set splitright                                        " Puts new vsplit windows to the right of the current
set tabstop=2                                         " An indentation every 2 columns
set viewoptions=cursor,unix,slash                     " Better unix / windows compatibility
set whichwrap=b,s,h,l,<,>,[,]                         " Backspace and cursor keys wrap too
set wildignore=*.class,*.o,*~,*.pyc,.git,node_modules " Ignore certain files in tab-completion
set wildmode=longest,full                             " Command <Tab> completion, list matches, then longest common part, then all.
set nowrap lbr

if has('persistent_undo')
  if has("nvim")
    let target_path = expand('~/.config/nvim-persistent-undo/')
  else
    let target_path = expand('~/.config/vim-persistent-undo/')
  endif

  if !isdirectory(target_path)
    call system('mkdir -p ' . target_path)
  endif

  let &undodir = target_path
  set undofile
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} UI {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

if has('termguicolors')
  set termguicolors
endif

syntax on
set background=dark
if has("nvim")
  silent! colorscheme catppuccin
  let g:lightline = {'colorscheme': 'catppuccin'}
else
  silent! colorscheme catppuccin_mocha
  let g:lightline = {'colorscheme': 'catppuccin_mocha'}
end

if has("gui_macvim")
  set guifont=Iosevka:h12
  set wrap lbr
  set clipboard=unnamed
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Key Mappings {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

" Mapleader
let mapleader = "\<Space>"
let maplocalleader = "\<Space>"

" Stupid shift key fixes
if has("user_commands")
  command! -bang -nargs=* -complete=file E e<bang> <args>
  command! -bang -nargs=* -complete=file W w<bang> <args>
  command! -bang -nargs=* -complete=file Wq wq<bang> <args>
  command! -bang -nargs=* -complete=file WQ wq<bang> <args>
  command! -bang Wa wa<bang>
  command! -bang WA wa<bang>
  command! -bang Q q<bang>
  command! -bang QA qa<bang>
  command! -bang Qa qa<bang>
endif

" Disable Q for entering Ex mode
nnoremap Q <Nop>

" Disable q: for viewing command history
nnoremap q: <Nop>

" Wrapped lines goes down/up to next row, rather than next line in file.
noremap j gj
noremap k gk

noremap <silent> <C-x> :redraw!<cr>

" Close window
nnoremap <Leader>q :close<CR>

" Folding
nnoremap , za
vnoremap , zf

nmap <Leader>fs :wa<CR>

" Upper/lower word
nnoremap <leader>uu mQviwU`Q
nnoremap <leader>ul mQviwu`Q

" Upper/lower first char of word
nnoremap <leader>uU mQgewvU`Q
nnoremap <leader>uL mQgewvu`Q

" Change current directory to current file
nnoremap <leader>cd :cd %:p:h<cr>:pwd<cr>
nnoremap <leader>cf :echo @%<cr>

" Quickly edit/reload the vimrc file
nnoremap <silent> <leader>rc :e $HOME/.vimrc<cr>
nnoremap <silent> <leader>rr :so $HOME/.vimrc<cr>

" Edit last file
nmap <leader>. :e#<cr>

" Trim spaces at EOL and retab
command! TEOL %s/\s\+$//
command! CLEAN retab | TEOL

" Fugitive
nnoremap <silent> <leader>ga :Gwrite<cr>
nnoremap <leader>gs :12split\|0Git<cr>
nnoremap <silent> <leader>gd :Gvdiffsplit<cr>
nnoremap <silent> <leader>gD :Gvdiffsplit master<cr>
nnoremap <silent> <leader>gb :Git blame<cr>

nmap <Leader>ai :set diffopt+=iwhite<CR>
nmap <Leader>aw :set diffopt-=iwhite<CR>

nnoremap \vv :vsplit<cr>
nnoremap \ss :split<cr>


""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Grep {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <leader><space> :Ack<space>

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} FZF {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <C-p> :Files<cr>
nnoremap <D-p> :Files<cr>
nnoremap <silent><leader>l :BLines<cr>
nnoremap <leader>/ :Rg<space>
nnoremap <silent><leader>; :Buffers<cr>
nnoremap <silent><leader>hh :History<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Netrw {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

" Netrw settings
let g:netrw_liststyle = 3  " Tree view by default

nnoremap <C-e> :e .<cr>
nnoremap <C-f> :Explore<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Autocommands {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

augroup basic
  " Remove ALL autocommands for the current group.
  autocmd!

  " Forcing wrap lines in vimdiff
  autocmd FilterWritePre * if &diff | setlocal wrap< | endif

  " Do not add comment leader after hitting 'o'
  " Add comment leader after hitting <CR>
  autocmd FileType * setlocal formatoptions-=c formatoptions-=o formatoptions+=r

  autocmd BufNewFile,BufRead *.md set filetype=markdown
  autocmd BufNewFile,BufRead *.mkdn set filetype=markdown
  autocmd BufNewFile,BufRead *.psgi,*.t,cpanfile set filetype=perl
  autocmd BufNewFile,BufRead *.tt set filetype=html

  autocmd Filetype gitcommit setlocal tw=80

  " Fix annoyances in the QuickFix window, like scrolling too much
  autocmd FileType qf setlocal number nolist scrolloff=0
  autocmd Filetype qf wincmd J " Makes sure it's at the bottom of the vim window

  " Resize panes when window/terminal gets resize
  autocmd VimResized * :wincmd =

  " Netrw mappings
  " Press q to close netrw and return to previous buffer
  autocmd FileType netrw nnoremap <buffer> q :bd<CR>
  " Refresh directory listing
  autocmd FileType netrw nnoremap <buffer> <C-r> :e .<CR>
  " Better back navigation (consistent with file browsing)
  autocmd FileType netrw nnoremap <buffer> <BS> -
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Vim/Neovim Specific {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

if has('nvim')
  nnoremap Y Y
else
  " Vim-only options (not supported in Neovim)
  set mousehide                                       " Hide the mouse cursor while typing
  set visualbell t_vb=                                " Disable visual bell
  set t_RV=                                           " Don't request terminal version string
  set guioptions=                                     " Remove macvim scrollbar
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"              " True color support
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Misc {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif

