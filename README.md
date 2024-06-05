# RAPpoet
Research Analysis Platform parallelisation orchestration engine (RAPpoet) template: Optimised driver and worker scripts for genomic analyses on UKBB cloud-based RAP

## Description  

This repository contains templates for a driver and worker approach to running a genomic analyses on the [The UK Biobank Research Analysis Platform (RAP)](https://documentation.dnanexus.com/). The UKBB RAP platform is available to all UK Biobank approved researchers, that are collaborating on an approved or in progress project. If you already have a RAP account, or wish to set one up click this [link](https://ukbiobank.dnanexus.com/landing). 

On the RAP, analyses are conducted on AWS Elastic Compute Cloud (EC2) instances, offering diverse options for storage, memory capacity, and core numbers. This workflow is tailored for executing a genomic analysis pipeline, utilising the cloud environment to run two stages of quality control (QC) and, subsequently, merging the data for a logistic regression genome-wide association analysis in the final step.

### 1. Quality Control Step 1: Sample and Variant Filtering
This step involves sample filtering, variant filtering, normalisation, and renaming using bcftools.

### 2. Quality Control Step 2: Chunking and Standard Filtering
This step includes chunking VCFs, applying standard filters (geno, MAF, HWE), and generating PLINK format files.

### 3. Merging Files and Logistic Regression with PLINK2
In this step, the QC filtered files are merged into a single file, followed by a PLINK2 logistic regression analysis. 

## Set up

### Environment Configuration for RAP CLI 
The UKBB RAP offers a user-friendly web User Interface (UI). However, to run RAPpoet and scale up your processes, you'll need to access the RAP via the command-line interface (CLI) using the DNAnexus Platform SDK, also known as [dx-toolkit](https://documentation.dnanexus.com/user/helpstrings-of-sdk-command-line-utilities). 

Follow the steps below to set up an environment for accessing the RAP from the command line. These steps assume you have [conda](https://conda.io/projects/conda/en/latest/user-guide/install/macos.html) and [pip](https://pip.pypa.io/en/stable/installation/) installed.

Check for python within conda:
```
conda search --full-name python
```
Create environment and install python 3 (here version 3.12)
```  
conda create -n <your conda env name> python=3.12 anaconda
```
Activate the environment
```
conda activate <your conda env name>
```
Then set your compiler to target the 64-bit x86 architecture 
```
export ARCHFLAGS="-arch x86_64"
```
and finally install the dx-toolkit: 
```
pip3 install dxpy
```
### Installation
Clone the RAPpoet repository: 
```
git clone https://github.com/aehrc/RAPpoet.git
```
This pipeline doesn't adhere to a specific input or directory structure and depends on your RAP storage setup as well as the VCFs you are using. Instead, a set of template scripts are provided in the `scripts_templates` folder, which you need to edit to match your configuration. 

UKBB 500K VCFs were designed to contain variants within specific genome windows, resulting in some files having no variant information. We determined that a file size of over 3.77MB indicates a non-empty VCF. Our list of non-empty VCFs is included in the `chr_vcf_lists` folder.

```
|-- script_templates
|-- chr_vcf_lists
```
### Software   
All tools (AKA Apps & applets on RAP) required to run the RAPpoet pipeline are globally installed on RAP. The process predominantly makes use of the Swiss Army Knife (SAK) App. SAK is a generic app which can be used to perform common file operations or bioinformatics manipulations- it is preloaded with the following tools:
* bcftools (v1.15.1)
* bedtools (v2.30.0)
* BGEN (v1.1.7)
* bgzip (v1.15.1)
* BOLT-LMM (v2.4)
* Picard (v2.27.1)
* Plato (2.1.0-beta4)
* plink (v1.90b6.26)
* plink2 (v2.00a3.1LM)
* QCTool (v2.2.0)
* REGENIE (v3.1.1)
* sambamba (v0.8.2)
* samtools (v1.15.1)
* seqtk (v1.3 r106)
* tabix (v1.15.1)
* vcflib (v1.0.3)
* vcftools (v0.1.16)

## User guide   
### RAPpoet: Orchestration Engine Scripts
The UKBB RAP operates akin to a cloud system, housing all files within a central bucket. However, performing intricate operations on these files often requires spinning up instances using apps or applets, which can quickly become costly and inefficient, especially when dealing with thousands whole genome sequencing VCFs.

RAPpoet employs two key scripts: the 'driver' and the 'worker'. The 'driver' script, executed locally, configures the instance environment, uploads essential files, and initiates the 'worker' scripts on the instances. Conversely, the 'worker' script, deployed to each instance, delineates processes for the uploaded files.

This configuration facilitates task parallelisation, enabling the 'worker' script to execute processes concurrently via the xargs tool. This optimises resource utilisation by allowing a single instance to manage multiple files, thereby reducing the requisite number of instances and streamlining job management and oversight.

In the scripts_templates folder, you'll find a driver (drive_N.sh) and worker script (worker_N.sh) for each step.

The scripts are set up to be run from the directory they are held in
```
cd script_templates
```
### 1. Quality Control Step 1: Sample and Variant Filtering
This step entails transforming extensive VCF files based on sample and variant quality, as well as normalization, utilizing bcftools through the SAK app.

#### driver_01.sh template lines to edit
* line 25 : update `output_dir` variable
* line 34 : update path
* line 36 : update path
* line 53 : update path to list of vcfs to process. eg in `chr_vcf_lists` folders

#### worker_01.sh template lines to edit
* line 15: update path to the cohort you are using (Ignore if using 500K VCFs)
* line 31: Update `bcftools view -S` flag to your cohort csv (csv should have one sample per line)

run QC1:
```
bash driver_01.sh <chr>
```
output:
* filtered VCFs
* indexed VCFs
* summary stats for each VCF

### 2. Quality Control Step 2: Chunking and Standard Filtering
This step includes chunking VCFs, applying standard filters (geno, MAF, HWE), and generating PLINK format files.
First generate a list of VCFs to process, must be in order for `bcftools concat`. Here is an example how with a bash one-liner:
1. cat your_file_list.txt: Reads the list of filenames from a file.
2. awk -F'_b|_v' '{print $2, $0}': Uses awk to split the lines at _b and _v and prints the numeric part after _b followed by the original line. This helps in sorting.
3. sort -n -k1,1: Sorts the output numerically based on the first field (the numeric part extracted by awk).
4. cut -d' ' -f2-: Removes the numeric part, leaving only the original filenames.
```
dx ls "/path/to/output/directory/ukb23374_c9_b*_v1_cad_seqQC_snps_split_cpraID.bcf.gz" | awk -F'_b|_v' '{print $2, $0}' | sort -n -k1,1 | cut -d' ' -f2- 
```
#### driver_02.sh template lines to edit
* line 25 : update `output_dir` variable
* line 34 : update path
* line 36 : update path
* line 53 : update path to list of vcfs to process in order, eg. above

#### worker_02.sh template lines to edit
* line 13: update path to the VCF directory

```
bash driver_02.sh <chr>
```
* PLINK files following standard quality control filtering

### 3. Merging Files and Logistic Regression with PLINK2
In this step, the QC filtered files are merged into a single file, followed by a PLINK2 logistic regression analysis. 
```
bash driver_03.sh
```
## Resource usage

DNAnexus analyses are executed on Virtual Machines. They have a range of AWS and Azure [instance types](https://documentation.dnanexus.com/developer/api/running-analyses/instance-types) available on the DNAnexus Platform. Instances can be started with different [priority levels](https://dnanexus.gitbook.io/uk-biobank-rap/working-on-the-research-analysis-platform/managing-job-priority) which determine execution times, spot VM interruptions and restart policies.

A list of instance types which you have access to is available via the command-line interface (CLI), by entering the command 
```
dx run --instance-type-help
```
Steps described in this repository were run using AWS EC2 instances and optimised on chromosomes 21 and 9 as described below. Full optimisation/benchmarking and estimated costs to be included on publication. 

| Job          | Instance type    | Job distribution           | Average CPU Usage (%) | Average Memory Usage (GiB)   | Run Time (Minutes) | Notes                       |
|--------------|----------|----------------------------|-----------|------------|----------|-----------------------------|
| Driver_1       | mem1_ssd1_v2_x72 | 140vcf/instance | ~60%         | ~75     | ~200-300  |                             |
| Driver_2  | mem2_ssd1_v2_x16   | 160vcf/instance          | ~50%         | ~6   | ~250-350   |     |
| Driver_3        | mem2_ssd1_v2_x48   |  all VCFs 1 instance       | 2         | see note   | ~15   | variable based on # VCFs|

Cloud computing requires downloading data onto the compute instance, leading to significant time and storage costs, especially for large-scale genomic data. RAPpoet accomodates for this by utilising [dxfuse](https://github.com/dnanexus/dxfuse) which acts like a storage bucket mount but works through API calls. Unfortunately, when optimising CPU usage the dxFUSE filesystem failed due to excessive API calls, so batch sizes and the number of concurrent pVCFs had to be adjusted to optimise compute performance without overloading the system and having instances killed. A list of tested parameters are outlined below.

| Test | Instance            | Batch size | VCFs processed in parallel  | Failed  | Error message                                                                                                           |
|------|---------------------|-------|-----|---------|------------------------------------------------------------------------------------------------------------------|
| 1    | mem2_ssd1_v2_x96    | 382   | 192 | All     | The machine running the job became unresponsive                                                                 |
| 2    | mem2_ssd1_v2_x48    | 382   | 100 | All     | The machine running the job became unresponsive. Error while running the command (refer to the job log for more information). Warning: Out of memory error occurred during this job. |
| 3    | mem2_ssd1_v2_x48    | 382   | 70  | Partial | The machine running the job became unresponsive. Error while running the command (refer to the job log for more information). Warning: Out of memory error occurred during this job. |
| 4    | mem1_ssd1_v2_x72    | 140   | 70  | All     | Error while running the command (refer to the job log for more information). Warning: Out of memory error occurred during this job. |
| 5    | mem2_ssd1_v2_x48    | 140   | 70  | 0       | NA                                                                                                               |


### Authors 

- Mitchell J. O'Brien (Transformational Bioinformatics group, aehrc, CSIRO)
- Anubhav Kaphle (Transformational Bioinformatics group, aehrc, CSIRO)
- Letitia M.F. Sng (Transformational Bioinformatics group, aehrc, CSIRO)

## Resources 
- [The UK Biobank Research Analysis Platform (RAP)](https://documentation.dnanexus.com/) 
- [Index of dx commands](https://documentation.dnanexus.com/user/helpstrings-of-sdk-command-line-utilities)
- [File format specifications](https://samtools.github.io/hts-specs/)
- [Bcftools documentation](https://samtools.github.io/bcftools/)
- [Plink2 documentation](https://www.cog-genomics.org/plink/2.0/)
