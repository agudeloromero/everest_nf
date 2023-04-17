/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors.smk */

include { BBMAP_PHIX                          } from '../../modules/local/bbmap_phix'
/* include { BBMAP_BBDUK as BBMAP_PHIX        } from '../../modules/nf-core/bbmap/bbduk' */
include { TRIMM                               } from '../../modules/local/trimm'
include { CAT_PAIR_UNPAIR                     } from '../../modules/local/cat_pair_unpair'
/* include { FASTQC  as FASTQC_TRIMM_SE          } from '../../modules/nf-core/fastqc' */
/* include { FASTQC  as FASTQC_TRIMM_PE          } from '../../modules/nf-core/fastqc' */
/* include { MULTIQC as MULTIQC_TRIMM            } from '../../modules/nf-core/multiqc' */

workflow TRIMMING_ADAPTERS_WF {

    take:
        reads_ch // [ val(meta), [ reads ] ]

    main:

        /* reads_ch.dump(tag:"reads_ch") */

        //TODO: Replace with the nf-core module
        BBMAP_PHIX( reads_ch ) 

        TRIMM( BBMAP_PHIX.out.clean, params.adaptor ) 

        //Filter single_end and paired_end samples using branch operator
        ch_trimmed = TRIMM.out.paired
                                .branch {
                                         se: it[0].single_end == true
                                         pe: it[0].single_end == false
                                     }

        ch_trimm_all_pe = ch_trimmed.pe
                            .join(TRIMM.out.unpaired)


        CAT_PAIR_UNPAIR( ch_trimm_all_pe )


        //TODO 
        /* FASTQC_TRIMM( CAT_PAIR_UNPAIR.out.concatenated ) */
        /* MULTIQC_TRIMM( FASTQC_TRIMM.out.zip.collect{it[1]}, [], [], [] ) */



       all_fastq_ch = ch_trimmed.se
                        .mix(CAT_PAIR_UNPAIR.out.concatenated)
                        .dump(tag:"all_fastq_ch")



    emit:
        /* fastqc_trimm_zip = FASTQC_TRIMM.out.zip.collect{it[1]} */
        trimm_se_fastq  = ch_trimmed.se
        cat_trimm_pe_fastq  = CAT_PAIR_UNPAIR.out.concatenated
        ch_all_fastq = all_fastq_ch

}
