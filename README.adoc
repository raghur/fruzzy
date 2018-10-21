# Freaky fast fuzzy Denite/CtrlP matcher for vim/neovim

This is a matcher plugin for https://github.com/Shougo/denite.nvim[denite.nvim] 
and https://github.com/ctrlpvim/ctrlp.vim[CtrlP].

Read more at https://blog.rraghur.in/2018/09/27/fruzzy---a-freaky-fast-fuzzy-finder-for-vim/neovim/

## Installation

In your `.vimrc`:

```vim
" vim-plug; for other plugin managers, use what's appropriate
" if you don't want to trust a prebuilt binary, skip the 'do' part
" and build the binaries yourself. Instructions are further down
" and place them in the /path/to/plugin/rplugin/python3 folder

Plug 'raghur/fruzzy', {'do': { -> fruzzy#install()}}

" optional - but recommended - see below
let g:fruzzy#usenative = 1

" When there's no input, fruzzy can sort entries based on how similar they are to the current buffer
" For ex: if you're on /path/to/somefile.h, then on opening denite, /path/to/somefile.cpp
" would appear on the top of the list.
" Useful if you're bouncing a lot between similar files.
" To turn off this behavior, set the variable below  to 0

let g:fruzzy#sortonempty = 1 " default value

" tell denite to use this matcher by default for all sources
call denite#custom#source('_', 'matchers', ['matcher/fruzzy'])

" tell CtrlP to use this matcher
let g:ctrlp_match_func = {'match': 'fruzzy#ctrlp#matcher'}
let g:ctrlp_match_current_file = 1 " to include current file in matches
```

## Native modules

Native module gives a 10 - 15x speedup over python - ~40-60μs!. Not that you'd notice 
it in usual operation (python impl is at 300 - 600μs)

. Run command `:call fruzzy#install()` if you're not using vim-plug.
. restart nvim

### Manual installation

. Download the module for your platform. If on mac, rename to `fruzzy_mod.so`
. place in `/path/to/fruzzy/rplugin/python3`
. Make sure you set the pref to use native module - `g:fruzzy#usenative=1`
. restart vim/nvim

## Troubleshooting/Support

Raise a ticket - please include the following info:

.Get the version
. Start vim/nvim
. Activate denite/ctrlp as the case may be.
. Execute `:call fruzzy#version()` - this will print one of the following
.. version number and branch - all is good
.. `purepy` - you're using the pure python version.
.. `modnotfound` - you requested the native mod with `let g:fruzzy#usenative=1` but it could not be loaded
.. `outdated` - native mod was loaded but it's < v0.3. You can update the native mod from the releases. 
. include output of the above

.Describe the issue
. include the list of items
. include your query
. What it did vs what you expected it to do.

## Development

.Build native module
. install nim >= 0.19
. dependencies
.. nimble install binaryheap
.. nimble install nimpy
. `cd rplugin/python3`
. [Windows] `nim c --app:lib --out:fruzzy_mod.pyd -d:release -d:removelogger fruzzy_mod`
. [Linux] `nim c --app:lib --out:fruzzy_mod.so -d:release -d:removelogger fruzzy_mod`
. `-d:removelogger` 
    - removes all log statements from code.
    - When `removelogger` is not defined, only info level logs are emitted
    - Debug builds (ie: without `-d:release` flag) also turns on additional debug level logs

.Running tests
. cd `rplugin`
. `pytest` - run tests with python implementation
. `FUZZY_CMOD=1 pytest` - run tests with native module


