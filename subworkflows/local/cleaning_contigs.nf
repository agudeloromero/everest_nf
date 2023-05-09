include { SEQKIT_FILTER  } from "../../modules/local/seqkit_filter.nf"

workflow CLEANING_CONTIGS_WF {

    take:
        repseq_fasta

    main:
        SEQKIT_FILTER(repseq_fasta)

//        VIRSORTER_DETECT

//        CHECKV_VIRAL_SEQ

        //TODO: Maybe, not needed
//        RENAME_VIRAL_SEQ

//        BBMAP_MAPPING_CONTIGS

//        BACPHLIP_LIFE_STYLE

    //emit:

}

