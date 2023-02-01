/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/03_Host_removal_PE.smk */
include { BBMAP_DEDUPE } from "../modules/local/bbmap_dedupe"


workflow HOST_REMOVAL_PE_WF {
    take:

    main:
        MINIMAP2_index
        MINIMAP2_host_removal
        BBMAP_singletons_PE
        CAT_PE
        BBMAP_dup
        BBMAP_deduped_reformat
        BBMAP_duduped_normalisation
        FASTQC_before_merge
        multiQC_before_merge

    emit:
}
