from ..base import Base
from denite.util import convert2fuzzy_pattern
from denite.util import relpath
import os
import sys
import logging
from os import path

logger = logging.getLogger()
pkgPath = os.path.dirname(__file__).split(os.path.sep)[:-3]
pkgPath = os.path.sep.join(pkgPath)
if pkgPath not in sys.path:
    logger.debug("added %s to sys.path" % pkgPath)
    sys.path.insert(0, pkgPath)

import fruzzy

class Filter(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'matcher/fruzzy'
        self.description = 'fruzzy - freakishly fast fuzzy matcher'
        self.useNative = False
        if self.vim.vars.get("fruzzy#usenative", 0):
            try:
                import fruzzy_mod
                self.nativeMethod = fruzzy_mod.scoreMatchesStr
                self.useNative = True
                if 'version' not in dir(fruzzy_mod):
                    self.debug("You have an old version of the native module")
                    self.debug("please execute :call fruzzy#install()")
                    self.vim.vars["fruzzy#version"] = "outdated"
                else:
                    self.vim.vars["fruzzy#version"] = fruzzy_mod.version()
            except ImportError:
                self.debug("Native module requested but module was not found")
                self.debug("falling back to python implementation")
                self.debug("execute :call fruzzy#install() to install the native module")
                self.debug("and then check if you have fruzzy_mod.so or fruzzy_mod.pyd at %s" %
                           pkgPath)
                self.vim.vars["fruzzy#version"] = "modnotfound"
                self.useNative = False
        else:
            self.vim.vars["fruzzy#version"] = "purepy"
        # self.debug("usenative: %s" % self.useNative)

    def filter(self, context):
        candidates = context['candidates']
        qry = context['input']
        # self.debug("source: %s" % candidates[0]['source_name'])
        # self.debug("context: %s" % context)
        ispath = candidates and 'action__path' in candidates[0]
        # self.debug("candidates %s %s" % (qry, len(candidates)))
        limit = context['winheight']
        limit = int(limit) if isinstance(limit, str) else limit
        buffer = context['bufnr']
        buffer = int(buffer) if isinstance(buffer, str) else buffer
        sortOnEmptyQuery = self.vim.vars.get("fruzzy#sortonempty", 1)
        results = self.scoreMatchesProxy(qry, candidates,
                                         limit,
                                         key=lambda x: x['word'],
                                         ispath=ispath,
                                         buffer=buffer,
                                         sortonempty=sortOnEmptyQuery)
        # self.debug("results %s" % results)
        rset = [w[0] for w in results]
        # self.debug("rset %s" % rset)
        return rset

    def scoreMatchesProxy(self, q, c, limit, key=None, ispath=True, buffer=0,
                          sortonempty=True):
        relname = ""
        if sortonempty and ispath and buffer > 0 and q == "":
            fname = self.vim.buffers[buffer].name
            relname = relpath(self.vim, fname)
        # self.debug("sort on empty: %s, '%s'" % (sortonempty, relname))
        if self.useNative:
            idxArr = self.nativeMethod(q, [key(d) for d in c],
                                       relname, limit, ispath)
            results = []
            for i in idxArr:
                idx, score = i
                results.append((c[idx], score))
            return results
        else:
            return fruzzy.scoreMatches(q, c, relname, limit, key, ispath)

    def convert_pattern(self, input_str):
        p = convert2fuzzy_pattern(input_str)
        # self.debug("pattern: %s : %s" % (input_str, p))
        return p
