" qfnotes.vim
" Create file notes in quickfix format
" Last Change: $HGLastChangedDate$
" Maintainer: Sergey Khorev <sergey.khorev@gmail.com>
" Based on qfn.vim by Will Drewry <redpig@dataspill.org>: http://www.vim.org/scripts/script.php?script_id=2216
" License: See qfnotes.txt packaged with this file.

if exists("g:loaded_qfnotes")
  finish
endif
let g:loaded_qfnotes = 1

let s:save_cpo = &cpo
set cpo&vim

if v:version < 700
  echo "QFXotes requires version 7.0 or higher"
  finish
endif

" Map these local functions globally with the script id
noremap <unique> <script> <Plug>QuickFixNote <SID>QFXAddQ
nnoremap <unique> <script> <Plug>QuickFixSave <SID>QFXSave
noremap <unique> <script> <Plug>QuickFixDelete <SID>QFXDelete
noremap <unique> <script> <Plug>QuickFixEdit <SID>QFXEdit
noremap <unique> <script> <Plug>QuickFixBuffer <SID>QFXBuffer
noremap <unique> <script> <Plug>QuickFixLoad <SID>QFXLoad
noremap <SID>QFXAddQ :call qfnotes#QFXAddQ()<CR>
nnoremap <SID>QFXSave :call qfnotes#QFXSave(0)<CR>
noremap <SID>QFXDelete :call qfnotes#QFXDelete()<CR>
noremap <SID>QFXEdit :call qfnotes#QFXEdit(0)<CR>
noremap <SID>QFXBuffer :call qfnotes#QFXEdit(1)<CR>
noremap <SID>QFXLoad :call qfnotes#QFXLoad()<CR>

command! -nargs=1 QFXAdd :call qfnotes#QFXAdd(<f-args>)
command! -nargs=0 QFXAddQ :call qfnotes#QFXAddQ()
command! -nargs=? -complete=file -bang QFXSave :call qfnotes#QFXSave('<bang>'=='!', <f-args>)
command! -nargs=1 -complete=file -bang -range QFXSaveRange <line1>,<line2>call qfnotes#QFXSaveRange('<bang>'=='!', <f-args>)
command! -nargs=0 -range QFXDelete :<line1>,<line2>call qfnotes#QFXDelete()
command! -nargs=0 -range -bang QFXEdit :<line1>,<line2>call qfnotes#QFXEdit('<bang>'=='!')
command! -nargs=* -complete=file QFXLoad :call qfnotes#QFXLoad(<f-args>)
command! -nargs=? -complete=file QFXNew :call qfnotes#QFXNew(<f-args>)

if !exists('g:QFXDefaultMappings') || g:QFXDefaultMappings
  if !hasmapto('<Plug>QuickFixNote')
    map <unique> <Leader>qn <Plug>QuickFixNote
  endif

  if !hasmapto('<Plug>QuickFixSave')
    map <unique> <Leader>qs <Plug>QuickFixSave
  endif

  if !hasmapto('<Plug>QuickFixLoad')
    map <unique> <Leader>ql <Plug>QuickFixLoad
  endif

  if !hasmapto('<Plug>QuickFixDelete')
    map <unique> <Leader>qd <Plug>QuickFixDelete
  endif

  if !hasmapto('<Plug>QuickFixEdit')
    map <unique> <Leader>qe <Plug>QuickFixEdit
  endif

  if !hasmapto('<Plug>QuickFixBuffer')
    map <unique> <Leader>qE <Plug>QuickFixBuffer
  endif
endif

let &cpo = s:save_cpo

finish

Vimball filelist

doc/qfnotes.txt
autoload/qfnotes.vim
plugin/qfnotes.vim

" vim: set ft=vim ts=8 sts=2 sw=2:
