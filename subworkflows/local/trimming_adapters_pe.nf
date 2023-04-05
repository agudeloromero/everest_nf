/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors_PE.smk */

include { BBMAP_PHIX                       } from '../../modules/local/bbmap_phix'
include { TRIMM_PE                          } from '../../modules/local/trimm_pe'
include { CAT_PAIR_UNPAIR                  } from '../../modules/local/cat_pair_unpair'
include { FASTQC  as FASTQC_TRIMM          } from '../../modules/nf-core/fastqc'
include { MULTIQC as MULTIQC_TRIMM         } from '../../modules/nf-core/multiqc'

workflow TRIMMING_ADAPTERS_PE_WF {

    take:
        reads_ch // [ val(meta), [ reads ] ]

    main:
        BBMAP_PHIX( reads_ch ) 

        TRIMM_PE( BBMAP_PHIX.out.clean, params.adaptor ) 

        joint_trimm_ch = TRIMM_PE.out.paired
                            .join(TRIMM_PE.out.unpaired)
                            .dump(tag: "TRIMM_PE", pretty: true)

        CAT_PAIR_UNPAIR( joint_trimm_ch )

        CAT_PAIR_UNPAIR.out.concatenated
                           .dump(tag: "CAT_PAIR_UNPAIR", pretty: true)

        FASTQC_TRIMM( CAT_PAIR_UNPAIR.out.concatenated )

        /* MULTIQC_TRIMM( FASTQC_TRIMM.out.zip.collect{it[1]}, [], [], [] ) */

    emit:
        fastqc_trimm_zip = FASTQC_TRIMM.out.zip.collect{it[1]}
        cat_trimm_fastq  = CAT_PAIR_UNPAIR.out.concatenated
}
