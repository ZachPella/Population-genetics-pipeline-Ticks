# *Ixodes scapularis* Population Genetics Pipeline

A comprehensive GATK-based pipeline for population genomics analysis of deer tick (*Ixodes scapularis*) whole genome sequencing data. This pipeline follows GATK best practices for variant calling from raw NovaSeq reads to population genetic analysis.

## Overview

This pipeline processes paired-end Illumina NovaSeq data through quality control, alignment, variant calling, and population genetics analysis. Designed for SLURM cluster environments with robust error handling and scalable array job processing.

## Pipeline Workflow

```
Raw FASTQ → Lane Concatenation → QC/Trimming → Alignment → BAM Processing → Variant Calling → Population Analysis
```

### Detailed Steps:
1. **Lane concatenation** - Merge L001/L002 lanes per sample
2. **Quality control & trimming** - fastp preprocessing  
3. **Alignment** - BWA-MEM to *I. scapularis* reference genome
4. **BAM processing** - SAM→BAM conversion, sorting, read groups, deduplication
5. **Variant calling** - GATK HaplotypeCaller (GVCF mode)
6. **Joint genotyping** - GenotypeGVCFs across all samples
7. **Population analysis** - PLINK format conversion and PCA

## Requirements

### Software Dependencies
- **SLURM** workload manager
- **fastp** (≥0.20) - Read trimming and QC
- **BWA** (≥0.7.17) - Read alignment  
- **samtools** (≥1.10) - BAM file manipulation
- **GATK4** (≥4.4) - Variant calling pipeline
- **PLINK** (≥1.9) - Population genetics analysis
- **Python** (≥3.7) - Data processing and visualization

### Reference Genome
- **Masked *Ixodes scapularis* reference genome** (`masked_ixodes_ref_genome.fasta`)
- Must be BWA-indexed with `.fai` and `.dict` files
- Interval list required for efficient variant calling

### Input Data Format
- **Paired-end Illumina NovaSeq** FASTQ files
- **Lane structure**: `*_L001_R1_*.fastq.gz`, `*_L001_R2_*.fastq.gz`, `*_L002_R1_*.fastq.gz`, `*_L002_R2_*.fastq.gz`
- **Sample list**: Text file with one sample name per line

## Installation

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/ixodes-popgen-pipeline.git
cd ixodes-popgen-pipeline
```

2. **Set up directory structure:**
```bash
mkdir -p {concatenated_fastq,trimmed_reads,sam_files,bam_files,readgroups,dedup,genotyping}
mkdir -p {fastqc_results,err_and_out}
```

3. **Prepare reference genome:**
```bash
# Index reference with BWA
bwa index masked_ixodes_ref_genome.fasta

# Create sequence dictionary
gatk CreateSequenceDictionary -R masked_ixodes_ref_genome.fasta

# Create interval list
bash 0_make_interval_list.sh
```

4. **Create sample list:**
```bash
# List all sample names (one per line) in sample_list.txt
ls /path/to/raw/data/ > sample_list.txt
```

## Usage

### Quick Start (62 samples)
```bash
# 1. Concatenate lane files
sbatch --array=1-62 g0_concatenate_all_samples.sh

# 2. Quality control and trimming  
sbatch --array=1-62 g1_fastp1.sh

# 3. FastQC analysis (optional)
sbatch --array=1-62 g1.5_fastqc.sh

# 4. Alignment with BWA-MEM
sbatch --array=1-62 g2_sam_generation.sh

# 5. SAM to BAM conversion and processing
sbatch --array=1-62 g3_sam_to_bam.sh

# 6. Add read groups
sbatch --array=1-62 g5_add_read_group.sh

# 7. Remove optical duplicates
sbatch --array=1-62 g6_remove_optical_duplicates.sh

# 8. Variant calling (per sample)
sbatch --array=1-62 1_haplotypecaller_array.sh

# 9. Consolidate GVCFs
sbatch 2_consolidate_gvcfs.sh

# 10. Joint genotyping
sbatch 3_genotype_gvcfs.sh

