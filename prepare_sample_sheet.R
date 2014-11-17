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
brn <- metadata[["biological_replicate_number"]]
trn <- metadata[["technical_replicate_number"]]

metadata[["Name"]] <- paste(specie, bst, tg, ea, fa, brn, trn, sep = "_")

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
if (length(single) > 0) {
  sample_sheet[["Run Type"]][1:length(single)] <- "SINGLE_END"
}
sample_sheet["Filename Prefix"] <- sample_sheet[["Name"]]
sample_sheet["FASTQ1"] <- paste(sample_sheet[["Name"]], "fastq.gz", sep = ".")

if (length(paired) > 0) {
  ## Add FASTQ files and paired Name
  # In sample_sheet data.frame, the first rows are the single ended files.
  # So if we start a length(single)+1, we can be sure were are in the
  # paired files section of sample_sheet.
  for (i in (length(single)+1):nrow(sample_sheet)) {
    # Set the correct Name and Filename Prefix
    tokens <- unlist(strsplit(sample_sheet[["Name"]][i], "_"))
    pair_1 <- tokens[5]
    pair_2 <- metadata[metadata[["paired_with"]] == pair_1,][["file_accession"]]
    pair_2 <- as.character(pair_2)
    new_name <- paste(c(tokens[1:5], pair_2, tokens[6:length(tokens)]), collapse = "_")
    sample_sheet[["Name"]][i] <- new_name
    sample_sheet[["Filename Prefix"]][i] <- new_name
    # Add FASTQ1 and FASTQ2
    sample_sheet[["FASTQ1"]] <- paste0(paste(tokens, collapse="_"), ".fastq.gz")
    fastq_2 <- paste(c(tokens[1:4], pair_2, tokens[6:length(tokens)]), collapse = "_")
    sample_sheet[["FASTQ2"]] <- paste0(fastq_2, ".fastq.gz")
  }
}

#### Save results
write.csv(sample_sheet, output, row.names = FALSE)
