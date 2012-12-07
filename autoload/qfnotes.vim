" qfnotes.vim
" Create file notes in quickfix format
" Last Change: $HGLastChangedDate$
" Maintainer: Sergey Khorev <sergey.khorev@gmail.com>
" Based on qfn.vim by Will Drewry <redpig@dataspill.org>: http://www.vim.org/scripts/script.php?script_id=2216
" License: See qfnotes.txt packaged with this file.

if exists("g:loaded_qfnotes_auto")
  finish
endif
let g:loaded_qfnotes_auto = 1

let s:save_cpo = &cpo

set cpo&vim

let s:qfbuff = -1

function s:QFXGetDefaultName()
  if exists('g:QFXDefaultFileName')
    if empty(g:QFXDefaultFileName)
      return &errorfile
    else
      return g:QFXDefaultFileName
    endif
  else
    return 'quickfix.err'
  endif
endfunction

let s:NonSenseComment = '!@#$%^{edf341f1-d270-4f35-a04f-cce6e3dd78ce}&*()-='

function s:QFXInput(prompt, default)
  if exists('g:QFXUseDialog') && g:QFXUseDialog
    let text = inputdialog(a:prompt, a:default, s:NonSenseComment)
    if text == s:NonSenseComment
      return ''
    endif
  else
    return input(a:prompt, a:default)
  endif
endfunction

function s:QFXList2Lines(list)
  return map(copy(a:list), 'join([bufname(v:val.bufnr), v:val.lnum, v:val.col, v:val.text], ":")')
endfunction

function s:QFXSetupBuff()
  set bufhidden=hide
  set nobuflisted
  let s:qfbuff = bufnr('%')
  augroup QFX
    " remove autocmd if another qf buffer existed
    autocmd!
    " updating quickfix window on each save
    autocmd BufWritePost <buffer> exec 'cgetbuffer' expand('<abuf>')
  augroup END

  "remove the autocmd on switching to another qf buffer
endfunction

function s:QFXSyncBuff()
  if s:qfbuff <= 0
    exec 'silent keepalt new' fnameescape(s:QFXGetDefaultName())
    call s:QFXSetupBuff()
  else
    exec 'silent keepalt sbuffer' s:qfbuff
    silent 1,$del _
  endif
  call setline(1, s:QFXList2Lines(getqflist()))
  silent keepalt hide
endfunction

" set QF list, open QF window, and position at pos-th error
function s:QFXSetList(list, action, pos)
  call setqflist(a:list, a:action)
  let len = len(getqflist())
  if a:pos < 0 || a:pos >= len
    let pos = len - 1
  else
    let pos = a:pos
  endif
  if &buftype == 'quickfix'
    let return2qf = 1
  else
    let return2qf = 0
  endif
  copen
  if pos >= 0
    exec 'cc' (pos + 1)
  endif
  if return2qf
    copen
  endif
  call s:QFXSyncBuff()
endfunction

function qfnotes#QFXAddQ()
  if &buftype != 'quickfix'
    let txt = s:QFXInput('Enter note: ', '')
    if !empty(txt)
      call qfnotes#QFXAdd(txt)
    endif
  endif
endfunction

" add support for different note types?
function qfnotes#QFXAdd(note)
  if a:note == ''
    return
  endif
  call s:QFXSetList(
	\[{'bufnr': bufnr('%'), 'lnum': line('.'), 'col': col('.'), 'text': a:note}],
	\'a', -1)
endfunction

function qfnotes#QFXSave(force, ...)
  if a:0 > 0
    let file = a:1
  else
    let file = ''
  endif

  if s:qfbuff > 0
    exec 'silent keepalt sbuffer' s:qfbuff
    if empty(file)
      exec 'silent noautocmd w' . (a:force ? '!' : '')
    else
      exec 'silent noautocmd w' . (a:force ? '! ' : ' ') . fnameescape(file)
    endif
    silent keepalt hide
  elseif empty(getqflist())
    echoerr 'No quickfix entries found'
  else
    echoerr 'Internal error: no qf buffer found but qf list is not empty'
  endif
endfunction

function qfnotes#QFXSaveRange(force, file) range
  call s:QFXSavePosn()
  try
    if &buftype != 'quickfix'
      let lines = filter(getqflist(),
	    \ 'v:val.bufnr == bufnr("%") && v:val.lnum >= a:firstline && v:val.lnum <= a:lastline')
    else
      let lines = getqflist()[a:firstline - 1: a:lastline - 1]
    endif

    if !a:force && filereadable(a:file)
      if &confirm
	if confirm('File ' . a:file . ' exists. Overwrite?', "&Yes\n&No") > 1
	  return
	endif
      else
	echoerr 'QuickFixNotes: file' a:file 'already exists'
	return
      endif
    endif

    call writefile(s:QFXList2Lines(lines), a:file)
  finally
    call s:QFXRestorePosn()
  endtry
