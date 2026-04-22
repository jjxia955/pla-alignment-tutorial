# Command Reference

This page summarizes the most important PLA alignment commands based on the current Java source in `PLA_alignment_java/src/PLA_alignment.java`.

## `ReadAlignmentSmartSeq`

Purpose: align plate or bulk style PLA reads from a manifest of FASTQ files.

Arguments:

- `R1_LIST`: CSV with `fastq_path,sample_or_cell_id`
- `O`: output aligned reads file
- `AB_BC_LIST`: antibody barcode lookup CSV
- `SUMMARY`: summary text file
- `HEADER`: whether the antibody barcode CSV has a header row
- `BASE_QUALITY`: minimum base quality threshold
- `NUM_BELOW_BASE_QUALITY`: allowed count of low-quality bases
- `BASE_QUALITY_START`: first base position to use for quality filtering

## `ReadAlignment10x`

Purpose: align 10x PLA paired FASTQ files.

Arguments:

- `R1`: read 1 FASTQ
- `R2`: read 2 FASTQ
- `O`: output aligned reads file
- `AB_BC_LIST`: antibody barcode lookup CSV
- `SUMMARY`: summary text file
- `HEADER`: whether the antibody barcode CSV has a header row
- `BASE_QUALITY`: minimum base quality threshold
- `NUM_BELOW_BASE_QUALITY`: allowed count of low-quality bases

## `CellBarcodeCorrection`

Purpose: correct aligned read cell barcodes using a reference barcode list.

Arguments:

- `I`: aligned reads input
- `O`: corrected aligned reads output
- `CELL_BC_LIST`: gzipped reference barcode file
- `MODE`: usually `10X` or `DROPSEQ`
- `SUMMARY`: summary text file
- `READCOUNT_CUTOFF`: mainly relevant for `DROPSEQ`
- `SUFFIX`: barcode suffix such as `-1`
- `HEADER`: whether the barcode list has a header row

## `UMIMerging`

Purpose: collapse reads that represent the same UMI-supported PLA event.

Arguments:

- `I`: aligned or barcode-corrected input
- `O`: merged output
- `SUMMARY`: summary text file

## `DigitalCount`

Purpose: generate the final count matrix.

Arguments:

- `I`: UMI-merged input
- `O`: count matrix output
- `CELL_BC_LIST`: chosen cell barcode list or `NONE`
- `HEADER`: whether the barcode list has a header row
- `SUMMARY`: summary text file
- `DUPLICATE_EXPORT`: duplicated PLA product export file
- `REMOVE_DUPLICATE`: whether to remove duplicated PLA products across cells
