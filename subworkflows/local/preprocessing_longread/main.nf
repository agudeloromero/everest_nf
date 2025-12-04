#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
 * LONGREAD_PREPROCESSING: Preprocessing and QC for long reads (FASTQ input only, up to host removal)
 */

include { NANOPLOT as NANOPLOT_RAW         } from '../../../modules/nf-core/nanoplot/main'
include { NANOPLOT as NANOPLOT_FILTERED    } from '../../../modules/nf-core/nanoplot/main'
include { NANOLYSE                         } from '../../../modules/nf-core/nanolyse/main'
include { PORECHOP_PORECHOP                } from '../../../modules/nf-core/porechop/porechop/main'
include { PORECHOP_ABI                     } from '../../../modules/nf-core/porechop/abi/main'

workflow LONGREAD_PREPROCESSING {

    take:
        ch_raw_long_reads
        val_skip_qc

    main:
        // Collect version and QC output files
        ch_versions = Channel.empty()
        ch_multiqc_files = Channel.empty()

        // Initial QC on raw reads
        NANOPLOT_RAW(ch_raw_long_reads)
        ch_versions = ch_versions.mix(NANOPLOT_RAW.out.versions)

        // Adapter trimming
        ch_long_reads = ch_raw_long_reads
        if (!params.skip_adapter_trimming && !val_skip_qc) {
            if (params.longread_adaptertrimming_tool == 'porechop_abi') {
                PORECHOP_ABI(ch_raw_long_reads, [])
                ch_versions = ch_versions.mix(PORECHOP_ABI.out.versions)
                ch_long_reads = PORECHOP_ABI.out.reads
                ch_multiqc_files = ch_multiqc_files.mix(PORECHOP_ABI.out.log)
            } else {
                PORECHOP_PORECHOP(ch_raw_long_reads)
                ch_versions = ch_versions.mix(PORECHOP_PORECHOP.out.versions)
                ch_long_reads = PORECHOP_PORECHOP.out.reads
                ch_multiqc_files = ch_multiqc_files.mix(PORECHOP_PORECHOP.out.log)
            }
        }

        // QC for filtered reads
        if (!(val_skip_qc)) {
            if (!(params.skip_adapter_trimming && params.skip_longread_filtering && params.keep_lambda)) {
                NANOPLOT_FILTERED(ch_long_reads)
                ch_versions = ch_versions.mix(NANOPLOT_FILTERED.out.versions)
            }
        }

    emit:
        longreads     = ch_long_reads
        versions      = ch_versions
        multiqc_files = ch_multiqc_files
}
