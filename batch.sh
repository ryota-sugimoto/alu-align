#!/usr/bin/env bash

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

conf_file=$(dirname ${0})/config
while getopts 's:' OPTION
do
  case ${OPTION} in
  s) [ -f ${OPTARG} ] || { echo "${OPTARG} not found"; exit 1; }
     conf_file=$(file_abs_path ${OPTARG}) ;;
  esac
done

declare -A conf
#default values
conf=( ["bwa_t_opt"]=4
       ["reference_fasta"]="/home/share/db/ucsc.hg19.fasta"
       ["fastx_clipper_l_opt"]=40
       ["merge_sam_jar"]="/usr/local/share/java/MergeSamFiles.jar"
       ["bed"]="~/hd/some_task/yamada/cowden_alu/samples/RefSeqGene_total_hg19.bed"
       ["repeat_mask_bed"]="/home/ryota/hd/some_task/yamada/cowden_alu/samples/hgRepMaskTables.bed" )

while read key value
do 
  conf[${key}]=${value}
done < ${conf_file}


[ ${#} == 3 ] || { echo "$0 <fastq_1> <fastq_2> <out_dir>"; exit 1; }
[ -f ${1} ] || { echo "${1} not found"; exit 1; }
[ -f ${2} ] || { echo "${2} not found"; exit 1; }
[ -d ${3} ] || { echo "${3} not found"; exit 1; }

fastq_1=$(file_abs_path ${1})
fastq_2=$(file_abs_path ${2})
out_dir=$(cd ${3}; pwd)

#collect unmapped reads
sai_1=${out_dir}/$(basename ${fastq_1} \
                   | sed -E 's/(fastq|fq)(\.(gz|gzip))?$//')sai
sam_1=${sai_1%sai}sam
sai_2=${out_dir}/$(basename ${fastq_2} \
                   | sed -E 's/(fastq|fq)(\.(gz|gzip))?$//')sai
sam_2=${sai_2%sai}sam
command=(bwa aln -t ${conf["bwa_t_opt"]} 
                 ${conf["reference_fasta"]})
${command[@]} ${fastq_1} > ${sai_1} || exit 1; echo
${command[@]} ${fastq_2} > ${sai_2} || exit 1; echo

unmapped_fastq_1=${sai_1%sai}unmapped.fq
unmapped_fastq_2=${sai_2%sai}unmapped.fq
command_1=(bwa samse ${conf["reference_fasta"]})
command_2=(gawk '$0!~/^@/&&and(4,$2){printf"@%s\n%s\n+\n%s\n",$1,$10,$11}')
${command_1[@]} ${sai_1} ${fastq_1} > ${sam_1}
${command_2[@]} ${sam_1} > ${unmapped_fastq_1} || exit 1; echo
${command_1[@]} ${sai_2} ${fastq_2} >${sam_2}
${command_2[@]} ${sam_2} > ${unmapped_fastq_2} || exit 1; echo
 
rm ${sai_1} ${sai_2}

#clip reads
alu_sequences=(GGCCGGGCGCGGTGGCTCACGCCTGTAATC
               GATTACAGGCGTGAGCCACCGCGCCCGGCC
               GCCTGGGCGACAGAGCGAGACTCCGTCTCA
               TGAGACGGAGTCTCGCTCTGTCGCCCAGGC)

clipped_fastq_1=${unmapped_fastq_1%unmapped.fq}clipped.fq
clipped_fastq_2=${unmapped_fastq_2%unmapped.fq}clipped.fq
[ -f ${clipped_fastq_1} ] && rm ${clipped_fastq_1}
[ -f ${clipped_fastq_2} ] && rm ${clipped_fastq_2}
for seq in ${alu_sequences[@]}
do
  command=(fastx_clipper -a ${seq}
                         -Q 33
                         -c -n -v
                         -l ${conf["fastx_clipper_l_opt"]}
                         -M 30
                         -i )
  ${command[@]} ${unmapped_fastq_1} >> ${clipped_fastq_1} || exit 1; echo
  echo
  ${command[@]} ${unmapped_fastq_2} >> ${clipped_fastq_2} || exit 1; echo
  echo
done

#align
sai_1=${clipped_fastq_1%fq}sai
sai_2=${clipped_fastq_2%fq}sai
command=(bwa aln -t ${conf["bwa_t_opt"]} ${conf["reference_fasta"]})
${command[@]} ${clipped_fastq_1} > ${sai_1} || exit 1; echo
${command[@]} ${clipped_fastq_2} > ${sai_2} || exit 1; echo

sam_1=${sai_1%sai}sam
sam_2=${sai_2%sai}sam
command=(bwa samse ${conf["reference_fasta"]})
${command[@]} ${sai_1} ${clipped_fastq_1} > ${sam_1} || exit 1; echo
${command[@]} ${sai_2} ${clipped_fastq_2} > ${sam_2} || exit 1; echo

bam=${sai_1%sai}bam
command_1=(java -jar ${conf["merge_sam_jar"]}
           INPUT=${sam_1}
           INPUT=${sam_2}
           OUTPUT=/dev/stdout
           SORT_ORDER=coordinate
           VALIDATION_STRINGENCY=LENIENT)
command_2=(samtools view -hb -L ${conf["bed"]} /dev/stdin)
${command_1[@]} | ${command_2[@]} > ${bam} || exit 1; echo
rm ${sai_1} ${sai_2} ${sam_1} ${sam_2}

#coverage
coverage=${bam%bam}bed
command_1=(bamToBed -i ${bam})
command_2=(coverageBed -a ${conf["repeat_mask_bed"]} -b stdin)
${command_1[@]} | ${command_2[@]} > ${coverage} || exit 1; echo
awk '$7 == 0 {print}' ${coverage} > ${coverage%bed}0cover.bed || exit 1; echo

command_1=(closestBed -d
                      -a ${coverage%bed}0cover.bed
                      -b ${conf["repeat_mask_bed"]})
command_2=(bedtools cluster -d 10)
${command_1[@]} \
 | awk '$17 > 2' \
 | sort -k1,1 -k2,2n \
 | ${command_2[@]} \
 | $(dirname ${0})/closest_bed_filter.py \
 > ${coverage%bed}0cover.closest.filtered.bed || exit 1
