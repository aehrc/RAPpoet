#!/bin/sh

#######################################################
## worker_03.sh
## Authors:Mitchell J. O’Brien, Anubhav Kaphle, Letitia M.F. Sng, 
## Info: This script executes the worker pushed by the driver script (driver_03.sh)
## Plink merge and logistic regression
#######################################################

chrom=$1
datafolder="/mnt/project/Bulk/GATK and GraphTyper WGS/VariantSpark/chr${chrom}"

plink2 --pmerge-list pmerge_sorted_list_${chrom} \
        --pmerge-list-dir "${datafolder}" \
        --memory 190000 \
        --out ukb23374_c${chrom}_merged_v1_cad_seqQC_snps_split_cpraID_geno0.02_maf0.00001_hwe1-6 \
        --make-pfile

wait

# make sure the --pheno flag is directed to your phenotype file
plink2 --pfile ukb23374_c${chrom}_merged_v1_cad_seqQC_snps_split_cpraID_geno0.02_maf0.00001_hwe1-6 \
       --glm \
       --mind 0.02 \
       --memory 190000 \
       --pheno /mnt/project/path/to/dir/chd_cov_26k_WGS.txt \
       --pheno-name case \
       --covar /mnt/project/chd_cov_26k_WGS.txt  \
       --covar-name PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,Age,sex,BMI \
       --out logistic_regression_output --1 