/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors_PE.smk */

include { BBMAP_PHIX                       } from '../../modules/local/bbmap_phix'
include { TRIM_PE                          } from '../../modules/local/trim_pe'
include { CAT_PAIR_UNPAIR                  } from '../../modules/local/cat_pair_unpair'
include { FASTQC  as FASTQC_TRIMM          } from '../../modules/nf-core/fastqc'
include { MULTIQC as MULTIQC_TRIMM         } from '../../modules/nf-core/multiqc'

workflow TRIMMING_ADAPTERS_PE_WF {

    take:
        reads_ch // [ val(meta), [ reads ] ]

    main:
        BBMAP_PHIX( reads_ch ) 

        TRIM_PE( BBMAP_PHIX.out.clean ) 

        joint_trimm_ch = TRIM_PE.out.paired
                            .join(TRIM_PE.out.unpaired)
                            .dump(tag: "TRIM_PE", pretty: true)

        CAT_PAIR_UNPAIR( joint_trimm_ch )

        CAT_PAIR_UNPAIR.out.concatenated
                           .dump(tag: "CAT_PAIR_UNPAIR", pretty: true)

        FASTQC_TRIMM( CAT_PAIR_UNPAIR.out.concatenated )

        /* MULTIQC_TRIMM( FASTQC_TRIMM.out.zip.collect{it[1]}, [], [], [] ) */

    emit:
        fastqc_trimm_zip_ch = FASTQC_TRIMM.out.zip.collect{it[1]}
        cat_trimm_fastq_ch  = CAT_PAIR_UNPAIR.out.concatenated
}
