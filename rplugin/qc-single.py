from python3 import fruzzy_mod
from python3 import fruzzy
l = ["d:/code/go/src/github.com/raghur/fuzzy-denite/scratch/pyfuzzy.py"]
print("Native: fuzz", l, fruzzy_mod.scoreMatchesStr("fuzz", l, "", 10, True))

print("Python: fuzz", l, fruzzy.scoreMatches("fuzz", l, "", 10, lambda x: x, True))

l = ["D:/code/go/src/github.com/raghur/fuzzy-denite/lib/api.pb.go"]
print("Native: fuzz", l, fruzzy_mod.scoreMatchesStr("fuzz", l, "", 10, True))
print("Native: api", l, fruzzy_mod.scoreMatchesStr("api", l, "", 10, True))
print("Native: xxx", l, fruzzy_mod.scoreMatchesStr("xxx", l, "", 10, True))
print("Native: gbf", l, fruzzy_mod.scoreMatchesStr("gbf", l, "", 10, True))


# python
print("Python: fuzz", l, fruzzy.scoreMatches("fuzz", l, "", 10, lambda x: x, True))
print("Python: api", l, fruzzy.scoreMatches("api", l, "", 10, lambda x: x, True))
print("Python: xxx", l, fruzzy.scoreMatches("xxx", l, "", 10, lambda x: x, True))
print("Python: gbf", l, fruzzy.scoreMatches("gbf", l, "", 10, lambda x: x, True))
