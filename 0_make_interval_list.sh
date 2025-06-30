#!/bin/bash
#SBATCH --job-name=0_create_interval_list_ticks
#SBATCH --mail-user=zpella@unmc.edu
#SBATCH --mail-type=ALL
#SBATCH --time=1-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --mem=20G
#SBATCH --partition=batch

## record relevant job info
START_DIR=$(pwd)
HOST_NAME=$(hostname)
RUN_DATE=$(date)
echo "Starting working directory: ${START_DIR}"
echo "Host name: ${HOST_NAME}"
echo "Run date: ${RUN_DATE}"
printf "\n"

## set working directory and variables
BASEDIR=/work/fauverlab/zachpella/scripts_ticksJune2025
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference
REFERENCE=${REFERENCEDIR}/masked_ixodes_ref_genome

## load modules
module purge
module load bedtools/2.27
module load gatk4/4.4
module load samtools/1.19

## move into working directory
cd ${REFERENCEDIR}

# Create .fai index if it doesn't exist
if [ ! -f "${REFERENCE}.fasta.fai" ]; then
    echo "Creating FASTA index..."
    samtools faidx ${REFERENCE}.fasta
fi

# Create .dict file if it doesn't exist
if [ ! -f "${REFERENCE}.dict" ]; then
    echo "Creating sequence dictionary..."
    gatk CreateSequenceDictionary \
        -R ${REFERENCE}.fasta \
        -O ${REFERENCE}.dict
fi

# get BED file from index file
echo "Creating BED file..."
awk -v FS="\t" -v OFS="\t" '{print $1 FS "0" FS ($2-1)}' ${REFERENCE}.fasta.fai > ${REFERENCE}.bed

# convert BED file to interval list file
echo "Converting BED to interval list..."
gatk \
        BedToIntervalList \
        -I ${REFERENCE}.bed \
        -O ${REFERENCE}.interval_list \
        -SD ${REFERENCE}.dict

echo "Files created:"
echo "BED file: ${REFERENCE}.bed"
echo "Interval list: ${REFERENCE}.interval_list"
