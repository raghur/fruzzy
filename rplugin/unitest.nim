import unicode
import strutils
import logging

let L = newConsoleLogger(levelThreshold = logging.Level.lvlDebug)
addHandler(L)

template l(fmt: varargs[string, `$`]) =
    when not defined(release):
        debug(fmt)

var s = "стакло"
echo s.len
let runes = s.toRunes()
echo s.toRunes().len
for i in s.toRunes():
    l "rune ", i, i.size 
    #echo i
echo s.rfind(runes[0])
