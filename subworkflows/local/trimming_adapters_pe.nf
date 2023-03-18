/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors_PE.smk */

include { BBMAP_PHIX                      } from '../../modules/local/bbmap_phix'
include { TRIM_PE                         } from '../../modules/local/trim_pe'
include { CAT_PAIR_UNPAIR                 } from '../../modules/local/cat_pair_unpair'

workflow TRIMMING_ADAPTERS_PE_WF {

    take:
        reads_ch // [ val(meta), [ reads ] ]

    main:

        BBMAP_PHIX(reads_ch) 

        TRIM_PE( BBMAP_PHIX.out.clean ) 

        CAT_PAIR_UNPAIR(TRIM_PE.out)

        /* FASTQC_trimm */

        /* multiQC_trimm */

    /* emit: */
}
