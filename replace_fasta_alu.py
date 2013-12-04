#!/usr/bin/env python

def parse_positions(file):
  res = []
  for line in file:
    (chr, range) = line.split(":")
    (begin, end) = map(int, range.split("-"))
    res.append((chr, begin, end))
  return res

def rewrite_fasta(file, positions, replace_char="A"):
  for line in file:
    line = line.strip()
    if line[0] == ">":
      current_ref = line[1:]
      current_pos = 1
    else:
      line_len = len(line)
      for pos in positions:
        (chr, begin, end) = pos
        if chr == current_ref:
          line_slice = line.__getslice__
          l1 = line_slice(0, begin-current_pos)
          l2 = line_slice(begin-current_pos, end-current_pos+1)
          l3 = line_slice(end-current_pos+1, line_len)
          line = l1 + replace_char*len(l2) + l3
      current_pos += len(line)
    yield line + "\n"

if __name__ == "__main__":
  import argparse
  parser = argparse.ArgumentParser()
  parser.add_argument("fasta")
  parser.add_argument("positions")
  args = parser.parse_args()
  
  import sys
  fasta = open(args.fasta)
  positions = parse_positions(open(args.positions))
  map(sys.stdout.write, rewrite_fasta(fasta, positions))
