" MacVim Search Pad
" Creates timestamped markdown files in ~/SearchPad for quick notes.
" Auto-saves periodically so nothing is lost.
" Each new window (Cmd+N) creates a fresh timestamped file.

if !has("gui_macvim")
  finish
endif

let g:searchpad_dir = expand('~/SearchPad')

if !isdirectory(g:searchpad_dir)
  call mkdir(g:searchpad_dir, 'p')
endif

function! s:NewSearchPadFile()
  let l:filename = g:searchpad_dir . '/' . strftime('%Y-%m-%d_%H%M%S') . '.md'
  execute 'edit ' . fnameescape(l:filename)
endfunction

function! s:IsSearchPadBuffer()
  return expand('%:p') =~# '^' . escape(g:searchpad_dir, '/')
endfunction

function! s:AutoSaveSearchPad()
  if s:IsSearchPadBuffer() && &modified && expand('%') != ''
    silent! write
  endif
endfunction

function! s:TimerAutoSave(timer_id)
  call s:AutoSaveSearchPad()
endfunction

augroup SearchPad
  autocmd!

  " Open a search pad file on startup if no file was given
  autocmd VimEnter * if argc() == 0 | call s:NewSearchPadFile() | endif

  " Auto-save when cursor is idle (after 'updatetime' ms of no input)
  autocmd CursorHold,CursorHoldI * call s:AutoSaveSearchPad()

  " Auto-save when MacVim loses focus
  autocmd FocusLost * call s:AutoSaveSearchPad()
augroup END

" Cmd+N opens a new search pad file instead of an empty buffer
nnoremap <D-n> :call <SID>NewSearchPadFile()<CR>

" Periodic auto-save every 30 seconds via timer
call timer_start(30000, function('s:TimerAutoSave'), {'repeat': -1})
