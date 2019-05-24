# unicode support
# string find and rfind will work.
# iterate over runes with str.runes()
# use toLower - but that doesn't work on a string - only single rune.
# do we do match positions? it still will be byte positions - not rune numbers.
# 
import nimpy
import strutils
import binaryheap
import logging
import strformat
import sequtils
import tables
import os
import system
import ospaths
import unicode

when defined(profile):
    import nimprof

proc getVersion(): string {.compileTime.}=
    let ver = strutils.strip(staticExec("git describe --tags --always --dirty"))
    # let cTime = format(times.now(), "yyyy-MM-dd hh:mm:ss")
    let branch = strutils.strip(staticExec("git rev-parse --abbrev-ref HEAD"))
    var options:seq[string] = newSeq[string]()
    if not defined(removelogger):
        options.add("info")
    if defined(profile):
        options.add("profile")
    if not defined(release):
        options.add("debug")
    else:
        options.add("release")
    let optionsStr = options.join(",")

    return &"rev: {ver} on branch: {branch} with options: {optionsStr}"

let L = newConsoleLogger(levelThreshold = logging.Level.lvlDebug)
addHandler(L)
const MAXCHARCOUNT = 30

const sep:seq[Rune] = "-/\\_. ".toRunes()
const VERSION = getVersion()

template info(args: varargs[string, `$`]) =
    when not defined(removelogger):
        info(args)

template l(fmt: string) =
    when not defined(release):
        debug(&fmt)
type
    Match = object
        found:bool
        positions: seq[int]
        sepScore, clusterScore, camelCaseScore: int
    VarLenArr = ref array[0..MAXCHARCOUNT, int]

proc newVarLenArr(): VarLenArr =
    var o = new(VarLenArr)
    return o

proc len(a: VarLenArr): int {.inline.}= result = a[MAXCHARCOUNT]
proc `[]`(a: VarLenArr, i: int): int {.inline.} = return a[i]
proc `$`(a: VarLenArr): string {.inline.} = return $(a)
proc high(a: VarLenArr): int {.inline.}= return a.len - 1
proc add(a: VarLenArr, x: int) {.inline.}=
    let p = a.len
    a[p] = x
    a[MAXCHARCOUNT].inc
iterator rev(a: VarLenArr): int {.inline.}=
    for i in countdown(a.high, 0):
        yield a[i]

# forward declaration
proc scorer(x: var Match, candidate:string, ispath:bool=true): int {.inline.}

proc assignScore(s: string, m: var Match) =
    let l = m.positions.len
    # min possible for consecutive matches like [51, 52, 53, 54]
    # = 51 * 4 + (4*3/2)
    # = 210
    m.clusterScore = -1 * (m.positions[0] * l + l * (l-1) div 2)
    for i,v in m.positions:
        if v == 0:
            m.sepScore.inc
            m.clusterScore.inc
        else:
            let
                prevChar = s[v-1]
                ch = s[v]
           # if prevChar in sep:
           #     m.sepScore.inc
           # if v < s.high:
           #     let nextChar = s[v+1]
           #     if nextChar in sep:
           #         m.sepScore.inc
            if prevChar.isLowerAscii and ch.isUpperAscii:
                m.camelCaseScore.inc
        m.clusterScore.inc(v)

proc rfirst1(a: VarLenArr, predicate: proc(x: int): bool, last:int = -1): tuple[f:bool, v:int] =
    #[
    Find first item matching predicate in a(last .. 0)
    ]#
    for m in a.rev:
        if predicate(m):
            return (true, m)
    return (false, -1)

proc greaterThan(x : int): (proc(x:int):bool) = 
    return proc(y:int):bool = return y > x

proc checkFullMatch(indexArr: var Table[char, VarLenArr], lq: string, pos: int, m: var Match) =
    var start = pos
    m.positions[0] = start
    l "Checking for entire string match starting from {pos}"
    m.found = true
    for k in 1..lq.high:
        let ch = lq[k]
        if not indexArr.hasKey(ch):
            m.found = false
            break
        l "looking for {lq[k]} in {indexArr[ch]}, greater than {start}"
        let (found, v) = rfirst1(indexArr[ch], greaterThan(start))
        if found:
            l "found at: {v}"
            start = v
            m.positions[k] = v
        else:
            m.found = false
            break

