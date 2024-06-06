#!/bin/sh

############ A driver-worker design, driver passess the files and commands to the worker node/s, and worker node/s execute the bash worker script on its shell ############

#######################################################
## driver_03.sh
## Authors: Mitchell J. O’Brien, Anubhav Kaphle, Letitia M.F. Sng, 
## run as: bash driver_03.sh
## Info: This script executes the worker scripts for plink merging of files and logistic regression
#######################################################

# Description:
# This script set the job parameters for the EC2 instance
# using the `swiss-army-knife` tool, where all chr pgen files are merged
# and a logistic regression association is conducted with plink2

#################### SCRIPT START ##################

project=$(dx ls -l --brief | grep "Project" | awk '{print $NF}' | sed "s/(//g;s/)//g")
# be careful about the spaces in the file names, another weird stuff from them
output_dir="${project}/path/to/outdir/"

######### Jobs tuning parameters ######

# see more instance type and cost: https://20779781.fs1.hubspotusercontent-na1.net/hubfs/20779781/Product%20Team%20Folder/Rate%20Cards/BiobankResearchAnalysisPlatform_Rate%20Card_Current.pdf
instance="mem2_ssd1_v2_x48" 

# delete worker_#.sh and re-update. DNA Nexus won't replace same file , rather duplicates them
CWD=$(echo $(pwd))
dx rm /path/to/dir/worker_03.sh
wait
dx upload ${CWD}/worker_03.sh --destination /path/to/dir
wait

#get worker script path from on the Nexus Platform
worker_sh_path=$(dx find data --name "worker_03.sh" --path / --brief | head -1)

dx rm /path/to/dir/pmerge_sorted_list_${chr}
wait
#upload list of files to merge - can be created with recommended line in 'User Guide > 3.Merging Files - https://github.com/aehrc/RAPpoet'
dx upload ${CWD}/path/to/dir/pmerge_sorted_list_${chr} --destination /path/to/dir/

chr=$1
merge_list=$(dx find data --name "pmerge_sorted_list_${chr}" --json | jq -r '.[].describe.id')

dx run swiss-army-knife \
-y \
-iin="${worker_sh_path}" \
-iin="${merge_list}" \
-icmd="bash worker_03.sh ${chr}" \
--tag="plink chr ${chr}" \
--instance-type "${instance}" \
--destination="${output_dir}/chr${chr}/" \
--name "Run merge and logistic regression on ${chr}" \
--brief \
--allow-ssh \
--priority normal
