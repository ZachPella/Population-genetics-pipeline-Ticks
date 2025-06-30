#!/bin/bash
#SBATCH --job-name=genomicsdb_import
#SBATCH --mail-user=zpella@unmc.edu
#SBATCH --mail-type=ALL
#SBATCH --time=4-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --cpus-per-task=16
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


## Automatically detect all GVCF files from HaplotypeCaller output
GVCF_INPUT=""
GVCF_COUNT=0

echo "Detecting GVCF files in ${WORKDIR}..."
for GVCF_FILE in ${WORKDIR}/*.raw_variants.g.vcf; do
    if [ -f "$GVCF_FILE" ]; then
        echo "Found GVCF: $GVCF_FILE"
        GVCF_INPUT="${GVCF_INPUT} -V ${GVCF_FILE}"
        ((GVCF_COUNT++))
    fi
done


## Load modules
module purge
module load gatk4/4.4

## Move into output directory
cd ${WORKDIR}

echo "Working directory: $(pwd)"
echo "Using interval list: $INTERVAL_LIST"
echo "Using reference: ${REFERENCEDIR}/${REFERENCE}"

## Remove existing genomicsdb if it exists
if [ -d "genomicsdb" ]; then
    echo "Removing existing genomicsdb directory..."
    rm -rf genomicsdb
fi

## Run GenomicsDBImport with multiple optimizations
echo "Running GenomicsDBImport on ${GVCF_COUNT} samples..."
gatk GenomicsDBImport \
    ${GVCF_INPUT} \
    --genomicsdb-workspace-path genomicsdb \
    -L ${INTERVAL_LIST} \
    --java-options "-Xmx150g -XX:+UseG1GC -XX:ParallelGCThreads=4" \
    --reader-threads 12
