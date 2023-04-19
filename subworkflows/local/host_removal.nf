include { BBMAP_DEDUPE                                 } from "../../modules/local/bbmap_dedupe"
include { BBMAP_DEDUPED_REFORMAT                       } from "../../modules/local/bbmap_deduped_reformat"
include { BBMAP_DUDUPED_NORMALIZATION                  } from "../../modules/local/bbmap_deduped_normalization"
include { BBMAP_REFORMAT as BBMAP_SINGLETONS           } from "../../modules/local/bbmap_reformat"
include { CAT                                          } from "../../modules/local/cat"
include { KALLISTO_ALIGN                               } from "../../modules/local/kallisto_align"
include { KALLISTO_INDEX                               } from "../../modules/nf-core/kallisto/index/main"
include { MINIMAP2_INDEX                               } from "../../modules/nf-core/minimap2/index"
include { MINIMAP2_HOST_REMOVAL                        } from "../../modules/local/minimap2_host_removal"
include { PIGZ                                         } from "../../modules/local/pigz"
include { SAMTOOLS_FASTQ                               } from "../../modules/local/samtools_fastq"


workflow HOST_REMOVAL_WF {
    take:
        ref_fasta_ch
        all_fastq_ch
        trim_fastq_ch

    main:

        //FIXME Add this param to the schema
        if(!params.rnaseq) {
            MINIMAP2_INDEX( ref_fasta_ch  )

            MINIMAP2_HOST_REMOVAL( MINIMAP2_INDEX.out.index, all_fastq_ch )

            //NOTE: Process the PE-singletons here
            BBMAP_SINGLETONS( MINIMAP2_HOST_REMOVAL.out.singleton )

            ch_cat_input = MINIMAP2_HOST_REMOVAL.out.unmapped
                                        .join(BBMAP_SINGLETONS.out.singleton_pair)
                                        /* .dump(tag: "HOST_REMOVAL: ch_cat_input" ) */

            CAT( ch_cat_input )


            //NOTE: Combine the SE and PE_Singletons FASTQ files here

            ch_unmapped_se = MINIMAP2_HOST_REMOVAL.out.unmapped.filter { it[0].single_end == true }

            ch_pigz_input = CAT.out.fastq
                                .concat(ch_unmapped_se)
                                /* .dump(tag: "ch_pigz_input") */

        } else {
            KALLISTO_INDEX( params.transcriptome )
            KALLISTO_ALIGN( trim_fastq_ch, KALLISTO_INDEX.out.idx )
            SAMTOOLS_FASTQ( KALLISTO_ALIGN.out.bam )

            //NOTE: Process the PE-singletons here
            BBMAP_SINGLETONS( SAMTOOLS_FASTQ.out.singleton )

            ch_cat_input = SAMTOOLS_FASTQ.out.unmapped
                                        .join(BBMAP_SINGLETONS.out.singleton_pair)
                                        /* .dump(tag: "HOST_REMOVAL: ch_cat_input" ) */

            CAT( ch_cat_input )


            //NOTE: Combine the SE and PE_Singletons FASTQ files here

            ch_unmapped_se = SAMTOOLS_FASTQ.out.unmapped.filter { it[0].single_end == true }

            ch_pigz_input = CAT.out.fastq
                                .concat(ch_unmapped_se)
                                //.dump(tag: "ch_pigz_input") 

        }

        PIGZ(ch_pigz_input)

        BBMAP_DEDUPE( PIGZ.out.fastqgz )

        //NOTE: Only needed for concatenated PE samples
        BBMAP_DEDUPED_REFORMAT( BBMAP_DEDUPE.out.cat_deduped_fastqgz )

        ch_deduped_se = BBMAP_DEDUPE.out.deduped_fastqgz.filter { it[0].single_end == true }

        ch_bbmap_norm_input = BBMAP_DEDUPED_REFORMAT.out.reformatted_fastq
                            .concat(ch_unmapped_se)
                            /* .dump(tag: "ch_bbmap_norm_input") */


        BBMAP_DUDUPED_NORMALIZATION( ch_bbmap_norm_input )


    emit:
        deduped_normalized_fastqgz = BBMAP_DUDUPED_NORMALIZATION.out.norm_fastqgz
   }

