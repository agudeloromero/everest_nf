#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
aa_file  = args[1]
nt_file  = args[2]
save_file = args[3]

#aa_file = snakemake@input[['aa_dir']]
#nt_file  = snakemake@input[['nt_dir']]
#save_file = snakemake@output[[1]]

aa=read.table(file=aa_file,sep="\t",header=T,fill=T)
nt=read.table(file=nt_file,sep="\t",header=T,fill=T)

combine.df = function(df1,df2){
  print("Combine files")
  df=data.frame(rbind(df1,df2))
  print("Sort files by samples name")
  df=df[order(df$sample,df$lca_query, df$database,decreasing=F),]
  return(df)
}

aa_nt = combine.df(aa,nt)

write.table(aa_nt, save_file, col.names=T,row.names=FALSE,sep="\t",quote=F)
