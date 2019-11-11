let s:cppcho_enable_vimwiki=0
let s:cppcho_is_dark_background=1
let s:cppcho_vimwiki_dir = '~/Dropbox/Notes/'

if has("gui_macvim")
  let s:cppcho_enable_vimwiki=1
else
  let s:cppcho_enable_vimwiki=0
endif

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

" Colors
Plug 'altercation/vim-colors-solarized'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'NLKNguyen/papercolor-theme'

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

" Personal Wiki for Vim
if s:cppcho_enable_vimwiki
  Plug 'vimwiki/vimwiki'

  let g:vimwiki_list = [{
        \ 'path': s:cppcho_vimwiki_dir,
        \ 'syntax': 'markdown',
        \ 'ext': '.md',
        \ 'auto_toc': 1,
        \ }]
  let g:vimwiki_auto_chdir = 0
  " let g:vimwiki_hl_cb_checked = 1
  " let g:vimwiki_hl_headers = 1
  let g:vimwiki_table_mappings = 0
  let g:vimwiki_toc_header = 'Table of Contents'
  let g:vimwiki_url_maxsave = 0
  let g:vimwiki_use_calendar = 0
  let g:vimwiki_menu = ''

  " Disable markdown syntax as it will conflict with the vimwiki one
  let g:polyglot_disabled = ['markdown']

  let g:auto_save = 1
  let g:auto_save_no_updatetime = 1
  let g:auto_save_in_insert_mode = 0
end

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
set diffopt+=vertical                                 " Start diff mode with vertical splits
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

" Make sure colored syntax mode is on, and make it Just Work with 256-color terminals.
if has("gui_macvim")
  colorscheme PaperColor
  let g:lightline = {
        \ 'colorscheme': 'PaperColor_light',
        \ }
else
  colorscheme solarized
  let g:lightline = {
        \ 'colorscheme': 'PaperColor_light',
        \ }
end

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

