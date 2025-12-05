#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { BBMAP_DEDUPE } from "../../modules/local/bbmap_dedupe"
include { BBMAP_DEDUPED_REFORMAT } from "../../modules/local/bbmap_deduped_reformat"
include { BBMAP_DUDUPED_NORMALIZATION } from "../../modules/local/bbmap_deduped_normalization"
include { BBMAP_REFORMAT as BBMAP_SINGLETONS__DNA } from "../../modules/local/bbmap_reformat"
include { BBMAP_REFORMAT as BBMAP_SINGLETONS__RNA } from "../../modules/local/bbmap_reformat"
include { CAT as CAT__DNA } from "../../modules/local/cat"
include { CAT as CAT__RNA } from "../../modules/local/cat"
include { KALLISTO_ALIGN as KALLISTO_ALIGN__DNA } from "../../modules/local/kallisto_align"
include { KALLISTO_ALIGN as KALLISTO_ALIGN__RNA } from "../../modules/local/kallisto_align"
include { KALLISTO_INDEX as KALLISTO_INDEX__DNA } from "../../modules/nf-core/kallisto/index/main"
include { KALLISTO_INDEX as KALLISTO_INDEX__RNA } from "../../modules/nf-core/kallisto/index/main"
include { MINIMAP2_INDEX as MINIMAP2_INDEX__DNA } from "../../modules/nf-core/minimap2/index"
include { MINIMAP2_INDEX as MINIMAP2_INDEX__RNA } from "../../modules/nf-core/minimap2/index"
include { MINIMAP2_HOST_REMOVAL as MINIMAP2_HOST_REMOVAL__DNA } from "../../modules/local/minimap2_host_removal"
include { MINIMAP2_HOST_REMOVAL as MINIMAP2_HOST_REMOVAL__RNA } from "../../modules/local/minimap2_host_removal"
include { SAMTOOLS_FASTQ as SAMTOOLS_FASTQ__DNA } from "../../modules/local/samtools_fastq"
include { SAMTOOLS_FASTQ as SAMTOOLS_FASTQ__RNA } from "../../modules/local/samtools_fastq"
include { PIGZ } from "../../modules/local/pigz"


workflow HOST_REMOVAL_WF {
    take:
        ref_fasta_ch
        all_fastq_ch
        trim_fastq_ch

    main:
        // Determine workflow branch by meta.seq_type

        all_fastq_ch.branch {
            dna: it[0].seq_type == "DNA"
            rna: it[0].seq_type == "RNA"
        }
        .set { ch_all_fastq_branched }

        trim_fastq_ch.branch {
            dna: it[0].seq_type == "DNA"
            rna: it[0].seq_type == "RNA"
        }
        .set { ch_trim_fastq_branched }

//FOR LONG-READS
// refer nf-core/taxprofiler use minimap2 for host removal and then proceed to spades-hybrid
// - refer the use of -ax parameters https://github.com/lh3/minimap2?tab=readme-ov-file#map-long-noisy-genomic-reads


//--------------------
// DNA branch
//--------------------
        //TODO: Implement an option to provide the pre-indexed file
            MINIMAP2_INDEX__DNA(ref_fasta_ch)
            MINIMAP2_HOST_REMOVAL__DNA(MINIMAP2_INDEX__DNA.out.index, ch_all_fastq_branched.dna)
            BBMAP_SINGLETONS__DNA(MINIMAP2_HOST_REMOVAL__DNA.out.singleton)

            ch_cat_input = MINIMAP2_HOST_REMOVAL__DNA.out.unmapped
                        .join(BBMAP_SINGLETONS__DNA.out.singleton_pair)

            CAT__DNA(ch_cat_input)
            ch_unmapped_se = MINIMAP2_HOST_REMOVAL__DNA.out.unmapped.filter { it[0].single_end == true }
            ch_pigz_input = CAT__DNA.out.fastq.concat(ch_unmapped_se)


//--------------------
// RNA branch
//--------------------

            if (params.long_read_aligner == "kallisto") {
        //TODO: Implement an option to provide the pre-indexed file
                KALLISTO_INDEX__RNA(params.transcriptome)
                KALLISTO_ALIGN__RNA(ch_trim_fastq_branched.rna, KALLISTO_INDEX__RNA.out.idx)
                SAMTOOLS_FASTQ__RNA(KALLISTO_ALIGN__RNA.out.bam)
                BBMAP_SINGLETONS__RNA(SAMTOOLS_FASTQ__RNA.out.singleton)
                ch_cat_input = SAMTOOLS_FASTQ__RNA.out.unmapped
                    .join(BBMAP_SINGLETONS__RNA.out.singleton_pair)
                CAT__RNA(ch_cat_input)
                ch_unmapped_se = SAMTOOLS_FASTQ__RNA.out.unmapped.filter { it[0].single_end == true }
                ch_pigz_input = CAT__RNA.out.fastq.concat(ch_unmapped_se)
            } else {
                MINIMAP2_INDEX__RNA(ref_fasta_ch)
                MINIMAP2_HOST_REMOVAL__RNA(MINIMAP2_INDEX__RNA.out.index, ch_all_fastq_branched.rna)
                BBMAP_SINGLETONS__RNA(MINIMAP2_HOST_REMOVAL__RNA.out.singleton)
                ch_cat_input = MINIMAP2_HOST_REMOVAL__RNA.out.unmapped
                    .join(BBMAP_SINGLETONS__RNA.out.singleton_pair)
                CAT__RNA(ch_cat_input)
                ch_unmapped_se = MINIMAP2_HOST_REMOVAL__RNA.out.unmapped.filter { it[0].single_end == true }
                ch_pigz_input = CAT__RNA.out.fastq.concat(ch_unmapped_se)
            }

        // Deduplication and normalization (applies to both branches)
        PIGZ(ch_pigz_input)
        BBMAP_DEDUPE(PIGZ.out.fastqgz)
        BBMAP_DEDUPED_REFORMAT(BBMAP_DEDUPE.out.cat_deduped_fastqgz)
        ch_deduped_se = BBMAP_DEDUPE.out.deduped_fastqgz.filter { it[0].single_end == true }
        ch_bbmap_norm_input = BBMAP_DEDUPED_REFORMAT.out.reformatted_fastq.concat(ch_unmapped_se)
        BBMAP_DUDUPED_NORMALIZATION(ch_bbmap_norm_input)

    emit:
        deduped_normalized_fastqgz = BBMAP_DUDUPED_NORMALIZATION.out.norm_fastqgz
}
