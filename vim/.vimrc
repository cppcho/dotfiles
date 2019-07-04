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

Plug 'altercation/vim-colors-solarized'
Plug 'christoomey/vim-tmux-navigator'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'editorconfig/editorconfig-vim'
Plug 'ervandew/supertab'                  " Perform all your vim insert mode completions with Tab
Plug 'google/vim-searchindex'             " vim-searchindex: display number of search matches & index of a current match
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align'
Plug 'scrooloose/nerdtree'
Plug 'sheerun/vim-polyglot'           " A solid language pack for Vim.
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'               " eunuch.vim: helpers for UNIX
Plug 'tpope/vim-fugitive', { 'tag': '*' }
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'           " unimpaired.vim: Pairs of handy bracket mappings  (]op to insert paste mode)
Plug 'vim-scripts/vim-auto-save'
Plug 'vimwiki/vimwiki'

call plug#end()

if plug_did_install == 0
  PlugInstall
end

"""""""""""""""""""""""""""""""""""""""""""""""""
" General Configurations
""""""""""""""""""""""""""""""""""""""""""""""""""

let cppcho_enable_vimwiki=0
if has("gui_macvim")
  let cppcho_enable_vimwiki=1
endif

set autoindent                                        " Copy indent from current line when starting a new line
set autoread                                          " Don't bother me hen a file changes
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
set nocursorcolumn                                      " Do not highlight current column
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
set nowrap lbr                                        " Wrap lines
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
" UI
""""""""""""""""""""""""""""""""""""""""""""""""""

let s:cppcho_is_dark_background=1

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

" Make sure colored syntax mode is on, and make it Just Work with 256-color terminals.
if has("gui_macvim")
  colorscheme palenight
  let g:lightline = {
        \ 'colorscheme': 'palenight',
        \ }
else
  colorscheme solarized
  let g:lightline = {
        \ 'colorscheme': 'PaperColor_light',
        \ }
end
if !has('gui_running')
  " let g:solarized_termcolors=256
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
  set background=dark

  let g:auto_save = 1
  let g:auto_save_no_updatetime = 1
  let g:auto_save_in_insert_mode = 0
  set wrap lbr
  set clipboard=unnamed
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" Key Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""

" Mapleader
let mapleader = "\<Space>"
let maplocalleader = "\<Space>"

nmap <Leader>fs :w<CR>
nmap <leader>xb :SwitchBackground<CR>

" use tab and shift tab to indent and de-indent code
nnoremap <Tab>   >>
nnoremap <S-Tab> <<
vnoremap <Tab>   >><Esc>gv
vnoremap <S-Tab> <<<Esc>gv
inoremap <S-Tab> <C-d>

" Disable Q for entering Ex mode
nnoremap Q <Nop>

" Disable q: for viewing command history
nnoremap q: <Nop>

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
cmap Tabe tabe

" Wrapped lines goes down/up to next row, rather than next line in file.
noremap j gj
noremap k gk

" Enter to clear highlight
nnoremap <silent> <cr> :noh<cr><cr>

noremap <silent> <C-x> :redraw!<CR>

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

" Folding
nnoremap , za
vnoremap , zf

" Tmux
nmap \r :!tmux send-keys -t right C-p C-j <cr><cr>

" Edit last file
nmap <leader>. :e#<cr>

" save using <C-s> in every mode
" when in operator-pending or insert, takes you to normal mode
nnoremap <C-s> :w<CR>
vnoremap <C-s> <C-c>:w<CR>
inoremap <C-s> <Esc>:w<CR>
onoremap <C-s> <Esc>:w<CR>

" Trim spaces at EOL and retab
command! TEOL %s/\s\+$//
command! CLEAN retab | TEOL

" close pane using <C-w>
noremap <silent> <C-w> :bdelete<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins
""""""""""""""""""""""""""""""""""""""""""""""""""

" SuperTab
let g:SuperTabClosePreviewOnPopupClose = 1
let g:SuperTabLongestEnhanced = 1
let g:SuperTabLongestHighlight = 1
let g:SuperTabDefaultCompletionType = "<c-n>"

function! FZFOpen(command_str)
  if (expand('%') =~# 'NERD_tree' && winnr('$') > 1)
    exe "normal! \<c-w>\<c-w>"
  endif
  exe 'normal! ' . a:command_str . "\<cr>"
endfunction

command! -bang -nargs=* Rg
      \ call fzf#vim#grep(
      \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
      \   <bang>0 ? fzf#vim#with_preview('up:60%')
      \           : fzf#vim#with_preview(),
      \   <bang>0)

command! -bang -nargs=? -complete=dir Files
      \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

nnoremap <leader>/ :Rg<space>

" FZF mappings
nnoremap ; :call FZFOpen(':Buffers')<cr>
nnoremap <C-p> :call FZFOpen(':Files')<cr>

" An action can be a reference to a function that processes selected lines
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Fugitive
nnoremap <silent> <leader>ga :Gwrite<cr>
nnoremap <silent> <leader>gs :Gstatus<cr>
nnoremap <silent> <leader>gd :Gdiff<cr>
nnoremap <silent> <leader>go :Gdiffoff<cr>
nnoremap <silent> <leader>gl :Glog<cr>
nnoremap <silent> <leader>gb :Gblame<cr>
nnoremap <silent> <leader>gr :Gread<cr>
nnoremap <silent> <leader>ge :Gedit<cr>
nnoremap <silent> <leader>gf :BCommits<cr>
nnoremap <silent> <leader>gh :Commits<cr>

