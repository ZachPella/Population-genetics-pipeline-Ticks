#!/bin/bash
#SBATCH --job-name=haplotype_caller
#SBATCH --mail-user=zpella@unmc.edu
#SBATCH --mail-type=ALL
#SBATCH --time=7-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=50G
#SBATCH --partition=batch
#SBATCH --array=1-62

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
BAMDIR=${BASEDIR}/dedup  # Updated to use deduplicated BAM files
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference
REFERENCE=masked_ixodes_ref_genome.fasta
INTERVAL_LIST=${REFERENCEDIR}/${REFERENCE}.interval_list
SAMPLE_LIST=${BASEDIR}/sample_list.txt

mkdir -p ${WORKDIR}

## Check if sample list exists
if [ ! -f "$SAMPLE_LIST" ]; then
    echo "Error: Sample list file not found: $SAMPLE_LIST"
    exit 1
fi

## Get total number of samples
TOTAL_SAMPLES=$(wc -l < "$SAMPLE_LIST")

## Check if array task ID is valid
if [ ${SLURM_ARRAY_TASK_ID} -gt ${TOTAL_SAMPLES} ]; then
    echo "Error: Array task ID ${SLURM_ARRAY_TASK_ID} exceeds number of samples (${TOTAL_SAMPLES})"
    exit 1
fi

## Get sample name from list - bulletproof method!
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

## Verify sample name is not empty
if [[ -z "$SAMPLE" ]]; then
    echo "Error: Empty sample name for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

## Set file paths
BAM_FILE="${BAMDIR}/${SAMPLE}.dedup.rg.sorted.bam"
OUTPUT_GVCF="${WORKDIR}/${SAMPLE}.raw_variants.g.vcf"

## Confirm that variables are properly assigned
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Sample: ${SAMPLE}"
echo "BAM file: ${BAM_FILE}"
echo "Reference: ${REFERENCEDIR}/${REFERENCE}"
echo "Interval list: ${INTERVAL_LIST}"
echo "Output GVCF: ${OUTPUT_GVCF}"
echo "CPUs allocated: ${SLURM_CPUS_PER_TASK}"
echo "Starting HaplotypeCaller for ${SAMPLE}..."
printf "\n"

## Load modules
module purge
module load gatk4/4.4

## Move into output directory
cd ${WORKDIR}

## Run HaplotypeCaller with the interval list
echo "Running GATK HaplotypeCaller..."
gatk HaplotypeCaller \
    -R ${REFERENCEDIR}/${REFERENCE} \
    -I ${BAM_FILE} \
    -L ${INTERVAL_LIST} \
    -ploidy 2 \
    --native-pair-hmm-threads ${SLURM_CPUS_PER_TASK} \
    -O ${OUTPUT_GVCF} \
    --emit-ref-confidence GVCF \
    --java-options "-Xmx44g"
