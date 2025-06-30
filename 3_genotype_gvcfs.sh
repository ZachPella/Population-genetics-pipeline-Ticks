#!/bin/bash
#SBATCH --job-name=genotype_gvcfs_ticks_na
#SBATCH --mail-user=zpella@unmc.edu
#SBATCH --mail-type=ALL
#SBATCH --time=2-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --cpus-per-task=30
#SBATCH --mem=200G
#SBATCH --partition=batch

## Record relevant job info
START_DIR=$(pwd)
HOST_NAME=$(hostname)
RUN_DATE=$(date)
echo "Starting working directory: ${START_DIR}"
echo "Host name: ${HOST_NAME}"
echo "Run date: ${RUN_DATE}"
printf "\n"

## Set working directory and variables
BASEDIR=/work/fauverlab/zachpella/scripts_ticksJune2025
WORKDIR=${BASEDIR}/genotyping
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference
REFERENCE=masked_ixodes_ref_genome.fasta
INTERVAL_LIST=${REFERENCEDIR}/${REFERENCE}.interval_list


## Load modules
module purge
module load gatk4/4.4
module load bcftools/1.21

## Move into output directory
cd ${WORKDIR}

echo "Starting GenotypeGVCFs..."
echo "Working directory: $(pwd)"

## Run GenotypeGVCFs
gatk GenotypeGVCFs \
    -R ${REFERENCEDIR}/${REFERENCE} \
    -V gendb://genomicsdb \
    -L ${INTERVAL_LIST} \
    -O ${WORKDIR}/cohort_ticks_june2025.vcf.gz \
    --java-options "-Xmx150g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Dsamjdk.compression_level=1" \
    --create-output-variant-index
    --number-genotype-threads ${SLURM_CPUS_PER_TASK}

echo "GenotypeGVCFs completed successfully"

## Get variant stats
echo "Generating VCF statistics..."
bcftools stats ${WORKDIR}/cohort_ticks_june2025.vcf.gz > ${WORKDIR}/cohort_ticks_june2025_vcf_stats.txt

echo "VCF statistics completed"

## Summary information
echo "Final outputs:"
echo "  VCF file: ${WORKDIR}/cohort_ticks_june2025.vcf.gz"
echo "  VCF index: ${WORKDIR}/cohort_ticks_june2025.vcf.gz.tbi"
echo "  VCF stats: ${WORKDIR}/cohort_ticks_june2025_vcf_stats.txt"

## Quick variant count
VARIANT_COUNT=$(bcftools view -H ${WORKDIR}/cohort_ticks_june2025.vcf.gz | wc -l)
echo "Total variants called: ${VARIANT_COUNT}"

echo "Genotyping pipeline completed successfully!"
printf "\n"
