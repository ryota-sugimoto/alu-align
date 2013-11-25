#!/usr/bin/env bash

[ $# == 1 ] || { echo "${0} <fastq>"; exit 1; }
[ -f ${1} ] || { echo "${1} not found"; exit 1; }

awk_script_1='
BEGIN{ c=1; } 
{ if (c < 4) { 
    printf("%s\t",$0); 
    c+=1; } 
  else { 
    c = 1; 
    print; } }'
 
awk_script_2='
BEGIN{ OFS="\t"; }
{ l=length($2);
  e_clip_l=match($2, /\.\.*$/);
  f_clip_l=match($2, /[ATGC][ATGC]*/);
  if (e_clip_l) {
    seq=substr($2,1,e_clip_l-1);
    score=substr($4,1,e_clip_l-1)} 
  else {
    seq=$2;
    score=$4 }
  if (f_clip_l) {
    seq=substr(seq,f_clip_l);
    score=substr(score,f_clip_l); }
  gsub(/\./,"N",seq); 
  if (seq) { print $1,seq,$3,score } }'

awk "${awk_script_1}" ${1} | awk "${awk_script_2}" | tr "\t" "\n" 
