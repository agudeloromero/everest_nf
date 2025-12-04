#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { BBMAP_DEDUPE } from "../../modules/local/bbmap_dedupe"
include { BBMAP_DEDUPED_REFORMAT } from "../../modules/local/bbmap_deduped_reformat"
include { BBMAP_DUDUPED_NORMALIZATION } from "../../modules/local/bbmap_deduped_normalization"
include { BBMAP_REFORMAT as BBMAP_SINGLETONS } from "../../modules/local/bbmap_reformat"
include { CAT } from "../../modules/local/cat"
include { KALLISTO_ALIGN } from "../../modules/local/kallisto_align"
include { KALLISTO_INDEX } from "../../modules/nf-core/kallisto/index/main"
include { MINIMAP2_INDEX } from "../../modules/nf-core/minimap2/index"
include { MINIMAP2_HOST_REMOVAL } from "../../modules/local/minimap2_host_removal"
include { PIGZ } from "../../modules/local/pigz"
include { SAMTOOLS_FASTQ } from "../../modules/local/samtools_fastq"


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

//--------------------
// DNA branch
//--------------------
        //TODO: Implement an option to provide the pre-indexed file
            MINIMAP2_INDEX(ref_fasta_ch)
            MINIMAP2_HOST_REMOVAL(MINIMAP2_INDEX.out.index, ch_all_fastq_branched.dna)
            BBMAP_SINGLETONS(MINIMAP2_HOST_REMOVAL.out.singleton)

            ch_cat_input = MINIMAP2_HOST_REMOVAL.out.unmapped
                        .join(BBMAP_SINGLETONS.out.singleton_pair)

            CAT(ch_cat_input)
            ch_unmapped_se = MINIMAP2_HOST_REMOVAL.out.unmapped.filter { it[0].single_end == true }
            ch_pigz_input = CAT.out.fastq.concat(ch_unmapped_se)


//--------------------
// RNA branch
//--------------------

            if (params.long_read_aligner == "kallisto") {
        //TODO: Implement an option to provide the pre-indexed file
                KALLISTO_INDEX(params.transcriptome)
                KALLISTO_ALIGN(ch_trim_fastq_branched.rna, KALLISTO_INDEX.out.idx)
                SAMTOOLS_FASTQ(KALLISTO_ALIGN.out.bam)
                BBMAP_SINGLETONS(SAMTOOLS_FASTQ.out.singleton)
                ch_cat_input = SAMTOOLS_FASTQ.out.unmapped
                    .join(BBMAP_SINGLETONS.out.singleton_pair)
                CAT(ch_cat_input)
                ch_unmapped_se = SAMTOOLS_FASTQ.out.unmapped.filter { it[0].single_end == true }
                ch_pigz_input = CAT.out.fastq.concat(ch_unmapped_se)
            } else {
                MINIMAP2_INDEX(ref_fasta_ch)
                MINIMAP2_HOST_REMOVAL(MINIMAP2_INDEX.out.index, ch_all_fastq_branched.rna)
                BBMAP_SINGLETONS(MINIMAP2_HOST_REMOVAL.out.singleton)
                ch_cat_input = MINIMAP2_HOST_REMOVAL.out.unmapped
                    .join(BBMAP_SINGLETONS.out.singleton_pair)
                CAT(ch_cat_input)
                ch_unmapped_se = MINIMAP2_HOST_REMOVAL.out.unmapped.filter { it[0].single_end == true }
                ch_pigz_input = CAT.out.fastq.concat(ch_unmapped_se)
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
