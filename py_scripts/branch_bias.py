#!/usr/bin/python

import sys
import pprint
import warnings

T = '1'
NT = '0'

ALWAYS_TAKEN = "Always Taken"
ALWAYS_NOT_TAKEN = "Always Not Taken"
BIASED_TAKEN = "Biased Taken"
BIASED_NOT_TAKEN = "Biased Not Taken"
UNBIASED = "Unbiased"
CONST_LOOP = "Const Loop"
TEMP_BIAS = "Temp Bias"

branch_hash = {}
branch_type_hash = {
        ALWAYS_TAKEN: [],
        ALWAYS_NOT_TAKEN: [],
        BIASED_TAKEN: [],
        BIASED_NOT_TAKEN: [],
        UNBIASED: [],
        CONST_LOOP: [],
        TEMP_BIAS: []
        }


def isBranchAlwaysTaken(branch):
    return len(branch_hash[branch]) == len([x for x in branch_hash[branch] if x == T])

def isBranchAlwaysNotTaken(branch):
    return len(branch_hash[branch]) == len([x for x in branch_hash[branch] if x == NT])

def isBranchBiasedTaken(branch):
    return len(branch_hash[branch]) * 0.9 <= len([x for x in branch_hash[branch] if x == T])

def isBranchBiasedNotTaken(branch):
    return len(branch_hash[branch]) * 0.9 <= len([x for x in branch_hash[branch] if x == NT])

def isConstantLoop(branch):
    hist = list(branch_hash[branch])

    if hist[0] != T or hist[-1] != NT:
        return False

    # Build a pattern to match
    pattern = []
    while hist[0] != NT:
        pattern.append(hist.pop(0))

    pattern.append(hist.pop(0))
    pattern_index = len(pattern) - 1
    pattern_str = "".join(pattern)

    # Match the pattern
    while len(hist) >= pattern_index:
        tmp_str = "".join(hist[0:pattern_index])

        if tmp_str != pattern_str:
            return False

        del hist[0:pattern_index]

    if len(hist) > 0:
        return False
    else:
        return True

def isTempBias(branch):
    hist = list(branch_hash[branch])
    prev_outcome = ''
    cur_outcome = ''
    match_count = 0

    while len(hist) > 0:
        cur_outcome = hist.pop(0)
        if cur_outcome == prev_outcome:
            match_count += 1
        prev_outcome = cur_outcome

    if (match_count > 0.9 * len(branch_hash[branch])
        and branch in branch_type_hash[UNBIASED]):
        return True
    else:
        return False

def classify_branches():
    for branch in branch_hash.keys():
        branch_type = UNBIASED

        if isBranchAlwaysTaken(branch):
            branch_type = ALWAYS_TAKEN

        elif isBranchAlwaysNotTaken(branch):
            branch_type = ALWAYS_NOT_TAKEN

        elif isBranchBiasedTaken(branch):
            branch_type = BIASED_TAKEN

        elif isBranchBiasedNotTaken(branch):
            branch_type = BIASED_NOT_TAKEN

        branch_type_hash[branch_type].append(branch)

        if isConstantLoop(branch):
            branch_type_hash[CONST_LOOP].append(branch)

        if isTempBias(branch):
            branch_type_hash[TEMP_BIAS].append(branch)

def read_data(filename):
    with open(filename) as input_file:
        for line in input_file:
            hist = line.strip().split(":")
            branch = hist.pop(0)
            branch_hash[branch] = hist

def print_results():
    #pp = pprint.PrettyPrinter(indent=4)
    #pp.pprint(branch_type_hash)

    print "Results"
    print "-------"
    print "{0:<{width1}}{1}{2:>{width2}}".format("Total Static", "|", len(branch_hash.keys()), width1 = 25, width2 = 10)
    print "{0:<{width1}}{1}{2:>{width2}}".format("Total Dynamic", "|", reduce((lambda y, z: y + z), map((lambda x:len(x)), branch_hash.values())), width1 = 25, width2 = 10)

    for typ in [ALWAYS_TAKEN, ALWAYS_NOT_TAKEN, BIASED_TAKEN, BIASED_NOT_TAKEN, UNBIASED, CONST_LOOP, TEMP_BIAS]:
        print "{0:<{width1}}|{1:>{width2}}".format(typ + " (S)", len(branch_type_hash[typ]), width1 = 25, width2 = 10)
        print "{0:<{width1}}|{1:>{width2}}".format(typ + " (D)", reduce((lambda y, z: y + z), map((lambda x: len(branch_hash[x])), branch_type_hash[typ]), 0), width1 = 25, width2 = 10)

def main():
    if len(sys.argv) < 2:
        print "Please provide the raw branches file, Sir Dumass."
        exit()

    filename = sys.argv[1]
    read_data(filename)
    classify_branches()
    print_results()


if __name__ == "__main__":
    main()
