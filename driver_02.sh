#!/bin/sh

############ A driver-worker design, driver passess the files and commands to the worker node/s, and worker node/s execute the bash worker script on its shell ############

#######################################################
## driver_02.sh
## Authors: Mitchell J. O’Brien, Anubhav Kaphle, Letitia M.F. Sng, 
## run as: bash driver_02.sh
## Info: This script executes the worker scripts for QC2
#######################################################

#################### SCRIPT START ##################

project=$(dx ls -l --brief | grep "Project" | awk '{print $NF}' | sed "s/(//g;s/)//g")
# be careful about the spaces in the file names
output_dir="${project}/path/to/outdir/"

######### Jobs tuning parameters ######
# see more instance type and cost: https://20779781.fs1.hubspotusercontent-na1.net/hubfs/20779781/Product%20Team%20Folder/Rate%20Cards/BiobankResearchAnalysisPlatform_Rate%20Card_Current.pdf
instance="mem2_ssd1_v2_x16" # update the instance as needed
batch_size=160              # update as needed

# delete worker_#.sh and re-update. DNA Nexus won't replace same file , rather duplicates them
CWD=$(echo $(pwd))
dx rm /path/to/dir/worker_02.sh
wait
dx upload ${CWD}/worker_02.sh --destination /path/to/dir
wait

#get worker script path from on the Nexus Platform
worker_sh_path=$(dx find data --name "worker_02.sh" --path / --brief | head -1)

# Initialize batch number, update to last batch run when splitting the process on larger chrs
batch_number=0

#Set the chr you're working on
chr=9

declare -a files=()
counter=0
batchSize=${batch_size} # set it above

# list the files you want to process in a local file, the list should be in order
ids_file="${CWD}/path/to/files/to/process.IDs"

# Read from your IDs file
while read -r line; do
    vcffile_id=$(echo "$line" | cut -d',' -f1) # File ID is the first column
    files+=("$vcffile_id")
    ((counter++))

    if [ "$counter" -eq "$batchSize" ]; then

        ((batch_number++))
        # Process the batch of files
        echo "counter is at $counter"
        echo "Processing batch: ${files[*]}"

        dx run swiss-army-knife -y \
        -iin="${worker_sh_path}" \
        -icmd="bash worker_02.sh \"${files[*]}\" ${chr}" \
        --tag="QC2 GATK chr ${chr}" \
        --instance-type "${instance}" \
        --destination="${output_dir}/chr${chr}/" \
        --name "Run QC2 batch no ${batch_number}" \
        --brief --allow-ssh --priority normal


        # Reset for the next batch
        files=()
        counter=0

        # # Add the break statement to exit the loop after the first batch for optimising purposes
        # break

    fi
done <"$ids_file"

# Process any remaining files in the last batch
    if [ "$counter" -gt 0 ]; then

        ((batch_number++))
        echo "Processing final batch: ${files[*]}"

        dx run swiss-army-knife -y \
        -iin="${worker_sh_path}" \
        -icmd="bash worker_02.sh \"${files[*]}\" ${chr}" \
        --tag="QC2 GATK chr ${chr}" \
        --instance-type "${instance}" \
        --destination="${output_dir}/chr${chr}/" \
        --name "Run QC2 on final batch no ${batch_number}" \
        --brief --allow-ssh --priority normal

    fi
done