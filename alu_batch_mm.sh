#!/usr/bin/env bash

L_OPTION="-l 40"
while getopts 'l:' OPTION
do
  case $OPTION in
  l) L_OPTION="-l ${OPTARG}" ;;
  esac
done
shift $((OPTIND - 1))

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

if [[ ${FASTQ_1} == *.gz ]]
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
BED=/home/ryota/hd/some_task/yamada/cowden_alu/samples/hgRepMaskTables.bed

SCRIPT_DIR=$(cd $(dirname $0); pwd)

#clip reads
COMMAND=(${SCRIPT_DIR}/clip.sh
         ${L_OPTION}
         ${FASTQ_1}
         ${OUT_DIR})
${COMMAND[@]} || exit 1
COMMAND=(${SCRIPT_DIR}/clip.sh
         ${L_OPTION}
         ${FASTQ_2}
         ${OUT_DIR})
${COMMAND[@]} || exit 1

#align
CLIPPED_FQ_1=${OUT_DIR}/$(basename ${FASTQ_1%fq}clipped.fq)
CLIPPED_FQ_2=${OUT_DIR}/$(basename ${FASTQ_2%fq}clipped.fq)
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

#pileup
PILEUP=${BAM%bam}pileup
COMMAND=(samtools mpileup 
         -f ${REF_FASTA}
         ${BAM})
${COMMAND[@]} | awk '$4 > 0{print}' > ${PILEUP} || exit 1

[[ ${REMOVE_FASTQ_1} ]] && rm ${FASTQ_1}
[[ ${REMOVE_FASTQ_2} ]] && rm ${FASTQ_2}
