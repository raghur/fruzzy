import sys
import heapq
import itertools

sep = '-/\_. '


def idfn(x):
    return x


def scorer(x, key, ispath=True):
    """
        :x: - tuple of (item, positions, clusterScore, endScore, sepScore)
            - item - the item itself
            - positions - indices where each char matched
            - clusterScore - How closely are matched chars clustered - 0 if
            consecutive
            - sepScore - how many matches were after separators (count)
            - camelCaseScore - how many matched chars were camelcase
        :key: - key func that when applied to x[0] returns the search string
    """
    candidate = key(x[0])
    lqry = len(x[1])
    lcan = len(candidate)

    position_boost, end_boost, filematchBoost = 0, 0, 0
    if ispath:
        # print("item is", candidate)
        # how close to the end of string as pct
        position_boost = 100 * (x[1][0]//lcan)
        # absolute value of how close it is to end
        end_boost = (100 - (lcan - x[1][0])) * 2

        lastPathSep = candidate.rfind("\\")
        if lastPathSep == -1:
            lastPathSep = candidate.rfind("/")
        fileMatchCount = sum(1 for i in itertools.filterfalse(
            lambda p: p < lastPathSep, x[1]))
        # print(candidate, lastPathSep, x[1], fileMatchCount)
        filematchBoost = 100 * fileMatchCount // lqry


    # how closely are matches clustered
    cluster_boost = 100 * (1 - x[2]//lcan) * 4

    # boost for matches after separators
    # weighted by length of query
    sep_boost = 100 * x[3]//lqry * 75//100

    # boost for camelCase matches
    # weighted by lenght of query
    camel_boost = 100 * x[4]//lqry

    return position_boost + end_boost + filematchBoost + \
        cluster_boost + sep_boost + camel_boost
    # return position_boost + cluster_boost + sep_boost + camel_boost


def scoreMatches(query, candidates, limit, key=None, ispath=True):
    key = idfn if not key else key
    matches = fuzzyMatches(query, candidates, limit * 5, key, ispath)
    return heapq.nlargest(limit, matches, key=lambda x: x[5])


def isMatch(query, candidate):
    def walkString(query, candidate, left, right):
        # print("Call ", query, left, right)
        orig = candidate
        candidate = candidate.lower()
        query = query.lower()
        matchPos = []
        first = True
        sepScore = 0
        clusterScore = 0
        camelCaseScore = 0
        for i, c in enumerate(query):
            # print ("Looking", i, c, left, right)
            if first:
                pos = candidate.rfind(c, left, right)
            else:
                pos = candidate.find(c, left)
            # print("Result", i, pos, c)
            if pos == -1:
                if first:
                    # if the first char was not found anywhere we're done
                    return (False, [])
                else:
                    # otherwise, find the non matching char to the left of the
                    # first char pos. Next search on has to be the left of this
                    # position
                    posLeft = candidate.rfind(c, 0, matchPos[0])
                    if posLeft == -1:
                        return (False, [])
                    else:
                        return (False, [posLeft])
            else:
                if pos < len(orig) - 1:
                    nextChar = orig[pos + 1]
                    sepScore = sepScore + 1 if nextChar in sep else sepScore
                if pos > 0:
                    prevChar = orig[pos -1]
                    sepScore = sepScore + 1 if prevChar in sep else sepScore
                    camelCaseScore = camelCaseScore + 1 if ord(orig[pos]) < 97 \
                        and ord(prevChar) >= 97 else camelCaseScore
                if pos == 0:
                    sepScore = sepScore + 1
                    camelCaseScore = camelCaseScore + 1
                matchPos.append(pos)
                if len(matchPos) > 1:
                    clusterScore = clusterScore + matchPos[-1] - matchPos[-2] - 1
                left = pos + 1
                first = False
        return (True, matchPos, clusterScore, sepScore, camelCaseScore)

    didMatch = False
    l, r = 0, len(candidate)
    while not didMatch:
        didMatch, positions, *rest = walkString(query, candidate, l, r)
        if didMatch:
            break  # all done
        if not positions:
            break  # all done too - first char didn't match

        # resume search - start looking left from this position onwards
        r = positions[0]
    return (didMatch, positions, *rest)


def fuzzyMatches(query, candidates, limit, key=None, ispath=True):
    """Find fuzzy matches among given candidates

    :query: TODO
    :candidates: TODO
    :limit: TODO
    :returns: TODO

    """
    key = idfn if not key else key
    findFirstN = True
    count = 0
    for x in candidates:
        s = key(x)
        didMatch, positions, *rest = isMatch(query, s)
        if didMatch:
            count = count + 1
            yield (x, positions, *rest, scorer((x, positions, *rest), key,
                                               ispath ))
            if findFirstN and count == limit:
                return


def usage():
    """TODO: Docstring for usage.
    :returns: TODO

    """
    print("usage")


if __name__ == "__main__":
    if len(sys.argv) == 1:
        usage()
        exit(0)

    file = "neomru_file"
    query = sys.argv[1]
    if len(sys.argv) == 3:
        file = sys.argv[1]
        query = sys.argv[2]

    with open(file) as fh:
        lines = (line.strip() for line in fh.readlines())
        for x in scoreMatches(query, lines, 10):
            print(x)