proc matcher(q, s: string):Match =
    var indexArr = initTable[char, VarLenArr]()
    let
        lq = q.toLowerAscii()
        ls = s.toLowerAscii()

    result.found = false
    result.positions = newSeq[int](len(q))
    l "looking for {q} in {s}"
    for i in countdown(ls.high, 0):
        let c = ls[i]
        if not indexArr.hasKey(c):
            indexArr[c] = newVarLenArr()
        indexArr[c].add(i)
        if c == lq[0]:
            checkFullMatch(indexArr, lq, i, result)
            if result.found:
                assignScore(s, result)
                l "match: {result}"
                return
    l "no match: {result}"
    return result

iterator fuzzyMatches01(q: string, candidates: openarray[string], limit: int, ispath:bool = true):tuple[i:int, r:int] =
    let findFirstN = true
    var count = 0
    var heap = newHeap[tuple[i:int, r:int]]() do (a, b: tuple[i:int, r:int]) -> int:
        b.r - a.r
    for i, s in candidates:
        var m = matcher(q, s)
        if m.found:
            let rank = scorer(m, s, ispath)
            heap.push((i, rank))
            count.inc
            if findFirstN and count == limit * 5:
                break
    count = 0
    while count < limit and heap.size > 0:
        yield  heap.pop
        count.inc

proc scorer(x: var Match, candidate:string, ispath:bool=true): int {.inline.}=
    let lqry = len(x.positions)
    let lcan = len(candidate)

    var
        position_boost = 0
        end_boost = 0
        filematchBoost = 0
    if ispath:
        # print("item is", candidate)
        # how close to the end of string as pct
        position_boost = 100 * (x.positions[0] div lcan)
        # absolute value of how close it is to end
        end_boost = (100 - (lcan - x.positions[0])) * 2

        var lastSep = candidate.rfind(ospaths.DirSep)
        if lastSep == -1:
            lastSep = candidate.rfind(ospaths.AltSep)
        let fileMatchCount = len(sequtils.filter(x.positions, proc(p: int):bool = p > lastSep))
        info &"fileMatchCount: {candidate}, {lastSep}, {x.positions}, {fileMatchCount}"
        filematchBoost = 100 * fileMatchCount div lqry

    # how closely are matches clustered
    let cluster_boost = 100 * (1 - x.clusterScore div lcan) * 4

    # boost for matches after separators
    # weighted by length of query
    let sep_boost = (100 * x.sepScore div lqry) * 75 div 100

    # boost for camelCase matches
    # weighted by lenght of query
    let camel_boost = 100 * x.camelCaseScore div lqry

    return position_boost + end_boost + filematchBoost + cluster_boost + sep_boost + camel_boost

proc walkString(query, candidate: openarray[Rune], cl:string, left, right: int, m: var Match) {.inline.}=
    l "Call {q} {left} {right}"
    if left > right or right == 0:
        m.found = false
        return
    var first = true
    var pos:int = -1
    var l = left
    var r = right
    for i, c in query:
        l "Looking: {i}, {c}, {l}, {r}"
        if first:
            pos = strutils.rfind(cl, $c, r)
        else:
            pos = strutils.find(cl, $c, l)
        l "Result: {i}, {pos}, {c}"
        if pos == -1:
            m.found = false
            if first:
                # if the first char was not found anywhere we're done
                m.positions[0] = 0
                return 
            else:
                # otherwise, find the non matching char to the left of the
                # first char pos. Next search on has to be the left of this
                # position
                let np = m.positions[0] - 1
                if np < 0:
                    # we've run out - clearly, no match possible
                    m.positions[0] = 0
                    return
                var posLeft = strutils.rfind(cl, $c, np)
                l "posLeft:  {c}, {np}, {posLeft}"
                m.positions[0] = posLeft
                return
        else:
            if pos < cl.high:
                let nextChar = candidate[pos + 1]
                if nextChar in sep:
                    m.sepScore.inc
            if pos == 0:
                m.sepScore.inc
                m.camelCaseScore.inc
            else:
                var prevChar = candidate[pos - 1]
                if prevChar in sep:
                    m.sepScore.inc
                if isUpper(candidate[pos]) and isLower(prevChar):
                # if ord(candidate[pos]) < ord('Z') and ord(prevChar) >= ord('a'):
                    m.camelCaseScore.inc
            m.positions[i] = pos
            if i == 0:
                let qlen = query.len
                m.clusterScore = -1 * ((pos * qlen) + (qlen * (qlen-1) div 2))
            m.clusterScore.inc(pos)
            l = pos + 1
            first = false
    m.found = true
    return

