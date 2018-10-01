let s:is_win = has('win32') || has('win64')
let s:root = expand('<sfile>:h:h')

if exists("g:loaded_fruzzy")
    finish
endif

let g:loaded_fruzzy = 1
if !exists("g:fruzzy#usenative")
    let g:fruzzy#usenative = 0
endif

function! fruzzy#install()
  let cmd = (s:is_win ? 'install.cmd' : './install.sh')
  call s:OpenTerminal({
        \ 'cmd': cmd,
        \ 'cwd': s:root,
        \ 'Callback': function('s:installed')
        \})
  wincmd p
endfunction

function! s:OpenTerminal(opts) abort
  execute 'belowright 5new +setl\ buftype=nofile '
  setl buftype=nofile
  setl winfixheight
  setl norelativenumber
  setl nonumber
  setl bufhidden=wipe
  let cmd = get(a:opts, 'cmd', '')
  let cwd = get(a:opts, 'cwd', '')
  if !empty(cwd) | execute 'lcd '.cwd | endif
  let bufnr = bufnr('%')
  let Callback = get(a:opts, 'Callback', v:null)
  if has('nvim')
    call termopen(cmd, {
          \ 'on_exit': function('s:OnExit', [bufnr, Callback]),
          \})
  else
    call term_start(cmd, {
          \ 'exit_cb': function('s:OnExit', [bufnr, Callback]),
          \ 'curwin': 1,
          \})
  endif
endfunction

function! s:OnExit(bufnr, Callback, job_id, status, ...)
  if a:status == 0
    execute 'silent! bd! '.a:bufnr
  endif
  if !empty(a:Callback)
    call call(a:Callback, [a:status, a:bufnr])
  endif
endfunction

function! s:installed(status, ...)
  if a:status == 0
    echohl MoreMsg | echon '[fruzzy] native module installed.' | echohl None
  else
    echohl Error | echon '[fruzzy] native module install failed, process exited with '.a:status | echohl None
  endif
endfunction
