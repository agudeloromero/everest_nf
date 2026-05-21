include { ABRICATE_RUN           } from "../../modules/nf-core/abricate/run/main.nf"
include { ABRICATE_SUMMARY       } from '../../modules/nf-core/abricate/summary/main'
include { SEQKIT_FILTER          } from "../../modules/local/seqkit_filter.nf"
include { PHAROKKA               } from "../../modules/local/pharokka.nf"
include { VIRSORTER_DETECT       } from "../../modules/local/virsorter_detect.nf"
include { CHECKV_VIRAL_SEQ       } from "../../modules/local/checkv_viral_seq.nf"
include { BACPHLIP_LIFE_STYLE    } from "../../modules/local/bacphlip_life_style.nf"
include { BBMAP_MAPPING_CONTIGS  } from "../../modules/local/bbmap_mapping_contigs.nf"

workflow CLEANING_CONTIGS_WF {

    take:
        repseq_fasta
        reads_ch

    main:

//LONG-READ we shouldn't need to change this workflow since the output of SPADES
//should have the same structure regardless of SR/LR

        SEQKIT_FILTER( repseq_fasta )

        //VIRSORTER_DETECT( SEQKIT_FILTER.out.filtered_fasta, params.virsorter_db )


        //NOTE: The output of nanopore analysis should be the the input for CHECKV
        CHECKV_VIRAL_SEQ( SEQKIT_FILTER.out.filtered_fasta, params.checkv_db )


        CHECKV_VIRAL_SEQ.out.renamed_fasta.dump(tag: "CHECKV_VIRAL_SEQ.out")

        bbmap_mapping_input_ch = CHECKV_VIRAL_SEQ.out.renamed_fasta.join(reads_ch)
        BBMAP_MAPPING_CONTIGS( bbmap_mapping_input_ch )


//--------------------------------
//--------------------------------
        //NOTE: This is only used for gathering the stats regarding the contigs.
            //We need to rethink whether this still makese sense, after the inclusion of
            // LR and DNA/RNA reads.
    // The BBMap stats files are consumed by the new summary post-processing steps.

//--------------------------------
//--------------------------------


        ABRICATE_RUN( CHECKV_VIRAL_SEQ.out.renamed_fasta, [] )

        ABRICATE_SUMMARY (
            ABRICATE_RUN.out.report.collect { entry -> entry[1] }.map{ reports -> [[ id: 'summary'], reports]}
        )

        BACPHLIP_LIFE_STYLE( CHECKV_VIRAL_SEQ.out.renamed_fasta )


    emit:
        fasta = CHECKV_VIRAL_SEQ.out.renamed_fasta
        bbmap_rpkm = BBMAP_MAPPING_CONTIGS.out.rpkm
        bbmap_covstats = BBMAP_MAPPING_CONTIGS.out.covstats

}
