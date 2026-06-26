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
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()

    ch_samplesheet.branch { sample ->
        short_reads: !sample[0].is_long_read && !sample[0].is_contig
        long_reads:   sample[0].is_long_read && !sample[0].is_contig
        contigs:      sample[0].is_contig
    }
   .set { ch_reads_branched }

    ch_reads_branched.long_reads.dump(tag: 'ch_reads_branched.long_reads')
    ch_reads_branched.short_reads.dump(tag: 'ch_reads_branched.short_reads')
    ch_reads_branched.contigs.dump(tag: 'ch_reads_branched.contigs')

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_reads_branched.short_reads
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.map { _meta, file -> file })


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
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'everest_nf_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'everest_nf'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )

    emit:
    multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    nt_summary     = EVEREST_COMBINE_SUMMARIES.out.nt_summary
    aa_summary     = EVEREST_COMBINE_SUMMARIES.out.aa_summary
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
