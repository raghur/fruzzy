import nimpy
import strutils
import binaryheap
import logging
import strformat
import sequtils
import tables
import os
import system
import std/editdistance
when defined(profile):
    import nimprof

proc getVersion(): string {.compileTime.}=
    let ver = staticExec("git describe --tags --always --dirty").strip()
    # let cTime = format(times.now(), "yyyy-MM-dd hh:mm:ss")
    let branch = staticExec("git rev-parse --abbrev-ref HEAD").strip()
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

const sep:string = "-/\\_. "
const VERSION = getVersion()

template info(args: varargs[string, `$`]) =
    when not defined(removelogger):
        info(args)

template l(fmt: string) =
    when not defined(removelogger):
        debug(&fmt)
type
    Match = object
        found:bool
        positions: seq[int]
        sepScore, clusterScore, camelCaseScore: int

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

        var lastSep = candidate.rfind(os.DirSep)
        if lastSep == -1:
            lastSep = candidate.rfind(os.AltSep)
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

proc walkString(q, orig: string, left, right: int, m: var Match) {.inline.}=
    l "CALL==> {q} {left} {right}, {orig[left..right]}"
    if left > right or right == 0:
        m.found = false
        return
    let candidate = strutils.toLowerAscii(orig)
    let query = strutils.toLowerAscii(q)
    var first = true
    var pos:int = -1
    var l = left
    for i, c in query:
        if first:
            l "ScanBack: {i}, {c}, candidate[{l}..{right}]: {candidate[l..right]}"
            pos = strutils.rfind(candidate, c, l, right)
        else:
            l "ScanFwd: {i}, {c}, candidate[{l}..{right}]: {candidate[l..right]}"
            pos = strutils.find(candidate, c, l)
        l "Result: {i}, {pos}, {c}"
        if pos == -1:
            return
        if pos < candidate.high:
            let nextChar = orig[pos + 1]
            if nextChar in sep:
                m.sepScore.inc
        if pos == 0:
            m.sepScore.inc
            m.camelCaseScore.inc
        else:
            var prevChar = orig[pos - 1]
            if prevChar in sep:
                m.sepScore.inc
            if ord(orig[pos]) < ord('Z') and ord(prevChar) >= ord('a'):
                m.camelCaseScore.inc
        m.positions[i] = pos
        if i == 0:
            let qlen = q.len
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

proc isMatch(query, candidate: string, m: var Match)  {.inline.}=
    var didMatch = false
    var r = candidate.high
    while not didMatch:
        resetMatch(m, query.len)
        walkString(query, candidate, 0, r, m)
        if m.found:
            break  # all done
        # resume search - start looking left from this position onwards
        r = m.positions[0] - 1
        if r < 0:
            m.found = false
            break
    return

iterator fuzzyMatches(query:string, candidates: openarray[string], current: string, limit: int, ispath: bool = true): tuple[i:int, r:int]  {.inline.}=
    let findFirstN = true
    var count = 0
    var mtch:Match
    mtch.positions = newSeq[int](query.len)
    var heap = newHeap[tuple[i:int, r:int]]() do (a, b: tuple[i:int, r:int]) -> int:
        b.r - a.r
    if query != "":
        for i, x in candidates:
            if ispath and x == current:
                continue
            l "processing:  {x}"
            isMatch(query, x, mtch)
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
                heap.push((i, 300 - editdistance.editDistanceAscii(current, x)))
    else: # just return top N items from candidates as is
        for j in 0 ..< min(limit, candidates.len):
            yield (j, 0)

    if heap.size > 0:
        count = 0
        while count < limit and heap.size > 0:
            let item =  heap.pop
            yield item
            count.inc


proc scoreMatchesStr(query: string, candidates: openarray[string], current: string, limit: int, ispath:bool=true): seq[tuple[i:int, r:int]] {.exportpy.} =
    result = newSeq[tuple[i:int, r:int]](limit)
    var idx = 0
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
