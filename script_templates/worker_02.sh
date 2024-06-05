#!/bin/sh

#######################################################
## worker_02.sh
## Authors: Mitchell J. O’Brien, Anubhav Kaphle, Letitia M.F. Sng, 
## Info: This script executes the worker pushed by the driver script (driver_02.sh) for QC2
#######################################################

batch_file_names=$1
chrom=$2

# Datafolder should direct to the cohort you are using, eg below
datafolder="/mnt/project/Bulk/GATK and GraphTyper WGS/VariantSpark/chr${chrom}"

read -r -a file_array <<< "${batch_file_names}"

#Define a function to process a multiple files
# The following function processes a set of VCF files:
# 1. Prepares a list of file paths based on the provided file names and data folder.
# 2. Concatenates the VCF files into a single compressed VCF file.
# 3. Determines the genomic coordinates (start and stop positions) of the concatenated VCF file.
# 4. Generates PLINK files from the concatenated VCF data with specified parameters (genotype, minor allele frequency, and Hardy-Weinberg equilibrium).
# 5. Outputs the PLINK files with a modified name based on genomic coordinates.
# 6. Cleans up temporary files created during the process.
process_file() {
    local file="$1"  # The file already contains the datafolder
    local chunk_no="$2"
    echo "Processing file: ${file}, chunk: ${chunk_no}"  # Debug line

    # Split the file variable by spaces
    IFS=' ' read -r -a files <<< "$file"

    # Loop over each file
    for f in "${files[@]}"; do
        # Execute dx find data for the current file and extract the folder using jq
        # folder=$(dx find data --name "$f" --json | jq -r '.[].describe.folder')
        file_list+=("$datafolder/$f"$'\n')
    done

    #trim white spaces
    # vcf_list=$(echo "${file_list[@]}" | tr ' ' '\n')
    for file in "${file_list[@]}"; do
        trimmed_file+="${file#"${file%%[![:space:]]*}"}"
        #  echo "$trimmed_file"
    done

    # echo "${trimmed_file[@]}"
    bcftools concat -f <(echo "${trimmed_file[@]}") --threads 8 -O z -o temp_${chunk_no}.vcf.gz ;
    wait
    start=$(zcat temp_${chunk_no}.vcf.gz | grep -v '#' | head -1 | cut -f2)
    stop=$(zcat temp_${chunk_no}.vcf.gz | tail -1 | cut -f2)
	plink2 --vcf temp_${chunk_no}.vcf.gz --geno 0.02 --maf 0.00001 --hwe 1E-6 midp --threads 8 --memory 24000 --out temp_${chunk_no}_2 --make-pfile ;
    wait
    plink2 --pfile temp_${chunk_no}_2 --set-all-var-ids @:#:$\r:$\a --threads 8 --memory 24000 --out ukb23374_c${chrom}_${start}_${stop}_v1_cad_seqQC_snps_split_cpraID_geno0.02_maf0.00001_hwe1-6 --make-pfile;
    rm temp_${chunk_no}.vcf.gz 
    rm temp_${chunk_no}_2*
}

# Export and execute the function 
export -f process_file
export datafolder
export chrom

# Define number of files to process at a time
chunk_size=80

# set limit of parallelization
parallel_limit=2

# Initialize a counter for chunk numbers
chunk_counter=1

# Loop through the array with chunk_size and parallel_limit
for ((i = 0; i < ${#file_array[@]}; i += chunk_size * parallel_limit)); do
    # Create a sublist of files to process in parallel
    sublist=("${file_array[@]:i:chunk_size * parallel_limit}")

    # Loop through the sublist with parallel_limit
    for ((j = 0; j < ${#sublist[@]}; j += chunk_size)); do
        # Create a chunk of files to process in parallel
        chunk=("${sublist[@]:j:chunk_size}")

        # Join the chunk into a single string with space-separated values
        joined_chunk="${chunk[*]}"

        # Process the joined chunk in parallel and pass the chunk number
        (bash -c "process_file '$joined_chunk' $chunk_counter") &

        # Increment the chunk counter for the next iteration
        ((chunk_counter++))
    done

    # Wait for the background jobs to finish before starting the next batch
    wait
done