" EasyAlign
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

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

" NERDTree
let NERDTreeShowHidden=1
map <C-e> :NERDTreeToggle<cr>
nnoremap <C-f> :NERDTreeFind<cr>

" Vimwiki
let s:vimwiki_dir = '~/Documents/Notes/'
if cppcho_enable_vimwiki
  let g:vimwiki_list = [{
        \ 'path': s:vimwiki_dir,
        \ 'syntax': 'markdown',
        \ 'ext': '.md',
        \ 'auto_toc': 1,
        \ }]

  let g:vimwiki_auto_chdir = 0
  let g:vimwiki_hl_cb_checked = 1
  let g:vimwiki_hl_headers = 1
  let g:vimwiki_table_mappings = 0
  let g:vimwiki_toc_header = 'Table of Contents'

  " Disable markdown syntax as it will conflict with the vimwiki one
  let g:polyglot_disabled = ['markdown']
end

" vim-tmux-navigator
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_disable_when_zoomed = 1

""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
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

  " close vim if the only window left open is a NERDTree
  autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

  autocmd Filetype gitcommit setlocal tw=80

  " Fix annoyances in the QuickFix window, like scrolling too much
  autocmd FileType qf setlocal number nolist scrolloff=0
  autocmd Filetype qf wincmd J " Makes sure it's at the bottom of the vim window

  " Resize panes when window/terminal gets resize
  autocmd VimResized * :wincmd =
  autocmd FileType vimwiki imap <buffer> <Tab> <Plug>VimwikiIncreaseLvlSingleItem
  autocmd FileType vimwiki imap <buffer> <S-Tab> <Plug>VimwikiDecreaseLvlSingleItem

  autocmd! FileType fzf
  autocmd  FileType fzf set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

  if cppcho_enable_vimwiki
    autocmd VimEnter * execute 'VimwikiIndex' | execute 'cd' fnameescape(s:vimwiki_dir)
  endif
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc
""""""""""""""""""""""""""""""""""""""""""""""""""

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" Labs
""""""""""""""""""""""""""""""""""""""""""""""""""

let g:fzf_history_dir = '~/.config/vim-fzf-history'

""""""""""""""""""""""""""""""""""""""""""""""""""
if cppcho_enable_vimwiki
  " Reference: https://github.com/michal-h21/vim-zettel

  function! s:get_visual_selection_lines()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
      return ''
    endif
    " let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    " let lines[0] = lines[0][column_start - 1:]
    return lines
  endfunction

  function! s:vimwiki_filename_to_link(filename)
    return printf('[[%s]]', filename)
  endfunction

  function! s:vimwiki_yank_name()
    let filepath = expand("%")
    let filename = fnamemodify(filepath, ":r")
    let link = <sid>vimwiki_filename_to_link(filename)
    if len(link) > 0
      let @" = link
      let @* = link
      echo link
    else
      echo "not a zettel note"
    end
  endfunction

  function! s:vimwiki_zettel_new(...)
    let lines = <sid>get_visual_selection_lines()
    let filename = strftime("%y%m%d%H%M%S")

    let title = join(a:000)
    if len(title) > 0
      let filename = filename . ' ' . title
    else
      echo "title is empty"
      return 0
    end

    execute "normal! :'<,'>d\<CR>O\<ESC>0i".<sid>vimwiki_filename_to_link(filename)."\<ESC>"
    call vimwiki#base#open_link(':e', filename)

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

  function! s:vimwiki_zettel_autocomplete_handler(line)
    let parts =  split(a:line,"\V:")
    let filename = parts[0]
    let fileparts = split(filename, '\V.')
    let filename_without_ext = join(fileparts[0:-2],".")
    execute 'normal! a '.<sid>vimwiki_filename_to_link(filename_without_ext)
  endfunction

  command! -bang -nargs=? -complete=dir VimwikiAutoComplete
        \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({
        \'sink':function('<sid>vimwiki_zettel_autocomplete_handler'),
        \'dir': s:vimwiki_dir,
        \}), <bang>0)

  command! -bang -nargs=* VimwikiYankName call <sid>vimwiki_yank_name()
  command! -bang -nargs=* VimwikiZettelNew call <sid>vimwiki_zettel_new(<q-args>)

  " Custom keybindings
  map <Leader><Space> <Plug>VimwikiToggleListItem
  nmap T :VimwikiYankName<CR>
  nmap <leader>ay :VimwikiYankName<CR>
  nmap <leader>al :VimwikiAutoComplete<CR>
  nmap <Leader>wgi <Plug>VimwikiDiaryGenerateLinks
  nmap <Leader>wgg :VimwikiGenerateLinks<CR>
  vmap <CR> :<C-U>VimwikiZettelNew<SPACE>

  " Remap
  nmap ++ <Plug>VimwikiNormalizeLink
  vmap ++ <Plug>VimwikiNormalizeLinkVisual
  vmap <nop> <Plug>VimwikiNormalizeLinkVisualCR

  function! VimwikiLinkHandler(link)
    " If the link has a zettel id, ignore the note title in the file name
    " when opening the link
    let matches = matchlist(a:link, '\(\d\{12\}\)')
    if len(matches) > 1
      let zettel_id = matches[1]
      let paths = split(globpath(s:vimwiki_dir, zettel_id.'*'), '\n')
      if len(paths) > 0
        execute 'edit' paths[0]
      else
        echo "zettel not found"
      end
      return 1
    end

    return 0
  endfunction
endif

