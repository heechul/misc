#! /usr/bin/python
# usage: python minsquare.py <data> <upperhull> > <output>

import sys
import os
import getopt

import corestats


def main():
    try:
        optlist, args = getopt.getopt(sys.argv[1:], 'd:h', ["deadline=", "help"])
    except getopt.GetoptError as err:
        print str(err)
        sys.exit(2)

    deadline = 0
    deadline_miss = 0;
    
    for opt, val in optlist:
        if opt in ("-h", "--help"):
            print args[0] + " [-d <deadline (ms)>]"
        elif opt in ("-d", "--deadline"):
            deadline = float(val)
        else:
            assert False, "unhandled option"


    file1 = open(args[0], 'r')
            
    items = []
    while(True):
        line = file1.readline()
        if not line:
            break
        tokens = line.split();
    # print tokens
        try:
            num  = float(tokens[0])
        except ValueError:
            break
        items[len(items):] = [num]
        if deadline > 0 and num > deadline:
            deadline_miss += 1
            
    # stats = corestats.Stats(items)
    stats = corestats.Stats(items[1:(len(items)-1)]) # remove first and last.
    print 
    print "----[", args[0], "]---"
    print "deadline: ", deadline
    print "count: ", stats.count()
    print "deadline miss: ", deadline_miss
    print "deadline miss ratio: %.2f pct" % (float(deadline_miss) * 100 / stats.count())
    print "min: %.2f" % stats.min()
    print "avg: %.2f" % stats.avg()
    print "90pctile: %.2f" % stats.percentile(90)
    print "95pctile: %.2f" % stats.percentile(95)
    print "99pctile: %.2f" %stats.percentile(99)
    print "median: ", stats.median()
    print "max: %.2f" % stats.max()
    print "stdev: %.2f" % stats.stdev()
    #avg  min max 99pctile
    print "LINE(avg|min|max|99pct|stdev|median): %.2f %.2f %.2f %.2f %.2f %.2f\n" % (stats.avg(), \
        stats.min(), stats.max(), stats.percentile(99), stats.stdev(), stats.median())

if __name__ == "__main__":
    main()

