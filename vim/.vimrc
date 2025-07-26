""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Plugins {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

" Install vim-plug if not found
" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

call plug#begin()

Plug '907th/vim-auto-save'
let g:auto_save = 0
let g:auto_save_silent = 1
augroup ft_markdown
  au!
  au FileType markdown let b:auto_save = 1
augroup END

" Colors
Plug 'sainnhe/everforest'
let g:everforest_disable_italic_comment = 1
let g:everforest_background = 'hard'

Plug 'christoomey/vim-tmux-navigator'
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_disable_when_zoomed = 1

Plug 'editorconfig/editorconfig-vim'

" A tree explorer plugin for vim.
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

" Perform all your vim insert mode completions with Tab
Plug 'ervandew/supertab'
let g:SuperTabClosePreviewOnPopupClose = 1
let g:SuperTabLongestEnhanced = 1
let g:SuperTabLongestHighlight = 1
let g:SuperTabDefaultCompletionType = "<c-n>"

" A light and configurable statusline/tabline plugin for Vim
Plug 'itchyny/lightline.vim'
let g:lightline = {'colorscheme' : 'everforest'}

" " The undo history visualizer for VIM
" Plug 'mbbill/undotree'
" let g:undotree_WindowLayout = 2
" Vim plugin for the Perl module / CLI script 'ack'
Plug 'mileszs/ack.vim'
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" A command-line fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
let g:fzf_history_dir = '~/.config/vim-fzf-history'
let g:fzf_colors = {
      \ 'fg':      ['fg', 'Normal'],
      \ 'bg':      ['bg', 'Normal'],
      \ 'hl':      ['fg', 'Comment'],
      \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
      \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
      \ 'hl+':     ['fg', 'Statement'],
      \ 'info':    ['fg', 'PreProc'],
      \ 'border':  ['fg', 'Ignore'],
      \ 'prompt':  ['fg', 'Conditional'],
      \ 'pointer': ['fg', 'Exception'],
      \ 'marker':  ['fg', 'Keyword'],
      \ 'spinner': ['fg', 'Label'],
      \ 'header':  ['fg', 'Comment'] }

" A Vim alignment plugin
Plug 'junegunn/vim-easy-align'
let g:easy_align_delimiters = {
\  ' ': { 'pattern': ' ',  'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0 },
\  '=': { 'pattern': '===\|<=>\|\(&&\|||\|<<\|>>\)=\|=\~[#?]\?\|=>\|[:+/*!%^=><&|.-]\?=[#?]\?',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  ':': { 'pattern': ':',  'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1 },
\  ',': { 'pattern': ',',  'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1 },
\  '|': { 'pattern': '|',  'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '.': { 'pattern': '\.', 'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0 },
\  '#': { 'pattern': '#\+', 'delimiter_align': 'l', 'ignore_groups': ['!Comment']  },
\  '&': { 'pattern': '\\\@<!&\|\\\\',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '{': { 'pattern': '(\@<!{',
\                          'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 },
\  '}': { 'pattern': '}',  'left_margin': 1, 'right_margin': 0, 'stick_to_left': 0 },
\  '/': { 'pattern': '//=',  'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0 }
\ }

" A solid language pack for Vim.
Plug 'sheerun/vim-polyglot'

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

set encoding=utf-8
set autoindent                                        " Copy indent from current line when starting a new line
set autoread                                          " Don't bother me when a file changes
set autowrite                                         " Write on :next/:prev/^Z
set backspace=eol,start,indent                        " Make backspace a more flexible
set completeopt=menu                                  " Do not show preview for insert mode completion
set nocursorline                                      " Whether to highlight the current line
set nocursorcolumn                                    " Do not highlight current column
set expandtab                                         " Tabs are spaces, not tabs
set hidden                                            " Allow buffer switching without saving
set hlsearch                                          " Highlight all matches when searching
set ignorecase                                        " Ignore case when the pattern contains lowercase letters only
set incsearch                                         " Search for the text as entered
set infercase                                         " Completion recognizes capitalization
set list                                              " Display unprintable characters
set mouse=a                                           " Automatically enable mouse usage
set mousehide                                         " Hide the mouse cursor while typing
set nobackup                                          " No backup files
set nowritebackup                                     " No backup files
set noerrorbells visualbell t_vb=
set noexrc                                            " Don't use local version of .(g)vimrc, .exrc
set nojoinspaces                                      " Prevents inserting two spaces after punctuation on a join (J)
set nostartofline                                     " Leave the cursor where it was
set noswapfile                                        " Use a swapfile for the buffer
set number                                            " Line numbers on
set ruler                                             " Show the ruler
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)    " A ruler on steroids
set scroll=5                                          " Number of lines to scroll with ^U/^D
set scrolljump=5                                      " Lines to scroll when cursor leaves screen
set scrolloff=10                                      " Keep cursor away from this many chars top/bot
set shiftround                                        " Shift to certain columns, not just n spaces
set shiftwidth=2                                      " Use indents of 2 spaces
set shortmess+=filmnrxoOtTA                           " Abbrev. of messages (avoids 'hit enter')
set showbreak=                                        " Show for lines that have been wrapped, like Emacs
set showcmd                                           " Show (partial) command in the last line of the screen
set showmatch                                         " Show matching bracket
set noshowmode                                        " NO Show Insert, Replace or Visual mode message
set sidescrolloff=3                                   " Keep cursor away from this many chars left/right
set smartcase                                         " Override 'ignorecase' option if the search pattern contains upper case letters
set softtabstop=2                                     " Let backspace delete indent
set splitright                                        " Puts new vsplit windows to the right of the current
set t_RV=                                             " Don't request terminal version string (for xterm)
set tabstop=2                                         " An indentation every 2 columns
set viewoptions=cursor,unix,slash                     " Better unix / windows compatibility
set whichwrap=b,s,h,l,<,>,[,]                         " Backspace and cursor keys wrap too
set wildignore=*.class,*.o,*~,*.pyc,.git,node_modules " Ignore certain files in tab-completion
set wildmenu                                          " Show autocomplete menus
set wildmode=longest,full                             " Command <Tab> completion, list matches, then longest common part, then all.
set nowrap lbr
set guioptions=                                       " Remove macvim scrollbar

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

" set Vim-specific sequences for RGB colors
if has('termguicolors')
  set termguicolors
endif
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

syntax on
set background=dark
silent! colorscheme everforest

if has("gui_macvim")
  set guifont=Iosevka\ Term:h12
  " set macligatures
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

" save using <C-s> in every mode
" when in operator-pending or insert, takes you to normal mode
nnoremap <C-s> :w<CR>
vnoremap <C-s> <C-c>:w<CR>
inoremap <C-s> <Esc>:w<CR>
onoremap <C-s> <Esc>:w<CR>

" Enter to clear highlight
nnoremap <silent> <cr> :noh<cr><cr>

noremap <silent> <C-x> :redraw!<cr>

nnoremap <C-w> :close<CR>

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
nnoremap <silent> <leader>gs :Git<cr>
nnoremap <silent> <leader>gd :Gvdiffsplit<cr>
nnoremap <silent> <leader>gD :Gvdiffsplit master<cr>
nnoremap <silent> <leader>gb :Git blame<cr>

" EasyAlign
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

nmap <Leader>ai :set diffopt+=iwhite<CR>
nmap <Leader>aw :set diffopt-=iwhite<CR>

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
" }}} NERDTree {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <C-f> :NERDTreeFind<cr>
nnoremap <C-e> :NERDTreeToggle<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Autocommands {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

augroup vimrc
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

  " https://github.com/scrooloose/nerdtree
  " How can I close vim if the only window left open is a NERDTree?
  autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Neovim {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

if has("nvim")
  nnoremap Y Y
end

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Misc {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

" toggles the quickfix window.
command -bang -nargs=? QFix call QFixToggle(<bang>0)
function! QFixToggle(forced)
  if exists("g:qfix_win") && a:forced == 0
    cclose
  else
    execute "copen"
  endif
endfunction

" used to track the quickfix window
augroup QFixToggle
  autocmd!
  autocmd BufWinEnter quickfix let g:qfix_win = bufnr("$")
  autocmd BufWinLeave * if exists("g:qfix_win") && expand("<abuf>") == g:qfix_win | unlet! g:qfix_win | endif
augroup END

" Tmux
nmap \r :!tmux send-keys -t right C-p C-j <cr><cr>

nnoremap \vv :vsplit<cr>
nnoremap \ss :split<cr>
nnoremap \cc :QFix<cr>
nnoremap <C-c> :QFix<cr>

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif

