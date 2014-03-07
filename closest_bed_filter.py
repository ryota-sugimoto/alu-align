#!/usr/bin/env python

import sys
l = [ l.strip() for l in sys.stdin]
l.sort(key = lambda s: int(s.split()[17]))
id_count = {}
for s in l:
  id = s.split()[17]
  id_count[id] = id_count.get(id,0) + 1

def f(prev_id,s):
  id = s.split()[17]
  if id != prev_id and id_count[id] > 2:
    print s + "\t" + str(id_count[id])
  return id

reduce(f, l, "")
