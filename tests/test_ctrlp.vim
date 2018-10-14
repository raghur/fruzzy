set nocompatible
let &rtp = '~/.vim/bundle/fruzzy/,' . &rtp
filetype plugin indent on
syntax enable

let g:fruzzy#usenative = 1

nnoremap q :qall!<cr>

highlight link CtrlPMatch Type
highlight link CtrlPLinePre PreProc

let s:items = [
      \ '.gitignore',
      \ 'README.adoc',
      \ 'python3/ctrlp.py',
      \ 'plugin/fruzzy.vim',
      \ 'autoload/fruzzy.vim',
      \ 'autoload/fruzzy/ctrlp.vim',
      \ 'rplugin/python3/fruzzy.py',
      \ 'rplugin/python3/qc-fast.py',
      \ 'python3/fruzzy_installer.py',
      \ 'rplugin/python3/neomru_file',
      \ 'rplugin/python3/qc-single.py',
      \ 'rplugin/python3/fruzzy_mod.nim',
      \ 'rplugin/python3/fruzzy_test.py',
      \ 'rplugin/python3/denite/filter/matcher/fruzzymatcher.py',
      \]

let s:items = [
      \ '~/.vim/bundle/ctrlp-py-matcher/autoload/pymatcher.py',
      \ '~/.vim/bundle/ctrlp-py-matcher/autoload/pymatcher.vim',
      \ '~/.vim/bundle/fruzzy/rplugin/python3/fruzzy_mod.nim',
      \ '~/.vim/personal/syntax/dagbok.vim',
      \ '~/.vim/bundle/vimtex/rplugin/python3/denite/source/vimtex.py',
      \ '~/.vim/bundle/fruzzy/rplugin/python3/denite/filter/matcher/fruzzymatcher.py',
      \ '~/.vim/bundle/wiki.vim/pythonx/ncm2_subscope_detector/wiki.py',
      \]

let s:qry = 'pymatc'
let s:cur = '~/.vim/bundle/ctrlp-py-matcher/autoload/pymatcher.vim'
echo 'Current:' s:cur . "\n"
for s:len in range(4)
  echo 'Query:' strpart(s:qry, 0, s:len)
  for s:res in fruzzy#ctrlp#matcher(s:items, strpart(s:qry, 0, s:len), 5, '', 1, s:cur, '')
    echo '  ' . s:res
  endfor
  echon "\n"
endfor

quitall!
