from python3 import fruzzy
import sys
import os

useNative = False
if os.getenv("FUZZY_CMOD"):
    from python3.fruzzy_mod import scoreMatchesStr, baseline
    useNative = True


def printResults(query, results):
    print()
    print("query: %s, results: " % query)
    for r in results:
        print(r)

def scoreMatches(q, c, limit, ispath):
    if useNative:
        idxArr = scoreMatchesStr(q, c, "", limit, ispath)
        results = []
        for i in idxArr:
            results.append((c[i[0]],i[1]))
        return results
    else:
        return fruzzy.scoreMatches(q, c, "", limit, ispath=ispath)

check = True
lines = []

def run():
    results = scoreMatches("api", lines, 10, True)
    printResults("api", results)
    if check:
        assert results[0][0].endswith("api.pb.go")

    results = scoreMatches("rct", lines, 10, True)
    printResults("rct", results)
    if check:
        assert results[0][0].endswith("root_cmd_test.go")

    results = scoreMatches("fuzz", lines, 10, True)
    printResults("fuzz", results)
    if check:
        assert results[0][0].endswith("pyfuzzy.py")
        assert results[1][0].endswith("gofuzzy.py")

    results = scoreMatches("ME", lines, 10, True)
    printResults("ME", results)
    if check:
        assert results[0][0].endswith("README.md")

    results = scoreMatches("cli", lines, 10, True)
    printResults("cli", results)
    if check:
        assert results[0][0].endswith("cli.go")
        assert results[1][0].endswith("client.go")

    results = scoreMatches("testn", lines, 10, True)
    printResults("testn", results)
    if check:
        assert results[0][0].endswith("test_main.py")

def main():
    global check
    global lines
    file = "neomru_file"
    if len(sys.argv) > 1:
        check = False
        file = sys.argv[1]
    with open(file) as fh:
        lines = [line.strip() for line in fh.readlines()]
    print("Loaded %d lines from file: %s. Asserts are %s" % (len(lines), file,
                                                             check))
    run()

if __name__ == "__main__":
    main()
