from ..base import Base
from denite.util import convert2fuzzy_pattern
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
        un = self.vim.vars["fruzzy#usenative"]
        if un > 0:
            try:
                import fruzzy_mod
                self.nativeMethod = fruzzy_mod.scoreMatchesStr
                self.useNative = True
            except ImportError:
                self.debug("Native module requested but unable to load native module")
                self.debug("falling back to python implementation")
                self.debug("Check if you have nim_fuzzy.so or nim_fuzzy.pyd at %s" %
                           pkgPath)
                self.useNative = False
        self.debug("usenative: %s" % self.useNative)

    def filter(self, context):
        candidates = context['candidates']
        qry = context['input']
        # self.debug("source: %s" % candidates[0]['source_name'])
        # self.debug("source: %s" % context['source_name'])
        ispath = False
        for s in context['sources']:
            if s['name'] in ["file", "file_rec",
                             "file_mru", "directory",
                             "directory_mru", "file_old",
                             "directory_rec", "buffer"]:
                ispath = True
                break
        # self.debug("candidates %s %s" % (qry, len(candidates)))
        results = self.scoreMatchesProxy(qry, candidates, 10,
                                         key=lambda x: x['word'],
                                         ispath=ispath,
                                         buffer=context['bufnr'])
        # self.debug("results %s" % results)
        rset = [w[0] for w in results]
        # self.debug("rset %s" % rset)
        return rset

    def scoreMatchesProxy(self, q, c, limit, key=None, ispath=True, buffer=0):
        relname = ""
        if ispath and buffer > 0 and q == "":
            fname = self.vim.buffers[buffer].name
            d = self.vim.command("pwd")
            try:
                relname = path.relpath(fname, start=d)
            except ValueError:
                relname = fname
                self.debug("buffer: %s, '%s'" % (relname, d))
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
