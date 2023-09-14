include { BBMAP_MERGE       } from "../../modules/local/bbmap_merge"
include { TRIMM_UNMERGE     } from "../../modules/local/trimm_unmerge"
include { TRIMM_MERGE       } from "../../modules/local/trimm_merge"
include { SPADES_DENOVO     } from "../../modules/local/spades_denovo"
include { MMSEQ2_ELINCLUST  } from "../../modules/local/mmseq2_elinclust"
include { PHAROKKA          } from "../../modules/local/pharokka.nf"

workflow DENOVO_WF {
    take:
        ch_deduped_normalized_fastqgz

    main:

        /* ch_deduped_normalized_fastqgz.dump(tag: "ch_deduped_normalized_fastqgz" ) */

        ch_deduped = ch_deduped_normalized_fastqgz.branch {
                                    se: it[0].single_end == true
                                    pe: it[0].single_end == false
                                }


        //NOTE: PE specific processes
        BBMAP_MERGE( ch_deduped.pe )

        TRIMM_UNMERGE( BBMAP_MERGE.out.unmerged, params.adaptor )

        TRIMM_MERGE( BBMAP_MERGE.out.merged, params.adaptor )

        ch_trimm_combined = TRIMM_MERGE.out.paired
                                .join(TRIMM_UNMERGE.out.paired)
                                .join(TRIMM_UNMERGE.out.unpaired)
                                /* .dump(tag:'ch_trimm_combined') */


        //NOTE: Merge the fastq file channels again

        ch_spades_input_se = ch_deduped.se
                                .map { it -> [it[0], it[1], [], []]}
                                /* .dump(tag: "ch_deduped.se.map") */

        ch_spades_input =  ch_trimm_combined
                            .mix(ch_spades_input_se)
                            /* .dump(tag: "ch_spades_input") */

        SPADES_DENOVO( ch_spades_input )

        PHAROKKA( SPADES_DENOVO.out.scaffolds )

        //NOTE: Optional
        //RENEO => PILON

        MMSEQ2_ELINCLUST(SPADES_DENOVO.out.scaffolds)


    emit:
        repseq_fasta = MMSEQ2_ELINCLUST.out.rep_seq

}

