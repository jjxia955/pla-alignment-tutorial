#!/bin/bash
#SBATCH --job-name=pla_10x_alignment
#SBATCH --output=/path/to/project/logs/10x_pla_alignment.out
#SBATCH --error=/path/to/project/logs/10x_pla_alignment.err
#SBATCH --partition=broadwl
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=32G

set -euo pipefail

module load java

MY_DIR=/path/to/project
JAR=$MY_DIR/PLA_alignment.jar
AB_BC_LIST=$MY_DIR/metadata/antibody_barcode.csv
PLA_FASTQ_DIR=$MY_DIR/fastq_pla
CDNA_BARCODES=$MY_DIR/cdna/outs/filtered_feature_bc_matrix/barcodes.tsv.gz
OUT_DIR=$MY_DIR/alignment

mkdir -p "$OUT_DIR"
cd "$MY_DIR"

java -jar "$JAR" ReadAlignment10x \
R1="$PLA_FASTQ_DIR/sample_10x_S1_R1_001.fastq.gz" \
R2="$PLA_FASTQ_DIR/sample_10x_S1_R2_001.fastq.gz" \
O="$OUT_DIR/10x_ReadAlignment_out.txt.gz" \
AB_BC_LIST="$AB_BC_LIST" \
SUMMARY="$OUT_DIR/10x_ReadAlignment_summary.txt" \
HEADER=TRUE

java -jar "$JAR" CellBarcodeCorrection \
I="$OUT_DIR/10x_ReadAlignment_out.txt.gz" \
O="$OUT_DIR/10x_cellbarcodecorrection_out.txt.gz" \
MODE=10X \
CELL_BC_LIST="$CDNA_BARCODES" \
SUFFIX=-1 \
READCOUNT_CUTOFF=100 \
SUMMARY="$OUT_DIR/10x_cellbarcodecorrection_summary.txt" \
HEADER=FALSE

java -jar "$JAR" UMIMerging \
I="$OUT_DIR/10x_cellbarcodecorrection_out.txt.gz" \
O="$OUT_DIR/10x_UMI_out.txt.gz" \
SUMMARY="$OUT_DIR/10x_UMI_summary.txt"

java -jar "$JAR" DigitalCount \
I="$OUT_DIR/10x_UMI_out.txt.gz" \
O="$OUT_DIR/10x_count_matrix.txt.gz" \
CELL_BC_LIST=NONE \
SUMMARY="$OUT_DIR/10x_count_summary.txt" \
DUPLICATE_EXPORT="$OUT_DIR/10x_DigitalCountduplicate_export.txt.gz" \
REMOVE_DUPLICATE=TRUE
