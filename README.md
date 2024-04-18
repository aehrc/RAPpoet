# RAPpoet
RAP paralelization orchestration engine template: Optimised driver and worker scripts for genomic analyses on UKBB cloud-based, Research Analysis Platform (RAP)

## This repository contains templates for driver and worker script for steps 1-3 for running a genomic analysis pipeline on RAP.

## Included Scripts
For each step a driver (drive_N.sh) and worker script (worker_N.sh) is included.
Driver Script: This script orchestrates the execution of the genomic analysis pipeline.

Worker Script: This script contains the necessary commands and functions for performing steps 1-3 of the pipeline.

## Pipeline Steps
Quality Control Step 1: This step involves [describe what happens in this step, e.g., filtering out low-quality data, identifying outliers].

Quality Control Step 2: In this step, [describe the actions taken, e.g., further cleaning of data, normalization procedures].

Merging Files and Logistic Regression with PLINK2: This step involves [describe the merging process and logistic regression using PLINK2 for association analysis].
