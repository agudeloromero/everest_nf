/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { TRIMMING_ADAPTORS_WF   } from '../subworkflows/local/trimming_adaptors'
include { HOST_REMOVAL_WF as HOSTREMOVAL_SHORTREAD_WF      } from '../subworkflows/local/host_removal'
include { LONGREAD_HOSTREMOVAL as HOSTREMOVAL_LONGREAD_WF  } from '../subworkflows/local/hostremoval_longread'
include { DENOVO_WF              } from '../subworkflows/local/denovo'
include { CLEANING_CONTIGS_WF    } from '../subworkflows/local/cleaning_contigs'
include { TAXONOMY_WF            } from '../subworkflows/local/taxonomy'
include { BBMAP_PROCESS          } from '../modules/local/bbmap_process.nf'
include { MERGE_SUMMARY_BBMAP    } from '../modules/local/merge_summary_bbmap.nf'
include { UPDATE_TAXONOMIC_RANK_MANUAL } from '../modules/local/update_taxonomic_rank_manual.nf'
include { EVEREST_COMBINE_SUMMARIES } from '../modules/local/everest_combine_summaries.nf'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_everest_nf_pipeline'
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow EVEREST_NF {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    // ch_samplesheet.dump(tag: 'ch_samplesheet')

    ch_samplesheet.branch { sample ->
        short_reads: !sample[0].is_long_read && !sample[0].is_contig
        long_reads:   sample[0].is_long_read && !sample[0].is_contig
        contigs:      sample[0].is_contig
    }
   .set { ch_reads_branched }

    ch_reads_branched.long_reads.dump(tag: 'ch_reads_branched.long_reads')
    ch_reads_branched.short_reads.dump(tag: 'ch_reads_branched.short_reads')
    ch_reads_branched.contigs.dump(tag: 'ch_reads_branched.contigs')

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_reads_branched.short_reads
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect { entry -> entry[1] })
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())



    //============================
    // START: EVEREST WORKFLOW
    //============================


    // BINNING_WF -> Optional
    // PRE_TRIMMING_QC_WF -> Optional, reuse the module


        TRIMMING_ADAPTORS_WF ( ch_reads_branched.short_reads,
                               ch_reads_branched.long_reads )

        HOSTREMOVAL_LONGREAD_WF ( params.genome,
                                  TRIMMING_ADAPTORS_WF.out.longreads_preprocessed )


        HOSTREMOVAL_SHORTREAD_WF ( params.fasta,
                                   params.transcriptome,
                                   TRIMMING_ADAPTORS_WF.out.shortreads_trimmed_pe,
                                   TRIMMING_ADAPTORS_WF.out.shortreads_preprocessed_se_pe )


        DENOVO_WF( HOSTREMOVAL_SHORTREAD_WF.out.deduped_normalized_fastqgz )

        DENOVO_WF.out.repseq_fasta.dump(tag:'DENOVO_WF.out.repseq_fasta')

        // TODO: Merge  ch_reads_branched.contigs and DENOVO_WF.out.repseq_fasta
        ch_contigs = ch_reads_branched.contigs.mix(DENOVO_WF.out.repseq_fasta)
        CLEANING_CONTIGS_WF(
            ch_contigs,
            HOSTREMOVAL_SHORTREAD_WF.out.deduped_normalized_fastqgz
        )

        bbmap_process_input_ch = CLEANING_CONTIGS_WF.out.bbmap_rpkm
            .map { entry -> entry[1] }
            .mix(CLEANING_CONTIGS_WF.out.bbmap_covstats.map { entry -> entry[1] })
            .collect()

        BBMAP_PROCESS( bbmap_process_input_ch )

        TAXONOMY_WF( CLEANING_CONTIGS_WF.out.fasta )

        merge_summary_input_ch = TAXONOMY_WF.out.summary_nt
            .mix(TAXONOMY_WF.out.summary_aa)
            .collect()

        MERGE_SUMMARY_BBMAP(
            BBMAP_PROCESS.out.bbmap_stats.collect(),
            merge_summary_input_ch
        )

        taxrank_input_ch = MERGE_SUMMARY_BBMAP.out.nt_stats
            .mix(MERGE_SUMMARY_BBMAP.out.aa_stats)
            .collect()

        UPDATE_TAXONOMIC_RANK_MANUAL( taxrank_input_ch )

        EVEREST_COMBINE_SUMMARIES(
            UPDATE_TAXONOMIC_RANK_MANUAL.out.taxrank_files.collect()
        )


        /* PILON didn't work */



    //============================
    // FINISH: EVEREST WORKFLOW
    //============================


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'everest_nf_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    nt_summary     = EVEREST_COMBINE_SUMMARIES.out.nt_summary
    aa_summary     = EVEREST_COMBINE_SUMMARIES.out.aa_summary
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
