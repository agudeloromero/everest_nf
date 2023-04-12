include { BBMAP_MERGE       } from "../../modules/local/bbmap_merge"
include { TRIMM_UNMERGE     } from "../../modules/local/trimm_unmerge"
include { TRIMM_MERGE       } from "../../modules/local/trimm_merge"
/* include { SPADES_DENOVO     } from "../../modules/local/spades_denovo" */
/* include { MMSEQ2_ELINCLUST  } from "../../modules/local/mmseq2_elinclust" */

workflow DENOVO_WF {
    take:
        ch_deduped_normalized_fastqgz

    main:
        /* ch_deduped_normalized_fastqgz.dump(tag: "ch_deduped_normalized_fastqgz" ) */

        BBMAP_MERGE( ch_deduped_normalized_fastqgz )

        TRIMM_UNMERGE( BBMAP_MERGE.out.unmerged, params.adaptor )

        TRIMM_MERGE( BBMAP_MERGE.out.merged, params.adaptor )


        /* ch_trimmed =  */
        /* SPADES_DENOVO */

/* TODO */
        /* MMSEQ2_ELINCLUST */



    /* emit: */


}

