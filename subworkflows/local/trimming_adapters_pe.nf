/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors_PE.smk */

workflow TRIMMING_ADAPTERS_PE_WF {

    take:
        reads_ch // [ val(meta), [ reads ] ]

    main:

        BBMAP_phix(reads_ch) 

        /* TRIMM_PE( BBMAP_phix.out.xyz ) */

        /* CAT_pair_unpair */

        /* FASTQC_trimm */

        /* multiQC_trimm */

    emit:
}
