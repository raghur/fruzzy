
if exists("g:loaded_fruzzy")
    finish
endif

let g:loaded_fruzzy = 1
if !exists("g:fruzzy#usenative")
    let g:fruzzy#usenative = 0
endif

