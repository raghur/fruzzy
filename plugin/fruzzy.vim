let s:is_win = has('win32') || has('win64')
let s:root = expand('<sfile>:h:h')

if exists("g:loaded_fruzzy")
    finish
endif

let g:loaded_fruzzy = 1
if !exists("g:fruzzy#usenative")
    let g:fruzzy#usenative = 0
endif

