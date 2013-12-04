#!/usr/bin/env bash

L_OPTION="-l 40"
while getopts 'l:' OPTION
do
  case $OPTION in
  l) L_OPTION="-l ${OPTARG}" ;;
  esac
done
shift $((OPTIND - 1))

[ $# == 2 ] || { echo "$0 <fastq> <out_dir>"; exit 1; }
[ -f ${1} ] || { echo ${1} not found; exit 1; }
[ -d ${2} ] || { echo ${2} not found; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

FASTQ=$(file_abs_path ${1})
OUT_DIR=$(cd ${2}; pwd;)

alu_seqs=(GGCCGGGCGCGGTGGCTCACGCCTGTAATC
          GATTACAGGCGTGAGCCACCGCGCCCGGCC
          GCCTGGGCGACAGAGCGAGACTCCGTCTCA
          TGAGACGGAGTCTCGCTCTGTCGCCCAGGC)

OUT_FASTQ=${OUT_DIR}/$(basename ${FASTQ%fq}clipped.fq)
for seq in ${alu_seqs[@]}
do
  COMMAND=(fastx_clipper -a ${seq}
                         -Q 33
                         -c -n -v
                         ${L_OPTION}
                         -M 30
                         -i ${FASTQ})
  ${COMMAND[@]} >> ${OUT_FASTQ} || exit 1
  echo
done
