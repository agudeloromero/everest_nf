include { SEQKIT_FILTER     } from "../../modules/local/seqkit_filter.nf"
include { VIRSORTER_DETECT  } from "../../modules/local/virsorter_detect.nf"
include { CHECKV_VIRAL_SEQ  } from "../../modules/local/checkv_viral_seq.nf"

workflow CLEANING_CONTIGS_WF {

    take:
        repseq_fasta

    main:
        SEQKIT_FILTER( repseq_fasta )

        VIRSORTER_DETECT( SEQKIT_FILTER.out.filtered_fasta, params.virsorter_db )

        CHECKV_VIRAL_SEQ( VIRSORTER_DETECT.out.combined, params.checkv_db )

        //TODO: Maybe, not needed
//        RENAME_VIRAL_SEQ

//        BBMAP_MAPPING_CONTIGS

//        BACPHLIP_LIFE_STYLE

    //emit:

}

