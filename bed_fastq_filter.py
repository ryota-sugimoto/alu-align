#!/usr/bin/env python

import sys

def read_id(bed):
  return set(s.split()[3] for s in bed)

def read_fastq(fastq, ids):
  length = len(iter(ids).next())
  for s in fastq:
    id = s.strip().split()[0][1:].split("/")[0]
    seq = fastq.next().strip()
    fastq.next()
    fastq.next()
    if id in ids:
      yield (id, seq)

def insert_newline(s,n):
  res = []
  remain = s
  while remain:
    res.append(remain[:n])
    remain = remain[n:]
  return "\n".join(res) 

if __name__ == "__main__":
  import argparse
  parser = argparse.ArgumentParser()
  parser.add_argument("bed", type=argparse.FileType("r"))
  parser.add_argument("fastq")
  args = parser.parse_args()
  
  ids = read_id(args.bed)

  import gzip
  if args.fastq[-3:] == ".gz" or args.fastq[-4:] == ".gzip":
    file_opener = gzip.open
  else:
    file_opener = open

  for id,read in read_fastq(file_opener(args.fastq), ids):
    print ">%s\n%s" % (id, insert_newline(read,50))