endfunction

function! s:GetBufNrAndLine()
  if &buftype != 'quickfix'
    return [bufnr('%'), line('.')]
  else
    let qfentry = getqflist()[line('.') - 1]
    return [qfentry.bufnr, qfentry.lnum]
  endif
endfunction

function qfnotes#QFXDelete()
  let [bufnr, line] = s:GetBufNrAndLine()
  let modified = 0
  let qflist = getqflist()
  let idx = 0
  let lastmodidx = -1
  for i in qflist
    if bufnr == i.bufnr && line == i.lnum
      call remove(qflist, idx)
      let modified = 1
      let lastmodidx = idx
    endif
    let idx += 1
  endfor
  if modified
    call s:QFXSetList(qflist, 'r', lastmodidx)
  endif
endfunction

function qfnotes#QFXEdit(inbuffer)
  let [bufnr, line] = s:GetBufNrAndLine()
  let modified = 0
  let qflist = getqflist()
  let idx = 0
  let lastmodidx = -1
  let found = 0

  for i in qflist
    if bufnr == i.bufnr && line == i.lnum
      let found = 1
      if a:inbuffer
	if &buftype == 'quickfix'
	  " leaving quickfix window
	  exec (idx + 1) . 'cc'
	endif
	call s:QFXOpen()
	exec 'normal' ((idx + 1) . 'G')
	return
      else
	let inp = s:QFXInput('Enter new comment: ', i.text)
	if !empty(inp)
	  let i.text = inp
	  let modified = 1
	  let lastmodidx = idx
	endif
      endif
    endif
    let idx += 1
  endfor
  if modified
    call s:QFXSetList(qflist, 'r', lastmodidx)
  elseif !found
    if a:inbuffer " simply open notes buffer
      if !empty(qflist)
	exec '.cc'
      endif
      call s:QFXOpen()
    else " not found => adding new note
      call qfnotes#QFXAddQ()
    endif
  endif
endfunction

function qfnotes#QFXLoad(...)
  if a:0 > 0
    let file = a:1
    if a:0 > 1
      let dir = a:2
    else
      let dir = ''
    endif
  else
    let file = s:QFXGetDefaultName()
    let dir = ''
  endif

  exec 'silent keepalt new' fnameescape(file)
  call s:QFXSetupBuff()
  if line('$') == 1 && getline(1) =~ '\m^\s*$'
    let bufempty = 1
  else
    let bufempty = 0
  endif
  silent keepalt hide

  let save_cwd = getcwd()
  let save_ef = &ef
  let save_efm = &efm
  try
    set efm&
    if !empty(dir)
      exec 'silent cd' dir
    endif
    if !bufempty
      exec 'silent cbuffer' s:qfbuff
    endif
    copen
  finally
    let &ef = save_ef
    let &efm = save_efm
    if !empty(dir)
      exec 'silent cd' fnameescape(save_cwd)
    endif
  endtry
endfunction

function s:QFXOpen()
  if s:qfbuff > 0
    exec ':buffer' s:qfbuff
  else
    exec ':e' s:QFXGetDefaultName()
    call s:QFXSetupBuff()
  endif
endfunction

function qfnotes#QFXNew(...)
  if a:0 > 0
    let file = a:1
  else
    let file = s:QFXGetDefaultName()
  endif
  exec ':silent keepalt new' file
  call s:QFXSetupBuff()
  silent keepalt hide
  call setqflist([], ' ')
endfunction

" code from netrw plugin to save and restore current position
function! s:QFXRestorePosn(...)
  let eikeep = &ei
  set ei=all

  if a:0 > 0
    exe a:1
  endif

  " restore window
  if exists('w:QFX_winnr')
    exe 'silent! '.w:QFX_winnr.'wincmd w'
  endif
  " restore top-of-screen line
  if exists('w:QFX_hline')
    exe 'norm! '.w:QFX_hline."G0z\<CR>"
  endif
  " restore position
  if exists('w:QFX_line') && exists('w:QFX_col')
    exe 'norm! '.w:QFX_line.'G0'.w:QFX_col."\<bar>"
  endif

  let &ei = eikeep
endfunction

function! s:QFXSavePosn()
  " Save current line and column
  let w:QFX_winnr = winnr()
  let w:QFX_line = line('.')
  let w:QFX_col = virtcol('.')
  " Save top-of-screen line
  norm! H0
  let w:QFX_hline = line('.')
  " set up string holding position parameters
  let ret = 'let w:QFX_winnr='.w:QFX_winnr.'|let w:QFX_line='.w:QFX_line.'|let w:QFX_col='.w:QFX_col.'|let w:QFX_hline='.w:QFX_hline

  call s:QFXRestorePosn()
  return ret
endfunction

let &cpo = s:save_cpo

" vim: set ft=vim ts=8 sts=2 sw=2:
