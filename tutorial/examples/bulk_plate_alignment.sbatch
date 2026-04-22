#!/bin/bash
#SBATCH --job-name=pla_bulk_plate_alignment
#SBATCH --output=/path/to/project/logs/bulk_plate_alignment.out
#SBATCH --error=/path/to/project/logs/bulk_plate_alignment.err
#SBATCH --partition=broadwl
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=16G

set -euo pipefail

module load java

MY_DIR=/path/to/project
JAR=/path/to/PLA_alignment.jar
FASTQ_MANIFEST=$MY_DIR/fastq/fastq_manifest.csv
AB_BC_LIST=$MY_DIR/metadata/antibody_barcode.csv
OUT_DIR=$MY_DIR/alignment

mkdir -p "$OUT_DIR"

java -jar "$JAR" ReadAlignmentSmartSeq \
R1_LIST="$FASTQ_MANIFEST" \
O="$OUT_DIR/ReadAlignmentSmartSeq_out.txt.gz" \
AB_BC_LIST="$AB_BC_LIST" \
SUMMARY="$OUT_DIR/ReadAlignmentSmartSeq_summary.txt" \
HEADER=TRUE

java -jar "$JAR" UMIMerging \
I="$OUT_DIR/ReadAlignmentSmartSeq_out.txt.gz" \
O="$OUT_DIR/UMIMerging_out.txt.gz" \
SUMMARY="$OUT_DIR/UMIMerging_summary.txt"

java -jar "$JAR" DigitalCount \
I="$OUT_DIR/UMIMerging_out.txt.gz" \
O="$OUT_DIR/pla_count_matrix.txt.gz" \
CELL_BC_LIST=NONE \
DUPLICATE_EXPORT="$OUT_DIR/DigitalCountduplicate_export.txt.gz" \
REMOVE_DUPLICATE=TRUE \
SUMMARY="$OUT_DIR/DigitalCount_summary.txt"
