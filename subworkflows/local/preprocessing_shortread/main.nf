#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
 * LONGREAD_PREPROCESSING: Preprocessing and QC for long reads (FASTQ input only, up to host removal)
 */

include { BBMAP_PHIX                          } from '../../../modules/local/bbmap_phix'
include { TRIMM                               } from '../../../modules/local/trimm'
include { CAT_PAIR_UNPAIR                     } from '../../../modules/local/cat_pair_unpair'

/* include { BBMAP_BBDUK as BBMAP_PHIX        } from '../../modules/nf-core/bbmap/bbduk' */

workflow SHORTREAD_PREPROCESSING {

    take:
        ch_raw_short_reads
        val_skip_qc

    main:
        // Collect version and QC output files
        ch_versions = Channel.empty()
        ch_multiqc_files = Channel.empty()

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


    emit:
        long_reads    = ch_long_reads
        versions      = ch_versions
        multiqc_files = ch_multiqc_files
}
