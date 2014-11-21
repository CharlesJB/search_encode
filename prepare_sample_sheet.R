### Parse parameters
argv <- commandArgs(trailingOnly = TRUE)
input <- argv[1]
specie <- argv[2]
output <- argv[3]

### Prepare metadata object
metadata <- read.csv(input, stringsAsFactors = FALSE)
single <- which(metadata[["run_type"]] != "Paired-ended")
paired <- which(metadata[["run_type"]] == "Paired-ended"
              & metadata[["paired_end"]] == 1)

metadata[["paired_with"]] <-
  sapply(strsplit(as.character(metadata[["paired_with"]]), "/"), 
    function(x) if (length(x) > 0) { x[3] } else { "" })

bst <- metadata[["biosample_term_name"]]
tg <- metadata[["target"]]
tg[tg == ""] <- "NA"
ea <- metadata[["experiment_accession"]]
fa <- metadata[["file_accession"]]

metadata[["Name"]] <- paste(specie, bst, tg, ea, fa, sep = "_")

### Initialize sample sheet
sample_sheet <- data.frame(Name = character(length(single) + length(paired)))
sample_sheet[["Library Barcode"]] <- "X"
sample_sheet[["Run"]] <- "X"
sample_sheet[["Region"]] <- "1"
sample_sheet[["Run Type"]] <- "PAIRED_END" # default value, might be changed later
sample_sheet[["Status"]] <- "Data is valid"
sample_sheet[["Quality Offset"]] <- 33
sample_sheet[["BED Files"]] <- "X"
sample_sheet[["ProcessingSheetId"]] <- "X"
sample_sheet[["Library Source"]] <- "X"
sample_sheet[["FASTQ1"]] <- ""
sample_sheet[["FASTQ2"]] <- ""
sample_sheet[["Read Set Id"]] <- "X"
sample_sheet[["Filename Prefix"]] <- "X"

### Populate sample sheet
sample_sheet$Name <- c(metadata[["Name"]][single], metadata[["Name"]][paired])
file1_accession <- c(metadata[["file_accession"]][single], metadata[["file_accession"]][paired])
if (length(single) > 0) {
  sample_sheet[["Run Type"]][1:length(single)] <- "SINGLE_END"
}
sample_sheet[["Filename Prefix"]] <- sample_sheet[["Name"]]
sample_sheet[["FASTQ1"]] <- paste0("raw_data/", file1_accession, ".fastq.gz")

if (length(paired) > 0) {
  ## Add FASTQ files and paired Name
  # In sample_sheet data.frame, the first rows are the single ended files.
  # So if we start a length(single)+1, we can be sure were are in the
  # paired files section of sample_sheet.
  for (i in (length(single)+1):nrow(sample_sheet)) {
    # Set the correct Name and Filename Prefix
    name <- sample_sheet[["Name"]][i]
    pair_1 <- file1_accession[i]
    pair_2 <- metadata[metadata[["paired_with"]] == pair_1,][["file_accession"]]
    pair_2 <- unique(as.character(pair_2))
    new_name <- paste(name, pair_1, pair_2, sep  = "_")
    sample_sheet[["Name"]][i] <- new_name
    sample_sheet[["Filename Prefix"]][i] <- new_name
    # Add FASTQ1 and FASTQ2
    sample_sheet[["FASTQ1"]][i] <- paste0("raw_data/", pair_1, ".fastq.gz")
    sample_sheet[["FASTQ2"]][i] <- paste0("raw_data/", pair_2, ".fastq.gz")
  }
}

#### Save results
write.csv(sample_sheet, output, row.names = FALSE)
