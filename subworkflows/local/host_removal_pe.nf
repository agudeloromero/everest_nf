/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/03_Host_removal_PE.smk */
include { BBMAP_DEDUPE                          } from "../../modules/local/bbmap_dedupe"
include { BBMAP_DEDUPED_REFORMAT                } from "../../modules/local/bbmap_deduped_reformat"
include { BBMAP_DUDUPED_NORMALIZATION           } from "../../modules/local/bbmap_deduped_normalization"
include { BBMAP_REFORMAT as BBMAP_SINGLETONS_PE } from "../../modules/local/bbmap_reformat"
include { CAT_PE                                } from "../../modules/local/cat_pe"
include { MINIMAP2_INDEX                        } from "../../modules/nf-core/minimap2/index"
include { MINIMAP2_HOST_REMOVAL                 } from "../../modules/local/minimap2_host_removal"


workflow HOST_REMOVAL_PE_WF {
    take:
        ref_fasta_ch
        fastq_ch

    main:
        MINIMAP2_INDEX( ref_fasta_ch  )

        MINIMAP2_HOST_REMOVAL( MINIMAP2_INDEX.out.index, fastq_ch )

        BBMAP_SINGLETONS_PE( MINIMAP2_HOST_REMOVAL.out.unmapped_singleton )

        ch_cat_pe_input = MINIMAP2_HOST_REMOVAL.out.unmapped_pair
                                    .join(BBMAP_SINGLETONS_PE.out.singleton_pair)
                                    .dump(tag: "HOST_REMOVAL_PE: ch_in_CAT_PE" )

        CAT_PE( ch_cat_pe_input )

        BBMAP_DEDUPE ( CAT_PE.out.fastqgz )

        BBMAP_DEDUPED_REFORMAT( BBMAP_DEDUPE.out.deduped_fastqgz )

        BBMAP_DUDUPED_NORMALIZATION( BBMAP_DEDUPED_REFORMAT.out.reformatted_fastq )

        //TODO
        /* FASTQC_BEFORE_MERGE */
        /* MULTIQC_BEFORE_MERGE */

    emit:
        deduped_normalized_fastqgz = BBMAP_DUDUPED_NORMALIZATION.out.norm_fastqgz
}
