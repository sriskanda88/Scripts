#!/usr/bin/python

import sys

btb_hash = {}

BTB_LKUPS = "btb_lkups"
BTB_HITS = "btb_hits"
LKUPS = "lkups"
HITS = "hits"
MISSES = "misses"
HITRATE = "hitrate"

def analyse(pc, btb_lookups, btb_hits):
    if pc not in btb_hash:
        btb_hash[pc] = {BTB_LKUPS: btb_lookups, BTB_HITS: btb_hits, LKUPS: 1.0,
                        HITS: 0.0, MISSES: 1.0, HITRATE: 0}
        return

    prev_btb_lookups = btb_hash[pc][BTB_LKUPS]
    prev_btb_hits = btb_hash[pc][BTB_HITS]

    btb_hash[pc][BTB_LKUPS] = btb_lookups
    btb_hash[pc][BTB_HITS] = btb_hits
    btb_hash[pc][LKUPS] = btb_hash[pc][LKUPS] + 1

    if ( (btb_lookups - prev_btb_lookups) == (btb_hits - prev_btb_hits) ):
        btb_hash[pc][HITS] = btb_hash[pc][HITS] + 1
    else:
        btb_hash[pc][MISSES] = btb_hash[pc][MISSES] + 1

    btb_hash[pc][HITRATE] = btb_hash[pc][HITS]/btb_hash[pc][LKUPS] * 100

def print_results():
    for pc in btb_hash.keys():
        btb_pc = btb_hash[pc]

        if btb_pc[LKUPS] < 10:
            continue

        print("PC: {0:>{width}}, BTB_LKUPS: {1:{width}}, BTB_HITS: {2:{width}}, BTB_MISSES: {3:{width}}, HITRATE: {4:{width}}"
              .format(pc, btb_pc[LKUPS], btb_pc[HITS], btb_pc[MISSES], btb_pc[HITRATE], width=15))

def read_data(filename):
    with open(filename) as input_file:
        prev_pc = 0
        prev_btb_lookups = 0
        pc_count = {}

        for line in input_file:
            try:
                (tid, pc, btb_lookups, btb_hits) = line.split(",")
                pc = pc.split(":")[1].strip()
                btb_lookups = float(btb_lookups.split(":")[1].strip())
                btb_hits = float(btb_hits.split(":")[1].strip())

                if not pc in pc_count:
                    pc_count[pc] = -1

                if pc != prev_pc or (btb_lookups - prev_btb_lookups) > 5:
                    pc_count[pc] = pc_count[pc] + 1

                new_pc = str(pc) + "." + str(pc_count[pc])
                analyse(new_pc, btb_lookups, btb_hits)
                prev_pc = pc
                prev_btb_lookups = btb_lookups

            except Exception as e:
                #print "Error: %s" % e.message
                pass


def main():
    if len(sys.argv) < 2:
        print "Please provide the btb stats file name, Sir Dumass\n"
        exit()

    filename = sys.argv[1]
    read_data(filename)
    print_results()


if __name__ == '__main__':
    main()
