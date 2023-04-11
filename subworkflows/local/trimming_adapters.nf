/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors.smk */

include { BBMAP_PHIX                       } from '../../modules/local/bbmap_phix'
/* include { BBMAP_BBDUK as BBMAP_PHIX        } from '../../modules/nf-core/bbmap/bbduk' */
include { TRIMM                            } from '../../modules/local/trimm'
include { CAT_PAIR_UNPAIR                  } from '../../modules/local/cat_pair_unpair'
include { FASTQC  as FASTQC_TRIMM          } from '../../modules/nf-core/fastqc'
include { MULTIQC as MULTIQC_TRIMM         } from '../../modules/nf-core/multiqc'

workflow TRIMMING_ADAPTERS_WF {

    take:
        reads_ch // [ val(meta), [ reads ] ]

    main:

        reads_ch.dump(tag:"reads_ch")

        //TODO: Replace with the nf-core module
        BBMAP_PHIX( reads_ch ) 

        TRIMM( BBMAP_PHIX.out.clean, params.adaptor ) 

}

/*

        joint_trimm_ch = TRIMM.out.paired
                            .join(TRIMM.out.unpaired)
                            .dump(tag: "TRIMM", pretty: true)

        CAT_PAIR_UNPAIR( joint_trimm_ch )

        CAT_PAIR_UNPAIR.out.concatenated
                           .dump(tag: "CAT_PAIR_UNPAIR", pretty: true)

        FASTQC_TRIMM( CAT_PAIR_UNPAIR.out.concatenated )

        //MULTIQC_TRIMM( FASTQC_TRIMM.out.zip.collect{it[1]}, [], [], [] )

    emit:
        fastqc_trimm_zip = FASTQC_TRIMM.out.zip.collect{it[1]}
        cat_trimm_fastq  = CAT_PAIR_UNPAIR.out.concatenated

*/
