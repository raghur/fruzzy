function! fruzzy#install()
    py3 import fruzzy_installer; fruzzy_installer.install()
endfunction


function! fruzzy#version()
    if !exists("g:fruzzy#version")
        echo "version not set. Depending on your usage:"
        echo "For denite: make sure that: "
        echo "      fruzzy is set as the matcher "
        echo "      Activate denite and filter list once to ensure it's loaded"
        echo "For Ctrlp: make sure that: "
        echo "      matcher is set as fruzzy#ctrlp#matcher"
        echo "      Ctrlp is activated once to ensure it's loaded"
        return
    endif
    echomsg g:fruzzy#version
    return g:fruzzy#version
endfunction
