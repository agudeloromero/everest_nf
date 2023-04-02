/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/03_Host_removal_PE.smk */
include { BBMAP_DEDUPE } from "../../modules/local/bbmap_dedupe"
include { MINIMAP2_INDEX } from "../../modules/nf-core/minimap2/index"
/* include { MINIMAP2_HOST_REMOVAL } from "../modules/local/minimap2_host_removal" */


workflow HOST_REMOVAL_PE_WF {
    take:
        fasta_ch
        fastq_ch

    main:
        MINIMAP2_INDEX( fasta_ch  )
        MINIMAP2_HOST_REMOVAL(MINIMAP2_INDEX.out.index.first(), fastq_ch)
        /* BBMAP_SINGLETONS_PE */
        /* CAT_PE */
        /* BBMAP_DUP */
        /* BBMAP_DEDUPED_REFORMAT */
        /* BBMAP_DUDUPED_NORMALISATION */
        /* FASTQC_BEFORE_MERGE */
        /* MULTIQC_BEFORE_MERGE */

    /* emit: */
}
