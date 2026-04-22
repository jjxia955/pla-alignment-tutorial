#!/bin/bash

set -euo pipefail

# Example preprocessing helper for plate or bulk PLA runs downloaded from BaseSpace.
# Update the variables below before running.

PROJECT_ID="<BASESPACE_PROJECT_ID>"
FASTQ_DIR="/path/to/project/Fastq"
MANIFEST_OUT="$FASTQ_DIR/fastq_manifest.csv"

module load bs-cli

# Inspect available projects first if needed.
bs --config default list projects

# Download the project into FASTQ_DIR.
bs download project -i "$PROJECT_ID" -o "$FASTQ_DIR" -vvv

# Move FASTQ files out of BaseSpace sample subdirectories.
for sample_dir in "$FASTQ_DIR"/*_ds.*; do
  [ -d "$sample_dir" ] || continue
  mv "$sample_dir"/*.fastq.gz "$FASTQ_DIR"
done

# Concatenate four lanes into one FASTQ per sample/read.
for lane1 in "$FASTQ_DIR"/*_L001_*.fastq.gz; do
  [ -f "$lane1" ] || continue
  lane2="${lane1/L001/L002}"
  lane3="${lane1/L001/L003}"
  lane4="${lane1/L001/L004}"
  merged="${lane1/_L001_/_}"
  cat "$lane1" "$lane2" "$lane3" "$lane4" > "$merged"
done

# Remove original lane-level FASTQs after confirming merged files were created.
rm -f "$FASTQ_DIR"/*_L00[1-4]_*.fastq.gz

# Optionally remove the original BaseSpace subdirectories.
# rm -rf "$FASTQ_DIR"/*_ds.*

# Build the Smart-seq manifest: absolute_path_to_fastq.gz,sample_id
find "$FASTQ_DIR" -type f -name "*.fastq.gz" -exec bash -c 'echo "$1,$(basename "$1" .fastq.gz)"' _ {} \; > "$MANIFEST_OUT"

echo "Wrote manifest to $MANIFEST_OUT"
