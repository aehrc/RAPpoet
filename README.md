# RAPpoet
Research Analysis Platform parallelisation orchestration engine (RAPpoet) template: Optimised driver and worker scripts for genomic analyses on UKBB cloud-based RAP

## Description  

This repository contains templates for a driver and worker approach to running a genomic analyses on the [The UK Biobank Research Analysis Platform (RAP)](https://documentation.dnanexus.com/). The UKBB RAP platform is available to all UK Biobank approved researchers, that are collaborating on an approved or in progress project. If you already have a RAP account, or wish to set one up click this [link](https://ukbiobank.dnanexus.com/landing). 

On the RAP, analyses are carried out on AWS Elastic Compute Cloud (EC2) instances with different options for storage, memory capacity, and number of cores.  This workflow is designed for the for steps 1-3 for running a genomic analysis pipeline, leveraging the cloud environment to run the first two stages of the workflow in parallel and merging the data in step three for a logistic regression genome-wide association analysis.

#### Quality Control Step 1:
This step involves sample filtering and variant filtering, normalisation and renaming.

#### Quality Control Step 2:
In this step involves chunking vcfs, standard filering (geno, maf, hwe), and generating plink format files.

#### Merging Files and Logistic Regression with PLINK2:
This step involves merging the QC filtered files into a single file and running a plink2 Logistic regression analysis. 

#### Orchestration Engine Scripts
For each step a driver (drive_N.sh) and worker script (worker_N.sh) is included.

Driver Script: This script orchestrates the execution of the genomic analysis pipeline.

Worker Script: This script that contains the necessary commands and functions for performing steps 1-3 of the pipeline.

### Environment for RAP 
The UKBB RAP proudly supports a user friendly web User interface (UI). However, to run RAPpoet and to scale up your processes you will need to access the RAP via the command-line interface (CLI) using the DNAnexus Platform SDK - also called dx-toolkit. 

Following the steps below you can set up an environment to access the RAP from the command line interface. These steps assume you have [conda](https://conda.io/projects/conda/en/latest/user-guide/install/macos.html) and [pip](https://pip.pypa.io/en/stable/installation/) installed.

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
Then 
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

## Set up 

This pipeline has specific input and directory structure requirements. The set up instructions below will help you to achieve the required set up, which will resemble the following:

```
|-- script_templates
|-- chr_vcf_lists
```
### Authors 

- Mitchell J. O'Brien (Transformational Bioinformatics group, aehrc, CSIRO)
- Anubhav Kaphle (Transformational Bioinformatics group, aehrc, CSIRO)
- Letitia M.F. Sng (Transformational Bioinformatics group, aehrc, CSIRO)

## Resources 
[The UK Biobank Research Analysis Platform (RAP)](https://documentation.dnanexus.com/) 
[Index of dx commands](https://documentation.dnanexus.com/user/helpstrings-of-sdk-command-line-utilities)  
