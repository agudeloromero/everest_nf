#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
dir  = args[1]
pattern.o  = args[2]
save_file = args[3]


#dir = snakemake@params[['dir']]
print(dir)
#pattern.o  = snakemake@params[['pattern']]
print(pattern.o)
#save_file = snakemake@output[[1]]

#dir = "/Users/pagudeloromero/Downloads/Summary"
#pattern.o="*_nt_summary_mmseqs2.txt"
#save_file = "/Users/pagudeloromero/Downloads/Summary/Summary_aa_mmseqs2.txt"

combine = function(dir,pattern){
  #-- Create list of text files
  print("Create list of text files")
  file_list = list.files(path=dir, pattern=pattern,full.names=T)
  #-- Removing empty files
  file_list = file_list[file.size(file_list) > 1]
  #-- Read the files
  print("Reading files")
  files <- lapply(file_list, function(x) {read.table(file = x, header = T, sep ="\t")})
  # Combine them
  print("Combining files")
  df <- do.call("rbind", lapply(files, as.data.frame))
  return(df)
}

mmseq.db = grepl("*_nt_*", pattern.o)
if (mmseq.db == TRUE) {
  print("-- nt --")
  pattern.n  = "*_nt_summary_mmseqs2.txt"
  combined_df = combine(dir,pattern.n)
} else {
  #-- Create list of text files
  print("-- aa --")
  pattern.a  = "*_aa_summary_mmseqs2.txt"
  combined_df = combine(dir,pattern.a)
}

print("Save file")
write.table(combined_df,file=save_file,col.names=T,row.names=F,sep="\t",quote=F)