if !has('gui_running')
  if $TERM == "xterm-256color" || $TERM == "screen-256color" || $COLORTERM == "gnome-terminal" || $TERM == "screen"
    set t_Co=256
  elseif has("terminfo")
    colorscheme default
    set t_Co=8
    set t_Sf=[3%p1%dm
    set t_Sb=[4%p1%dm
  else
    colorscheme default
    set t_Co=8
    set t_Sf=[3%dm
    set t_Sb=[4%dm
  endif

  " Disable Background Color Erase when within tmux - https://stackoverflow.com/q/6427650/102704
  if $TMUX != ""
    set t_ut=
  endif
endif

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

" use tab and shift tab to indent and de-indent code
" nnoremap <Tab>   >>
" nnoremap <S-Tab> <<
" vnoremap <Tab>   >><Esc>gv
" vnoremap <S-Tab> <<<Esc>gv
" inoremap <S-Tab> <C-d>

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
" nnoremap , za
" vnoremap , zf

" Tmux
nmap \r :!tmux send-keys -t right C-p C-j <cr><cr>
nmap \tt :!tmux send-keys -t right "prove -lr -PPretty " % ENTER<cr><cr>

nmap <Leader>fs :w<CR>
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
nnoremap <silent> <leader>gd :Gdiff<cr>
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

if executable('ag')
  let &grepprg = 'ag --nogroup --nocolor --column'
else
  let &grepprg = 'grep -rn $* *'
endif
command! -nargs=1 -bar Grep execute 'silent! grep! <q-args>' | redraw! | copen

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} FZF {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

function! FZFOpen(command_str)
  if (expand('%') =~# 'NERD_tree' && winnr('$') > 1)
    exe "normal! \<c-w>\<c-w>"
  endif
  exe 'normal! ' . a:command_str . "\<cr>"
endfunction

" All files
command! -nargs=? -complete=dir AF
      \ call fzf#run(fzf#wrap(fzf#vim#with_preview({
      \   'source': 'fd --type f --hidden --follow --exclude .git --no-ignore . '.expand(<q-args>)
      \ })))

" FZF mappings
command! -bang -nargs=? -complete=dir Files
      \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

nnoremap <C-p> :call FZFOpen(':Files')<cr>
nnoremap <silent><leader>af :call FZFOpen(':AF')<cr>
nnoremap <silent><leader>l :call FZFOpen(':BLines')<cr>
nnoremap <leader>/ :Ag<space>
nnoremap <silent><leader>; :call FZFOpen(':Buffers')<cr>

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

  autocmd! FileType fzf
  autocmd  FileType fzf set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

  " https://github.com/scrooloose/nerdtree
  " How can I close vim if the only window left open is a NERDTree?
  autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Vimwiki {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

if s:cppcho_enable_vimwiki
  augroup vimrc
    autocmd!
    autocmd VimEnter * execute 'VimwikiIndex' | execute 'cd' fnameescape(s:cppcho_vimwiki_dir)
  augroup END

  " Reference: https://github.com/michal-h21/vim-zettel

  function! s:vimwiki_filename_to_link(filename)
    return printf('[[%s]]', a:filename)
  endfunction

  function! s:vimwiki_yank_name()
    let filename = fnamemodify(expand("%"), ":~:.")
    let link = <sid>vimwiki_filename_to_link(filename)
    if len(link) > 0
      let @" = link
      let @* = link
      echo link
    else
      echo "cannot yank file name"
    end
  endfunction

  function! s:vimwiki_autocomplete_handler(line)
    let parts =  split(a:line,"\V:")
    let filename = parts[0]
    let fileparts = split(filename, '\V.')
    let filename_without_ext = join(fileparts[0:-2],".")
    execute 'normal! o- '.<sid>vimwiki_filename_to_link(filename_without_ext)
  endfunction

  command! -bang -nargs=? -complete=dir VimwikiAutoComplete
        \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({
        \'sink':function('<sid>vimwiki_autocomplete_handler'),
        \'dir': s:cppcho_vimwiki_dir,
        \}), <bang>0)

  function! VimwikiLinkHandler(link)
    let filepath = expand(s:cppcho_vimwiki_dir . a:link . '.md')
    if filereadable(filepath)
      execute 'edit' filepath
      return 1
    end
    return 0
  endfunction

  command! -bang -nargs=* VimwikiYankName call <sid>vimwiki_yank_name()

  command! -bang -nargs=* RgShowRelated
        \ call fzf#vim#grep(
        \   'rg --no-heading --color=always --smart-case --vimgrep --max-count=1 --fixed-strings --trim -- '.shellescape(<q-args>), 1,
        \   <bang>0 ? fzf#vim#with_preview('up:60%')
        \           : fzf#vim#with_preview(),
        \   <bang>0)

  function! s:vimwiki_show_related(...)
    let filename = fnamemodify(expand("%"), ":~:.")
    if len(filename) > 1
      execute 'RgShowRelated' filename
    else
      echo "error occurred in vimwiki_show_related()"
    end
  endfunction

  command! -bang -nargs=* VimwikiShowRelated call <sid>vimwiki_show_related(<q-args>)

  " Custom keybindings
  nmap <Leader>wgi <Plug>VimwikiDiaryGenerateLinks
  nmap <Leader>wgg :VimwikiGenerateLinks<CR>
  inoremap <C-l><C-l> <ESC>:VimwikiAutoComplete<CR>
  nmap <C-Y> :VimwikiYankName<CR>
  nmap <leader>ar :VimwikiShowRelated<CR>

  " Remap
  nmap <nop> <Plug>VimwikiNormalizeLink
  vmap <nop> <Plug>VimwikiNormalizeLinkVisual
  vmap <nop> <Plug>VimwikiNormalizeLinkVisualCR
  nmap + <Plug>VimwikiAddHeaderLevel
  nmap _ <Plug>VimwikiRemoveHeaderLevel
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Misc {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif

