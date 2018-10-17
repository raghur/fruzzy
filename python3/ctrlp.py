"""A fruzzy wrapper for ctrlp support."""
from __future__ import print_function

import sys

# pylint: disable=import-error, wrong-import-position
import vim
sys.path.append(vim.eval('s:root_dir') + '/rplugin/python3')

USE_NATIVE = vim.vars.get('fruzzy#usenative', 0)
if USE_NATIVE:
    try:
        from fruzzy_mod import scoreMatchesStr
        import fruzzy_mod
        if 'version' in dir(fruzzy_mod):
            vim.vars["fruzzy#version"] = fruzzy_mod.version()
        else:
            vim.vars["fruzzy#version"] = "outdated"
    except ImportError:
        vim.vars["fruzzy#version"] = "modnotfound"
        from fruzzy import scoreMatches
        USE_NATIVE = False
else:
    from fruzzy import scoreMatches
    vim.vars["fruzzy#version"] = "purepy"
# pylint: enable=import-error, wrong-import-position


def fruzzy_match():
    """The wrapper for fruzzy matcher"""
    args = vim.eval('input')
    args['limit'] = int(args['limit'])
    args['ispath'] = int(args['ispath'])

    if USE_NATIVE:
        output = scoreMatchesStr(args['query'],
                                 args['candidates'],
                                 args['current'],
                                 args['limit'],
                                 args['ispath'])
        matches = [args['candidates'][i[0]] for i in output]
    else:
        matches = [c[0] for c in scoreMatches(**args)]

    return matches
