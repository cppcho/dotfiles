let s:cppcho_is_dark_background=1
let s:cppcho_vimwiki_dir = '~/mywiki/'

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

Plug '907th/vim-auto-save'
let g:auto_save = 0
let g:auto_save_silent = 1
augroup ft_markdown
  au!
  au FileType markdown let b:auto_save = 1
augroup END

" Colors
Plug 'sainnhe/gruvbox-material'
let g:gruvbox_material_background = 'hard'
let g:gruvbox_material_foreground = 'material'

Plug 'christoomey/vim-tmux-navigator'
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_disable_when_zoomed = 1

Plug 'editorconfig/editorconfig-vim'

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
let g:lightline = {'colorscheme' : 'gruvbox_material'}

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
if s:cppcho_enable_vimwiki
  let g:polyglot_disabled = ['markdown']
end

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

" Personal Wiki for Vim
if s:cppcho_enable_vimwiki
  Plug 'vimwiki/vimwiki'

  let g:vimwiki_list = [{
        \ 'path': s:cppcho_vimwiki_dir,
        \ 'syntax': 'markdown',
        \ 'ext': '.md',
        \ 'auto_toc': 0,
        \ }]
  let g:vimwiki_auto_chdir = 1
  let g:vimwiki_auto_header = 1
  let g:vimwiki_table_auto_fmt = 0
  let g:vimwiki_url_maxsave = 0
  let g:vimwiki_use_calendar = 0
  let g:vimwiki_hl_headers = 1
  let g:vimwiki_hl_cb_checked = 1
  let g:vimwiki_links_header_level = 2
  let g:vimwiki_menu = ''
  let g:vimwiki_key_mappings = { 'all_maps': 0, }
  let g:vimwiki_conceal_onechar_markers = 0
  let g:vimwiki_conceal_pre = 0
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
set nocursorline                                      " Whether to highlight the current line
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
if has('termguicolors')
  set termguicolors
endif

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

colorscheme gruvbox-material

if has("gui_macvim")
  set guifont=JetBrains\ Mono:h12
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
nnoremap <silent> <leader>gs :Git<cr>
nnoremap <silent> <leader>gd :Gvdiffsplit<cr>
nnoremap <silent> <leader>gD :Gvdiffsplit master<cr>
nnoremap <silent> <leader>gb :Git blame<cr>
nnoremap <silent> <leader>gp :Git push<cr>
nnoremap <silent> <leader>gf :BCommits<cr>
nnoremap <silent> <leader>gh :Commits<cr>

" EasyAlign
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

nmap <Leader>ai :set diffopt+=iwhite<CR>
nmap <Leader>aw :set diffopt-=iwhite<CR>

nnoremap U :UndotreeToggle<CR>

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

nnoremap \vv :vsplit<cr>
nnoremap \ss :split<cr>
nnoremap \cc :QFix<cr>
nnoremap <C-c> :QFix<cr>

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" }}} Vimwiki {{{
""""""""""""""""""""""""""""""""""""""""""""""""""

if s:cppcho_enable_vimwiki
  " Reference: https://github.com/michal-h21/vim-zettel

  function! s:vimwiki_filename_to_link(filename)
    return printf('[[%s]]', a:filename)
  endfunction

  function! s:get_visual_selection_lines()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
      return ''
    endif
    return lines
  endfunction

  function! s:vimwiki_new_note(...)
    let lines = <sid>get_visual_selection_lines()
    let filename = ''

    let title = join(a:000)
    if len(title) > 0
      let filename = filename . title
    else
      echo "title is empty"
      return 0
    end

    execute "normal! :'<,'>d\<CR>O\<ESC>0I".<sid>vimwiki_filename_to_link(filename)."\<ESC>"
    call vimwiki#base#edit_file(':e', filename.'.md', '')

    if line('$') == 1 && getline(1) == ''
      " append title if the file is empty
      call append(0, '# '.filename)
    else
      call append("$", '')
    end

    for line in lines
      call append("$", line)
    endfor
    execute 'normal! G'
  endfunction

  command! -bang -nargs=* VimwikiZettelNew call <sid>vimwiki_new_note(<q-args>)

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

  command! -bang -nargs=* VimwikiYankName call <sid>vimwiki_yank_name()

  vmap <CR> :<C-U>VimwikiZettelNew<SPACE>
  nmap <C-Y> :VimwikiYankName<CR>

  nmap <nop> <Plug>VimwikiNormalizeLink
  vmap <nop> <Plug>VimwikiNormalizeLinkVisual
  vmap <nop> <Plug>VimwikiNormalizeLinkVisualCR

  nmap <Leader>ww <Plug>VimwikiMakeDiaryNote
  nmap <Leader>wm <Plug>VimwikiMakeTomorrowDiaryNote
  nmap <Leader>wy <Plug>VimwikiMakeYesterdayDiaryNote
  nmap <Leader>wi <Plug>VimwikiIndex
  nmap <Leader>wd <Plug>VimwikiDeleteFile
  nmap <Leader>wr <Plug>VimwikiRenameFile
  nmap <Leader>wn <Plug>VimwikiGoto

  autocmd FileType vimwiki nmap + <Plug>VimwikiAddHeaderLevel
  autocmd FileType vimwiki nmap _ <Plug>VimwikiRemoveHeaderLevel
  autocmd FileType vimwiki nmap ]] <Plug>VimwikiGoToNextSiblingHeader
  autocmd FileType vimwiki nmap [[ <Plug>VimwikiGoToPrevSiblingHeader
  autocmd FileType vimwiki nmap <C-CR> <Plug>VimwikiToggleListItem
  autocmd FileType vimwiki vmap <C-CR> <Plug>VimwikiToggleListItem
  autocmd FileType vimwiki nmap <Tab> <Plug>VimwikiIncreaseLvlSingleItem
  autocmd FileType vimwiki nmap <S-Tab> <Plug>VimwikiDecreaseLvlSingleItem
  autocmd FileType vimwiki vmap <Tab> <Plug>VimwikiIncreaseLvlSingleItem
  autocmd FileType vimwiki vmap <S-Tab> <Plug>VimwikiDecreaseLvlSingleItem
  autocmd FileType vimwiki imap <C-T> <Plug>VimwikiIncreaseLvlSingleItem
  autocmd FileType vimwiki imap <C-D> <Plug>VimwikiDecreaseLvlSingleItem
  autocmd FileType vimwiki nmap o <Plug>VimwikiListo
  autocmd FileType vimwiki nmap O <Plug>VimwikiListO
  autocmd FileType vimwiki nmap <S-BS> <Plug>VimwikiGoBackLink
  autocmd FileType vimwiki nmap <S-CR> <Plug>VimwikiFollowLink

  autocmd FileType vimwiki nnoremap <silent><buffer> <Leader>wg <Esc>:VimwikiGenerateLinks<CR>
  autocmd FileType vimwiki inoremap <silent><buffer> <CR> <Esc>:VimwikiReturn 1 5<CR>
  autocmd FileType vimwiki inoremap <silent><buffer> <S-CR> <Esc>:VimwikiReturn 2 2<CR>

  autocmd FileType vimwiki setlocal listchars=tab:›\ ,extends:#,nbsp:.
  autocmd FileType vimwiki setlocal nonumber
endif
