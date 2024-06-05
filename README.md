# RAPpoet
Research Analysis Platform parallelisation orchestration engine (RAPpoet) template: Optimised driver and worker scripts for genomic analyses on UKBB cloud-based RAP

## Description  

This repository contains templates for a driver and worker approach to running a genomic analyses on the [The UK Biobank Research Analysis Platform (RAP)](https://documentation.dnanexus.com/). The UKBB RAP platform is available to all UK Biobank approved researchers, that are collaborating on an approved or in progress project. If you already have a RAP account, or wish to set one up click this [link](https://ukbiobank.dnanexus.com/landing). 

On the RAP, analyses are carried out on AWS Elastic Compute Cloud (EC2) instances with various options for storage, memory capacity, and number of cores. This workflow is designed for steps 1-3 of running a genomic analysis pipeline, leveraging the cloud environment to run the first two stages of the workflow in parallel and merge the data in step three for a logistic regression genome-wide association analysis.

### 1. Quality Control Step 1: Sample and Variant Filtering
This step involves sample filtering, variant filtering, normalisation, and renaming using bcftools.

### 2. Quality Control Step 2: Chunking and Standard Filtering
This step includes chunking VCFs, applying standard filters (geno, MAF, HWE), and generating PLINK format files.

### 3. Merging Files and Logistic Regression with PLINK2
In this step, the QC filtered files are merged into a single file, followed by a PLINK2 logistic regression analysis. 

### Environmental set up to run RAP on CLI 
The UKBB RAP proudly offers a user-friendly web User Interface (UI). However, to run RAPpoet and scale up your processes, you'll need to access the RAP via the command-line interface (CLI) using the DNAnexus Platform SDK, also known as [dx-toolkit](https://documentation.dnanexus.com/user/helpstrings-of-sdk-command-line-utilities). 

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
This pipeline doesn't adhere to a specific input or directory structure and depends on your RAP storage setup. Instead, a set of template scripts are provided in the `scripts_templates` folder, which you need to edit to match your configuration.

UKBB 500K VCFs were designed to contain variants within specific genome windows, resulting in some files having no variant information. We determined that a file size of over 3.77MB indicates a non-empty VCF. Our list of non-empty VCFs is included in the `chr_vcf_lists` folder.

```
|-- script_templates
|-- chr_vcf_lists
```

#### Orchestration Engine Scripts
The UKBB RAP operates akin to a cloud system, housing all files within a central bucket. However, performing intricate operations on these files often requires spinning up instances using apps or applets, which can quickly become costly and inefficient, especially when dealing with thousands whole genome sequencing VCFs.

RAPpoet employs two key scripts: the 'driver' and the 'worker'. The 'driver' script, executed locally, configures the instance environment, uploads essential files, and initiates the 'worker' scripts on the instances. Conversely, the 'worker' script, deployed to each instance, delineates processes for the uploaded files.

This configuration facilitates task parallelisation, enabling the 'worker' script to execute processes concurrently via the xargs tool. This optimises resource utilisation by allowing a single instance to manage multiple files, thereby reducing the requisite number of instances and streamlining job management and oversight.

In the scripts_templates folder, you'll find a driver (drive_N.sh) and worker script (worker_N.sh) for each step.

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

Cloud computing requires downloading data onto the compute instance, leading to significant time and storage costs, especially for large-scale genomic data. RAPpoet accomodates for this by utilising [dxfuse](https://github.com/dnanexus/dxfuse) which acts like a storage bucket mount but works through API calls. However the dxFUSE filesystem failed due to excessive API calls, so batch sizes and the number of concurrent pVCFs were adjusted to optimise compute performance without overloading the system and having instances killed.

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
