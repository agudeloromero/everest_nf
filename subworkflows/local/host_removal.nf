include { BBMAP_DEDUPE                          } from "../../modules/local/bbmap_dedupe"
include { BBMAP_DEDUPED_REFORMAT                } from "../../modules/local/bbmap_deduped_reformat"
include { BBMAP_DUDUPED_NORMALIZATION           } from "../../modules/local/bbmap_deduped_normalization"
include { BBMAP_REFORMAT as BBMAP_SINGLETONS    } from "../../modules/local/bbmap_reformat"
include { CAT                                   } from "../../modules/local/cat"
include { MINIMAP2_INDEX                        } from "../../modules/nf-core/minimap2/index"
include { MINIMAP2_HOST_REMOVAL                 } from "../../modules/local/minimap2_host_removal"
include { PIGZ                                  } from "../../modules/local/pigz"


workflow HOST_REMOVAL_WF {
    take:
        ref_fasta_ch
        all_fastq_ch

    main:
        MINIMAP2_INDEX( ref_fasta_ch  )

        MINIMAP2_HOST_REMOVAL( MINIMAP2_INDEX.out.index, all_fastq_ch )

        //NOTE: Process the PE-singletons here
        BBMAP_SINGLETONS( MINIMAP2_HOST_REMOVAL.out.singleton )

        ch_cat_input = MINIMAP2_HOST_REMOVAL.out.unmapped
                                    .join(BBMAP_SINGLETONS.out.singleton_pair)
                                    .dump(tag: "HOST_REMOVAL: ch_cat_input" )

        CAT( ch_cat_input )

        //NOTE: Combine the SE and PE_Singletons FASTQ files here
        ch_pigz_input = CAT.out.fastq
                            .concat(MINIMAP2_HOST_REMOVAL.out.unmapped)
                            .unique()
                            .dump(tag: "ch_pigz_input")

        PIGZ(ch_pigz_input)


}

/*

        BBMAP_DEDUPE ( CAT.out.fastq )

        BBMAP_DEDUPED_REFORMAT( BBMAP_DEDUPE.out.deduped_fastqgz )

        BBMAP_DUDUPED_NORMALIZATION( BBMAP_DEDUPED_REFORMAT.out.reformatted_fastq )

        //TODO
        //FASTQC_BEFORE_MERGE
        //MULTIQC_BEFORE_MERGE

    emit:
        deduped_normalized_fastqgz = BBMAP_DUDUPED_NORMALIZATION.out.norm_fastqgz
        */
