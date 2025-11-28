/* https://github.com/agudeloromero/EVEREST/blob/main/SMK/02_trimming_adaptors.smk */

include { LONGREAD_PREPROCESSING              } from './preprocessing_longread'
include { SHORTREAD_PREPROCESSING              } from './preprocessing_shortread'
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

        SHORTREAD_PREPROCESSING (
            ch_short_reads,
            params.skip_shortread_qc,
        )
        ch_versions = ch_versions.mix(SHORTREAD_PREPROCESSING.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(SHORTREAD_PREPROCESSING.out.multiqc_files.collect { it[1] }.ifEmpty([]))
        ch_short_reads_preprocessed = SHORTREAD_PREPROCESSING.out.short_reads


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
