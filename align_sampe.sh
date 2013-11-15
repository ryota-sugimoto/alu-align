#!/usr/bin/env bash

[ $# == 4 ] || { echo "$0 <fastq_1> <fastq_2> <ref_fasta> <out_dir>"; exit 1; }
[ -f ${1} ] || { echo ${1} not found; exit 1; }
[ -f ${2} ] || { echo ${2} not found; exit 1; }
[ -f ${3} ] || { echo ${3} not found; exit 1; }
[ -d ${4} ] || { echo ${4} not found; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

FASTQ_1=$(file_abs_path ${1})
FASTQ_2=$(file_abs_path ${2})
REF_FASTA=$(file_abs_path ${3})
OUT_DIR=$(cd ${4}; pwd)

SORT_SAM="/usr/local/share/java/SortSam.jar"
[ -f ${REF_FASTA} ] \
  || { echo "reference fasta ${REF_FASTA} not found."; exit 1; }
[ -f ${SORT_SAM} ] \
  || { echo "picard SortSam not found."; exit 1; }

#bwa
SAI_1=${OUT_DIR}/$(basename ${FASTQ_1%fq}sai)
SAI_2=${OUT_DIR}/$(basename ${FASTQ_2%fq}sai)

COMMAND=(bwa aln -t 4 ${REF_FASTA} ${FASTQ_1})
${COMMAND[@]} > ${SAI_1} || exit 1
echo
COMMAND=(bwa aln -t 4 ${REF_FASTA} ${FASTQ_2})
${COMMAND[@]} > ${SAI_2} || exit 1
echo

SAM=${OUT_DIR}/$(basename ${FASTQ_1%fq}sam)
COMMAND=(bwa sampe ${REF_FASTA}
                   ${SAI_1}
                   ${SAI_2}
                   ${FASTQ_1}
                   ${FASTQ_2})
${COMMAND[@]} > ${SAM} || exit 1
echo

#sort
COMMAND=(java -jar ${SORT_SAM}
              INPUT=${SAM}
              OUTPUT=${SAM%sam}bam
              SORT_ORDER=coordinate
              VALIDATION_STRINGENCY=LENIENT)
${COMMAND[@]} || exit 1

#rm ${SAI_1}
#rm ${SAI_2}
#rm ${SAM}
