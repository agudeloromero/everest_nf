include { ABRICATE_RUN           } from "../../../modules/nf-core/abricate/run/main.nf"
include { ABRICATE_SUMMARY       } from '../../../modules/nf-core/abricate/summary/main'
include { dbStaged; dbMounted   } from "../db_inputs"
include { SEQKIT_FILTER          } from "../../../modules/local/seqkit_filter/main"
include { PHAROKKA               } from "../../../modules/local/pharokka/main"
include { VIRSORTER_DETECT       } from "../../../modules/local/virsorter_detect/main"
include { CHECKV_VIRAL_SEQ       } from "../../../modules/local/checkv_viral_seq/main"
include { BACPHLIP_LIFE_STYLE    } from "../../../modules/local/bacphlip_life_style/main"
include { BBMAP_MAPPING_CONTIGS  } from "../../../modules/local/bbmap_mapping_contigs/main"

workflow CLEANING_CONTIGS_WF {

    take:
        repseq_fasta
        reads_ch

    main:

        // versions now flow via channel.topic('versions')
        ch_multiqc_files = Channel.empty()

//LONG-READ we shouldn't need to change this workflow since the output of SPADES
//should have the same structure regardless of SR/LR

        SEQKIT_FILTER( repseq_fasta )

        //VIRSORTER_DETECT( SEQKIT_FILTER.out.filtered_fasta, params.virsorter_db )


        // A sample whose contigs are all shorter than the SEQKIT_FILTER cut-off leaves an
        // empty FASTA; CheckV aborts on empty input ("input FASTA file is empty") and that
        // single task failure used to terminate the whole cohort. Drop such samples here.
        filtered_contigs_ch = SEQKIT_FILTER.out.filtered_fasta
            .filter { meta, fasta ->
                if (fasta.size() > 0) return true
                log.warn "[everest] ${meta.id}: no contigs left after length filtering (SEQKIT_FILTER); skipping CheckV and downstream contig steps"
                return false
            }

        //NOTE: The output of nanopore analysis should be the the input for CHECKV
        CHECKV_VIRAL_SEQ( filtered_contigs_ch, dbStaged(params.checkv_db), dbMounted(params.checkv_db) )

        // CheckV can also run cleanly yet keep no sequences; BBMap (empty reference),
        // Bacphlip and the taxonomy steps would then fail on an empty FASTA.
        checkv_contigs_ch = CHECKV_VIRAL_SEQ.out.renamed_fasta
            .filter { meta, fasta ->
                if (fasta.size() > 0) return true
                log.warn "[everest] ${meta.id}: CheckV kept no sequences; skipping downstream contig steps"
                return false
            }

        checkv_contigs_ch.dump(tag: "CHECKV_VIRAL_SEQ.out")

        bbmap_mapping_input_ch = checkv_contigs_ch.join(reads_ch)
        BBMAP_MAPPING_CONTIGS( bbmap_mapping_input_ch )


//--------------------------------
//--------------------------------
        //NOTE: This is only used for gathering the stats regarding the contigs.
            //We need to rethink whether this still makese sense, after the inclusion of
            // LR and DNA/RNA reads.
    // The BBMap stats files are consumed by the new summary post-processing steps.

//--------------------------------
//--------------------------------


        ABRICATE_RUN( checkv_contigs_ch, [] )

        ABRICATE_SUMMARY (
            ABRICATE_RUN.out.report.collect { entry -> entry[1] }.map{ reports -> [[ id: 'summary'], reports]}
        )
        // AMR/virulence summary — MultiQC has a first-party abricate module.
        ch_multiqc_files = ch_multiqc_files.mix(ABRICATE_SUMMARY.out.report.map { it[1] })

        BACPHLIP_LIFE_STYLE( checkv_contigs_ch )


    emit:
        fasta = checkv_contigs_ch
        bbmap_rpkm = BBMAP_MAPPING_CONTIGS.out.rpkm
        bbmap_covstats = BBMAP_MAPPING_CONTIGS.out.covstats
        multiqc_files = ch_multiqc_files

}