proc resetMatch(m: var Match, l:int) {.inline.} =
    m.found = false
    for j in 0 ..< l:
        m.positions[j] = 0
    m.clusterScore =0
    m.sepScore = 0
    m.camelCaseScore = 0

proc isMatch(qlower: openarray[Rune], candidate: string, m: var Match)  {.inline.}=
    var didMatch = false
    var clower = candidate.toRunes()
    clower.apply(unicode.toLower)
    let cl = $clower
    let c = candidate.toRunes()
    var r = c.high
    # var clower = candidate.toLowerAscii
    while not didMatch:
        resetMatch(m, qlower.len)
        walkString(qlower, c, cl, 0, r, m)
        if m.found:
            break  # all done
        # resume search - start looking left from this position onwards
        r = m.positions[0]
        if r <= 0:
            m.found = false
            break
    return

iterator fuzzyMatches(query:string, candidates: openarray[string], current: string, limit: int, ispath: bool = true): tuple[i:int, r:int]  {.inline.}=
    let findFirstN = true
    var count = 0
    var mtch:Match
    var qlower = query.toRunes()
    qlower.apply(unicode.toLower)
    mtch.positions = newSeq[int](query.len)
    var heap = newHeap[tuple[i:int, r:int]]() do (a, b: tuple[i:int, r:int]) -> int:
        b.r - a.r
    if query != "":
        for i, x in candidates:
            if ispath and x == current:
                continue
            l "processing:  {x}"
            isMatch(qlower, x, mtch)
            if mtch.found:
                count.inc
                l "ADDED: {x}"
                let rank = scorer(mtch, x, ispath)
                info &"{x} - {mtch} - {rank}"
                heap.push((i, rank))
                if findFirstN and count == limit * 5:
                    break
    elif query == "" and current != "" and ispath: # if query is empty just take N items based on levenshtien (rev)
        for i, x in candidates:
            if current != x:
                heap.push((i, 300 - current.editDistance(x)))
    else: # just return top N items from candidates as is
        for j in 0 ..< min(limit, candidates.len):
            yield (j, 0)

    if heap.size > 0:
        count = 0
        while count < limit and heap.size > 0:
            let item =  heap.pop
            yield item
            count.inc
let USEALT = os.existsEnv("FRUZZY_USEALT")
proc scoreMatchesStr(query: string, candidates: openarray[string], current: string, limit: int, ispath:bool=true): seq[tuple[i:int, r:int]] {.exportpy.} =
    result = newSeq[tuple[i:int, r:int]](limit)
    var idx = 0
    if USEALT:
        l "Using alternate impl"
        for m in fuzzyMatches01(query, candidates, limit, ispath):
            result[idx] = m
            idx.inc
    else:
        for m in fuzzyMatches(query, candidates, current, limit, ispath):
            result[idx] = m
            idx.inc

    result.setlen(idx)
    return

proc baseline(candidates: openarray[string] ): seq[tuple[i:int, r:int]] {.exportpy.} =
    result = newSeq[tuple[i:int, r:int]](candidates.len)
    var idx = 0
    for m in candidates:
        result[idx] = (idx, m.len)
        idx.inc
    result.setlen(idx)
    return

proc version():string {.exportpy.} =
    return VERSION
