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


#bwa
SAI_1=${OUT_DIR}/$(basename ${FASTQ_1%.fq}.sai)
SAI_2=${OUT_DIR}/$(basename ${FASTQ_2%.fq}.sai)

COMMAND=(bwa aln -t 4 ${REF_FASTA} ${FASTQ_1})
${COMMAND[@]} > ${SAI_1} || exit 1
echo
COMMAND=(bwa aln -t 4 ${REF_FASTA} ${FASTQ_2})
${COMMAND[@]} > ${SAI_2} || exit 1
echo

#collect unmapped reads
UNMAPPED_FQ_1=${OUT_DIR}/$(basename ${FASTQ_1%.fq}.unmapped.fq)
UNMAPPED_FQ_2=${OUT_DIR}/$(basename ${FASTQ_2%.fq}.unmapped.fq)
COMMAND_1=(bwa samse ${REF_FASTA} 
                     ${SAI_1}
                     ${FASTQ_1})
COMMAND_2=(gawk '$0!~/^@/&&and(4,$2){printf"@%s\n%s\n+\n%s\n",$1,$10,$11}')
${COMMAND_1[@]} | ${COMMAND_2[@]} > ${UNMAPPED_FQ_1} || exit 1
echo
COMMAND_1=(bwa samse ${REF_FASTA} 
                     ${SAI_2}
                     ${FASTQ_2})
${COMMAND_1[@]} | ${COMMAND_2[@]} > ${UNMAPPED_FQ_2} || exit 1

rm ${SAI_1}
rm ${SAI_2}
