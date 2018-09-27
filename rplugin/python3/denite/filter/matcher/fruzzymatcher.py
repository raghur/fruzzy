from ..base import Base
from denite.util import convert2fuzzy_pattern
import os
import sys
import logging

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
        un = self.vim.api.get_var("fruzzy#usenative")
        if un > 0:
            try:
                import fruzzy_mod
                self.nativeMethod = fruzzy_mod.scoreMatchesStr
                self.useNative = True
            except ModuleNotFoundError:
                self.debug("Native module requested but unable to load native module")
                self.debug("falling back to python implementation")
                self.debug("Check if you have nim_fuzzy.so or nim_fuzzy.pyd at %s" %
                           pkgPath)
                self.useNative = False
        self.debug("usenative: %s" % self.useNative)

    def filter(self, context):
        if not context['candidates'] or not context['input']:
            return context['candidates']
        candidates = context['candidates']
        qry = context['input']
        # self.debug("source: %s" % candidates[0]['source_name'])
        # self.debug("source: %s" % context['source_name'])
        ispath = candidates[0]['source_name'] in ["file", "file_rec",
                                                  "file_mru", "directory",
                                                  "directory_mru", "file_old",
                                                  "directory_rec", "buffer"]
        # self.debug("candidates %s %s" % (qry, len(candidates)))
        results = self.scoreMatchesProxy(qry, candidates, 10,
                                         key=lambda x: x['word'],
                                         ispath=ispath)
        # self.debug("results %s" % results)
        rset = [w[0] for w in results]
        # self.debug("rset %s" % rset)
        return rset

    def scoreMatchesProxy(self, q, c, limit, key=None, ispath=True):
        if self.useNative:
            idxArr = self.nativeMethod(q, [key(d) for d in c], limit, ispath)
            results = []
            for i in idxArr:
                results.append((c[i[0]], i[1]))
            return results
        else:
            return fruzzy.scoreMatches(q, c, limit, key, ispath)

    def convert_pattern(self, input_str):
        # return convert2fuzzy_pattern(input_str)
        p = convert2fuzzy_pattern(input_str)
        # self.debug("pattern: %s : %s" % (input_str, p))
        return p
