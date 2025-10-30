/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors.smk */

include { LONGREAD_PREPROCESSING              } from './preprocessing_longread'
include { BBMAP_PHIX                          } from '../../modules/local/bbmap_phix'
/* include { BBMAP_BBDUK as BBMAP_PHIX        } from '../../modules/nf-core/bbmap/bbduk' */
include { TRIMM                               } from '../../modules/local/trimm'
include { CAT_PAIR_UNPAIR                     } from '../../modules/local/cat_pair_unpair'
/* include { FASTQC  as FASTQC_TRIMM_SE          } from '../../modules/nf-core/fastqc' */
/* include { FASTQC  as FASTQC_TRIMM_PE          } from '../../modules/nf-core/fastqc' */
/* include { MULTIQC as MULTIQC_TRIMM            } from '../../modules/nf-core/multiqc' */


workflow TRIMMING_ADAPTORS_WF {

    take:
        ch_short_reads // [ val(meta), [ reads ] ]
        ch_long_reads // [ val(meta), [ reads ] ]

    main:

        ch_versions = Channel.empty()
        ch_multiqc_files = Channel.empty()
        ch_long_reads_preprocessed = Channel.empty()
        ch_short_reads_preprocessed = Channel.empty()

    //-------------
    // LONG-READS

        //NOTE FOR LONG READS
        // - no need to concatenate
        // - use nf-core/mag setup for long-read QC (step-2)

    //-------------

        ch_long_reads.dump(tag:"ch_long_reads")


        LONGREAD_PREPROCESSING (
            ch_long_reads,
            params.skip_longread_qc,
        )
        ch_versions = ch_versions.mix(LONGREAD_PREPROCESSING.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(LONGREAD_PREPROCESSING.out.multiqc_files.collect { it[1] }.ifEmpty([]))
        ch_long_reads_preprocessed = LONGREAD_PREPROCESSING.out.long_reads


    //-------------
    // SHORT-READS
    //-------------

        ch_short_reads.dump(tag:"short_reads")

        //TODO: Replace with the nf-core module
        BBMAP_PHIX( ch_short_reads )

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



       ch_short_reads_preprocessed = ch_trimmed.se
                                        .mix(CAT_PAIR_UNPAIR.out.concatenated)
                                        /* .dump(tag:"all_fastq_ch") */



    emit:
        longreads_preprocessed = ch_long_reads_preprocessed
        shortreads_preprocessed_se_pe = ch_short_reads_preprocessed
        shortreads_trimmed_pe = TRIMM.out.paired
        // shortreads_trimmed_single = ch_trimmed.se
        /* fastqc_trimm_zip = FASTQC_TRIMM.out.zip.collect{it[1]} */

}
