let s:cppcho_is_dark_background=1

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Plugins {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

let plug_did_install=1
let plug_file=expand('~/.vim/autoload/plug.vim')

if !filereadable(plug_file)
  echo "Installing vim-plug..."
  echo ""
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  let plug_did_install=0
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" https://github.com/iamcco/markdown-preview.nvim
if has("gui_macvim")
  Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }
  let g:mkdp_preview_options = {
        \'mkit': { 'breaks': 1 },
        \}
endif

" Colors
Plug 'altercation/vim-colors-solarized'
Plug 'lifepillar/vim-solarized8'
Plug 'NLKNguyen/papercolor-theme'
Plug 'morhetz/gruvbox'

Plug 'christoomey/vim-tmux-navigator'
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_disable_when_zoomed = 1

Plug 'editorconfig/editorconfig-vim'

" The missing motion for Vim
Plug 'justinmk/vim-sneak'
let g:sneak#s_next = 1

" A tree explorer plugin for vim.
Plug 'scrooloose/nerdtree'

" Perform all your vim insert mode completions with Tab
Plug 'ervandew/supertab'
let g:SuperTabClosePreviewOnPopupClose = 1
let g:SuperTabLongestEnhanced = 1
let g:SuperTabLongestHighlight = 1
let g:SuperTabDefaultCompletionType = "<c-n>"

" display number of search matches & index of a current match
Plug 'google/vim-searchindex'

" A light and configurable statusline/tabline plugin for Vim
Plug 'itchyny/lightline.vim'

" The undo history visualizer for VIM
Plug 'mbbill/undotree'
let g:undotree_WindowLayout = 2

" Vim plugin for the Perl module / CLI script 'ack'
Plug 'mileszs/ack.vim'
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" A command-line fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
let g:fzf_history_dir = '~/.config/vim-fzf-history'

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

" Automatically save changes to disk
Plug 'vim-scripts/vim-auto-save'
let g:auto_save        = 0
let g:auto_save_silent = 0

call plug#end()

if plug_did_install == 0
  PlugInstall
end

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} General Configurations {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

set autoindent                                        " Copy indent from current line when starting a new line
set autoread                                          " Don't bother me when a file changes
set autowrite                                         " Write on :next/:prev/^Z
set backspace=eol,start,indent                        " Make backspace a more flexible
set completeopt=menu                                  " Do not show preview for insert mode completion
set nocursorline                                        " Whether to highlight the current line
"set diffopt+=vertical                                 " Start diff mode with vertical splits
set expandtab                                         " Tabs are spaces, not tabs
set hidden                                            " Allow buffer switching without saving
set hlsearch                                          " Highlight all matches when searching
set ignorecase                                        " Ignore case when the pattern contains lowercase letters only
set incsearch                                         " Search for the text as entered
set infercase                                         " Completion recognizes capitalization
set laststatus=2
set list                                              " Display unprintable characters
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.        " Highlight problematic whitespace
set mouse=a                                           " Automatically enable mouse usage
set mousehide                                         " Hide the mouse cursor while typing
set nobackup                                          " No backup files
set nocursorcolumn                                    " Do not highlight current column
set noerrorbells visualbell t_vb=
set noexrc                                            " Don't use local version of .(g)vimrc, .exrc
set nojoinspaces                                      " Prevents inserting two spaces after punctuation on a join (J)
set nostartofline                                     " Leave the cursor where it was
set noswapfile                                        " Use a swapfile for the buffer
set nowritebackup                                     " No backup files
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
  let target_path = expand('~/.config/vim-persisted-undo/')

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
set termguicolors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ }

function! s:set_background()
  if s:cppcho_is_dark_background
    set background=dark
  else
    set background=light
  end
endfunction
function! s:switch_background()
  if s:cppcho_is_dark_background
    let s:cppcho_is_dark_background=0
  else
    let s:cppcho_is_dark_background=1
  end
  call s:set_background()
endfunction

command! -bang SwitchBackground call <sid>switch_background()

syntax on

call <sid>set_background()

colorscheme solarized8_flat

if has("gui_macvim")
  set guifont=Fira\ Code:h12
  set macligatures
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
nmap <leader>xb :SwitchBackground<CR>

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
nnoremap <silent> <leader>rc :e $MYVIMRC<cr>
nnoremap <silent> <leader>rr :so $MYVIMRC<cr>

" Edit last file
nmap <leader>. :e#<cr>

" Trim spaces at EOL and retab
command! TEOL %s/\s\+$//
command! CLEAN retab | TEOL

" Fugitive
nnoremap <silent> <leader>ga :Gwrite<cr>
nnoremap <silent> <leader>gs :Gstatus<cr>
nnoremap <silent> <leader>gd :Gvdiffsplit<cr>
nnoremap <silent> <leader>gD :Gvdiffsplit master<cr>
nnoremap <silent> <leader>gb :Gblame<cr>
nnoremap <silent> <leader>gp :Gpush<cr>
nnoremap <silent> <leader>gf :BCommits<cr>
nnoremap <silent> <leader>gh :Commits<cr>

" EasyAlign
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

nmap <Leader>ai :set diffopt+=iwhite<CR>
nmap <Leader>aw :set diffopt-=iwhite<CR>

nnoremap U :UndotreeToggle<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Todo {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

" https://github.com/junegunn/dotfiles/blob/master/vimrc#L965

function! s:todo() abort
  let entries = []
  for cmd in ['git grep -niI -e TODO -e FIXME 2> /dev/null']
    let lines = split(system(cmd), '\n')
    if v:shell_error != 0 | continue | endif
    for line in lines
      let [fname, lno, text] = matchlist(line, '^\([^:]*\):\([^:]*\):\(.*\)')[1:3]
      call add(entries, { 'filename': fname, 'lnum': lno, 'text': text })
    endfor
    break
  endfor

  if !empty(entries)
    call setqflist(entries)
    copen
  endif
endfunction
command! Todo call s:todo()

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Grep {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <leader><space> :Ack<space>

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} FZF {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <C-p> :Files<cr>
nnoremap <silent><leader>l :BLines<cr>
nnoremap <leader>/ :Ag<space>
nnoremap <silent><leader>; :Buffers<cr>
nnoremap <silent><leader>hh :History<cr>


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
" }}} Vimwiki {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

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
nmap \tt :!tmux send-keys -t right "prove -lr -PPretty " % ENTER<cr><cr>
nmap \vv :vsplit<cr>
nmap \ss :split<cr>
nmap \cc :QFix<cr>

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif


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
