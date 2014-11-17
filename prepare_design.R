### Define functions
get_replicate_accession <- function(i) {
  ea <- metadata[["experiment_accession"]][i]
  brn <- metadata[["biological_replicate_number"]][i]
  trn <- metadata[["technical_replicate_number"]][i]
  pe <- metadata[["paired_end"]][i]
  res <- NA
  if (!is.na(pe)) {
    res <- which(metadata[["experiment_accession"]] == ea
               & metadata[["biological_replicate_number"]] == brn
               & metadata[["technical_replicate_number"]] == trn
               & metadata[["paired_end"]] != pe)
  }
  res
}

get_paired_names <- function() {
  res <- character(length(paired))
  idx <- 1
  for (i in paired) {
    target <- metadata[["target"]][i]
    experiment_accession <- metadata[["experiment_accession"]][i]
    accession_1 <- metadata[["file_accession"]][i]
    j <- get_replicate_accession(i)
    accession_2 <- unique(metadata[["file_accession"]][j])
    to_paste <- paste("Hosa",
                  unique(metadata[["biosample_term_name"]][i]),
                  target,
                  experiment_accession,
                  accession_1,
                  accession_2,
                  sep = "_")
    res[idx] <- to_paste 
    idx <- idx + 1
  }
  res
}

### Parse parameters
argv <- commandArgs(trailingOnly = TRUE)
input <- argv[1]
output <- argv[2]

### Prepare metadata object
metadata <- read.csv(input)
metadata <- metadata[metadata$file_format == "fastq",]
single <- which(metadata[["run_type"]] != "Paired-ended")
paired <- which(metadata[["run_type"]] == "Paired-ended"
              & metadata[["paired_end"]] == 1)
paired2 <- which(metadata[["run_type"]] == "Paired-ended"
               & metadata[["paired_end"]] == 2)

metadata[["Name"]] <- ""
if (length(single) > 0) {
  metadata[["Name"]][single] <- paste("Hosa",
                                metadata[["biosample_term_name"]][single],
                                metadata[["target"]][single],
                                metadata[["experiment_accession"]][single],
                                metadata[["file_accession"]][single],
                                sep = "_")
}
metadata[["Name"]][paired] <- get_paired_names()

### Initialize design file
design <- data.frame(Name = character(length(single) + length(paired)))

### Populate design file
design$Name <- c(metadata[["Name"]][single], metadata[["Name"]][paired])
unique_accession <- unique(metadata[["experiment_accession"]])
for (exp_accession in unique_accession) {
  if (!exp_accession %in% metadata[["control_accession"]]) {
    current_file_accessions <- metadata[metadata[["experiment_accession"]] == exp_accession,][["file_accession"]]
    current_assay <- unique(metadata[metadata[["experiment_accession"]] == exp_accession,][["assay_term_name"]])
    if (current_assay == "ChIP-seq") {
      for (file_accession in current_file_accessions) {
        ## Initialize column
        i <- metadata[["file_accession"]] == file_accession
        current_biosample <- metadata[["biosample_term_name"]][which(i)[1]]
        current_target <- metadata[["target"]][which(i)[1]]
        current_column <- paste("Hosa",
                            current_biosample,
                            current_target,
                            exp_accession,
                            file_accession,
                            sep = "_") 
        design[[current_column]] <- 0
        ## Populate column
        j <- design[["Name"]] %in% metadata[["Name"]][i]
        design[[current_column]][j] <- 1
        # If this if not a control experiment accession
        ctrl <- unique(metadata[metadata[["experiment_accession"]]==exp_accession,][["control_accession"]])
        if (length(ctrl) > 0) {
          ctrl_accessions <- unique(metadata[metadata[["experiment_accession"]] %in% ctrl,][["experiment_accession"]])
        } else {
          # If there is no control associated with current accession, we pool all the control for the current cell line
          # Get current cell line (biosample_term_name)
          biosample <- unique(metadata[metadata[["experiment_accession"]]==exp_accession,][["biosample_term_name"]])
          # Get all sample associated 
          ctrl_accessions <- unique(metadata[["experiment_accession"]][metadata[["biosample_term_name"]] == biosample])
          # Keep only the controls
          ctrl_accessions <- ctrl_accessions[ctrl_accessions %in% metadata[["control_accession"]]]
          # Remove empty entries
          ctrl_accessions <- ctrl_accessions[ctrl_accessions != ""]
        }
        ctrl_Names <- metadata[["Name"]][metadata[["experiment_accession"]] %in% ctrl_accessions]
        i <- which(design[["Name"]] %in% ctrl_Names)
        j <- design[["Name"]] %in% metadata[["Name"]][i]
        design[[current_column]][j] <- 2
      }
    } else {
      i <- metadata[["experiment_accession"]] == exp_accession
      current_biosample <- metadata[["biosample_term_name"]][which(i)[1]]
      current_target <- metadata[["target"]][which(i)[1]]
      current_column <- paste("Hosa",
                          current_biosample,
                          current_target,
                          exp_accession,
                          sep = "_") 
      design[[current_column]] <- 0
      ## Populate column
      j <- design[["Name"]] %in% metadata[["Name"]][i]
      design[[current_column]][j] <- 1
      # If this if not a control experiment accession
      ctrl <- unique(metadata[metadata[["experiment_accession"]]==exp_accession,][["control_accession"]])
      if (length(ctrl) > 0) {
        ctrl_accessions <- unique(metadata[metadata[["experiment_accession"]] %in% ctrl,][["experiment_accession"]])
      } else {
        # If there is no control associated with current accession, we pool all the control for the current cell line
        # Get current cell line (biosample_term_name)
        biosample <- unique(metadata[metadata[["experiment_accession"]]==exp_accession,][["biosample_term_name"]])
        # Get all sample associated 
        ctrl_accessions <- unique(metadata[["experiment_accession"]][metadata[["biosample_term_name"]] == biosample])
        # Keep only the controls
        ctrl_accessions <- ctrl_accessions[ctrl_accessions %in% metadata[["control_accession"]]]
        # Remove empty entries
        ctrl_accessions <- ctrl_accessions[ctrl_accessions != ""]
      }
      ctrl_Names <- metadata[["Name"]][metadata[["experiment_accession"]] %in% ctrl_accessions]
      i <- which(design[["Name"]] %in% ctrl_Names)
      j <- design[["Name"]] %in% metadata[["Name"]][i]
      design[[current_column]][j] <- 2
    }
  }
}

### Save results
write.table(design, output, row.names = FALSE, sep = "\t", quote = FALSE)