# 11. Convert to PLINK format
sbatch 5_plink.sh
```

### Configuration

Update paths in scripts to match your system:
```bash
# Base directory (update in all scripts)
BASEDIR=/work/fauverlab/zachpella/scripts_ticksJune2025

# Reference directory
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference

# Sample count (update --array parameter)
#SBATCH --array=1-62  # Adjust for your sample size
```

## Detailed Step Descriptions

### Step 0: Prepare Interval List
```bash
bash 0_make_interval_list.sh
```
- Creates interval list from reference genome for efficient parallel processing
- Required for GATK HaplotypeCaller

### Step 1: Lane Concatenation  
```bash
sbatch --array=1-62 g0_concatenate_all_samples.sh
```
- **Input**: Raw FASTQ files split across lanes (L001, L002)
- **Output**: Merged FASTQ files per sample (`{sample}_R1_merged.fastq.gz`)
- **Resources**: 4 CPUs, 16GB RAM, 6 hours per sample

### Step 2: Quality Control & Trimming
```bash
sbatch --array=1-62 g1_fastp1.sh
```
- **Tool**: fastp with minimum length 50bp
- **Output**: Trimmed FASTQ files (`{sample}_R1_trimmed.fastq.gz`)
- **QC Reports**: HTML reports per sample
- **Resources**: 1 CPU, 15GB RAM, 6 hours per sample

### Step 3: Read Alignment
```bash
sbatch --array=1-62 g2_sam_generation.sh
```
- **Tool**: BWA-MEM with 4 threads
- **Output**: SAM alignment files
- **Parameters**: `-M` flag for Picard compatibility
- **Resources**: 4 CPUs, 45GB RAM, 6 days per sample

### Step 4: BAM Processing Pipeline
```bash
# Convert SAM to BAM, sort, and index
sbatch --array=1-62 g3_sam_to_bam.sh

# Add read group information
sbatch --array=1-62 g5_add_read_group.sh

# Remove optical duplicates
sbatch --array=1-62 g6_remove_optical_duplicates.sh
```
- **Tools**: samtools, GATK MarkDuplicates
- **Output**: Processed BAM files ready for variant calling
- **Quality metrics**: Flagstats and duplicate statistics

### Step 5: Variant Calling
```bash
sbatch --array=1-62 1_haplotypecaller_array.sh
```
- **Tool**: GATK HaplotypeCaller in GVCF mode
- **Ploidy**: Diploid (ploidy=2)
- **Output**: Individual GVCF files per sample
- **Resources**: 12 CPUs, 50GB RAM, 7 days per sample

### Step 6: Joint Genotyping
```bash
# Consolidate GVCFs
sbatch 2_consolidate_gvcfs.sh

