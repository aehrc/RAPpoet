#!/bin/sh

#######################################################
## worker_01.sh
## Authors: Mitchell J. O’Brien, Anubhav Kaphle, Letitia M.F. Sng, 
## Info: This script executes the worker pushed by the driver script (driver_01.sh) for QC1
#######################################################

# xargs runs things sequentially by default, can be modified to run things in parallel using -P <number of commands>

batch_file_names=$1
chrom=$2

# Datafolder should direct to the cohort you are using, eg below
datafolder="/mnt/project/Bulk/GATK and GraphTyper WGS/GraphTyper population level WGS variants, pVCF format [500k release]/chr${chrom}"

read -r -a file_array <<< "${batch_file_names}"

# Define a function to process a single file
process_file() {
    local file="${datafolder}/$1"  # The file already contains the datafolder
    echo "Processing file: ${file}"  # Debug line
    #make sure -S flag goes to your sample list
    bcftools view -S /mnt/project/UKB_CAD_samples.csv "${file}" --force-samples | bcftools filter -i "INFO/AAScore > 0.15 && INFO/PASS_ratio > 0.05 && INFO/ABHet > 0.175 && INFO/ABHom > 0.9 && INFO/QD > 6 && QUAL >= 10" | bcftools view -v snps | bcftools norm -m-snps | bcftools annotate -x ID -I +'%CHROM:%POS:%REF:%ALT' -O b -o $(basename "${file}" .vcf.gz)_cad_seqQC_snps_split_cpraID.bcf.gz ;
    wait;
    bcftools index -c $(basename "${file}" .vcf.gz)_cad_seqQC_snps_split_cpraID.bcf.gz;
    wait;
    bcftools stats $(basename "${file}" .vcf.gz)_cad_seqQC_snps_split_cpraID.bcf.gz > $(basename "${file}" .vcf.gz)_cad_seqQC_snps_split_cpraID.STATS;
}

# Export the function so it can be used by xargs
export -f process_file
export datafolder

# Add the datafolder to each file name before passing to xargs, increase P to process more files
printf "%s\n" "${file_array[@]}" | xargs -P 70 -n 1 -I {} bash -c "process_file '{}' $datafolder"