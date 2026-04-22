# PLA Alignment Tutorial

This tutorial is designed for a GitHub repository that explains how to run the PLA alignment Java program from raw sequencing files to final count matrices.

It covers:

1. Downloading FASTQ files from Illumina BaseSpace
2. Preprocessing FASTQ files, especially lane concatenation for plate or bulk runs
3. Running the PLA alignment workflow for plate or bulk data
4. Running the PLA alignment workflow for 10x-based data

## What This Program Does

The Java program supports these core steps:

- `ReadAlignmentSmartSeq`: align plate or bulk style PLA reads from a manifest of FASTQ files
- `ReadAlignment10x`: align paired 10x PLA FASTQ files
- `CellBarcodeCorrection`: correct cell barcodes against a reference barcode list, typically for 10x
- `UMIMerging`: merge reads with the same UMI and PLA product
- `DigitalCount`: generate the final PLA count matrix

## Expected Inputs

You will usually need:

- A compiled jar file such as `PLA_alignment.jar`
- Gzipped FASTQ files
- An antibody barcode lookup table in CSV format
- For plate or bulk mode, a CSV manifest listing FASTQ file path and sample or cell ID
- For 10x mode, a filtered barcode list from the matched cDNA run, usually `barcodes.tsv.gz`

## Build The Program

This repository already contains a Maven project in `PLA_alignment_java/`.

Example build:

```bash
cd PLA_alignment_java
mvn package
```

After packaging, point the tutorial commands to the jar generated under `PLA_alignment_java/target/`.

## Recommended Tutorial Layout

```text
tutorial/
├── README.md
├── examples/
│   ├── bulk_plate_alignment.sbatch
│   ├── 10x_pla_alignment.sbatch
│   ├── preprocess_from_basespace.sh
│   ├── antibody_barcode_template.csv
│   └── fastq_manifest_template.csv
└── notes/
    └── command_reference.md
```

## Step 1: Download FASTQ Files From Illumina BaseSpace

One practical approach is the BaseSpace CLI.

Example:

```bash
module load bs-cli
bs --config default list projects
bs download project -i <PROJECT_ID> -o <OUTPUT_DIR> -vvv
```

Notes:

- Find the project ID in the BaseSpace web interface
- BaseSpace often downloads each sample into its own subdirectory
- Plate or bulk datasets may contain four lanes per sample and need concatenation before alignment

The example helper script is in [tutorial/examples/preprocess_from_basespace.sh](/Users/junjie/Desktop/Alignment/tutorial/examples/preprocess_from_basespace.sh).

## Step 2: Preprocess FASTQ Files

For plate or bulk workflows, preprocessing commonly includes:

1. Moving FASTQ files out of BaseSpace-created subdirectories
2. Concatenating lanes such as `L001` to `L004`
3. Removing the original per-lane FASTQ files
4. Building a manifest file for `ReadAlignmentSmartSeq`

The manifest format is:

```csv
/absolute/path/to/sample_R1_001.fastq.gz,sample_id
```

Use [tutorial/examples/fastq_manifest_template.csv](/Users/junjie/Desktop/Alignment/tutorial/examples/fastq_manifest_template.csv) as a template.

## Step 3: Plate or Bulk Workflow

This mode uses `ReadAlignmentSmartSeq`.

Pipeline:

1. `ReadAlignmentSmartSeq`
2. `UMIMerging`
3. `DigitalCount`

Example SLURM script:

[tutorial/examples/bulk_plate_alignment.sbatch](/Users/junjie/Desktop/Alignment/tutorial/examples/bulk_plate_alignment.sbatch)

Key points:

- Input is `R1_LIST=<manifest.csv>`
- `AB_BC_LIST` is the antibody-to-barcode lookup table
- `CELL_BC_LIST=NONE` in `DigitalCount` exports all detected barcodes
- `REMOVE_DUPLICATE=TRUE` removes duplicated PLA products across cells

### Plate or Bulk Example Commands

```bash
java -jar PLA_alignment.jar ReadAlignmentSmartSeq \
R1_LIST=/path/to/fastq_manifest.csv \
O=/path/to/output/ReadAlignmentSmartSeq_out.txt.gz \
AB_BC_LIST=/path/to/antibody_barcode.csv \
SUMMARY=/path/to/output/ReadAlignmentSmartSeq_summary.txt \
HEADER=TRUE

java -jar PLA_alignment.jar UMIMerging \
I=/path/to/output/ReadAlignmentSmartSeq_out.txt.gz \
O=/path/to/output/UMIMerging_out.txt.gz \
SUMMARY=/path/to/output/UMIMerging_summary.txt

java -jar PLA_alignment.jar DigitalCount \
I=/path/to/output/UMIMerging_out.txt.gz \
O=/path/to/output/pla_count_matrix.txt.gz \
CELL_BC_LIST=NONE \
DUPLICATE_EXPORT=/path/to/output/DigitalCountduplicate_export.txt.gz \
REMOVE_DUPLICATE=TRUE \
SUMMARY=/path/to/output/DigitalCount_summary.txt
```

