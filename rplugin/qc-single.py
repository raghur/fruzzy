from python3 import fruzzy_mod
l = ["d:/code/go/src/github.com/raghur/fuzzy-denite/scratch/pyfuzzy.py"]
print("fuzz", l, fruzzy_mod.scoreMatchesStr("fuzz", l, "", 10,True))

l = ["D:/code/go/src/github.com/raghur/fuzzy-denite/lib/api.pb.go"]
print("fuzz", l, fruzzy_mod.scoreMatchesStr("fuzz", l, "", 10,True))
print("api", l, fruzzy_mod.scoreMatchesStr("api", l, "", 10,True))
print("xxx", l, fruzzy_mod.scoreMatchesStr("xxx", l, "", 10,True))
print("gbf", l, fruzzy_mod.scoreMatchesStr("gbf", l, "", 10,True))

