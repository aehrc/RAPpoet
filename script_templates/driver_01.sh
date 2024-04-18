#!/bin/sh

############ A driver-worker design, driver passess the files and commands to the worker node/s, and worker node/s execute the bash worker script on its shell ############

#######################################################
## driver_01.sh
## Authors: Mitchell J. O’Brien, Anubhav Kaphle, Letitia M.F. Sng, 
## run as: bash driver_01.sh
## Info: This script executes the worker scripts for QC1
#######################################################

#################### SCRIPT START ##################

project=$(dx ls -l --brief | grep "Project" | awk '{print $NF}' | sed "s/(//g;s/)//g")
# be careful about the spaces in the file names
output_dir="${project}/path/to/outdir/"

######### Jobs tuning parameters ######
# see more instance type and cost: https://20779781.fs1.hubspotusercontent-na1.net/hubfs/20779781/Product%20Team%20Folder/Rate%20Cards/BiobankResearchAnalysisPlatform_Rate%20Card_Current.pdf
instance="mem2_ssd1_v2_x48" # update the instance as needed 
batch_size=140              # update as needed

# delete worker_#.sh and re-update. DNA Nexus won't replace same file , rather duplicates them
CWD=$(echo $(pwd))
dx rm /path/to/dir/worker_01.sh
wait
dx upload ${CWD}/worker_01.sh --destination /path/to/dir
wait

#get worker script path from on the Nexus Platform
worker_sh_path=$(dx find data --name "worker_01.sh" --path / --brief | head -1)

# Initialize batch number, update to last batch run when splitting the process on larger chrs
batch_number=0

#Set the chr you're working on
chr=9

declare -a files=()
counter=0
batchSize=${batch_size} # set it above

# list the files you want to process in a local file
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

        #Run command to spin up instance with swiss-army-knif and call worker file to execute
        #--head-job-on-demand use this flag to make on demand instances
        dx run swiss-army-knife \
        -y \
        -iin="${worker_sh_path}" \
        -icmd="bash worker_01.sh \"${files[*]}\" ${chr}" \
        --tag="QC GATK chr ${chr}" \
        --instance-type "${instance}" \
        --destination="${output_dir}/chr${chr}/" \
        --name "Run batch no ${batch_number}" \
        --brief \
        --allow-ssh \
        --priority normal

        # Reset for the next batch
        files=()
        counter=0
    fi
done <"$ids_file"

# Process any remaining files in the last batch
if [ "$counter" -gt 0 ]; then

    ((batch_number++))
    echo "Processing final batch: ${files[*]}"
                
    #Run command to spin up instance with swiss-army-knif and call worker file to execute
    #--head-job-on-demand use this flag to make on demand instances
        dx run swiss-army-knife \
        -y \
        -iin="${worker_sh_path}" \
        -icmd="bash worker_01.sh \"${files[*]}\" ${chr}" \
        --tag="QC GATK chr ${chr}" \
        --instance-type "${instance}" \
        --destination="${output_dir}/chr${chr}/" \
        --name "Run on final batch no ${batch_number}" \
        --brief \
        --allow-ssh \
        --priority normal
    fi
done