## Step 4: 10x Workflow

This mode uses `ReadAlignment10x` and adds barcode correction.

Pipeline:

1. `ReadAlignment10x`
2. `CellBarcodeCorrection`
3. `UMIMerging`
4. `DigitalCount`

Example SLURM script:

[tutorial/examples/10x_pla_alignment.sbatch](/Users/junjie/Desktop/Alignment/tutorial/examples/10x_pla_alignment.sbatch)

Key points:

- Input is paired PLA FASTQ files: `R1` and `R2`
- `CellBarcodeCorrection` requires the 10x barcode list from the matching cDNA library
- Use `MODE=10X`
- If your reference barcodes look like `AAAC...-1`, use `SUFFIX=-1`

### 10x Example Commands

```bash
java -jar PLA_alignment.jar ReadAlignment10x \
R1=/path/to/fastq_pla/sample_R1.fastq.gz \
R2=/path/to/fastq_pla/sample_R2.fastq.gz \
O=/path/to/output/ReadAlignment_out.txt.gz \
AB_BC_LIST=/path/to/antibody_barcode.csv \
SUMMARY=/path/to/output/ReadAlignment_summary.txt \
HEADER=TRUE

java -jar PLA_alignment.jar CellBarcodeCorrection \
I=/path/to/output/ReadAlignment_out.txt.gz \
O=/path/to/output/cellbarcodecorrection_out.txt.gz \
MODE=10X \
CELL_BC_LIST=/path/to/filtered_feature_bc_matrix/barcodes.tsv.gz \
SUFFIX=-1 \
READCOUNT_CUTOFF=100 \
SUMMARY=/path/to/output/cellbarcodecorrection_summary.txt \
HEADER=FALSE

java -jar PLA_alignment.jar UMIMerging \
I=/path/to/output/cellbarcodecorrection_out.txt.gz \
O=/path/to/output/UMI_out.txt.gz \
SUMMARY=/path/to/output/UMI_summary.txt

java -jar PLA_alignment.jar DigitalCount \
I=/path/to/output/UMI_out.txt.gz \
O=/path/to/output/count_matrix.txt.gz \
CELL_BC_LIST=NONE \
SUMMARY=/path/to/output/count_summary.txt \
DUPLICATE_EXPORT=/path/to/output/DigitalCountduplicate_export.txt.gz \
REMOVE_DUPLICATE=TRUE
```

## File Format Notes

### Antibody barcode lookup table

Expected CSV structure:

```csv
protein_target,barcode
CD3,ACGTACGT
CD19,TGCATGCA
```

Use [tutorial/examples/antibody_barcode_template.csv](/Users/junjie/Desktop/Alignment/tutorial/examples/antibody_barcode_template.csv) as a starting point.

### Plate or bulk FASTQ manifest

Expected CSV structure:

```csv
/data/run1/sampleA_R1.fastq.gz,SampleA
/data/run1/sampleB_R1.fastq.gz,SampleB
```

## Important Parameters

The current Java source supports these commonly used arguments:

- `HEADER`: whether the referenced CSV or barcode file has a header row
- `BASE_QUALITY`: minimum Phred threshold used during read filtering
- `NUM_BELOW_BASE_QUALITY`: maximum number of low-quality bases allowed
- `BASE_QUALITY_START`: first base position to start quality filtering
- `READCOUNT_CUTOFF`: used in `CellBarcodeCorrection`, mainly for Drop-seq mode
- `SUFFIX`: barcode suffix for 10x reference barcodes, often `-1`
- `REMOVE_DUPLICATE`: whether to remove duplicated PLA products across cells

See [tutorial/notes/command_reference.md](/Users/junjie/Desktop/Alignment/tutorial/notes/command_reference.md) for a compact command summary derived from the Java source.

## Outputs

Typical outputs include:

- Read alignment intermediate tables
- Summary text files for each step
- UMI-merged intermediate files
- Final PLA count matrix
- Duplicate export file from `DigitalCount`

## Suggested Next Improvements For The GitHub Repo

- Add a release jar or build instructions for generating the jar
- Add a small toy dataset for dry-run testing
- Add an example antibody barcode CSV from a public demo dataset
- Add screenshots of the expected folder structure and outputs
- Add a troubleshooting section once common user errors are known
