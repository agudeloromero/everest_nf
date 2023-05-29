#!/bin/env bash
set -uex

#Complete RefSeq release of viral sequences
#https://www.ncbi.nlm.nih.gov/genome/viruses/
#

#NOTE: Uncomment if needed
#conda create -n blast-env blast=2.14.0 -c bioconda

VIRAL_DB_FOLDER="Viral_DB_2"
DIR="${PWD}/$VIRAL_DB_FOLDER"
CONDA_BLAST_ENV="micromamba run -n blast-env "
CONDA_MMSEQS_ENV="micromamba run -n mmseqs-env "


mkdir "$VIRAL_DB_FOLDER"

wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.1.1.genomic.fna.gz -P "$VIRAL_DB_FOLDER"
cd $VIRAL_DB_FOLDER
gzip -d viral.1.1.genomic.fna.gz

#grep ">" viral.1.1.genomic.fna | wc -l
#16398

#echo "-- remove seq duplicated --"
#dedupe.sh -Xmx20g in=${DIR}/DB_virus/refseq/viral/Viral_seq.fasta \
#out=${DIR}/DB_virus/refseq/viral/Viral_seq_dup.fasta ac=f

echo "--- create database --"

${CONDA_BLAST_ENV} makeblastdb \
-in ${DIR}/DB_virus/refseq/viral/Viral_seq_dup.fasta \
-dbtype nucl \
-parse_seqids \
-input_type fasta \
-title "Viral_ncbi" \
-out ${DIR}/DB_virus/Viral_ncbi

echo "--- download taxonomy --"

wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz -P $DIR/taxonomy
tar -xxvf $DIR/taxonomy/taxdump.tar.gz -C $DIR/taxonomy

echo "--- retrieve fasta ---"

${CONDA_BLAST_ENV} blastdbcmd \
-db ${DIR}/DB_virus/Viral_ncbi \
-entry all > ${DIR}/DB_virus/viral_seq.fna

${CONDA_BLAST_ENV} blastdbcmd \
-db ${DIR}/DB_virus/Viral_ncbi \
-entry all -outfmt "%a %T" > ${DIR}/DB_virus/viral.fna.taxidmapping

echo "--- MMSeqs2 database ---"

if [ ! -d ${DIR}/DB_MMSEQ2 ]
then
	mkdir ${DIR}/DB_MMSEQ2
fi

if [ ! -d ${DIR}/tmp ]
then
	mkdir ${DIR}/tmp
fi

echo "--- 1. createdb ---"

${CONDA_MMSEQS_ENV} mmseqs createdb ${DIR}/DB_virus/viral_seq.fna ${DIR}/DB_MMSEQ2/viral.nt.fnaDB

echo "--- 2. createtaxdb ---"

${CONDA_MMSEQS_ENV} mmseqs createtaxdb ${DIR}/DB_MMSEQ2/viral.nt.fnaDB ${DIR}/tmp --ncbi-tax-dump ${DIR}/taxonomy/ --tax-mapping-file viral.fna.taxid mapping

rm -r ${DIR}/tmp

#uniprot
#https://www.uniprot.org/uniprotkb?query=taxonomy_id%3A10239
