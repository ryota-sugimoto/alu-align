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

MERGE_SAM="/usr/local/share/java/MergeSamFiles.jar"
[ -f ${REF_FASTA} ] \
  || { echo "reference fasta ${REF_FASTA} not found."; exit 1; }
[ -f ${MERGE_SAM} ] \
  || { echo "picard MergeSamFiles not found."; exit 1; }

BED="/home/ryota/some_task/yamada/cowden_alu/samples/RefSeqGene_total_hg19.bed"

#bwa
SAI_1=${OUT_DIR}/$(basename ${FASTQ_1%fq}sai)
SAI_2=${OUT_DIR}/$(basename ${FASTQ_2%fq}sai)

COMMAND=(bwa aln -t 4 ${REF_FASTA} ${FASTQ_1})
${COMMAND[@]} > ${SAI_1} || exit 1
echo
COMMAND=(bwa aln -t 4 ${REF_FASTA} ${FASTQ_2})
${COMMAND[@]} > ${SAI_2} || exit 1
echo

SAM_1=${OUT_DIR}/$(basename ${FASTQ_1%fq}sam)
COMMAND=(bwa samse ${REF_FASTA}
                   ${SAI_1}
                   ${FASTQ_1})
${COMMAND[@]} > ${SAM_1} || exit 1
echo

SAM_2=${OUT_DIR}/$(basename ${FASTQ_2%fq}sam)
COMMAND=(bwa samse ${REF_FASTA}
                   ${SAI_2}
                   ${FASTQ_2})
${COMMAND[@]} > ${SAM_2} || exit 1
echo

#sort and clip outside bed
COMMAND_1=(java -jar ${MERGE_SAM}
              INPUT=${SAM_1}
              INPUT=${SAM_2}
              OUTPUT=/dev/stdout
              SORT_ORDER=coordinate
              VALIDATION_STRINGENCY=LENIENT)
COMMAND_2=(samtools view
                    -hb
                    -L ${BED} 
                    /dev/stdin)
${COMMAND_1[@]} | ${COMMAND_2[@]} > ${SAM_1%sam}bam || exit 1

rm ${SAI_1}
rm ${SAI_2}
rm ${SAM_1}
rm ${SAM_2}