# Joint genotyping across all samples
sbatch 3_genotype_gvcfs.sh
```
- **Tool**: GATK GenotypeGVCFs
- **Output**: Multi-sample VCF with population-level variants
- **Benefits**: Improved genotype quality and variant discovery

### Step 7: Population Analysis
```bash
sbatch 5_plink.sh
```
- **Tool**: PLINK format conversion
- **Output**: Binary PLINK files (.bed, .bim, .fam)
- **Ready for**: PCA, ADMIXTURE, FST analysis, GWAS

## Output Files

### Primary Results
- **`final_variants.vcf`** - Joint-genotyped variants across all samples
- **`tick_variants.{bed,bim,fam}`** - PLINK binary format for population analysis
- **`comprehensive_stats_summary.csv`** - Alignment and quality statistics

### Intermediate Files
- **`concatenated_fastq/`** - Lane-merged FASTQ files
- **`trimmed_reads/`** - Quality-trimmed reads
- **`bam_files/`** - Aligned and processed BAM files  
- **`genotyping/`** - Individual GVCF files
- **`dedup/`** - Deduplicated BAM files

### Quality Control
- **`fastqc_results/`** - Read quality reports
- **`*.fastp.html`** - Trimming statistics
- **Flagstat reports** - Alignment statistics
- **Duplicate metrics** - PCR duplicate rates

## Resource Requirements

### Computational Resources
- **Total CPU hours**: ~50,000 CPU hours for 62 samples
- **Peak memory**: 50GB RAM per variant calling job
- **Storage**: ~2TB for intermediate files
- **Runtime**: 2-3 weeks for complete pipeline

### Per-Step Resources
| Step | CPUs | Memory | Time | 
|------|------|---------|------|
| Concatenation | 4 | 16GB | 6h |
| Trimming | 1 | 15GB | 6h |
| Alignment | 4 | 45GB | 6d |
| BAM processing | 4 | 30GB | 12h |
| Variant calling | 12 | 50GB | 7d |
| Joint genotyping | 8 | 64GB | 2d |

## Quality Control Metrics

### Expected Results
- **Alignment rate**: >90% for high-quality tick DNA
- **Duplicate rate**: 10-25% depending on library complexity
- **Variant count**: 1-5M SNPs depending on population diversity
- **Transition/transversion ratio**: ~2.0 for high-quality variants

### Quality Flags
- **Low alignment**: <80% alignment rate (check reference quality)
- **High duplicates**: >40% duplicates (library complexity issues)
- **Low variant count**: <100K variants (coverage or reference issues)

## Troubleshooting

### Common Issues

1. **Memory errors in HaplotypeCaller**:
   ```bash
   # Increase memory allocation
   --java-options "-Xmx48g"  # Adjust based on available RAM
   ```

2. **BWA index missing**:
   ```bash
   # Re-index reference genome
   bwa index masked_ixodes_ref_genome.fasta
   ```

3. **Sample list mismatches**:
   ```bash
   # Verify sample names match directory structure
   head sample_list.txt
   ls /path/to/raw/data/
   ```

4. **Array job size mismatches**:
   ```bash
   # Count samples and update array parameter
   wc -l sample_list.txt
   # Update: #SBATCH --array=1-N
   ```

### File Path Updates
All scripts contain absolute paths that need updating:
```bash
# Update these paths in all scripts:
BASEDIR=/work/fauverlab/zachpella/scripts_ticksJune2025  # Your base directory
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference  # Reference location
```

## Population Genetics Applications

This pipeline produces data suitable for:
- **Population structure analysis** (PCA, ADMIXTURE)
- **Phylogeographic studies** 
- **Genome-wide association studies (GWAS)**
- **Selection scans** (FST, Tajima's D)
- **Demographic modeling** (PSMC, δaδi)
- **Adaptive introgression** detection

## Citation

If you use this pipeline, please cite:
- **GATK**: McKenna, A. et al. The Genome Analysis Toolkit: a MapReduce framework for analyzing next-generation DNA sequencing data. Genome Res. 20, 1297-1303 (2010).
- **BWA**: Li, H. & Durbin, R. Fast and accurate short read alignment with Burrows-Wheeler transform. Bioinformatics 25, 1754-1760 (2009).
- **fastp**: Chen, S. et al. fastp: an ultra-fast all-in-one FASTQ preprocessor. Bioinformatics 34, i884-i890 (2018).

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test with small datasets
4. Submit a pull request

## Contact

- **Author**: Zach Pella  
- **Institution**: Fauver Lab, University of Nebraska Medical Center
- **Issues**: Use GitHub issues for bug reports and questions

---

## File Structure
```
ixodes-popgen-pipeline/
├── README.md
├── LICENSE  
├── scripts/
│   ├── 0_make_interval_list.sh
│   ├── g0_concatenate_all_samples.sh
│   ├── g1_fastp1.sh
│   ├── g1.5_fastqc.sh
│   ├── g2_sam_generation.sh
│   ├── g3_sam_to_bam.sh
│   ├── g5_add_read_group.sh
│   ├── g6_remove_optical_duplicates.sh
│   ├── 1_haplotypecaller_array.sh
│   ├── 2_consolidate_gvcfs.sh
│   ├── 3_genotype_gvcfs.sh
│   └── 5_plink.sh
├── config/
│   └── pipeline_config.yaml
├── docs/
│   ├── installation.md
│   ├── troubleshooting.md
│   └── population_analysis.md
└── example_data/
    └── sample_list.txt
```
