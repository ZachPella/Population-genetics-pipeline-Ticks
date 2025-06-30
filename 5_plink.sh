#!/bin/bash
#SBATCH --job-name=pop_structure
#SBATCH --mail-user=zpella@unmc.edu
#SBATCH --mail-type=ALL
#SBATCH --time=12:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=16G
#SBATCH --partition=batch

## Set working directory and variables
WORKDIR=/work/fauverlab/zachpella/practice_pop_gen
cd ${WORKDIR}

## Create output directory
mkdir -p population_structure

## Load modules
module purge
module load plink/1.90  # Load PLINK1.9
module load plink2      # Load PLINK2

## Step 1: Convert VCF to PLINK format using PLINK1.9 and filter for biallelic variants
plink --vcf genotyping/filtered_vcfs/pass_snps.vcf.gz \
      --make-bed \
      --out population_structure/tick_population \
      --allow-extra-chr \
      --biallelic-only strict

## Step 2: Perform PCA using PLINK2 on the dataset
plink2 --bfile population_structure/tick_population \
       --pca 20 \
       --out population_structure/tick_pca \
       --allow-extra-chr
