#!/usr/bin/env bash

[ $# == 3 ] || { echo "$0 <fastq_1> <fastq_2> <out_dir>"; exit 1; }
[ -f ${1} ] || { echo ${1} not found; exit 1; }
[ -f ${2} ] || { echo ${2} not found; exit 1; }
[ -d ${3} ] || { echo ${3} not found; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

FASTQ_1=$(file_abs_path ${1})
FASTQ_2=$(file_abs_path ${2})
OUT_DIR=$(cd ${3}; pwd)

if [[ ${FASTQ_2} == *.gz ]]
then
  gunzip -c ${FASTQ_2} > ${OUT_DIR}/$(basename ${FASTQ_1%.gz})
  FASTQ_1=${OUT_DIR}/$(basename ${FASTQ_1%.gz})
  REMOVE_FASTQ_1=t
fi 
if [[ ${FASTQ_2} == *.gz ]]
then
  gunzip -c ${FASTQ_2} > ${OUT_DIR}/$(basename ${FASTQ_2%.gz})
  FASTQ_2=${OUT_DIR}/$(basename ${FASTQ_2%.gz})
  REMOVE_FASTQ_2=t
fi 

REF_FASTA=/home/share/db/ucsc.hg19.fasta
BED=/home/ryota/some_task/yamada/cowden_alu/samples/hgRepMaskTables.bed

SCRIPT_DIR=$(cd $(dirname $0); pwd)

#collect unmapped reads
COMMAND=(${SCRIPT_DIR}/collect_unmapped_read.sh 
         ${FASTQ_1}
         ${FASTQ_2}
         ${REF_FASTA}
         ${OUT_DIR})
${COMMAND[@]} || exit 1;
echo

#clip reads
UNMAPPED_FQ_1=${OUT_DIR}/$(basename ${FASTQ_1%fq}unmapped.fq)
UNMAPPED_FQ_2=${OUT_DIR}/$(basename ${FASTQ_2%fq}unmapped.fq)
COMMAND=(${SCRIPT_DIR}/clip.sh
         ${UNMAPPED_FQ_1}
         ${OUT_DIR})
${COMMAND[@]} || exit 1
COMMAND=(${SCRIPT_DIR}/clip.sh
         ${UNMAPPED_FQ_2}
         ${OUT_DIR})
${COMMAND[@]} || exit 1

#align
CLIPPED_FQ_1=${UNMAPPED_FQ_1%fq}clipped.fq
CLIPPED_FQ_2=${UNMAPPED_FQ_2%fq}clipped.fq
COMMAND=(${SCRIPT_DIR}/align.sh
         ${CLIPPED_FQ_1}
         ${CLIPPED_FQ_2}
         ${REF_FASTA}
         ${OUT_DIR})
${COMMAND[@]} || exit 1

#coverage
BAM=${CLIPPED_FQ_1%fq}bam
COMMAND=(${SCRIPT_DIR}/coverage.sh
         ${BAM}
         ${BED}
         ${OUT_DIR})
${COMMAND[@]} || exit 1

[[ ${REMOVE_FASTQ_1} ]] && rm ${FASTQ_1}
[[ ${REMOVE_FASTQ_2} ]] && rm ${FASTQ_2}
