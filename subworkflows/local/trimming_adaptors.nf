/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors.smk */

include { LONGREAD_PREPROCESSING as LONGREADS               } from './preprocessing_longread'
include { SHORTREAD_PREPROCESSING as SHORTREADS             } from './preprocessing_shortread'
/* include { FASTQC  as FASTQC_TRIMM_SE          } from '../../modules/nf-core/fastqc' */
/* include { FASTQC  as FASTQC_TRIMM_PE          } from '../../modules/nf-core/fastqc' */
/* include { MULTIQC as MULTIQC_TRIMM            } from '../../modules/nf-core/multiqc' */


workflow TRIMMING_ADAPTORS_WF {

    take:
        ch_shortreads // [ val(meta), [ reads ] ]
        ch_longreads // [ val(meta), [ reads ] ]

    main:

        ch_versions = Channel.empty()
        ch_multiqc_files = Channel.empty()
    //-------------
    // LONG-READS

        //NOTE FOR LONG READS
        // - no need to concatenate
        // - use nf-core/mag setup for long-read QC (step-2)

    //-------------

        ch_longreads.dump(tag:"ch_longreads")


        LONGREADS (
            ch_longreads,
            params.skip_longread_qc,
        )
        ch_versions = ch_versions.mix(LONGREADS.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(LONGREADS.out.multiqc_files.collect { it[1] }.ifEmpty([]))


    //-------------
    // SHORT-READS
    //-------------

        ch_shortreads.dump(tag:"ch_shortreads")

        SHORTREADS (
            ch_shortreads
        )
        ch_versions = ch_versions.mix(SHORTREADS.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(SHORTREADS.out.multiqc_files.collect { it[1] }.ifEmpty([]))


    emit:
        longreads_preprocessed = LONGREADS.out.longreads
        shortreads_preprocessed_se_pe = SHORTREADS.out.shortreads_preprocessed_se_pe
        shortreads_trimmed_pe = SHORTREADS.out.shortreads_trimmed_pe
        // shortreads_trimmed_single = ch_trimmed.se
        /* fastqc_trimm_zip = FASTQC_TRIMM.out.zip.collect{it[1]} */

}
