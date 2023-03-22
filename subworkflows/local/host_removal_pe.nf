/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/03_Host_removal_PE.smk */
include { BBMAP_DEDUPE } from "../modules/local/bbmap_dedupe"


workflow HOST_REMOVAL_PE_WF {
    take:

    main:
        MINIMAP2_INDEX
        MINIMAP2_HOST_REMOVAL
        BBMAP_SINGLETONS_PE
        CAT_PE
        BBMAP_DUP
        BBMAP_DEDUPED_REFORMAT
        BBMAP_DUDUPED_NORMALISATION
        FASTQC_BEFORE_MERGE
        MULTIQC_BEFORE_MERGE

    emit:
}
