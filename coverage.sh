#!/usr/bin/env bash
[ $# == 3 ] || { echo "$0 <bam> <bed> <out_dir>"; exit 1; }
[ -f ${1} ] || { echo ${1} not found; exit 1; }
[ -f ${2} ] || { echo ${2} not found; exit 1; }
[ -d ${3} ] || { echo ${3} not found; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

BAM=$(file_abs_path ${1})
BED=$(file_abs_path ${2})
OUT_DIR=$(cd ${3}; pwd;)

COVERAGE=${OUT_DIR}/$(basename ${BAM%bam}bed)
COMMAND1=(bamToBed -i ${BAM})
COMMAND2=(coverageBed -a ${BED}
                      -b stdin)
${COMMAND1[@]} | ${COMMAND2[@]} > ${COVERAGE} || exit 1
awk '$7 == 0 {print}' ${COVERAGE} > ${COVERAGE%bed}0cover.bed || exit 1

COMMAND1=(closestBed -d
                     -a ${COVERAGE%bed}0cover.bed
                     -b ${BED})
COMMAND2=(bedtools cluster -d 10)
${COMMAND1[@]} \
  | awk '$17 > 2' \
  | sort -k1,1 -k2,2n \
  | ${COMMAND2[@]} \
  | $(dirname ${0})/closest_bed_filter.py \
  > ${COVERAGE%bed}0cover.closest.filtered.bed || exit 1
