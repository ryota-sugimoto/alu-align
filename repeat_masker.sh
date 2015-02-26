#!/usr/bin/env bash

[ $# == 2 ] || { echo "$0 <bed> <fastq>"; exit 1; }
[ -f ${1} ] || { echo ${1} not exist; exit 1; }
[ -f ${2} ] || { echo ${2} not exist; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

bed=$(file_abs_path ${1})
fastq=$(file_abs_path ${2})

repeat_masker=""

$(dirname ${0})/bed_fastq_filter.py ${bed} ${fastq} \
  | ${repeat_masker} /dev/stdin || exit 1
