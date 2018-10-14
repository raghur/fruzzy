if !has('python3')
  echom 'fruzzy#ctrlp requires python3!'
  finish
endif

let s:root_dir = escape(expand('<sfile>:p:h:h:h'), '\')
unsilent execute 'py3file ' . s:root_dir . '/python3/ctrlp.py'

function! fruzzy#ctrlp#matcher(items, str, limit, mmode, ispath, crfile, regex) abort
  call clearmatches()

  let input = {
        \ 'query': a:str,
        \ 'candidates': a:items,
        \ 'limit': a:limit,
        \ 'ispath': a:ispath,
        \ 'current': '',
        \}

  if a:ispath && !get(g:, 'ctrlp_match_current_file')
    if filereadable(expand(a:crfile))
      let input.current = resolve(a:crfile)
    else
      let current = resolve(getcwd() . '/' . a:crfile)
      if getftype(current) ==# 'file'
        let input.current = resolve(a:crfile)
      endif
    endif
  endif

  if empty(a:str)
    let matches = a:items[0:(a:limit)]
  else
    call matchadd('CtrlPMatch',
          \ '\v' . substitute(a:str, '.', '\0[^\0]{-}', 'g')[:-8])
    call matchadd('CtrlPLinePre', '^>')
    try
      let matches = py3eval('fruzzy_match()')
    catch /E688/
      return []
    endtry
  endif

  if !empty(input.current)
    call remove(matches, index(matches, input.current))
  endif

  return matches
endfunction
